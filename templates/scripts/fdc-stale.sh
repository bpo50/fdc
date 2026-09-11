#!/usr/bin/env bash
# scripts/fdc-stale.sh
# fdc-version: 2026.09.11
#
# OPTIONAL staleness + trust audit for operational docs. The drift checker
# proves a doc was TOUCHED alongside code; it cannot tell whether a runbook
# still works or who last confirmed it. This reports, for every runbook and
# troubleshooting note:
#
#   - trust tier (OKF convention): unverified | machine-confirmed | human-reviewed
#     derived from `verified:` actors — `human:<id>` ⇒ human-reviewed,
#     anything else (`<agent>/<version>`, `process:<id>`) ⇒ machine-confirmed.
#   - staleness: `stale_after: YYYY-MM-DD` if present (absolute; stale when
#     today >= it), else latest `verified` date (else `timestamp`) older than
#     FDC_STALE_DAYS (default 180).
#
# `verified` accepts three forms:
#     verified: 2026-09-11
#     verified: { by: human:bogdan, at: 2026-09-11 }
#     verified:
#       - { by: claude-code/fable-5.1, at: 2026-09-01 }
#       - { by: human:bogdan, at: 2026-09-11 }
#
# It NEVER fails the build: exit code is always 0. Run it in CI for the report,
# or by hand before an on-call rotation. Decisions and briefs are not audited.
#
# Usage:   bash scripts/fdc-stale.sh
#          FDC_STALE_DAYS=90 bash scripts/fdc-stale.sh
#
# Portable: stock macOS /bin/bash 3.2 and Linux; BSD or GNU date.
set -euo pipefail
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
# --- per-repo settings (scripts/fdc.conf overrides the defaults above) -------
fdc_root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
# shellcheck disable=SC1090
[[ -f "$fdc_root/scripts/fdc.conf" ]] && . "$fdc_root/scripts/fdc.conf"
days="${FDC_STALE_DAYS:-180}"; note_days="${FDC_NOTE_DAYS:-30}"
[[ -d fdc ]] || { echo "[fdc-stale] no fdc/ — nothing to audit."; exit 0; }

