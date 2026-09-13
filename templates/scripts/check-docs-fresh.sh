#!/usr/bin/env bash
# scripts/check-docs-fresh.sh
# fdc-version: 2026.09.13
#
# Enforces the TOP PRIORITY rule from AGENTS.md: when code changes, the doc that
# OWNS that code must change in the same commit. It also validates required
# frontmatter on changed (or, with FDC_VALIDATE_ALL=1, all) long-form /fdc/ docs.
#
# "Owns" = the nearest ancestor folder (the file's own folder, then its parents)
# that actually has an FDC index doc. This matches the convention: leaf folders
# without their own <folder>.md are documented by the closest ancestor that has
# one (and root config files are owned by the root readme/AGENTS doc). A folder
# is NOT required to have its own doc just because code changed in it.
#
# Portability: works on stock macOS /bin/bash (3.2) and Linux bash, with BSD or
# GNU awk/grep/sed. No bash 4 features (no associative arrays), no GNU-only flags.
#
# Install (worktree- and submodule-safe):
#     bash scripts/install-hook.sh
#
# Run manually:        bash scripts/check-docs-fresh.sh
# Bypass one commit:   SKIP_DOC_CHECK=1 git commit ...
# CI (any provider):   bash scripts/check-docs-ci.sh   (or set CHECK_RANGE yourself)
#
# Env knobs:
#   CHECK_RANGE        a git range (e.g. "origin/main...HEAD") to check instead of
#                      the staged/working-tree diff. Used by CI.
#   FDC_VALIDATE_ALL=1 validate frontmatter on the WHOLE fdc/ tree, not just the
#                      changed docs. Recommended in CI / for audits. Locally the
#                      hook only checks changed fdc docs, to keep commits low-friction.

set -euo pipefail
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

# Defaults. Override in scripts/fdc.conf (never edit here — this file is
# replaced by `fdc.sh update`). See LLM_PROMPT.md "Project-type-specific
# guidance" for per-stack recommendations.
CODE_REGEX='\.(yml|yaml|json|toml|sh|py|cs|csproj|sln|rs|ts|tsx|js|jsx|mjs|cjs|vue|svelte|html|scss|css|php|blade\.php|go|rb|java|kt|groovy|xml|tf|tfvars|hcl|tpl|conf|ini|cfg|properties|service|timer|Dockerfile|j2|dart)$'
DOC_REGEX='\.md$'

# Extension-less build/ops files that are code too. Matched on the basename, so
# a bare `Dockerfile` or `Makefile` counts (CODE_REGEX only sees extensions).
CODE_BASENAME_REGEX='^(Dockerfile|Containerfile|Makefile|GNUmakefile|Justfile|justfile|Vagrantfile|Procfile|Jenkinsfile|Rakefile|Gemfile|\.env(\.[A-Za-z0-9_-]+)?)$'

# Generated / machine-owned files. Documenting these is pointless, so they never
# trigger the check.
SKIP_FILE_REGEX='(^|/)(package-lock\.json|pnpm-lock\.yaml|yarn\.lock|bun\.lockb|Cargo\.lock|composer\.lock|poetry\.lock|Gemfile\.lock|go\.sum|pubspec\.lock)$'

# Tooling / state folders that are never subject to the doc-sync rule. Matched at
# ANY depth (`(^|/)`), so nested copies in a monorepo are skipped too — e.g.
# frontend/node_modules/, backend/target/, mobile/.dart_tool/.
SKIP_FOLDER_REGEX='(^|/)(\.git/|node_modules/|target/|vendor/|dist/|build/|\.next/|\.nuxt/|\.dart_tool/|\.fvm/|bin/|obj/|graphify-out/|\.factory/|\.ansible/|\.planning/|\.vscode/|\.idea/|\.remember/|\.claude/|\.terraform/|\.vagrant/|\.venv/|__pycache__/)'

