#!/usr/bin/env bash
# Tests for check-docs-ci.sh: (#18) soft hint when commit messages suggest a
# decision/incident/fix but no /fdc/ doc changed — never affects exit code.
set -u
here=$(cd "$(dirname "$0")" && pwd); pass=0; fail=0
ok() { pass=$((pass+1)); echo "PASS  $1"; }; ko() { fail=$((fail+1)); echo "FAIL  $1"; }
mk() {  # mk <msg> <also-touch-fdc:0|1>
    local d; d=$(mktemp -d)
    ( cd "$d" && git init -q -b main && git config user.email t@t && git config user.name t && mkdir -p scripts src fdc/troubleshooting \
      && cp "$here/../check-docs-ci.sh" "$here/../check-docs-fresh.sh" scripts/ && echo "# src" > src/src.md && echo "# root" > readme.md \
      && git add -A && git commit -qm base && git checkout -qb feat && echo x > src/a.py && echo "# src2" > src/src.md \
      && { [[ "$2" == 1 ]] && printf -- '---\ntype: troubleshooting\ntitle: t\ndescription: d\ntags: [a]\ntimestamp: 2026-01-01\nstatus: resolved\n---\n# t\n\n## See also\n- x\n' > fdc/troubleshooting/boom.md; true; } \
      && git add -A && git commit -qm "$1" )
    echo "$d"
}
r=$(mk "fix: crash when db is down" 0); out=$( cd "$r" && FDC_CI_BASE=main bash scripts/check-docs-ci.sh 2>&1 ); rc=$?
[[ $rc -eq 0 && "$out" == *"hint"* ]] && ok "fix commit without fdc change prints a hint and still passes" || ko "hint (rc=$rc)"; rm -rf "$r"
r=$(mk "fix: crash when db is down" 1); out=$( cd "$r" && FDC_CI_BASE=main bash scripts/check-docs-ci.sh 2>&1 ); rc=$?
[[ $rc -eq 0 && "$out" != *"hint"* ]] && ok "fix commit with fdc change prints no hint" || ko "no hint (rc=$rc)"; rm -rf "$r"
r=$(mk "chore: bump deps" 0); out=$( cd "$r" && FDC_CI_BASE=main bash scripts/check-docs-ci.sh 2>&1 ); rc=$?
[[ $rc -eq 0 && "$out" != *"hint"* ]] && ok "neutral commit prints no hint" || ko "neutral (rc=$rc)"; rm -rf "$r"
echo; echo "$pass passed, $fail failed"; [[ $fail -eq 0 ]]
