#!/usr/bin/env bash
# tools/build-prompt.sh — assemble LLM_PROMPT.md from LLM_PROMPT.src.md.
#
# LLM_PROMPT.src.md contains lines of the form  {{include:templates/<path>}} ;
# each is replaced by the file's content. templates/ is therefore the ONLY
# source of truth for everything the prompt inlines.
#
#   bash tools/build-prompt.sh          # (re)generate LLM_PROMPT.md
#   bash tools/build-prompt.sh --check  # exit 1 if LLM_PROMPT.md is stale
#
# Portable: stock macOS bash 3.2 + BSD awk, or Linux.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
src=LLM_PROMPT.src.md; out=LLM_PROMPT.md

render() {
    awk '
        /^\{\{include:[^}]+\}\}$/ {
            f = $0; sub(/^\{\{include:/, "", f); sub(/\}\}$/, "", f)
            while ((getline line < f) > 0) print line
            if (close(f) != 0) { print "build-prompt: cannot read " f > "/dev/stderr"; exit 1 }
            next
        }
        { print }
    ' "$src"
}

if [[ "${1:-}" == "--check" ]]; then
    if diff -q <(render) "$out" >/dev/null; then echo "[build-prompt] $out is up to date."; exit 0; fi
    echo "[build-prompt] $out is STALE — run: bash tools/build-prompt.sh"; diff <(render) "$out" | head -20; exit 1
fi
render > "$out.tmp" && mv "$out.tmp" "$out"
echo "[build-prompt] wrote $out ($(wc -l < "$out" | tr -d ' ') lines, $(grep -c '^{{include:' "$src") includes)"