to_epoch() { date -j -f '%Y-%m-%d' "$1" +%s 2>/dev/null || date -d "$1" +%s 2>/dev/null || echo 0; }
frontmatter() { awk '{ sub(/\r$/, "") } NR==1 { if ($0!="---") exit; next } $0=="---" { exit } { print }' "$1"; }
fm_date() {  # fm_date <file> <key>  → first 10 chars of the scalar, or empty
    frontmatter "$1" | awk -v key="$2" '
        index($0, key ":")==1 { v=$0; sub(/^[^:]*:[[:space:]]*["'"'"']?/,"",v); if (v ~ /^[0-9]/) print substr(v,1,10); exit }'
}
# Emit one "AT<TAB>BY" line per verified entry (any of the three forms).
verified_entries() {
    frontmatter "$1" | awk '
        function emit(s,   a, b) {
            a = ""; b = ""
            if (match(s, /at:[[:space:]]*["'"'"']?[0-9]{4}-[0-9]{2}-[0-9]{2}/)) { a = substr(s, RSTART, RLENGTH); sub(/^at:[[:space:]]*["'"'"']?/, "", a) }
            if (match(s, /by:[[:space:]]*["'"'"']?[^,}"'"'"']+/))              { b = substr(s, RSTART, RLENGTH); sub(/^by:[[:space:]]*["'"'"']?/, "", b); sub(/[[:space:]]+$/, "", b) }
            print a "\t" b
        }
        /^verified:/ {
            rest = $0; sub(/^verified:[[:space:]]*/, "", rest)
            if (rest ~ /^\{/)            { emit(rest); next }
            if (rest ~ /^["'"'"']?[0-9]{4}-/) { v = rest; gsub(/["'"'"']/, "", v); print substr(v,1,10) "\t"; next }
            inblk = 1; next
        }
        inblk && /^[[:space:]]*-[[:space:]]*\{/ { emit($0); next }
        inblk && /^[^[:space:]]/ { inblk = 0 }
    '
}

now=$(date +%s); today=$(date +%F); cutoff=$(( now - days*86400 ))
stale=0; total=0; t_h=0; t_m=0; t_u=0
while IFS= read -r f; do
    case "$f" in
        fdc/runbooks/runbooks.md|fdc/troubleshooting/troubleshooting.md) continue ;;
        fdc/runbooks/*/*|fdc/troubleshooting/*/*) continue ;;
    esac
    total=$((total+1))

    # --- trust tier + latest verification ---
    tier=unverified; latest=""; latest_e=0
    while IFS=$'\t' read -r at by; do
        [[ -z "$at" && -z "$by" ]] && continue
        if [[ "$by" == human:* ]]; then tier=human-reviewed
        elif [[ "$tier" != human-reviewed ]]; then tier=machine-confirmed; fi
        if [[ -n "$at" ]]; then e=$(to_epoch "$at"); if [[ "$e" -gt "$latest_e" ]]; then latest_e=$e; latest=$at; fi; fi
    done < <(verified_entries "$f")
    case "$tier" in human-reviewed) t_h=$((t_h+1));; machine-confirmed) t_m=$((t_m+1));; *) t_u=$((t_u+1));; esac

    # --- staleness ---
    sa=$(fm_date "$f" stale_after)
    if [[ -n "$sa" ]]; then
        sae=$(to_epoch "$sa")
        if [[ "$sae" -eq 0 ]]; then echo "STALE  $f  (unparseable stale_after: $sa)"; stale=$((stale+1))
        elif [[ "$now" -ge "$sae" ]]; then echo "STALE  $f  (stale_after $sa has passed; $tier)"; stale=$((stale+1))
        else echo "ok     $f  ($tier; stale_after $sa)"; fi
        continue
    fi
    src=verified; d="$latest"
    [[ -z "$d" ]] && { d=$(fm_date "$f" timestamp); src=timestamp; }
    if [[ -z "$d" ]]; then echo "STALE  $f  (no verified/timestamp date; $tier)"; stale=$((stale+1)); continue; fi
    e=$(to_epoch "$d")
    if [[ "$e" -eq 0 ]]; then echo "STALE  $f  (unparseable $src: $d; $tier)"; stale=$((stale+1))
    elif [[ "$e" -lt "$cutoff" ]]; then echo "STALE  $f  ($src: $d, older than ${days}d; $tier)"; stale=$((stale+1))
    else echo "ok     $f  ($tier; $src $d)"; fi
done < <(find fdc/runbooks fdc/troubleshooting -type f -name '*.md' 2>/dev/null | sort)

# --- notes: open longer than FDC_NOTE_DAYS ---
n_open=0; n_stale=0; note_cut=$(( now - note_days*86400 ))
while IFS= read -r f; do
    [[ "$f" == fdc/notes/notes.md ]] && continue
    st=$(frontmatter "$f" | awk '/^status:/ { v=$0; sub(/^status:[[:space:]]*/,"",v); print v; exit }')
    [[ "$st" == open ]] || continue
    n_open=$((n_open+1)); d=$(fm_date "$f" timestamp); e=$(to_epoch "${d:-1970-01-01}")
    if [[ "$e" -lt "$note_cut" ]]; then echo "STALE  $f  (note open since $d, longer than ${note_days}d — act on it or close it)"; n_stale=$((n_stale+1)); fi
done < <(find fdc/notes -maxdepth 1 -type f -name '*.md' 2>/dev/null | sort)
[[ $n_open -gt 0 ]] && echo "[fdc-stale] notes: $n_open open, $n_stale stale (threshold ${note_days}d)."

echo "[fdc-stale] $total audited, $stale stale (threshold ${days}d) — human-reviewed: $t_h, machine-confirmed: $t_m, unverified: $t_u."
echo "[fdc-stale] After re-running a procedure, record it:  verified: { by: human:<you>, at: $today }"
exit 0
