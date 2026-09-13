#!/usr/bin/env bash
# Tests for scripts/fdc.sh (dispatcher) + scripts/fdc.conf (manifest):
# conf overrides, doctor self-heal, whoami, update from an upstream tag,
# index generation, notes delivery.
set -u
here=$(cd "$(dirname "$0")" && pwd); T="$here/.."; pass=0; fail=0
ok() { pass=$((pass+1)); echo "PASS  $1"; }; ko() { fail=$((fail+1)); echo "FAIL  $1${2:+ — $2}"; }
fm() { printf -- '---\ntype: %s\ntitle: %s\ndescription: %s\ntags: [a]\ntimestamp: %s\n%s---\n# t\n\n## See also\n- x\n' "$1" "$2" "$3" "$4" "${5:-}"; }
new_repo() {  # a downstream repo with the templates installed
    local d; d=$(mktemp -d)
    ( cd "$d" && git init -q -b main && git config user.email bogdan@example.com && git config user.name "Bogdan" \
      && mkdir -p scripts .githooks fdc/decisions fdc/runbooks fdc/troubleshooting fdc/briefs fdc/notes fdc/work \
      && cp "$T"/*.sh scripts/ && cp "$T/fdc.conf" scripts/fdc.conf && cp "$T/../.githooks/pre-commit" .githooks/ \
      && for f in fdc decisions/decisions runbooks/runbooks troubleshooting/troubleshooting briefs/briefs notes/notes work/work; do cp "$T/../fdc/$f.md" "fdc/$f.md"; done \
      && echo "# root" > readme.md && git add -A && git commit -qm init )
    echo "$d"
}

# --- manifest overrides the checker's defaults ---
r=$(new_repo); ( cd "$r" && mkdir -p src && echo "# src" > src/src.md && git add -A && git commit -qm base \
  && printf 'CODE_REGEX=%s\n' "'\\.(zig)$'" >> scripts/fdc.conf && echo x > src/a.py && git add -A && bash scripts/check-docs-fresh.sh >/dev/null 2>&1 ); rc=$?
[[ $rc -eq 0 ]] && ok "fdc.conf CODE_REGEX override: .py no longer counts as code" || ko "conf override" "rc=$rc"
( cd "$r" && echo y > src/a.zig && git add -A && bash scripts/check-docs-fresh.sh >/dev/null 2>&1 ); rc=$?
[[ $rc -eq 1 ]] && ok "fdc.conf CODE_REGEX override: .zig counts as code" || ko "conf override zig" "rc=$rc"
rm -rf "$r"

# --- whoami ---
r=$(new_repo); out=$( cd "$r" && bash scripts/fdc.sh whoami )
[[ "$out" == "human:bogdan" ]] && ok "whoami derives human:<email local part>" || ko "whoami" "$out"
rm -rf "$r"

# --- doctor: installs missing hook via core.hooksPath, is idempotent, exit 0 ---
r=$(new_repo); out=$( cd "$r" && bash scripts/fdc.sh doctor 2>&1 ); rc=$?
hp=$( cd "$r" && git config --get core.hooksPath )
[[ $rc -eq 0 && "$hp" == ".githooks" ]] && ok "doctor sets core.hooksPath=.githooks when missing" || ko "doctor hook" "rc=$rc hp=$hp"
[[ "$out" == *"FIXED"* ]] && ok "doctor reports what it fixed" || ko "doctor FIXED line"
out=$( cd "$r" && bash scripts/fdc.sh doctor 2>&1 ); [[ "$out" != *"FIXED"* ]] && ok "doctor second run fixes nothing" || ko "doctor idempotent"
[[ "$out" == *"human:bogdan"* ]] && ok "doctor prints identity" || ko "doctor identity"
# hook actually fires through hooksPath
( cd "$r" && mkdir -p src && echo "# src" > src/src.md && git add -A && git commit -qm base && echo x > src/a.py && git add -A && git commit -qm "code only" >/dev/null 2>&1 ); rc=$?
[[ $rc -ne 0 ]] && ok "committed hook in .githooks blocks a code-only commit" || ko "hooksPath hook fires"
rm -rf "$r"

# --- doctor: version check against an upstream with a newer tag; update pulls it ---
up=$(mktemp -d); ( cd "$up" && git init -q -b main && git config user.email u@u && git config user.name u \
  && mkdir -p templates/scripts templates/.githooks && cp "$T"/*.sh "$T/fdc.conf" templates/scripts/ && cp "$T/../.githooks/pre-commit" templates/.githooks/ \
  && git add -A && git commit -qm v1 && git tag 2026.09.11 \
  && echo "# newer" >> templates/scripts/fdc-log.sh && git add -A && git commit -qm v2 && git tag 2027.01.01 )
r=$(new_repo); ( cd "$r" && sed -i.bak "s#^FDC_UPSTREAM=.*#FDC_UPSTREAM=\"$up\"#" scripts/fdc.conf && rm scripts/fdc.conf.bak )
out=$( cd "$r" && bash scripts/fdc.sh doctor 2>&1 )
[[ "$out" == *"2027.01.01"* && "$out" == *"WARN"* ]] && ok "doctor warns when upstream has a newer tag" || ko "doctor version" "$out"
out=$( cd "$r" && bash scripts/fdc.sh update 2>&1 ); rc=$?
[[ $rc -eq 0 ]] && grep -q '^# newer' "$r/scripts/fdc-log.sh" && ok "update pulls scripts from the latest upstream tag" || ko "update scripts" "rc=$rc"
grep -q 'FDC_VERSION="2027.01.01"' "$r/scripts/fdc.conf" && ok "update bumps FDC_VERSION in fdc.conf" || ko "update version"
( cd "$r" && printf 'CODE_REGEX=%s\n' "'\\.(zig)$'" >> scripts/fdc.conf && bash scripts/fdc.sh update >/dev/null 2>&1 ) && grep -q 'zig' "$r/scripts/fdc.conf" && ok "update preserves local conf settings" || ko "update preserves conf"
out=$( cd "$r" && bash scripts/fdc.sh update 2026.09.11 2>&1 ); grep -q 'FDC_VERSION="2026.09.11"' "$r/scripts/fdc.conf" && ok "update <ref> pins an explicit tag" || ko "update pin"
rm -rf "$r" "$up"

# --- index generation from frontmatter ---
r=$(new_repo); ( cd "$r" && fm decision "Use X" "Because Y." 2026-01-02 "status: accepted"$'\n' > fdc/decisions/2026-01-02-use-x.md \
  && fm decision "Use Z" "Because W." 2026-03-04 "status: proposed"$'\n' > fdc/decisions/2026-03-04-use-z.md \
  && fm runbook "Deploy X" "How to deploy." 2026-01-01 > fdc/runbooks/deploy-x.md \
  && bash scripts/fdc.sh index >/dev/null )
grep -q '\[Use X\](2026-01-02-use-x.md)' "$r/fdc/decisions/decisions.md" && grep -q 'Because W' "$r/fdc/decisions/decisions.md" && ok "index lists decisions with title/description" || ko "index decisions"
grep -q 'accepted' "$r/fdc/decisions/decisions.md" && ok "index shows status" || ko "index status"
grep -q '\[Deploy X\](deploy-x.md)' "$r/fdc/runbooks/runbooks.md" && ok "index lists runbooks" || ko "index runbooks"
grep -q '^## Template' "$r/fdc/decisions/decisions.md" && ok "index keeps the template section above" || ko "index template kept"
( cd "$r" && bash scripts/fdc.sh index >/dev/null ) && [[ $(grep -c 'Use X' "$r/fdc/decisions/decisions.md") -eq 1 ]] && ok "index is idempotent" || ko "index idempotent"
rm -rf "$r"

# --- notes: validation, delivery, staleness ---
r=$(new_repo)
( cd "$r" && fm note "Check the cron" "The nightly job looks off." 2026-01-01 > fdc/notes/check-cron.md && git add -A && bash scripts/check-docs-fresh.sh >/dev/null 2>&1 ); rc=$?
[[ $rc -eq 1 ]] && ok "note without to/from/status is rejected" || ko "note validation" "rc=$rc"
( cd "$r" && fm note "Check the cron" "The nightly job looks off." 2026-01-01 "from: human:alice"$'\n'"to: human:bogdan"$'\n'"status: open"$'\n' > fdc/notes/check-cron.md \
  && fm note "For the team" "Freeze on Friday." 2026-01-01 "from: human:alice"$'\n'"to: team"$'\n'"status: open"$'\n' > fdc/notes/freeze.md \
  && fm note "Not mine" "x" 2026-01-01 "from: human:alice"$'\n'"to: human:carol"$'\n'"status: open"$'\n' > fdc/notes/carol.md \
  && fm note "Done one" "x" 2026-01-01 "from: human:alice"$'\n'"to: human:bogdan"$'\n'"status: done"$'\n' > fdc/notes/done.md \
  && git add -A && bash scripts/check-docs-fresh.sh >/dev/null 2>&1 ); rc=$?
[[ $rc -eq 0 ]] && ok "notes with to/from/status validate" || ko "note valid" "rc=$rc"
out=$( cd "$r" && bash scripts/fdc.sh notes )
[[ "$out" == *"check-cron.md"* && "$out" == *"freeze.md"* && "$out" != *"carol.md"* && "$out" != *"done.md"* ]] && ok "notes lists open notes to me or team only" || ko "notes delivery" "$out"
out=$( cd "$r" && bash scripts/fdc.sh doctor 2>&1 ); [[ "$out" == *"check-cron.md"* ]] && ok "doctor surfaces open notes" || ko "doctor notes"
out=$( cd "$r" && FDC_NOTE_DAYS=30 bash scripts/fdc-stale.sh ); [[ "$out" == *"STALE  fdc/notes/check-cron.md"* ]] && ok "fdc-stale flags notes open longer than FDC_NOTE_DAYS" || ko "stale notes" "$out"
rm -rf "$r"

# --- dispatcher delegates ---
r=$(new_repo); out=$( cd "$r" && bash scripts/fdc.sh check 2>&1 ); rc=$?; [[ $rc -eq 0 ]] && ok "fdc.sh check delegates to the drift checker" || ko "check" "rc=$rc"
out=$( cd "$r" && bash scripts/fdc.sh bogus 2>&1 ); rc=$?; [[ $rc -ne 0 && "$out" == *"usage"* ]] && ok "unknown subcommand prints usage" || ko "usage"
rm -rf "$r"

# --- compaction: lifecycle, findings, work/, archive, prune, budget ---
old=$(date -v-400d +%F 2>/dev/null || date -d '400 days ago' +%F); recent=$(date +%F)
r=$(new_repo)
( cd "$r" && fm troubleshooting "Disk full" "Nodes fill up." "$recent" > fdc/troubleshooting/disk-full.md && git add -A && bash scripts/check-docs-fresh.sh >/dev/null 2>&1 ); rc=$?
[[ $rc -eq 1 ]] && ok "troubleshooting without status is rejected" || ko "troubleshooting status" "rc=$rc"
( cd "$r" && fm troubleshooting "Disk full" "Nodes fill up." "$recent" "status: open"$'\n' > fdc/troubleshooting/disk-full.md \
  && fm troubleshooting "Old fixed" "Was fixed." "$old" "status: resolved"$'\n' > fdc/troubleshooting/old-fixed.md \
  && fm plan "Migrate X" "Plan to migrate." "$old" "status: done"$'\n' > fdc/work/2026-01-01-migrate-x.md \
  && fm plan "Active plan" "In flight." "$recent" "status: open"$'\n' > fdc/work/active.md \
  && fm decision "Old way" "Superseded." "$old" "status: superseded"$'\n' > fdc/decisions/2025-01-01-old-way.md \
  && fm decision "Live" "Current." "$recent" "status: accepted"$'\n' > fdc/decisions/2026-09-01-live.md \
  && git add -A && bash scripts/check-docs-fresh.sh >/dev/null 2>&1 ); rc=$?
[[ $rc -eq 0 ]] && ok "open/resolved troubleshooting and fdc/work plans validate" || ko "lifecycle validate" "rc=$rc"
( cd "$r" && fm plan "No status" "x" "$recent" > fdc/work/bad.md && git add -A && bash scripts/check-docs-fresh.sh >/dev/null 2>&1 ); rc=$?
[[ $rc -eq 1 ]] && ok "fdc/work plan without status is rejected" || ko "work status" "rc=$rc"; rm -f "$r/fdc/work/bad.md"
out=$( cd "$r" && bash scripts/fdc.sh findings ); [[ "$out" == *"disk-full.md"* && "$out" != *"old-fixed.md"* ]] && ok "findings lists only open troubleshooting" || ko "findings" "$out"
out=$( cd "$r" && bash scripts/fdc.sh doctor 2>&1 ); [[ "$out" == *"disk-full.md"* ]] && ok "doctor surfaces open findings" || ko "doctor findings"
( cd "$r" && git add -A && git commit -qm docs )
out=$( cd "$r" && bash scripts/fdc.sh archive --dry-run ); [[ "$out" == *"old-fixed.md"* && "$out" == *"migrate-x.md"* && "$out" == *"old-way.md"* && "$out" != *"disk-full.md"* && "$out" != *"active.md"* && "$out" != *"live.md"* ]] && ok "archive --dry-run lists only end-state docs past FDC_ARCHIVE_DAYS" || ko "archive dry-run" "$out"
[[ -f "$r/fdc/troubleshooting/old-fixed.md" ]] && ok "dry-run moves nothing" || ko "dry-run moved"
( cd "$r" && bash scripts/fdc.sh archive >/dev/null )
[[ -f "$r/fdc/archive/troubleshooting/old-fixed.md" && -f "$r/fdc/archive/work/2026-01-01-migrate-x.md" && -f "$r/fdc/archive/decisions/2025-01-01-old-way.md" && ! -f "$r/fdc/troubleshooting/old-fixed.md" ]] && ok "archive moves docs into fdc/archive/<type>/" || ko "archive move"
( cd "$r" && git add -A && FDC_VALIDATE_ALL=1 bash scripts/check-docs-fresh.sh >/dev/null 2>&1 ); rc=$?; [[ $rc -eq 0 ]] && ok "archived docs are exempt from validation" || ko "archive exempt" "rc=$rc"
out=$( cd "$r" && bash scripts/fdc.sh stale ); [[ "$out" != *"old-fixed.md"* ]] && ok "archived docs are exempt from stale" || ko "archive stale"
( cd "$r" && bash scripts/fdc.sh index >/dev/null ); grep -q 'old-way' "$r/fdc/decisions/decisions.md" && ko "index still lists archived doc" || ok "index skips archived docs"
( cd "$r" && git add -A && git commit -qm archive >/dev/null )
out=$( cd "$r" && bash scripts/fdc.sh prune --dry-run ); [[ "$out" == *"old-fixed.md"* ]] && ok "prune --dry-run lists archive entries older than FDC_PRUNE_DAYS" || ko "prune dry-run" "$out"
[[ -f "$r/fdc/archive/troubleshooting/old-fixed.md" ]] && ok "prune without --yes deletes nothing" || ko "prune safety"
( cd "$r" && bash scripts/fdc.sh prune --yes >/dev/null ); [[ ! -f "$r/fdc/archive/troubleshooting/old-fixed.md" ]] && ok "prune --yes deletes" || ko "prune delete"
out=$( cd "$r" && mkdir -p big && { echo "# big"; for i in $(seq 1 200); do echo "line $i"; done; } > big/big.md && bash scripts/fdc.sh budget )
[[ "$out" == *"big/big.md"* && "$out" == *"over"* ]] && ok "budget flags a folder doc over FDC_BUDGET_FOLDER_LINES" || ko "budget" "$out"
[[ "$out" == *"fdc/work"* && "$out" == *"archive"* ]] && ok "budget reports lines per area incl. work and archive" || ko "budget areas"
rm -rf "$r"

# --- doctor: policy reporting ---
r=$(new_repo); out=$( cd "$r" && bash scripts/fdc.sh doctor 2>&1 )
[[ "$out" == *"policy     WARN"* && "$out" == *"not set"* ]] && ok "doctor warns when bootstrap policies are still unset" || ko "doctor unset policies" "$out"
( cd "$r" && printf 'FDC_TEAM="team"\nFDC_CREDENTIALS_POLICY="A"\nFDC_COMMIT_POLICY="A"\n' >> scripts/fdc.conf ); out=$( cd "$r" && bash scripts/fdc.sh doctor 2>&1 )
[[ "$out" == *"policy     ERROR"* && "$out" == *"FDC_CREDENTIALS_OVERRIDE"* ]] && ok "doctor reports team + A without override as ERROR" || ko "doctor team+A" "$out"
( cd "$r" && printf 'FDC_CREDENTIALS_OVERRIDE="two admins on a LAN"\n' >> scripts/fdc.conf ); out=$( cd "$r" && bash scripts/fdc.sh doctor 2>&1 )
[[ "$out" == *"policy     WARN"* && "$out" == *"two admins on a LAN"* ]] && ok "doctor shows the override reason as a warning" || ko "doctor override" "$out"
rm -rf "$r"

echo; echo "$pass passed, $fail failed"; [[ $fail -eq 0 ]]
