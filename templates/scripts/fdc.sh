#!/usr/bin/env bash
# scripts/fdc.sh
# fdc-version: 2026.09.13
#
# Single entry point for the Folder-Doc Convention tooling. Every subcommand
# is a thin wrapper over the sibling scripts; `doctor` is the one an agent
# runs at session start to self-heal a clone.
#
#   fdc.sh doctor          hook installed? version behind upstream? tools? who am I? open notes/briefs?
#   fdc.sh check           run the drift check (what the pre-commit hook runs)
#   fdc.sh install-hook    activate .githooks/ via core.hooksPath (idempotent)
#   fdc.sh update [ref]    pull scripts + .githooks from FDC_UPSTREAM at <ref> (default: newest tag)
#   fdc.sh stale           staleness + trust-tier report
#   fdc.sh log             regenerate fdc/log.md from git
#   fdc.sh graph           build graphify-out/fdc-graph.json
#   fdc.sh index           regenerate the ## Index lists in fdc/*/<type>.md from frontmatter
#   fdc.sh notes           open notes addressed to me or to the team
#   fdc.sh findings        open troubleshooting notes (known, unresolved problems)
#   fdc.sh archive [--dry-run]   move end-state docs older than FDC_ARCHIVE_DAYS into fdc/archive/
#   fdc.sh prune [--dry-run|--yes]  delete fdc/archive/ entries older than FDC_PRUNE_DAYS (git keeps them)
#   fdc.sh budget          lines per area, largest docs, docs over budget — the token-cost report
#   fdc.sh whoami          the actor id used for verified:/from:/to:
#
# Portable: stock macOS bash 3.2 and Linux (Git Bash on Windows).
set -euo pipefail
root=$(git rev-parse --show-toplevel 2>/dev/null || pwd); cd "$root"
S="$root/scripts"
# shellcheck disable=SC1090
[[ -f "$S/fdc.conf" ]] && . "$S/fdc.conf"

usage() { echo "usage: bash scripts/fdc.sh <subcommand>"; echo; sed -n '8,22p' "$0" | sed 's/^# \{0,1\}//'; }

whoami_actor() {
    local e n
    e=$(git config --get user.email 2>/dev/null || true)
    if [[ -n "$e" ]]; then echo "human:${e%%@*}"; return; fi
    n=$(git config --get user.name 2>/dev/null || true)
    if [[ -n "$n" ]]; then echo "human:$(printf '%s' "$n" | tr 'A-Z ' 'a-z-')"; return; fi
    echo "human:${USER:-unknown}"
}

fm_get() { awk -v key="$2" '{ sub(/\r$/,"") } NR==1 { if ($0!="---") exit; next } $0=="---" { exit } index($0, key ":")==1 { v=$0; sub(/^[^:]*:[[:space:]]*["'"'"']?/,"",v); sub(/["'"'"'][[:space:]]*$/,"",v); print v; exit }' "$1"; }

list_notes() {  # open notes to me / team / me-as-author
    local me f to st from
    me=$(whoami_actor)
    [[ -d fdc/notes ]] || return 0
    while IFS= read -r f; do
        [[ "$f" == fdc/notes/notes.md ]] && continue
        st=$(fm_get "$f" status); [[ "$st" == open ]] || continue
        to=$(fm_get "$f" to); from=$(fm_get "$f" from)
        if [[ "$to" == "$me" || "$to" == team || ( "$to" == me && "$from" == "$me" ) ]]; then
            echo "   $f  — $(fm_get "$f" title)  (from $from, $(fm_get "$f" timestamp))"
        fi
    done < <(find fdc/notes -maxdepth 1 -type f -name '*.md' | sort)
}

list_findings() {  # troubleshooting notes with status: open
    local f st
    [[ -d fdc/troubleshooting ]] || return 0
    while IFS= read -r f; do
        [[ "$f" == fdc/troubleshooting/troubleshooting.md ]] && continue
        st=$(fm_get "$f" status); [[ "$st" == open ]] || continue
        echo "   $f  — $(fm_get "$f" title)  (since $(fm_get "$f" timestamp)$( o=$(fm_get "$f" owners); [[ -n "$o" ]] && echo ", owners: $o"))"
    done < <(find fdc/troubleshooting -maxdepth 1 -type f -name '*.md' | sort)
}

