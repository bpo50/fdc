#!/usr/bin/env bash
# Behavioural tests for check-docs-fresh.sh. Each test builds a throwaway git
# repo, stages a change, and asserts the checker's exit code.
# Run: bash templates/scripts/tests/check-docs-fresh.test.sh
set -u
here=$(cd "$(dirname "$0")" && pwd)
checker="$here/../check-docs-fresh.sh"
pass=0; fail=0

new_repo() {
    local d; d=$(mktemp -d)
    ( cd "$d" && git init -q && git config user.email t@t && git config user.name t \
      && mkdir -p scripts && cp "$checker" scripts/ && echo "# root" > readme.md \
      && git add -A && git commit -qm init )
    echo "$d"
}
commit_all() { ( cd "$1" && git add -A && git commit -qm "$2" ); }
expect() {  # expect <name> <repo> <want-exit>
    local name="$1" repo="$2" want="$3" got
    ( cd "$repo" && git add -A && bash scripts/check-docs-fresh.sh >/dev/null 2>&1 ); got=$?
    if [[ "$got" == "$want" ]]; then pass=$((pass+1)); echo "PASS  $name"
    else fail=$((fail+1)); echo "FAIL  $name (want exit $want, got $got)"; fi
    rm -rf "$repo"
}

# 1. Extension-less build files (Dockerfile, Makefile) count as code.
r=$(new_repo); mkdir -p "$r/svc"; echo "# svc" > "$r/svc/svc.md"; commit_all "$r" docs
printf 'FROM alpine\n' > "$r/svc/Dockerfile"; printf 'all:\n\ttrue\n' > "$r/svc/Makefile"
expect "bare Dockerfile/Makefile without doc update is blocked" "$r" 1

# 2. A sibling doc inside a deeper folder satisfies an ancestor owner.
r=$(new_repo); mkdir -p "$r/src/auth"; echo "# src" > "$r/src/src.md"
echo "x" > "$r/src/auth/x.ts"; echo "# flow" > "$r/src/auth/auth-flow.md"; commit_all "$r" base
echo "y" > "$r/src/auth/x.ts"; echo "# flow v2" > "$r/src/auth/auth-flow.md"
expect "doc change in a sub-folder covers ancestor-owned code" "$r" 0

# 3. Deleting a whole documented folder passes without touching the parent doc.
r=$(new_repo); mkdir -p "$r/old"; echo "# old" > "$r/old/old.md"; echo "x" > "$r/old/a.py"; commit_all "$r" base
rm -rf "$r/old"
expect "deleting a folder with its own index doc is not blocked" "$r" 0

# 4. Ops file types (tfvars, ini, systemd unit) count as code; .terraform/ is skipped.
r=$(new_repo); mkdir -p "$r/infra/.terraform/x"; echo "# infra" > "$r/infra/infra.md"; commit_all "$r" base
echo 'a=1' > "$r/infra/prod.tfvars"; echo '[x]' > "$r/infra/hosts.ini"; echo '[Unit]' > "$r/infra/app.service"
expect "tfvars/ini/service without doc update is blocked" "$r" 1

r=$(new_repo); mkdir -p "$r/infra/.terraform/x"; echo "# infra" > "$r/infra/infra.md"; commit_all "$r" base
echo '{}' > "$r/infra/.terraform/x/state.json"
expect "changes under .terraform/ are ignored" "$r" 0

# 5. (#10) decisions and briefs must carry a non-empty `status`.
mkfdc() {  # mkfdc <repo> <path> <type> <extra-frontmatter-lines>
    mkdir -p "$1/$(dirname "$2")"
    printf -- '---\ntype: %s\ntitle: t\ndescription: d\ntags: [a]\ntimestamp: 2026-01-01\n%s---\n# t\n\n## See also\n- x\n' "$3" "$4" > "$1/$2"
}
r=$(new_repo); mkfdc "$r" fdc/decisions/2026-01-01-x.md decision ""
expect "decision without status is rejected" "$r" 1
r=$(new_repo); mkfdc "$r" fdc/decisions/2026-01-01-x.md decision "status: accepted"$'\n'
expect "decision with status passes" "$r" 0
r=$(new_repo); mkfdc "$r" fdc/briefs/x.md brief ""
expect "brief without status is rejected" "$r" 1
r=$(new_repo); mkfdc "$r" fdc/runbooks/do-x.md runbook ""
expect "runbook without status still passes" "$r" 0

# 6. (#11) In CI range mode, a `Skip-Doc-Check:` trailer with a reason justifies a code-only commit.
range_expect() {  # range_expect <name> <repo> <want>
    local name="$1" repo="$2" want="$3" got
    ( cd "$repo" && CHECK_RANGE="main...HEAD" bash scripts/check-docs-fresh.sh >/dev/null 2>&1 ); got=$?
    if [[ "$got" == "$want" ]]; then pass=$((pass+1)); echo "PASS  $name"; else fail=$((fail+1)); echo "FAIL  $name (want exit $want, got $got)"; fi
    rm -rf "$repo"
}
mkbranch() {  # mkbranch <repo> <commit-msg>  → code-only commit on a feature branch
    ( cd "$1" && git branch -q -M main && mkdir -p src && echo "# src" > src/src.md && git add -A && git commit -qm base \
      && git checkout -qb feat && echo x > src/a.py && git add -A && git commit -qm "$2" )
}
r=$(new_repo); mkbranch "$r" "refactor: rename"
range_expect "CI range: code-only commit without trailer fails" "$r" 1
r=$(new_repo); mkbranch "$r" $'refactor: rename\n\nSkip-Doc-Check: pure rename, no documented behaviour changed'
range_expect "CI range: trailer with reason passes" "$r" 0
r=$(new_repo); mkbranch "$r" $'refactor: rename\n\nSkip-Doc-Check:'
range_expect "CI range: trailer with empty reason fails" "$r" 1

# 7. OKF-style fields validate: verified mapping/list, generated, ISO datetime timestamp, sources, not.
r=$(new_repo); mkfdc "$r" fdc/runbooks/do-x.md runbook "verified: { by: human:bogdan, at: 2026-09-11 }"$'\n'"generated: { by: claude-code/fable-5.1, at: 2026-09-11T10:00:00Z }"$'\n'
expect "verified mapping + generated validate" "$r" 0
r=$(new_repo); mkfdc "$r" fdc/decisions/2026-01-01-x.md decision "status: accepted"$'\n'"sources:"$'\n'"  - { id: t1, resource: https://example.com, title: T }"$'\n'"not:"$'\n'"  - { term: X, why: Y, instead: Z }"$'\n'
expect "sources + not blocks validate" "$r" 0
r=$(new_repo); mkdir -p "$r/fdc/briefs"; printf -- '---\ntype: brief\ntitle: t\ndescription: d\ntags: [a]\ntimestamp: 2026-09-11T10:00:00Z\nstatus: open\n---\n# t\n\n## See also\n- x\n' > "$r/fdc/briefs/x.md"
expect "ISO datetime timestamp validates" "$r" 0

# Regression guards for existing behaviour.
r=$(new_repo); mkdir -p "$r/src"; echo "# src" > "$r/src/src.md"; commit_all "$r" base
echo "x" > "$r/src/a.py"
expect "code change without owning doc is blocked" "$r" 1

r=$(new_repo); mkdir -p "$r/src"; echo "# src" > "$r/src/src.md"; commit_all "$r" base
echo "x" > "$r/src/a.py"; echo "# src v2" > "$r/src/src.md"
expect "code change with owning doc passes" "$r" 0

echo; echo "$pass passed, $fail failed"
[[ $fail -eq 0 ]]
