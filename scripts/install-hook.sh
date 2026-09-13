#!/usr/bin/env bash
# scripts/install-hook.sh
# fdc-version: 2026.09.14
#
# Installs check-docs-fresh.sh as a pre-commit hook in a way that survives
# git worktrees and submodules (where .git is a file, not a directory) and
# honors core.hooksPath. Idempotent — safe to re-run.

set -euo pipefail

root=$(git rev-parse --show-toplevel)
# --- per-repo settings (scripts/fdc.conf overrides the defaults above) -------
fdc_root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
# shellcheck disable=SC1090
[[ -f "$fdc_root/scripts/fdc.conf" ]] && . "$fdc_root/scripts/fdc.conf"

# Preferred: the repo ships a versioned .githooks/pre-commit. Point git at it
# (per clone) and stop — a hook change then reaches every clone on pull.
if [[ -f "$root/.githooks/pre-commit" ]]; then
    chmod +x "$root/.githooks/pre-commit" "$root/scripts/check-docs-fresh.sh" 2>/dev/null || true
    current=$(git config --get core.hooksPath || true)
    if [[ "$current" == ".githooks" ]]; then
        echo "Already installed: core.hooksPath=.githooks"
    elif [[ -n "$current" ]]; then
        echo "core.hooksPath is already '$current' (another hook manager?). Not changing it."
        echo "Add this to that tool's pre-commit stage:"
        echo '    "$(git rev-parse --show-toplevel)/scripts/check-docs-fresh.sh" || exit 1'
        exit 1
    else
        git config core.hooksPath .githooks
        echo "Installed: core.hooksPath=.githooks (versioned hook)"
    fi
    exit 0
fi

# Fallback (no .githooks/ in the repo): write into the git hooks dir.
hooks_path=$(git config --get core.hooksPath || true)
if [[ -n "$hooks_path" ]]; then
    hooks_dir="$hooks_path"
else
    hooks_dir=$(git rev-parse --git-path hooks)
fi
mkdir -p "$hooks_dir"

hook="$hooks_dir/pre-commit"
call='"$(git rev-parse --show-toplevel)/scripts/check-docs-fresh.sh" || exit 1   # fdc doc-drift check'

if [[ -L "$hook" ]]; then
    # A symlinked hook is almost always owned by a hook manager (husky,
    # pre-commit.com, lefthook). Don't write through it — tell the user instead.
    echo "pre-commit at $hook is a symlink (managed by another tool). Not touching it."
    echo "Add this to that tool's pre-commit stage:"
    echo "    $call"
    exit 1
fi

if [[ -e "$hook" ]] && grep -q check-docs-fresh "$hook" 2>/dev/null; then
    echo "Already installed in $hook — nothing to do."
elif [[ -e "$hook" ]]; then
    # Someone else's hook: keep it, append our call after it.
    printf '\n# --- FDC doc-drift check (appended by scripts/install-hook.sh) ---\n%s\n' "$call" >> "$hook"
    echo "Appended FDC check to existing hook $hook"
else
    # A tiny wrapper that resolves the script at runtime — no fragile relative
    # symlink, so it works from any worktree.
    cat > "$hook" <<'HOOK'
#!/usr/bin/env bash
exec "$(git rev-parse --show-toplevel)/scripts/check-docs-fresh.sh"
HOOK
    echo "Installed pre-commit hook -> $hook"
fi
chmod +x "$hook"
chmod +x "$root/scripts/check-docs-fresh.sh" 2>/dev/null || true