# Age of a doc: its frontmatter timestamp ("created or last materially updated"
# per the convention), falling back to the git commit date when there is none.
# Frontmatter first on purpose — a migration or a mass rename touches every
# file in git without changing what the docs say.
doc_age_epoch() {
    local f="$1" t d e=0
    d=$(fm_get "$f" timestamp); d=${d:0:10}
    [[ -n "$d" ]] && e=$(date -j -f '%Y-%m-%d' "$d" +%s 2>/dev/null || date -d "$d" +%s 2>/dev/null || echo 0)
    [[ "$e" -gt 0 ]] && { echo "$e"; return; }
    t=$(git log -1 --format=%ct -- "$f" 2>/dev/null || true)
    echo "${t:-0}"
}

# End-state statuses per subfolder: docs in these states are not current knowledge.
end_state() {
    case "$1/$2" in
        decisions/superseded|decisions/rejected|troubleshooting/resolved|troubleshooting/accepted|briefs/done|briefs/dropped|notes/done|notes/read|work/done|work/dropped|runbooks/retired) return 0 ;;
    esac
    return 1
}

cmd_archive() {
    local dry=0 days="${FDC_ARCHIVE_DAYS:-90}" cutoff sub f st n=0
    [[ "${1:-}" == --dry-run ]] && dry=1
    cutoff=$(( $(date +%s) - days*86400 ))
    for sub in decisions runbooks troubleshooting briefs notes work; do
        [[ -d "fdc/$sub" ]] || continue
        while IFS= read -r f; do
            [[ "$f" == "fdc/$sub/$sub.md" ]] && continue
            st=$(fm_get "$f" status); end_state "$sub" "$st" || continue
            [[ "$(doc_age_epoch "$f")" -lt "$cutoff" ]] || continue
            n=$((n+1))
            if [[ $dry -eq 1 ]]; then echo "   would archive  $f  ($st)"; continue; fi
            mkdir -p "fdc/archive/$sub"
            if git ls-files --error-unmatch "$f" >/dev/null 2>&1; then git mv -k "$f" "fdc/archive/$sub/"; else mv "$f" "fdc/archive/$sub/"; fi
            echo "   archived  $f  → fdc/archive/$sub/  ($st)"
        done < <(find "fdc/$sub" -maxdepth 1 -type f -name '*.md' | sort)
    done
    [[ $dry -eq 1 ]] && echo "[fdc archive] dry run: $n candidate(s) older than ${days}d in an end state. Run without --dry-run to move them." \
                     || { echo "[fdc archive] $n doc(s) moved. fdc/archive/ is never read by default, validated, indexed, or audited. Commit the move; run 'fdc.sh index'."; [[ $n -gt 0 ]] && cmd_index >/dev/null; }
    return 0
}

cmd_prune() {
    local mode="${1:---dry-run}" days="${FDC_PRUNE_DAYS:-365}" cutoff f n=0
    [[ -d fdc/archive ]] || { echo "[fdc prune] no fdc/archive/."; return 0; }
    cutoff=$(( $(date +%s) - days*86400 ))
    while IFS= read -r f; do
        [[ "$(doc_age_epoch "$f")" -lt "$cutoff" ]] || continue
        n=$((n+1))
        if [[ "$mode" == --yes ]]; then
            if git ls-files --error-unmatch "$f" >/dev/null 2>&1; then git rm -q "$f"; else rm -f "$f"; fi
            echo "   deleted  $f"
        else echo "   would delete  $f"; fi
    done < <(find fdc/archive -type f -name '*.md' | sort)
    [[ "$mode" == --yes ]] && echo "[fdc prune] $n file(s) deleted (still in git history). Commit the deletion." \
                           || echo "[fdc prune] dry run: $n archived file(s) older than ${days}d. Run with --yes to delete."
    return 0
}

