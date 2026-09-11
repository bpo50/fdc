#!/usr/bin/env bash
# scripts/fdc-graph.sh
# fdc-version: 2026.09.11
#
# Build a portable knowledge graph from the /fdc/ layer. The graph is the thing
# FDC already mandates: every long-form concept doc has typed frontmatter
# (type/title/tags) and a `## See also` section of links — those links ARE the
# relationship graph. This script extracts them into a dependency-free JSON that
# any graph tool can ingest.
#
# IMPORTANT — this is OPTIONAL and is NOT part of the pre-commit hook. It never
# blocks a commit. A teammate who has no graph tooling installed can ignore it
# entirely; FDC still works without it. Run it when you want a fresh graph.
#
# Portability: stock macOS /bin/bash (3.2) and Linux bash; BSD or GNU awk/sed.
# Output goes to graphify-out/ (gitignored by convention), so it is never shared
# state and never trips the drift checker.
#
# Optional richer rendering: if you set FDC_GRAPH_CMD, this runs it with the JSON
# path appended — wire your own tool there (e.g. graphify). Teammates who do not
# set it just get the JSON. Example:
#     FDC_GRAPH_CMD="graphify --input" bash scripts/fdc-graph.sh

set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
# --- per-repo settings (scripts/fdc.conf overrides the defaults above) -------
fdc_root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
# shellcheck disable=SC1090
[[ -f "$fdc_root/scripts/fdc.conf" ]] && . "$fdc_root/scripts/fdc.conf"

out_dir="${FDC_GRAPH_OUT:-graphify-out}"
json="$out_dir/fdc-graph.json"

if [[ ! -d fdc ]]; then
    echo "[fdc-graph] no fdc/ directory — nothing to graph."
    exit 0
fi
mkdir -p "$out_dir"

# Minimal JSON string escaping (backslash + double quote).
esc() { printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'; }

# A flat, non-index fdc concept doc? (mirrors check-docs-fresh.sh)
is_concept() {
    local f="$1" rest
    case "$f" in
        fdc/decisions/*)       rest=${f#fdc/decisions/} ;;
        fdc/runbooks/*)        rest=${f#fdc/runbooks/} ;;
        fdc/troubleshooting/*) rest=${f#fdc/troubleshooting/} ;;
        fdc/briefs/*)          rest=${f#fdc/briefs/} ;;
        *) return 1 ;;
    esac
    case "$rest" in */*) return 1 ;; *.md) ;; *) return 1 ;; esac
    case "$rest" in decisions.md|runbooks.md|troubleshooting.md|briefs.md|notes.md|work.md) return 1 ;; esac
    return 0
}

# Echo a scalar frontmatter field's value.
fm_field() {
    awk -v key="$2" '
        { sub(/\r$/, "") }
        NR == 1 { if ($0 != "---") exit; next }
        $0 == "---" { exit }
        index($0, key ":") == 1 { v = $0; sub(/^[^:]*:[[:space:]]*/, "", v); print v; exit }
    ' "$1"
}

