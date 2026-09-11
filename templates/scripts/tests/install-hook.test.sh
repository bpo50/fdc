#!/usr/bin/env bash
# Tests for install-hook.sh: fresh install, idempotent re-run, append to a
# foreign hook, and refusal to touch a symlinked hook (hook managers).
set -u
here=$(cd "$(dirname "$0")" && pwd); pass=0; fail=0
new_repo() { local d; d=$(mktemp -d); ( cd "$d" && git init -q && mkdir -p scripts && cp "$here/../install-hook.sh" "$here/../check-docs-fresh.sh" scripts/ ); echo "$d"; }
ok() { pass=$((pass+1)); echo "PASS  $1"; }; ko() { fail=$((fail+1)); echo "FAIL  $1"; }

r=$(new_repo); ( cd "$r" && bash scripts/install-hook.sh >/dev/null ) && grep -q check-docs-fresh "$r/.git/hooks/pre-commit" && ok "fresh install writes hook" || ko "fresh install"
( cd "$r" && bash scripts/install-hook.sh >/dev/null ) && [[ $(grep -c check-docs-fresh "$r/.git/hooks/pre-commit") -eq 1 ]] && ok "re-run is idempotent" || ko "idempotent"
rm -rf "$r"

r=$(new_repo); printf '#!/usr/bin/env bash\necho other-tool\n' > "$r/.git/hooks/pre-commit"; chmod +x "$r/.git/hooks/pre-commit"
( cd "$r" && bash scripts/install-hook.sh >/dev/null ) && grep -q other-tool "$r/.git/hooks/pre-commit" && grep -q check-docs-fresh "$r/.git/hooks/pre-commit" && ok "foreign hook is appended to, not replaced" || ko "append to foreign hook"
( cd "$r" && bash scripts/install-hook.sh >/dev/null ) && [[ $(grep -c check-docs-fresh "$r/.git/hooks/pre-commit") -eq 1 ]] && ok "append is idempotent" || ko "append idempotent"
rm -rf "$r"

r=$(new_repo); printf '#!/bin/sh\n' > "$r/managed"; ln -s "$r/managed" "$r/.git/hooks/pre-commit"
( cd "$r" && bash scripts/install-hook.sh >/dev/null 2>&1 ); rc=$?
[[ $rc -ne 0 ]] && ! grep -q check-docs-fresh "$r/managed" && ok "symlinked (managed) hook is left alone with instructions" || ko "symlinked hook (rc=$rc)"
rm -rf "$r"

echo; echo "$pass passed, $fail failed"; [[ $fail -eq 0 ]]
