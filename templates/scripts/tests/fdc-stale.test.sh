#!/usr/bin/env bash
# Tests for fdc-stale.sh: flags runbooks/troubleshooting whose `verified` (or,
# failing that, `timestamp`) date is older than FDC_STALE_DAYS. Never exits 1.
set -u
here=$(cd "$(dirname "$0")" && pwd); script="$here/../fdc-stale.sh"
pass=0; fail=0
mk() {  # mk <repo> <path> <type> <timestamp> [verified-value] [extra-frontmatter]
    mkdir -p "$1/$(dirname "$2")"
    { printf -- '---\ntype: %s\ntitle: t\ndescription: d\ntags: [a]\ntimestamp: %s\n' "$3" "$4"
      [[ -n "${5:-}" ]] && printf 'verified: %s\n' "$5"
      [[ -n "${6:-}" ]] && printf '%s\n' "$6"
      printf -- '---\n# t\n\n## See also\n- x\n'; } > "$1/$2"
}
run() { ( cd "$1" && git init -q && FDC_STALE_DAYS="${2:-180}" bash scripts/fdc-stale.sh 2>&1 ); }
check() { local name="$1" out="$2" want="$3"; if [[ "$out" == *"$want"* ]]; then pass=$((pass+1)); echo "PASS  $name"; else fail=$((fail+1)); echo "FAIL  $name"; echo "$out" | sed 's/^/      /'; fi; }
old=$(date -v-400d +%F 2>/dev/null || date -d '400 days ago' +%F); recent=$(date +%F)

r=$(mktemp -d); mkdir -p "$r/scripts"; cp "$script" "$r/scripts/"
mk "$r" fdc/runbooks/deploy-x.md runbook "$old"
out=$(run "$r"); check "old runbook without verified is flagged" "$out" "STALE  fdc/runbooks/deploy-x.md"
rm -rf "$r"

r=$(mktemp -d); mkdir -p "$r/scripts"; cp "$script" "$r/scripts/"
mk "$r" fdc/runbooks/deploy-x.md runbook "$old" "$recent"
out=$(run "$r"); check "old runbook with recent verified is not flagged" "$out" "0 stale"
rm -rf "$r"

r=$(mktemp -d); mkdir -p "$r/scripts"; cp "$script" "$r/scripts/"
mk "$r" fdc/decisions/2020-01-01-x.md decision "$old"
out=$(run "$r"); check "decisions are never flagged" "$out" "0 stale"
rm -rf "$r"

r=$(mktemp -d); mkdir -p "$r/scripts"; cp "$script" "$r/scripts/"
mk "$r" fdc/troubleshooting/boom.md troubleshooting "$old"
( cd "$r" && git init -q && FDC_STALE_DAYS=180 bash scripts/fdc-stale.sh >/dev/null 2>&1 ); rc=$?
if [[ $rc -eq 0 ]]; then pass=$((pass+1)); echo "PASS  exit code is 0 even with stale docs"; else fail=$((fail+1)); echo "FAIL  exit code was $rc"; fi
rm -rf "$r"

# --- OKF adoption: actor-tagged verified → trust tier ---
r=$(mktemp -d); mkdir -p "$r/scripts"; cp "$script" "$r/scripts/"
mk "$r" fdc/runbooks/a.md runbook "$recent" "{ by: human:bogdan, at: $recent }"
out=$(run "$r"); check "verified mapping with human: actor reports human-reviewed" "$out" "human-reviewed"
rm -rf "$r"
r=$(mktemp -d); mkdir -p "$r/scripts"; cp "$script" "$r/scripts/"
mk "$r" fdc/runbooks/a.md runbook "$recent" "{ by: claude-code/fable-5.1, at: $recent }"
out=$(run "$r"); check "verified by an agent actor reports machine-confirmed" "$out" "machine-confirmed"
rm -rf "$r"
r=$(mktemp -d); mkdir -p "$r/scripts"; cp "$script" "$r/scripts/"
mk "$r" fdc/runbooks/a.md runbook "$recent"
out=$(run "$r"); check "no verified reports unverified" "$out" "unverified"
rm -rf "$r"
r=$(mktemp -d); mkdir -p "$r/scripts"; cp "$script" "$r/scripts/"
mk "$r" fdc/runbooks/a.md runbook "$old" "" "verified:
  - { by: claude-code/fable-5.1, at: $old }
  - { by: human:bogdan, at: $recent }"
out=$(run "$r"); check "list form: latest at wins and human entry gives human-reviewed" "$out" "0 stale"
check "list form tier" "$out" "human-reviewed"
rm -rf "$r"
# --- OKF adoption: per-doc stale_after overrides the global threshold ---
r=$(mktemp -d); mkdir -p "$r/scripts"; cp "$script" "$r/scripts/"
mk "$r" fdc/runbooks/a.md runbook "$recent" "$recent" "stale_after: 2020-01-01"
out=$(run "$r"); check "stale_after in the past flags even a freshly verified doc" "$out" "STALE  fdc/runbooks/a.md"
rm -rf "$r"
r=$(mktemp -d); mkdir -p "$r/scripts"; cp "$script" "$r/scripts/"
mk "$r" fdc/runbooks/a.md runbook "$old" "$old" "stale_after: 2999-01-01"
out=$(run "$r"); check "stale_after in the future keeps an old doc fresh" "$out" "0 stale"
rm -rf "$r"

echo; echo "$pass passed, $fail failed"; [[ $fail -eq 0 ]]