cmd_budget() {
    local fl="${FDC_BUDGET_FOLDER_LINES:-150}" dl="${FDC_BUDGET_DOC_LINES:-300}" tl="${FDC_BUDGET_TOTAL_LINES:-6000}" total=0 over=0 area n lines
    echo "[fdc budget] lines per area (what a session may load):"
    area_lines() { local sum=0 c=0; while IFS= read -r f; do [[ -z "$f" ]] && continue; n=$(wc -l < "$f" | tr -d ' '); sum=$((sum+n)); c=$((c+1)); done; echo "$sum $c"; }
    read -r lines n < <(git ls-files '*.md' 2>/dev/null | grep -v '^fdc/' | grep -v '^AGENTS.md$\|^CLAUDE.md$\|^readme.md$\|^README.md$' | area_lines)
    printf '   %-22s %6s lines %4s files\n' "folder docs" "$lines" "$n"; total=$((total+lines))
    for area in decisions runbooks troubleshooting briefs notes; do
        [[ -d "fdc/$area" ]] || continue
        read -r lines n < <(find "fdc/$area" -maxdepth 1 -type f -name '*.md' | area_lines)
        printf '   %-22s %6s lines %4s files\n' "fdc/$area" "$lines" "$n"; total=$((total+lines))
    done
    read -r lines n < <(find fdc/work -maxdepth 1 -type f -name '*.md' 2>/dev/null | area_lines)
    printf '   %-22s %6s lines %4s files   (ephemeral — not read by default)\n' "fdc/work" "$lines" "$n"
    read -r lines n < <(find fdc/archive -type f -name '*.md' 2>/dev/null | area_lines)
    printf '   %-22s %6s lines %4s files   (never read by default)\n' "fdc/archive" "$lines" "$n"
    echo "   active layer total      $total lines  (budget FDC_BUDGET_TOTAL_LINES=$tl)$( [[ $total -gt $tl ]] && echo '  ← over budget')"
    echo "[fdc budget] largest active docs:"
    { git ls-files '*.md' 2>/dev/null | grep -v '^fdc/archive/\|^fdc/work/'; } | while IFS= read -r f; do [[ -f "$f" ]] && printf '%6s %s\n' "$(wc -l < "$f" | tr -d ' ')" "$f"; done | sort -rn | head -10 | sed 's/^/   /'
    echo "[fdc budget] over budget (folder docs > $fl, fdc docs > $dl):"
    while IFS= read -r f; do
        [[ -f "$f" ]] || continue
        n=$(wc -l < "$f" | tr -d ' ')
        case "$f" in fdc/archive/*|fdc/work/*) continue ;; fdc/*) [[ $n -gt $dl ]] && { echo "   $f  $n lines  over $dl"; over=$((over+1)); } ;; *) [[ $n -gt $fl ]] && { echo "   $f  $n lines  over $fl"; over=$((over+1)); } ;; esac
    done < <(git ls-files '*.md' 2>/dev/null; git ls-files --others --exclude-standard '*.md' 2>/dev/null)
    [[ $over -eq 0 ]] && echo "   none"
    echo "[fdc budget] archive candidates now: $(cmd_archive --dry-run | grep -c 'would archive' || true)   (fdc.sh archive --dry-run)"
    return 0
}

newest_upstream_tag() {
    [[ -n "${FDC_UPSTREAM:-}" && "$FDC_UPSTREAM" != *"{{"* ]] || return 1
    git ls-remote --tags --refs "$FDC_UPSTREAM" 2>/dev/null | sed 's#.*/tags/##' | grep -E '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}' | sort | tail -1
}

cmd_index() {
    local sub type f title desc st date line tmp
    for sub in decisions runbooks troubleshooting briefs notes work; do
        [[ -f "fdc/$sub/$sub.md" ]] || continue
        tmp=$(mktemp)
        # keep everything up to and including the "## Index" heading
        awk '{ print } /^## Index[[:space:]]*$/ { exit }' "fdc/$sub/$sub.md" > "$tmp"
        grep -q '^## Index' "$tmp" || printf '\n## Index\n' >> "$tmp"
        echo >> "$tmp"
        local n=0
        while IFS= read -r f; do
            [[ "$f" == "fdc/$sub/$sub.md" ]] && continue
            title=$(fm_get "$f" title); [[ -z "$title" ]] && title=$(basename "$f" .md)
            desc=$(fm_get "$f" description); st=$(fm_get "$f" status); date=$(fm_get "$f" timestamp)
            line="- [$title]($(basename "$f"))"
            [[ "$sub" == decisions && -n "$date" ]] && line="- ${date:0:10} — [$title]($(basename "$f"))"
            [[ -n "$desc" ]] && line="$line — $desc"
            [[ -n "$st" ]] && line="$line (\`$st\`)"
            echo "$line" >> "$tmp"; n=$((n+1))
        done < <(find "fdc/$sub" -maxdepth 1 -type f -name '*.md' | sort)
        [[ $n -eq 0 ]] && echo "_No entries yet._" >> "$tmp"
        mv "$tmp" "fdc/$sub/$sub.md"
        echo "[fdc index] fdc/$sub/$sub.md — $n entries"
    done
}

