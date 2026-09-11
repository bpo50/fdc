#!/usr/bin/env bash
# (#12/#15) Every fdc-version stamp must equal FDC_VERSION in templates/scripts/fdc.conf,
# and the installed copies (scripts/, .githooks/) must be byte-identical to templates/.
set -u
here=$(cd "$(dirname "$0")" && pwd); root=$(cd "$here/../../.." && pwd); cd "$root"
pass=0; fail=0
want=$(sed -n 's/^FDC_VERSION="\(.*\)"/\1/p' templates/scripts/fdc.conf)
[[ -n "$want" ]] && { pass=$((pass+1)); echo "PASS  FDC_VERSION in fdc.conf = $want"; } || { fail=$((fail+1)); echo "FAIL  no FDC_VERSION in templates/scripts/fdc.conf"; }
bad=$(grep -Hno 'fdc-version: [0-9.]*' templates/scripts/*.sh templates/scripts/fdc.conf templates/AGENTS.md scripts/*.sh scripts/fdc.conf AGENTS.md LLM_PROMPT.md 2>/dev/null | grep -v "fdc-version: $want\$" || true)
[[ -z "$bad" ]] && { pass=$((pass+1)); echo "PASS  all fdc-version stamps = $want"; } || { fail=$((fail+1)); echo "FAIL  stamps not equal to $want:"; printf '%s\n' "$bad"; }
for f in templates/scripts/*.sh templates/scripts/fdc.conf templates/.githooks/pre-commit; do
    case "$f" in templates/.githooks/*) b=".githooks/$(basename "$f")" ;; *) b="scripts/$(basename "$f")" ;; esac
    [[ -f "$b" ]] || { fail=$((fail+1)); echo "FAIL  $b missing"; continue; }
    if [[ "$b" == scripts/fdc.conf ]]; then
        # conf is per-repo: only the shipped version line must match
        [[ "$(sed -n 's/^FDC_VERSION="\(.*\)"/\1/p' "$b")" == "$want" ]] && { pass=$((pass+1)); echo "PASS  scripts/fdc.conf FDC_VERSION = $want"; } || { fail=$((fail+1)); echo "FAIL  scripts/fdc.conf FDC_VERSION != $want"; }
    elif diff -q "$f" "$b" >/dev/null; then pass=$((pass+1)); echo "PASS  $b matches template"
    else fail=$((fail+1)); echo "FAIL  $b differs from template"; fi
done
echo; echo "$pass passed, $fail failed"; [[ $fail -eq 0 ]]
