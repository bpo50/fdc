#!/usr/bin/env bash
# install.sh — install or refresh the FDC tooling in the current git repo.
#
#   curl -fsSL <raw-url>/install.sh | bash -s -- init            # first install (newest tag)
#   curl -fsSL <raw-url>/install.sh | bash -s -- init 2026.09.11 # pin a version
#   bash scripts/fdc.sh update                                   # afterwards, use this instead
#
# Needs: bash, git, curl. No package manager. Installs scripts/, .githooks/,
# scripts/fdc.conf, and the /fdc/ index skeleton; then activates the hook.
# It does NOT write AGENTS.md or folder docs — paste LLM_PROMPT.md for that.
set -euo pipefail
UPSTREAM="${FDC_UPSTREAM:-https://github.com/bpo50/fdc.git}"
cmd="${1:-init}"; ref="${2:-}"
[[ "$cmd" == init || "$cmd" == update ]] || { echo "usage: install.sh init|update [version]"; exit 2; }
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "[fdc install] run this inside a git repository (git init first)."; exit 1; }
cd "$(git rev-parse --show-toplevel)"
if [[ "$cmd" == update && -f scripts/fdc.sh ]]; then exec bash scripts/fdc.sh update "$ref"; fi
[[ -n "$ref" ]] || ref=$(git ls-remote --tags --refs "$UPSTREAM" 2>/dev/null | sed 's#.*/tags/##' | grep -E '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}' | sort | tail -1)
[[ -n "$ref" ]] || { echo "[fdc install] no version tags at $UPSTREAM"; exit 1; }
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
echo "[fdc install] $UPSTREAM @ $ref"
git -c advice.detachedHead=false clone -q --depth 1 --branch "$ref" "$UPSTREAM" "$tmp/up"
mkdir -p scripts .githooks fdc/decisions fdc/runbooks fdc/troubleshooting fdc/briefs fdc/notes fdc/work
cp "$tmp/up"/templates/scripts/*.sh scripts/
[[ -f scripts/fdc.conf ]] || { cp "$tmp/up/templates/scripts/fdc.conf" scripts/fdc.conf; sed "s#^FDC_UPSTREAM=.*#FDC_UPSTREAM=\"$UPSTREAM\"#; s#^FDC_VERSION=.*#FDC_VERSION=\"$ref\"#" scripts/fdc.conf > scripts/fdc.conf.tmp && mv scripts/fdc.conf.tmp scripts/fdc.conf; }
cp "$tmp/up/templates/.githooks/pre-commit" .githooks/
for f in fdc.md decisions/decisions.md runbooks/runbooks.md troubleshooting/troubleshooting.md briefs/briefs.md notes/notes.md work/work.md; do [[ -f "fdc/$f" ]] || cp "$tmp/up/templates/fdc/$f" "fdc/$f"; done
[[ -f fdc/runbooks/onboard-developer.md ]] || cp "$tmp/up/templates/fdc/runbooks/onboard-developer.md" fdc/runbooks/
[[ -f scripts/scripts.md ]] || printf '# scripts\n\n**Purpose:** FDC tooling. Entry point `fdc.sh`; settings in `fdc.conf`. See `AGENTS.md`.\n' > scripts/scripts.md
chmod +x scripts/*.sh .githooks/pre-commit
grep -q '^graphify-out/' .gitignore 2>/dev/null || printf '\n# FDC generated output\ngraphify-out/\n' >> .gitignore
bash scripts/install-hook.sh
echo "[fdc install] done. Next: edit scripts/fdc.conf (team/policies), then paste LLM_PROMPT.md into an LLM session to write AGENTS.md and the folder docs."