cmd_update() {
    local ref="${1:-}" tmp
    [[ -n "${FDC_UPSTREAM:-}" && "$FDC_UPSTREAM" != *"{{"* ]] || { echo "[fdc update] FDC_UPSTREAM is not set in scripts/fdc.conf"; exit 1; }
    [[ -z "$ref" ]] && ref=$(newest_upstream_tag || true)
    [[ -n "$ref" ]] || { echo "[fdc update] no version tags found at $FDC_UPSTREAM"; exit 1; }
    tmp=$(mktemp -d)
    echo "[fdc update] fetching $FDC_UPSTREAM @ $ref"
    git -c advice.detachedHead=false clone -q --depth 1 --branch "$ref" "$FDC_UPSTREAM" "$tmp/up" || { echo "[fdc update] clone failed"; rm -rf "$tmp"; exit 1; }
    [[ -d "$tmp/up/templates/scripts" ]] || { echo "[fdc update] upstream has no templates/scripts — wrong URL?"; rm -rf "$tmp"; exit 1; }
    mkdir -p scripts .githooks
    cp "$tmp/up"/templates/scripts/*.sh scripts/
    [[ -f "$tmp/up/templates/.githooks/pre-commit" ]] && cp "$tmp/up/templates/.githooks/pre-commit" .githooks/
    chmod +x scripts/*.sh .githooks/pre-commit 2>/dev/null || true
    if [[ -f scripts/fdc.conf ]]; then
        sed "s#^FDC_VERSION=.*#FDC_VERSION=\"$ref\"#" scripts/fdc.conf > scripts/fdc.conf.tmp && mv scripts/fdc.conf.tmp scripts/fdc.conf
    else
        cp "$tmp/up/templates/scripts/fdc.conf" scripts/fdc.conf
        sed "s#^FDC_VERSION=.*#FDC_VERSION=\"$ref\"#; s#^FDC_UPSTREAM=.*#FDC_UPSTREAM=\"$FDC_UPSTREAM\"#" scripts/fdc.conf > scripts/fdc.conf.tmp && mv scripts/fdc.conf.tmp scripts/fdc.conf
    fi
    rm -rf "$tmp"
    bash scripts/install-hook.sh >/dev/null 2>&1 || true
    echo "[fdc update] scripts/ and .githooks/ now at $ref (fdc.conf kept; FDC_VERSION set). Review with: git diff --stat"
    echo "[fdc update] Docs/templates (AGENTS.md rules, fdc/ index templates) are NOT touched — run LLM_UPDATE_PROMPT.md from upstream for those."
}

cmd_doctor() {
    local fixed=0 warn=0 me t hp latest
    me=$(whoami_actor)
    echo "[fdc doctor] repo: $root"
    echo "   identity   $me   (used for verified:/from:/to:; from git config user.email)"
    echo "   version    ${FDC_VERSION:-unknown}   team=${FDC_TEAM:-?} credentials=${FDC_CREDENTIALS_POLICY:-?} commits=${FDC_COMMIT_POLICY:-?}"
    # hook
    hp=$(git config --get core.hooksPath || true)
    if [[ -f .githooks/pre-commit ]]; then
        if [[ "$hp" == ".githooks" ]]; then echo "   hook       OK  core.hooksPath=.githooks"
        elif [[ -z "$hp" ]]; then git config core.hooksPath .githooks; chmod +x .githooks/pre-commit 2>/dev/null || true; echo "   hook       FIXED  set core.hooksPath=.githooks"; fixed=$((fixed+1))
        else echo "   hook       WARN  core.hooksPath=$hp (another manager) — add scripts/check-docs-fresh.sh to its pre-commit stage"; warn=$((warn+1)); fi
    else
        local h; h="$(git rev-parse --git-path hooks)/pre-commit"
        if [[ -x "$h" ]] && grep -q check-docs-fresh "$h"; then echo "   hook       OK  $h"
        else bash "$S/install-hook.sh" >/dev/null 2>&1 && { echo "   hook       FIXED  installed $h"; fixed=$((fixed+1)); } || { echo "   hook       WARN  could not install (run: bash scripts/install-hook.sh)"; warn=$((warn+1)); }; fi
    fi
    # version vs upstream
    if [[ -z "${FDC_UPSTREAM:-}" || "$FDC_UPSTREAM" == *"{{"* ]]; then echo "   upstream   WARN  FDC_UPSTREAM not set in scripts/fdc.conf — updates disabled"; warn=$((warn+1))
    else
        latest=$(newest_upstream_tag || true)
        if [[ -z "$latest" ]]; then echo "   upstream   --  unreachable or no tags (offline?) — skipped"
        elif [[ "$latest" != "${FDC_VERSION:-}" && "$latest" > "${FDC_VERSION:-}" ]]; then echo "   upstream   WARN  newer version $latest available (installed ${FDC_VERSION:-?}) — run: bash scripts/fdc.sh update"; warn=$((warn+1))
        else echo "   upstream   OK  $latest"; fi
    fi
    # tools
    local missing=""; for t in rg fd jq yq; do command -v "$t" >/dev/null 2>&1 || missing="$missing $t"; done
    [[ -z "$missing" ]] && echo "   tools      OK  rg fd jq yq" || echo "   tools      --  missing:$missing (fall back to grep/find; see AGENTS.md)"
    # team safety
    if [[ -z "${FDC_TEAM:-}" || -z "${FDC_CREDENTIALS_POLICY:-}" || -z "${FDC_COMMIT_POLICY:-}" ]]; then echo "   policy     WARN  FDC_TEAM / FDC_CREDENTIALS_POLICY / FDC_COMMIT_POLICY not set in scripts/fdc.conf — bootstrap (LLM_PROMPT.md Step 0) not finished"; warn=$((warn+1))
    elif [[ "$FDC_TEAM" == team && "$FDC_CREDENTIALS_POLICY" == A ]]; then
        if [[ -n "${FDC_CREDENTIALS_OVERRIDE:-}" ]]; then echo "   policy     WARN  team repo with credentials policy A, override: $FDC_CREDENTIALS_OVERRIDE"; warn=$((warn+1))
        else echo "   policy     ERROR team repo with credentials policy A and no FDC_CREDENTIALS_OVERRIDE — commits are blocked until you set it or switch to B"; warn=$((warn+1)); fi
    fi
    # log: regenerate if gitignored (team mode) so it is fresh locally
    if [[ -d fdc ]] && git check-ignore -q fdc/log.md 2>/dev/null; then bash "$S/fdc-log.sh" >/dev/null 2>&1 && echo "   log        OK  fdc/log.md regenerated (gitignored)"; fi
    # notes + briefs
    local notes; notes=$(list_notes)
    if [[ -n "$notes" ]]; then echo "   notes      open notes for you:"; printf '%s\n' "$notes"; else echo "   notes      none open for $me"; fi
    local fnd; fnd=$(list_findings)
    if [[ -n "$fnd" ]]; then echo "   findings   open (known, unresolved — read before diagnosing):"; printf '%s\n' "$fnd"; fi
    if [[ -d fdc/briefs ]]; then
        local b; b=$(for f in fdc/briefs/*.md; do [[ "$f" == fdc/briefs/briefs.md || ! -f "$f" ]] && continue; st=$(fm_get "$f" status); [[ "$st" == open || "$st" == claimed ]] && echo "   $f  ($st$( [[ "$st" == claimed ]] && echo ", owners: $(fm_get "$f" owners)"))  — $(fm_get "$f" title)"; done)
        [[ -n "$b" ]] && { echo "   briefs     open/claimed:"; printf '%s\n' "$b"; }
    fi
    if [[ -d fdc ]]; then
        local tl="${FDC_BUDGET_TOTAL_LINES:-6000}" act; act=$(cmd_budget | awk '/active layer total/ { print $4 }')
        [[ -n "$act" && "$act" -gt "$tl" ]] && { echo "   budget     WARN  active knowledge layer is $act lines (budget $tl) — run: bash scripts/fdc.sh budget / archive --dry-run"; warn=$((warn+1)); }
    fi
    echo "[fdc doctor] $fixed fixed, $warn warnings."
    return 0
}

case "${1:-}" in
    doctor)       cmd_doctor ;;
    check)        exec bash "$S/check-docs-fresh.sh" ;;
    install-hook) exec bash "$S/install-hook.sh" ;;
    update)       shift; cmd_update "$@" ;;
    stale)        exec bash "$S/fdc-stale.sh" ;;
    log)          exec bash "$S/fdc-log.sh" ;;
    graph)        exec bash "$S/fdc-graph.sh" ;;
    index)        cmd_index ;;
    notes)        list_notes ;;
    findings)     list_findings ;;
    archive)      shift; cmd_archive "$@" ;;
    prune)        shift; cmd_prune "$@" ;;
    budget)       cmd_budget ;;
    whoami)       whoami_actor ;;
    -h|--help|help|"") usage; [[ -n "${1:-}" ]] ;;
    *)            echo "fdc.sh: unknown subcommand '$1'"; echo; usage; exit 2 ;;
esac