# Echo each item of an inline (`key: [a, b]`) or block (`key:` then `- a`) list.
list_values() {
    awk -v key="$2" '
        { sub(/\r$/, "") }
        NR == 1 { if ($0 != "---") exit; next }
        $0 == "---" { exit }
        inblk && /^[[:space:]]*-[[:space:]]*/ {
            v = $0; sub(/^[[:space:]]*-[[:space:]]*/, "", v)
            if (v != "") print v; next
        }
        inblk && /^[^[:space:]]/ { inblk = 0 }
        index($0, key ":") == 1 {
            rest = $0; sub(/^[^:]*:[[:space:]]*/, "", rest)
            if (rest ~ /^\[/) {
                gsub(/^\[|\]$/, "", rest)
                n = split(rest, a, ",")
                for (i = 1; i <= n; i++) {
                    gsub(/^[[:space:]]+|[[:space:]]+$/, "", a[i])
                    if (a[i] != "") print a[i]
                }
            } else if (rest == "") { inblk = 1 }
            next
        }
    ' "$1"
}

# Echo each link target in the `## See also` section: markdown `(target)` and
# backticked `path` tokens that look like paths.
see_also_targets() {
    awk '
        { sub(/\r$/, "") }
        tolower($0) ~ /^##[[:space:]]+see also/ { insec = 1; next }
        insec && /^##[[:space:]]/ { insec = 0 }
        insec {
            s = $0
            while (match(s, /\([^)]+\)/)) { print substr(s, RSTART + 1, RLENGTH - 2); s = substr(s, RSTART + RLENGTH) }
            s = $0
            while (match(s, /`[^`]+`/)) {
                t = substr(s, RSTART + 1, RLENGTH - 2)
                if (t ~ /\// || t ~ /\.md$/) print t
                s = substr(s, RSTART + RLENGTH)
            }
        }
    ' "$1"
}

# resource: values inside a `sources:` block — inline `- { id: x, resource: y }`
# entries or nested `resource:` lines. Bundle paths and URLs alike become edges.
sources_resources() {
    awk '
        { sub(/\r$/, "") }
        NR==1 { if ($0!="---") exit; next }
        $0=="---" { exit }
        /^sources:/ { inblk=1; next }
        inblk && /^[^[:space:]]/ { inblk=0 }
        inblk && match($0, /resource:[[:space:]]*["'"'"']?[^,}"'"'"' ]+/) { v=substr($0,RSTART,RLENGTH); sub(/^resource:[[:space:]]*["'"'"']?/,"",v); print v }
    ' "$1"
}
emit_joined() {  # comma+newline-join the lines of a file (valid JSON array body)
    awk 'NR > 1 { printf ",\n" } { printf "%s", $0 } END { if (NR) printf "\n" }' "$1"
}

nodes_tmp="$out_dir/.nodes.tmp"; edges_tmp="$out_dir/.edges.tmp"
: > "$nodes_tmp"; : > "$edges_tmp"

find fdc -type f -name '*.md' | sort | while IFS= read -r f; do
    is_concept "$f" || continue

    ftype=$(fm_field "$f" type)
    title=$(fm_field "$f" title); [ -z "$title" ] && title="$f"

    tags_json=""
    while IFS= read -r t; do
        [ -z "$t" ] && continue
        tags_json="${tags_json}\"$(esc "$t")\","
    done < <(list_values "$f" tags)
    tags_json="[${tags_json%,}]"

    printf '    {"id":"%s","type":"%s","title":"%s","tags":%s}\n' \
        "$(esc "$f")" "$(esc "$ftype")" "$(esc "$title")" "$tags_json" >> "$nodes_tmp"

    { see_also_targets "$f"; list_values "$f" related; list_values "$f" supersedes; list_values "$f" superseded_by; sources_resources "$f"; } \
    | while IFS= read -r tgt; do
        [ -z "$tgt" ] && continue
        printf '    {"from":"%s","to":"%s"}\n' "$(esc "$f")" "$(esc "$tgt")" >> "$edges_tmp"
    done
done

sort -u "$edges_tmp" -o "$edges_tmp"   # dedup edges (a See-also link + a related: entry can repeat)

node_count=$(grep -c '"id"' "$nodes_tmp" 2>/dev/null || echo 0)
edge_count=$(grep -c '"from"' "$edges_tmp" 2>/dev/null || echo 0)

{
    printf '{\n  "nodes": [\n'
    emit_joined "$nodes_tmp"
    printf '  ],\n  "edges": [\n'
    emit_joined "$edges_tmp"
    printf '  ]\n}\n'
} > "$json"

rm -f "$nodes_tmp" "$edges_tmp"

echo "[fdc-graph] wrote $json — $node_count concept nodes, $edge_count edges."

if [[ -n "${FDC_GRAPH_CMD:-}" ]]; then
    echo "[fdc-graph] FDC_GRAPH_CMD set — handing the graph to your tool..."
    # Intentionally unquoted so FDC_GRAPH_CMD can carry args.
    # shellcheck disable=SC2086
    ${FDC_GRAPH_CMD} "$json"
else
    echo "[fdc-graph] (set FDC_GRAPH_CMD to post-process the JSON with your own graph tool, e.g. graphify.)"
fi
