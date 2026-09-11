#!/usr/bin/env bash
# Tests for fdc-graph.sh: See-also links and bundle-relative sources[].resource become edges.
set -u
here=$(cd "$(dirname "$0")" && pwd); script="$here/../fdc-graph.sh"; pass=0; fail=0
ok() { pass=$((pass+1)); echo "PASS  $1"; }; ko() { fail=$((fail+1)); echo "FAIL  $1"; }
r=$(mktemp -d); ( cd "$r" && git init -q && mkdir -p scripts fdc/decisions fdc/runbooks && cp "$script" scripts/ \
  && printf -- '---\ntype: decision\ntitle: D\ndescription: d\ntags: [a]\ntimestamp: 2026-01-01\nstatus: accepted\nsources:\n  - { id: rb, resource: fdc/runbooks/do-x.md, title: R }\n  - { id: ext, resource: https://example.com/x, title: E }\n---\n# D\n\n## See also\n- `src/src.md` — x\n' > fdc/decisions/2026-01-01-d.md \
  && printf -- '---\ntype: runbook\ntitle: R\ndescription: d\ntags: [a]\ntimestamp: 2026-01-01\n---\n# R\n\n## See also\n- x\n' > fdc/runbooks/do-x.md \
  && bash scripts/fdc-graph.sh >/dev/null )
j="$r/graphify-out/fdc-graph.json"
grep -q '"to":"src/src.md"' "$j" && ok "See-also link is an edge" || ko "see-also edge"
grep -q '"to":"fdc/runbooks/do-x.md"' "$j" && ok "bundle-relative sources[].resource is an edge" || ko "sources edge"
grep -q '"to":"https://example.com/x"' "$j" && ok "external source URL is an edge too" || ko "external source edge"
rm -rf "$r"
echo; echo "$pass passed, $fail failed"; [[ $fail -eq 0 ]]
