#!/usr/bin/env bash
# scripts/check-docs-ci.sh
# fdc-version: 2026.09.14
#
# CI-agnostic entry point for the FDC doc-freshness check. It resolves the
# base..HEAD range for the current change, then runs check-docs-fresh.sh against
# that range with full-tree metadata validation enabled.
#
# It is NOT tied to any provider. It works in GitLab CI, Gitea/Forgejo Actions,
# Woodpecker, Drone, Jenkins, Buildkite, Bitbucket Pipelines, a git server hook,
# or a plain cron box — anything that can run a shell command in a git checkout.
#
# Why this exists: the local pre-commit hook is bypassable (SKIP_DOC_CHECK=1 or
# git commit --no-verify). This re-runs the same check across the whole change at
# merge time, so a local bypass is caught in review.
#
# Base ref resolution (first match wins):
#   1. $FDC_CI_BASE                  explicit override (e.g. origin/develop)
#   2. first argument                bash scripts/check-docs-ci.sh origin/main
#   3. a known CI "target branch" env var (provider-neutral best effort)
#   4. the remote's default branch   (origin/HEAD), else origin/main
#
# Usage in CI:   bash scripts/check-docs-ci.sh
#         or:    FDC_CI_BASE=origin/develop bash scripts/check-docs-ci.sh

set -euo pipefail

cd "$(git rev-parse --show-toplevel)"
# --- per-repo settings (scripts/fdc.conf overrides the defaults above) -------
fdc_root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
# shellcheck disable=SC1090
[[ -f "$fdc_root/scripts/fdc.conf" ]] && . "$fdc_root/scripts/fdc.conf"

base="${FDC_CI_BASE:-${1:-}}"

if [[ -z "$base" ]]; then
    # Common "merge/PR target branch" env vars across CI providers. Add yours if
    # it isn't here.
    for v in \
        "${CI_MERGE_REQUEST_TARGET_BRANCH_NAME:-}" \
        "${CI_DEFAULT_BRANCH:-}" \
        "${BITBUCKET_PR_DESTINATION_BRANCH:-}" \
        "${DRONE_TARGET_BRANCH:-}" \
        "${CHANGE_TARGET:-}" \
        "${GITHUB_BASE_REF:-}"; do
        if [[ -n "$v" ]]; then base="origin/$v"; break; fi
    done
fi

if [[ -z "$base" ]]; then
    if git symbolic-ref -q refs/remotes/origin/HEAD >/dev/null 2>&1; then
        base=$(git symbolic-ref --short refs/remotes/origin/HEAD)
    else
        base="origin/main"
    fi
fi

# Shallow CI clones often lack the base ref — fetch it if missing.
if ! git rev-parse --verify -q "$base" >/dev/null 2>&1; then
    git fetch -q --depth=200 origin "${base#origin/}" 2>/dev/null || git fetch -q origin "${base#origin/}" 2>/dev/null || true
fi

# --- Soft hint (never fails): "user intent → docs" -------------------------
# The hook can enforce code→docs. It cannot know that a session produced a
# decision, an incident, or a procedure. This looks at the commit subjects in the
# range for words that usually mean one of those happened, and if nothing under
# fdc/ changed, prints a hint. It is deliberately a nudge, not a gate: a false
# positive costs one line of CI output; a hard failure would train people to
# ignore it.
if ! git diff --name-only "${base}...HEAD" 2>/dev/null | grep -q '^fdc/'; then
    intent=$(git log --format='%s' "${base}..HEAD" 2>/dev/null \
        | grep -Ei '(^|[^a-z])(fix|hotfix|bug|incident|outage|rollback|decid|decision|because|migrat|runbook|procedure)' || true)
    if [[ -n "$intent" ]]; then
        echo "[check-docs-ci] hint: these commits look like a fix, incident, or decision, but nothing under fdc/ changed:"
        printf '%s\n' "$intent" | sed 's/^/    /'
        echo "    If there is a cause→fix or a why, capture it in fdc/troubleshooting/ or fdc/decisions/ (see AGENTS.md → user-request-side triggers)."
    fi
fi

echo "[check-docs-ci] comparing ${base}...HEAD (full-tree metadata validation on)"
CHECK_RANGE="${base}...HEAD" FDC_VALIDATE_ALL=1 \
    exec bash "$(git rev-parse --show-toplevel)/scripts/check-docs-fresh.sh"
