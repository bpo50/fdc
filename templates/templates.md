# templates

**Purpose:** Ready-to-copy file templates for the Folder-Doc Convention (FDC). **This folder is the single source of truth**: `LLM_PROMPT.md` is generated from these files by `tools/build-prompt.sh`, and this repo's own `scripts/` and `fdc/` are copies of them.

## When to use these vs. the prompt

- **Letting an LLM bootstrap a repo:** use `LLM_PROMPT.md` at the repo root. The templates are inlined; you don't need this folder.
- **Bootstrapping a repo manually (no LLM):** copy these files into the target repo, fill in placeholders marked `{{ … }}` or `<placeholder>`, install the pre-commit hook.

## Files

| Template | Drop it at | Purpose |
|---|---|---|
| `scripts/fdc.sh` | `<repo-root>/scripts/fdc.sh` | Entry point: `doctor`, `check`, `install-hook`, `update`, `stale`, `log`, `graph`, `index`, `notes`, `findings`, `archive`, `prune`, `budget`, `whoami`. |
| `scripts/fdc.conf` | `<repo-root>/scripts/fdc.conf` | Per-repo settings (upstream, version, team, policies, thresholds, regex overrides). Ships with `FDC_UPSTREAM` pointing at `https://github.com/bpo50/fdc.git`. The only file a downstream repo edits under `scripts/`. |
| `.githooks/pre-commit` | `<repo-root>/.githooks/pre-commit` | Versioned hook; `install-hook` sets `core.hooksPath` to it. |
| `fdc/notes/notes.md` | `<repo-root>/fdc/notes/notes.md` | Notes index + template (messages with a lifecycle). |
| `fdc/work/work.md` | `<repo-root>/fdc/work/work.md` | Ephemeral plans/specs index + template; the compaction rule. |
| `fdc/runbooks/onboard-developer.md` | `<repo-root>/fdc/runbooks/onboard-developer.md` | Five-minute setup runbook for a new teammate or machine. |
| `PULL_REQUEST_TEMPLATE.md` | your forge's PR template path | Team repos: definition-of-done checklist for reviewers. |
| `AGENTS.md` | `<repo-root>/AGENTS.md` | Canonical operating rules + behaviour contract. Fill `{{ … }}` placeholders, including `{{CREDENTIALS_POLICY}}` and `{{COMMIT_POLICY}}` (pick A or B from the comment under each). |
| `CLAUDE.md` | `<repo-root>/CLAUDE.md` | Thin Claude-only addendum. Fill slash-command list. |
| `readme.md` | `<repo-root>/readme.md` | Root human entry point (the only README in the repo). |
| `folder-index.md` | `<folder>/<folder>.md` | One per folder. Rename to match the folder. |
| `fdc/fdc.md` | `<repo-root>/fdc/fdc.md` | `/fdc/` top-level index. |
| `fdc/decisions/decisions.md` | `<repo-root>/fdc/decisions/decisions.md` | ADR index + template. |
| `fdc/runbooks/runbooks.md` | `<repo-root>/fdc/runbooks/runbooks.md` | Runbook index + template. |
| `fdc/troubleshooting/troubleshooting.md` | `<repo-root>/fdc/troubleshooting/troubleshooting.md` | Troubleshooting index + template. |
| `fdc/briefs/briefs.md` | `<repo-root>/fdc/briefs/briefs.md` | Brief index + template. |
| `scripts/check-docs-fresh.sh` | `<repo-root>/scripts/check-docs-fresh.sh` | Drift checker and `/fdc/` frontmatter validator. Adjust `CODE_REGEX` for the project's languages. |
| `scripts/install-hook.sh` | `<repo-root>/scripts/install-hook.sh` | Worktree-safe pre-commit hook installer. |
| `scripts/check-docs-ci.sh` | `<repo-root>/scripts/check-docs-ci.sh` | Provider-neutral CI backstop. Re-runs the check across `base...HEAD` with full-tree metadata validation. (Teams.) |
| `scripts/fdc-graph.sh` | `<repo-root>/scripts/fdc-graph.sh` | Optional. Builds `graphify-out/fdc-graph.json` from `/fdc/` frontmatter + `## See also` links. Not part of the hook; set `FDC_GRAPH_CMD` to post-process. |
| `scripts/fdc-stale.sh` | `<repo-root>/scripts/fdc-stale.sh` | Optional, never fails. Flags runbooks / troubleshooting notes not `verified:` within `FDC_STALE_DAYS` (180) or past `stale_after:`; reports trust tier from `verified` actors. |
| `scripts/fdc-log.sh` | `<repo-root>/scripts/fdc-log.sh` | Optional. Regenerates `fdc/log.md` (newest-first history of `/fdc/` from git). |
| `scripts/tests/fdc-stale.test.sh` | (stays in this repo) | Tests for the staleness audit and trust tiers. |
| `scripts/tests/fdc-log.test.sh` | (stays in this repo) | Tests for the log generator. |
| `scripts/tests/fdc-graph.test.sh` | (stays in this repo) | Tests for the graph extractor (See-also and `sources` edges). |
| `scripts/tests/install-hook.test.sh` | (stays in this repo) | Tests for the installer: fresh, idempotent, append to foreign hook, leave symlinks alone. |
| `scripts/tests/check-docs-ci.test.sh` | (stays in this repo) | Tests for the CI backstop's soft intent hint. |
| `scripts/tests/version-stamps.test.sh` | (stays in this repo) | All `fdc-version` stamps agree and `scripts/` matches `templates/scripts/`. |
| `scripts/tests/fdc-cli.test.sh` | (stays in this repo) | Manifest overrides, doctor self-heal, whoami, update from a tag, index generation, notes. |
| `scripts/tests/build-prompt.test.sh` | (stays in this repo) | `LLM_PROMPT.md` is up to date with its source and these templates. |
| `scripts/tests/check-docs-fresh.test.sh` | (stays in this repo) | Behavioural test suite for the drift checker: builds throwaway git repos and asserts exit codes. Run before changing the checker. |