# --- per-repo settings (scripts/fdc.conf overrides the defaults above) -------
fdc_root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
# shellcheck disable=SC1090
[[ -f "$fdc_root/scripts/fdc.conf" ]] && . "$fdc_root/scripts/fdc.conf"

if [[ "${SKIP_DOC_CHECK:-0}" == "1" ]]; then
    echo "[check-docs-fresh] SKIP_DOC_CHECK=1 set — bypassing check."
    exit 0
fi

# --- policy sanity -----------------------------------------------------------
# A team repo may keep credentials policy A only with a written reason in
# FDC_CREDENTIALS_OVERRIDE (see AGENTS.md rule 8 / METHODOLOGY Convention 7).
# Unset policies (bootstrap not finished yet) never block a commit.
if [[ "${FDC_TEAM:-}" == team && "${FDC_CREDENTIALS_POLICY:-}" == A && -z "${FDC_CREDENTIALS_OVERRIDE:-}" ]]; then
    echo "[check-docs-fresh] FAIL: FDC_TEAM=team with FDC_CREDENTIALS_POLICY=A and no FDC_CREDENTIALS_OVERRIDE in scripts/fdc.conf."
    echo "  Either switch to credentials policy B, or set FDC_CREDENTIALS_OVERRIDE=\"<why plaintext credentials are acceptable for this team>\"."
    exit 1
fi

# --- /fdc/ concept metadata --------------------------------------------------
# Default scope is the CHANGED fdc docs only, so a stale legacy doc never blocks
# an unrelated commit (that would just train people to bypass the hook). Set
# FDC_VALIDATE_ALL=1 (CI does this) to sweep the whole fdc/ tree and catch drift
# in docs the current change didn't touch.

# Echo the concept type for a flat fdc concept doc, or return 1 for index files,
# nested files, and non-fdc paths.
expected_fdc_type() {
    local f="$1" cat rest
    case "$f" in
        fdc/decisions/*)       cat=decision;        rest=${f#fdc/decisions/} ;;
        fdc/runbooks/*)        cat=runbook;         rest=${f#fdc/runbooks/} ;;
        fdc/troubleshooting/*) cat=troubleshooting; rest=${f#fdc/troubleshooting/} ;;
        fdc/briefs/*)          cat=brief;           rest=${f#fdc/briefs/} ;;
        fdc/notes/*)           cat=note;            rest=${f#fdc/notes/} ;;
        fdc/work/*)            cat=plan;            rest=${f#fdc/work/} ;;
        fdc/archive/*)         return 1 ;;   # archived: never validated, never read by default
        *) return 1 ;;
    esac
    case "$rest" in
        */*)  return 1 ;;   # nested — not a flat concept doc, don't force a type
        *.md) ;;            # ok
        *)    return 1 ;;
    esac
    case "$rest" in
        decisions.md|runbooks.md|troubleshooting.md|briefs.md|notes.md|work.md) return 1 ;;  # index, exempt
    esac
    echo "$cat"
}

# Print the YAML frontmatter block (between the first two `---` lines). Tolerates
# CRLF line endings. Exits non-zero if there is no frontmatter.
frontmatter_for() {
    awk '
        { sub(/\r$/, "") }
        NR == 1 { if ($0 != "---") exit 1; next }
        $0 == "---" { found = 1; for (i = 1; i <= n; i++) print lines[i]; exit 0 }
        { lines[++n] = $0 }
        END { if (!found) exit 1 }
    ' "$1"
}

frontmatter_has_nonempty_field() {
    local fm="$1" field="$2"
    printf '%s\n' "$fm" | grep -Eq "^${field}:[[:space:]]*[^[:space:]#]+"
}

frontmatter_type_matches() {
    local fm="$1" expected="$2"
    printf '%s\n' "$fm" | grep -Eq "^type:[[:space:]]*['\"]?${expected}['\"]?[[:space:]]*(#.*)?$"
}

