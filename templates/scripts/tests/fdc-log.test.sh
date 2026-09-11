#!/usr/bin/env bash
# Tests for fdc-log.sh: generates fdc/log.md from git history of fdc/, newest first.
set -u
here=$(cd "$(dirname "$0")" && pwd); script="$here/../fdc-log.sh"; pass=0; fail=0
ok() { pass=$((pass+1)); echo "PASS  $1"; }; ko() { fail=$((fail+1)); echo "FAIL  $1"; }
r=$(mktemp -d); ( cd "$r" && git init -q && git config user.email t@t && git config user.name t && mkdir -p scripts fdc/runbooks && cp "$script" scripts/ \
  && printf -- '---\ntype: runbook\ntitle: Deploy X\ndescription: d\ntags: [a]\ntimestamp: 2026-01-01\n---\n# t\n\n## See also\n- x\n' > fdc/runbooks/deploy-x.md \
  && git add -A && GIT_AUTHOR_DATE=2026-01-05T10:00:00Z GIT_COMMITTER_DATE=2026-01-05T10:00:00Z git commit -qm "add deploy runbook" \
  && echo "more" >> fdc/runbooks/deploy-x.md && git add -A && GIT_AUTHOR_DATE=2026-02-10T10:00:00Z GIT_COMMITTER_DATE=2026-02-10T10:00:00Z git commit -qm "update deploy runbook" \
  && echo "x" > unrelated.txt && git add -A && GIT_AUTHOR_DATE=2026-03-01T10:00:00Z GIT_COMMITTER_DATE=2026-03-01T10:00:00Z git commit -qm "unrelated" \
  && bash scripts/fdc-log.sh >/dev/null )
log="$r/fdc/log.md"
[[ -f "$log" ]] && ok "writes fdc/log.md" || ko "log.md missing"
grep -q '^## 2026-02-10' "$log" && grep -q '^## 2026-01-05' "$log" && ok "date headings from fdc commits" || ko "date headings"
[[ $(grep -n '^## 2026-02-10' "$log" | cut -d: -f1) -lt $(grep -n '^## 2026-01-05' "$log" | cut -d: -f1) ]] && ok "newest first" || ko "ordering"
grep -q 'unrelated' "$log" && ko "non-fdc commit leaked in" || ok "non-fdc commits excluded"
grep -q 'fdc/runbooks/deploy-x.md' "$log" && ok "entries name the touched doc" || ko "doc path missing"
grep -q 'log.md' <(cd "$r" && git status --short) && ok "log.md is left for the user to commit (not auto-committed)" || ko "status"
( cd "$r" && bash scripts/fdc-log.sh >/dev/null && bash scripts/fdc-log.sh >/dev/null ) && [[ $(grep -c '^## 2026-02-10' "$log") -eq 1 ]] && ok "re-run is idempotent" || ko "idempotent"
rm -rf "$r"
echo; echo "$pass passed, $fail failed"; [[ $fail -eq 0 ]]