## Versioning

Each script carries `# fdc-version: YYYY.MM.DD` on line 2 and `AGENTS.md` carries `<!-- fdc-version: … -->` on line 2. Bump **all stamps (every script, `fdc.conf`, the AGENTS template) and `FDC_VERSION` in `fdc.conf` to the same date** whenever any of them changes materially. Downstream repos compare stamps via `LLM_UPDATE_PROMPT.md`.

## Gotchas

- After editing anything here: `bash tools/build-prompt.sh` regenerates the prompt, `cp templates/scripts/*.sh scripts/` refreshes the installed copy. `bash templates/scripts/tests/*.test.sh` fails until both are done.
- `fdc.sh update` (and root `install.sh`) clone the release tag quietly with `advice.detachedHead=false`; the temporary clone is deleted and the target repo never leaves its branch.
- The drift checker requires `status` on decisions and briefs; the CI range mode honours a `Skip-Doc-Check: <reason>` commit trailer; the installer appends to an existing hook and refuses to write through a symlink.
- The checker classifies code by extension (`CODE_REGEX`) **and** by basename (`CODE_BASENAME_REGEX`) so `Dockerfile`, `Makefile`, `Justfile`, `.env*` count without an extension.
- A doc change anywhere under an owner folder satisfies that owner, and deleting a folder together with its index doc is not a violation.

## Bootstrap order (manual)

Prefer `install.sh` (repo root) — it does steps 1–3 below from a tagged release. Manual copy is for offline machines.

```bash
# 1. Copy core files
cp /path/to/llm-icm/templates/AGENTS.md ./
cp /path/to/llm-icm/templates/CLAUDE.md ./
cp /path/to/llm-icm/templates/readme.md ./   # rename/merge if one exists

# 2. Create /fdc/ structure
mkdir -p fdc/decisions fdc/runbooks fdc/troubleshooting fdc/briefs
cp /path/to/llm-icm/templates/fdc/fdc.md fdc/
cp /path/to/llm-icm/templates/fdc/decisions/decisions.md fdc/decisions/
cp /path/to/llm-icm/templates/fdc/runbooks/runbooks.md fdc/runbooks/
cp /path/to/llm-icm/templates/fdc/troubleshooting/troubleshooting.md fdc/troubleshooting/
cp /path/to/llm-icm/templates/fdc/briefs/briefs.md fdc/briefs/

# 3. Drift checker + hook installer (+ CI backstop)
mkdir -p scripts
cp /path/to/llm-icm/templates/scripts/check-docs-fresh.sh scripts/
cp /path/to/llm-icm/templates/scripts/install-hook.sh scripts/
cp /path/to/llm-icm/templates/scripts/check-docs-ci.sh scripts/   # teams only; harmless to keep
cp /path/to/llm-icm/templates/scripts/fdc-graph.sh scripts/       # optional knowledge-graph builder
cp /path/to/llm-icm/templates/scripts/fdc-stale.sh scripts/       # optional staleness + trust audit
cp /path/to/llm-icm/templates/scripts/fdc-log.sh scripts/         # optional fdc/log.md generator
chmod +x scripts/*.sh
bash scripts/install-hook.sh   # worktree- & submodule-safe; honors core.hooksPath
# Then wire `bash scripts/check-docs-ci.sh` into whatever CI the repo uses (one line).
# Add graphify-out/ to .gitignore if you use scripts/fdc-graph.sh.

# 4. Folder indexes — one per top-level folder
for d in src tests infrastructure; do  # adjust to your folders
  cp /path/to/llm-icm/templates/folder-index.md "$d/$d.md"
done

# 5. Fill placeholders (rg for them)
rg '\{\{' .
rg '<placeholder' .

# 6. Validate code/doc drift and required /fdc/ frontmatter
bash scripts/check-docs-fresh.sh
```