frontmatter_timestamp_valid() {
    local fm="$1"
    printf '%s\n' "$fm" | grep -Eq "^timestamp:[[:space:]]*['\"]?[0-9]{4}-[0-9]{2}-[0-9]{2}"
}

# tags must be a NON-empty list. Handles inline (`tags: [a, b]`) and block form
# (`tags:` then `- a`). `tags: []` / `tags:` with nothing is rejected.
frontmatter_tags_nonempty() {
    local fm="$1"
    printf '%s\n' "$fm" | awk '
        BEGIN { ok = 0; blk = 0 }
        /^tags:[[:space:]]*\[.*[[:alnum:]].*\]/ { ok = 1; blk = 0; next }   # inline [a, b]
        /^tags:[[:space:]]*[[:alnum:]"'"'"']/   { ok = 1; blk = 0; next }   # inline scalar (rare)
        /^tags:[[:space:]]*(#.*)?$/             { blk = 1; next }           # block list begins
        blk && /^[[:space:]]*-[[:space:]]*[[:alnum:]"'"'"']/ { ok = 1 }     # a block item
        blk && /^[^[:space:]#-]/                { blk = 0 }                 # next top-level key
        END { exit ok ? 0 : 1 }
    '
}

# Emit the list of fdc concept docs to validate: the whole tree under
# FDC_VALIDATE_ALL=1, otherwise just the changed fdc/*.md files still on disk.
fdc_docs_to_validate() {
    [[ -d fdc ]] || return 0
    if [[ "${FDC_VALIDATE_ALL:-0}" == "1" ]]; then
        find fdc -type f -name '*.md' 2>/dev/null | sort
        return 0
    fi
    printf '%s\n' "$changed" | while IFS= read -r f; do
        [[ "$f" == fdc/*.md && -f "$f" ]] && echo "$f"
    done
}

validate_fdc_frontmatter() {
    local failures=() f expected fm
    while IFS= read -r f; do
        [[ -z "$f" ]] && continue
        expected=$(expected_fdc_type "$f" || true)
        [[ -z "$expected" ]] && continue

        fm=$(frontmatter_for "$f" || true)
        if [[ -z "$fm" ]]; then
            failures+=("$f: missing YAML frontmatter block at top of file")
            continue
        fi

        frontmatter_type_matches "$fm" "$expected" || failures+=("$f: frontmatter type must be '$expected'")
        frontmatter_has_nonempty_field "$fm" "title" || failures+=("$f: missing non-empty title")
        frontmatter_has_nonempty_field "$fm" "description" || failures+=("$f: missing non-empty description")
        frontmatter_tags_nonempty "$fm" || failures+=("$f: missing non-empty tags")
        frontmatter_timestamp_valid "$fm" || failures+=("$f: timestamp must start with YYYY-MM-DD")
        case "$expected" in
            decision|brief|troubleshooting|plan)  # lifecycle types: status decides what is current and what archives
                frontmatter_has_nonempty_field "$fm" "status" || failures+=("$f: $expected needs a non-empty status (decision: proposed|accepted|superseded|rejected; brief: open|claimed|done|dropped; troubleshooting: open|resolved|accepted; plan: open|done|dropped)")
                ;;
            note)  # a note is a message: it needs a sender, a recipient, and a lifecycle
                frontmatter_has_nonempty_field "$fm" "from"   || failures+=("$f: note needs from: (human:<id> or <agent>/<version>)")
                frontmatter_has_nonempty_field "$fm" "to"     || failures+=("$f: note needs to: (human:<id> | team | me)")
                frontmatter_has_nonempty_field "$fm" "status" || failures+=("$f: note needs status: (open|read|done)")
                ;;
        esac
        grep -Eqi '^##[[:space:]]+see also' -- "$f" || failures+=("$f: missing '## See also' section")
    done < <(fdc_docs_to_validate)

    [[ ${#failures[@]} -eq 0 ]] && return 0

    echo
    echo "================================================================"
    echo " check-docs-fresh: /fdc/ concept metadata is incomplete"
    echo "================================================================"
    printf '   %s\n' "${failures[@]}"
    echo
    echo "Every non-index file under fdc/decisions, fdc/runbooks,"
    echo "fdc/troubleshooting, fdc/briefs, fdc/notes, and fdc/work must start with YAML"
    echo "frontmatter containing type, title, description, tags, and"
    echo "timestamp, and must include a '## See also' section. Decisions and"
    echo "briefs, troubleshooting notes, and plans need a 'status' field; notes need"
    echo "from, to, status. fdc/archive/ is exempt."
    echo "(Local commits check only changed fdc docs; CI / FDC_VALIDATE_ALL=1"
    echo "validates the whole fdc/ tree.)"
    echo
    exit 1
}

# --- Collect changed files --------------------------------------------------
# Priority: explicit range (CI) > staged (pre-commit hook) > working tree vs HEAD.
skip_reasons=""
if [[ -n "${CHECK_RANGE:-}" ]]; then
    changed=$(git diff --name-only "$CHECK_RANGE")
    # A commit in the range may declare that it intentionally shipped code
    # without a doc change, via a trailer:   Skip-Doc-Check: <reason>
    # The reason is mandatory. With a valid trailer the drift part is skipped
    # for the whole range (metadata validation still runs); the reasons are
    # printed so reviewers see them.
    range_for_log=${CHECK_RANGE/.../..}
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        reason=$(printf '%s' "$line" | sed -E 's/^[Ss]kip-[Dd]oc-[Cc]heck:[[:space:]]*//')
        if [[ -z "$reason" ]]; then
            echo "check-docs-fresh: a commit in $CHECK_RANGE has an empty 'Skip-Doc-Check:' trailer — give a reason."
            exit 1
        fi
        skip_reasons="${skip_reasons}   - ${reason}"$'\n'
    done < <(git log --format='%(trailers:key=Skip-Doc-Check,valueonly=false)' "$range_for_log" 2>/dev/null | grep -Ei '^skip-doc-check:' || true)
else
    changed=$(git diff --cached --name-only)
    if [[ -z "$changed" ]]; then
        # No staged changes (e.g. a manual run). Compare working tree to HEAD,
        # but only if HEAD exists — on a brand-new repo there is nothing to diff.
        if git rev-parse --verify -q HEAD >/dev/null 2>&1; then
            changed=$(git diff --name-only HEAD)
        fi
    fi
fi

# Validate fdc concept metadata (scope depends on FDC_VALIDATE_ALL — see above).
validate_fdc_frontmatter

[[ -z "$changed" ]] && exit 0

# --- Helpers ----------------------------------------------------------------
# A folder "has an index doc" if its FDC index file exists. Root is special:
# the root readme / AGENTS / CLAUDE file plays the index role there.
index_doc_exists() {
    local dir="$1" base
    if [[ "$dir" == "." ]]; then
        [[ -f readme.md || -f README.md || -f AGENTS.md || -f CLAUDE.md ]]
        return
    fi
    base=$(basename "$dir")
    [[ -f "$dir/$base.md" ]]
}

# Walk up from a folder to the nearest ancestor (inclusive) that has an index
# doc. Echoes the owner folder, or "" if no ancestor is documented (repo not yet
# FDC-structured along this path — nothing to enforce).
find_owner() {
    local dir="$1"
    while :; do
        if index_doc_exists "$dir"; then
            echo "$dir"
            return 0
        fi
        [[ "$dir" == "." ]] && break
        dir=$(dirname "$dir")
    done
    echo ""
}

is_code_file() {
    [[ "$1" =~ $CODE_REGEX || "$(basename "$1")" =~ $CODE_BASENAME_REGEX ]]
}

# True if dir (or an ancestor) had its own index doc deleted in this change.
under_deleted_index() {
    local dir="$1"
    while :; do
        printf '%s\n' "$deleted_index_dirs" | grep -Fxq -- "$dir" && return 0
        [[ "$dir" == "." ]] && return 1
        dir=$(dirname "$dir")
    done
}

# --- Classify changed files -------------------------------------------------
# bash 3.2 has no associative arrays, so we use newline-delimited string "sets"
# and grep -Fxq for membership.
doc_dirs=$'\n'        # dirs that had a *.md change
owners=$'\n'          # owner folders that had a code change
deleted_index_dirs=$'\n'  # folders whose own index doc was deleted (folder removed)

# Two passes: docs first (so deleted-index folders are known), then code.
for pass in docs code; do
while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    [[ "$f" =~ $SKIP_FOLDER_REGEX ]] && continue
    [[ "$f" =~ $SKIP_FILE_REGEX ]] && continue
    if [[ "$f" =~ $DOC_REGEX ]]; then
        [[ "$pass" == docs ]] || continue
        d=$(dirname "$f")
        # A doc change counts for the folder it lives in AND for the owner of
        # that folder, so `src/auth/auth-flow.md` covers code owned by src/src.md.
        doc_dirs="${doc_dirs}${d}"$'\n'
        owner=$(find_owner "$d")
        [[ -n "$owner" ]] && doc_dirs="${doc_dirs}${owner}"$'\n'
        # A deleted index doc means the whole folder went away; its (deleted)
        # code is documented by that deletion, not by the parent doc.
        if [[ ! -f "$f" && "$(basename "$f")" == "$(basename "$d").md" ]]; then
            deleted_index_dirs="${deleted_index_dirs}${d}"$'\n'
        fi
    elif is_code_file "$f"; then
        [[ "$pass" == code ]] || continue
        owner=$(find_owner "$(dirname "$f")")
        [[ -z "$owner" ]] && continue   # no documented ancestor — can't enforce
        # Deleted code under a folder whose index doc was deleted too: skip.
        if [[ ! -f "$f" ]] && under_deleted_index "$(dirname "$f")"; then continue; fi
        owners="${owners}${owner}"$'\n'
    fi
done <<< "$changed"
done

# --- Find owners whose doc was not touched ----------------------------------
missing=()
while IFS= read -r owner; do
    [[ -z "$owner" ]] && continue
    printf '%s\n' "$doc_dirs" | grep -Fxq -- "$owner" || missing+=("$owner")
done < <(printf '%s' "$owners" | sort -u | sed '/^$/d')

[[ ${#missing[@]} -eq 0 ]] && exit 0

if [[ -n "$skip_reasons" ]]; then
    echo "[check-docs-fresh] drift check skipped for $CHECK_RANGE — justified by commit trailer(s):"
    printf '%s' "$skip_reasons"
    exit 0
fi

echo
echo "================================================================"
echo " check-docs-fresh: code changed without updating its owning doc"
echo "================================================================"
for owner in "${missing[@]}"; do
    if [[ "$owner" == "." ]]; then
        echo "   owner: <repo root>  (expected a change to readme.md / AGENTS.md)"
    else
        echo "   owner: $owner/  (expected a change to $owner/$(basename "$owner").md)"
    fi
    while IFS= read -r cf; do
        [[ -z "$cf" ]] && continue
        [[ "$cf" =~ $SKIP_FOLDER_REGEX || "$cf" =~ $SKIP_FILE_REGEX ]] && continue
        is_code_file "$cf" || continue
        [[ "$(find_owner "$(dirname "$cf")")" == "$owner" ]] && echo "        $cf"
    done <<< "$changed"
done
echo
echo "Per AGENTS.md TOP PRIORITY rule, update the owning folder's *.md doc in the"
echo "same commit. If the change genuinely doesn't affect documented behavior,"
echo "bypass locally AND leave the reason in the commit message so CI accepts it:"
echo "    SKIP_DOC_CHECK=1 git commit -m 'refactor: ...' -m 'Skip-Doc-Check: <why no doc change is needed>'"
echo
exit 1
