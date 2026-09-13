# AGENTS.md
<!-- fdc-version: 2026.09.13 — compare with the upstream FDC repo's templates/AGENTS.md; see LLM_UPDATE_PROMPT.md there. -->

**Canonical operating rules for this repo.** Applies to every LLM / agent working on it (Claude, Codex, Copilot CLI, Cursor, Gemini, Aider, or any other). If you are Claude Code, also read `CLAUDE.md` afterwards — it adds Claude-only extras. All other agents: this is the only rules file you need.

---

## TOP PRIORITY — Keep documentation in sync with code AND user intent

> **This rule is non-negotiable. It is the single highest-priority rule in this repository.** It overrides convenience, brevity, time pressure, or "I'll do it later". A change that ships code without the corresponding doc update is an **incomplete task** — do not report it as done.

### The rule

**Every change to this repo must update the relevant Markdown documentation in the SAME change.** Two halves:

1. **Code → docs.** If you modify a source file, config file, dependency manifest, build script, or any executable/config artifact, you MUST update the per-folder `*.md` doc in the same folder, plus every cross-referenced doc that mentions the changed identifier.
2. **User intent → docs.** If the user asks for something — a new feature, a procedure, a decision, a problem report, a revealed constraint — capture it in the right place *before or during* implementation. See "Triggers — user-request-side" below.

A diff that touches code or a conversation that reveals new intent without also touching docs is treated as a bug. `scripts/check-docs-fresh.sh` (pre-commit hook) enforces the code-side and rejects commits that violate it.

### Definition of done

A task is NOT done until ALL of these are true:

- [ ] The per-folder `<folder>.md` in every touched folder reflects the new reality.
- [ ] Parent index docs reflect any added / renamed / removed files.
- [ ] Cross-referenced docs have been updated (find with `rg <changed-identifier>`).
- [ ] `/fdc/` entries (decision / runbook / troubleshooting / brief) have been created when warranted, have required frontmatter, and are linked from at least one folder doc.
- [ ] Existing non-index `/fdc/` docs still pass the required-frontmatter and `## See also` rules.
- [ ] `bash scripts/check-docs-fresh.sh` exits 0 (or you've used `SKIP_DOC_CHECK=1` with justification in the commit message).

If any item is unchecked, the task is not done. Do not report the work as complete. Either finish the missing items or state clearly which is outstanding and why.

### Triggers — code-side

| You did this | You MUST also do this |
|---|---|
| Changed a source file ({{CODE_EXTENSIONS_LIST}}) or its config/manifest. | Update the adjacent `<folder>.md`. |
| Added / renamed / removed a file. | Update the parent folder's index doc. |
| Changed a public API, env-var name, service URL, port, db name, credential field, or any value referenced from docs. | `rg <old-value> -l` and update every hit. |
| Changed a cross-folder dependency. | Update "Depends on" in both folder docs. |
| Added a new service, package, route, command, or top-level feature. | Update parent index tables and the Navigation section of this file. |

### Triggers — user-request-side

The rule covers user intent, not just code. When the user does any of the following, create or update the appropriate doc *before or during* implementation:

| User did this | You MUST do this |
|---|---|
| Explains *why* something is done a certain way. | Create an ADR in `fdc/decisions/YYYY-MM-DD-<title>.md`. Link from the affected folder doc. |
| Describes a multi-step procedure they want to run reliably. | Create a runbook in `fdc/runbooks/<action>-<thing>.md`. Link from the affected folder doc. |
| Reports a problem you then diagnose / fix. | Create or update `fdc/troubleshooting/<symptom>.md` (symptom → cause → fix, `status: resolved`). Link from the affected folder doc. |
| Reports a problem you diagnose but **do not** fix (needs a window, another team, out of scope). | Same file, `status: open` — that is a *finding*. `fdc.sh doctor` lists open findings every session. Saying "still outstanding" in chat is not enough; chat is lost. |
| Finishes a plan / spec / investigation. | Write the durable outcome (≤1 ADR + doc updates), set the plan `status: done` in `fdc/work/`. The plan is not knowledge; its conclusion is. |
| Asks for something that needs design or significant work before code. | Create a brief in `fdc/briefs/<topic>.md` capturing intent + scope + constraints. Move out of `briefs/` once implemented. |
| Reveals a new constraint, credential, host, convention, or "gotcha". | Update the relevant folder doc's "Gotchas" or "Depends on" section in the same turn. |
| Reports that docs are wrong / out of date. | Treat as P0 in the next message — `rg` for every cross-reference and fix all of them. |

See `fdc/fdc.md` for the full `/fdc/` structure and templates.

### Self-check ritual

**At session start**, run `bash scripts/fdc.sh doctor`. It installs the hook if this clone lacks it, tells you who you are (`human:<id>`), whether the tooling is behind upstream, and lists open notes and briefs addressed to you. Then, before reading any code: identify which folder(s) you will touch and open their `<folder>.md` first.

**At task end**, before saying "done":

```bash
git diff --name-only                    # what changed
git diff --name-only | grep '\.md$'     # docs changed?
bash scripts/check-docs-fresh.sh        # drift check
rg <old-identifier>                     # stale references?
```

If `git diff` shows code without matching `*.md` changes in the same folders, **stop** and update docs before continuing.

### Why this rule exists

Folder docs are this repo's interface to every future LLM session. A stale doc is worse than no doc — it actively misleads the next session into proposing broken changes. The whole "folder-as-architecture" approach only works if the docs are trustworthy.

If you genuinely cannot update a doc (the change is exploratory and you don't yet know what to write), say so explicitly — don't silently skip.

---

## How to work in this repo (behaviour contract)

These rules apply to every agent, whatever model or vendor. They exist because different models default differently on exactly these points; the repo is the only place a consistent contract can live.

1. **Docs versus code.** When they disagree, code is the truth. Fix the doc in the same change and say so in the report.
2. **Uncertainty.** Never invent a command, host, port, path, or value. Write a visible `_TODO: …_` marker in the doc and list it in the report.
3. **Mutating actions outside the repo.** Deploys, migrations, restarts, deletions, credential rotation: show the exact command and wait for a yes. Read-only commands (`plan`, `diff`, `--dry-run`, `--check`, `status`, `config`) run without asking. In a folder with a `## Targets` table, name the target you are about to touch.
4. **Scope.** Do what was asked. Name adjacent problems you notice; do not fix them unprompted.
5. **Skipping.** If a step cannot be done, say which step and why. A partially done task is reported as partial, never as done.
6. **Report shape.** Files changed, commands run, what was verified and how, what remains. Facts separated from assumptions. Short.
7. **Language.** Docs, commit messages, and code comments in English regardless of the conversation language.
8. **Credentials.** {{CREDENTIALS_POLICY}}

   <!-- Pick ONE of the two policies below, paste it in place of the placeholder, delete this comment.

   A — DOCUMENTED IN PLACE (local-only infrastructure, VPN/LAN access, frequent rotation, one user; a team repo may use it only with FDC_CREDENTIALS_OVERRIDE="<reason>" in scripts/fdc.conf — then append the sentence "This repo is a team repo running policy A under a recorded override; see scripts/fdc.conf."):
   Infrastructure documented here is reachable only over VPN or the local network and credentials rotate often, so they are written where an agent will look for them: the `## Access` table of the owning folder doc (columns: Service, Host, User, Secret, Rotated on). One row per service, never scattered in prose. When a credential rotates, update the row and its `Rotated on` date in the same change, then `rg` the old value so no stale copy survives. Never paste credentials into commit messages, ADRs, or troubleshooting notes — link to the table.

   B — VAULT REFERENCE (public or shared repo):
   Never write a credential value into any file. The `## Access` table holds `<vault: item-name>` references (Vault, 1Password, sops, AWS Secrets Manager); the value lives only in the vault. If you find a plaintext credential, replace it with a reference and tell the user.
   -->

9. **Commits.** {{COMMIT_POLICY}}

   <!-- Pick ONE, paste it in place of the placeholder, delete this comment.

   A — MILESTONE COMMITS BY THE AGENT (several sessions and several machines may share this repo):
   At session start `git fetch`; if the branch is behind and the tree is clean, fast-forward; if it is behind with local changes, say so and continue without merging. Commit when a coherent piece of work is done and verified — a feature slice, a fixed bug with its troubleshooting note, a runbook that has been run, a doc sync. Not after every edit, and not a mixed bag at session end. Before committing: `git status`, stage only the files this task touched (never `git add -A`), run `bash scripts/fdc.sh check`. Message: one imperative summary line, then a body listing what changed and what was verified. `Skip-Doc-Check:` trailer only with a reason. After a milestone commit, `git push` if it is a fast-forward; if the push is rejected, stop and report — never rebase, amend, reset, or force. Commit on the current branch; never switch to or commit on `main` unless the user says so, and never create branches unasked.

   B — USER COMMITS:
   Never run `git commit`. When work is done, show `git status` and `git diff --stat` and stop.
   -->

10. **Parallel sessions.** Assume another agent may be editing the same checkout. Re-read a file before editing it if time has passed. Do not revert changes you did not make. If `git status` shows files you never touched, leave them out of your commit and mention them in the report.
11. **Handoff.** When you stop with work unfinished, write or update a brief in `fdc/briefs/` with a `## Where I stopped` and a `## Next steps` section, set `status: claimed` with `owners: [<your human id>]`, commit it (policy A) or list it (policy B), and name it in the report. The next session — on any machine, by anyone — reads open and claimed briefs first (`fdc.sh doctor` lists them).
12. **Tools.** Prefer `rg`, `fd`, `jq`, `yq`, `ast-grep` when present; fall back to `grep -r`, `find`, and reading the file when they are not. Never report a tool as missing without trying the fallback. On Windows use Git Bash; the scripts and hook run there unchanged.
13. **Identity and authority.** Your human is `human:<git user.email local part>` (`fdc.sh whoami`); you are `<tool>/<model>`. Use these in `verified:`, `generated:`, `from:`, `to:`, `owners:` — never invent or borrow an identity. An agent may *propose* (`status: proposed` / `open` / draft text); only a human moves a decision to `accepted`, `superseded`, or `rejected`, or a brief to `done` or `dropped`. Say who needs to do that in the report.
14. **Read budget.** By default a session reads: `AGENTS.md`, `fdc.sh doctor` output, and the `<folder>.md` of each folder it touches — nothing else until a task needs it. Never read `fdc/archive/` (end-state docs kept for history), `fdc/work/` (ephemeral plans), or `fdc/log.md` unless the user asks or a brief points at a specific file. Do not load other folders' docs "for context". Long docs are a smell: keep folder docs under 150 lines and knowledge docs under 300 (`fdc.sh budget` reports the offenders).
15. **Process, without depending on any plugin.** These four habits are the rules here, whatever tooling a given machine or model has:
    - *Think before building.* Anything non-trivial starts as a brief in `fdc/briefs/` (intent, scope, constraints, open questions) that the user has seen. No brief, no build.
    - *Plan in `fdc/work/`.* Multi-step work gets a plan there (`type: plan`, `status: open`), executed step by step. When done: outcome into the knowledge layer, plan `status: done`.
    - *Tests first for code.* A bug fix starts with a failing test that reproduces it; a feature starts with a failing test that specifies it. Watch it fail, then make it pass.
    - *Verify before "done".* Run the checks (`fdc.sh check`, the project's tests) and quote the result. "Should work" is not done.
    A planning or process plugin (e.g. Claude Code's *superpowers*) may drive these steps and is welcome; **its plan/spec output goes to `fdc/work/`, never to its own folder** (`docs/superpowers/…`). When the plugin is absent — another machine, another model — the rules above are the same process, done by hand.

---

## Naming convention for docs

- Every folder has exactly one index doc named `<folder-name>.md` (matching the folder's actual name and casing).
- No `README.md` / `readme.md` for folder indexes. The repo root has a single `readme.md`; everything else uses `<folder>.md`.
- Sub-topic docs inside a folder use descriptive kebab-case filenames (e.g. `auth-flow.md`, `deploy-commands.md`).
- One exception: when two parallel trees describe the same domain entity from different angles, the second one suffixes its index (e.g. `applications/grafana/grafana.md` + `resources/grafana/grafana-resources.md`).

---

## Creating docs in `/fdc/`

`/fdc/` holds long-form knowledge that doesn't fit inside any single folder index. {{DOCS_TRACKED_STATEMENT}}. Create files here in these situations:

| Situation | Where | Naming |
|---|---|---|
| **Decision (ADR)** — significant architectural / operational choice with tradeoffs. | `fdc/decisions/` | `YYYY-MM-DD-<short-kebab-title>.md` |
| **Runbook** — multi-step operational procedure. | `fdc/runbooks/` | `<action>-<thing>.md` |
| **Troubleshooting note** — symptom → cause → fix for an issue that has happened. | `fdc/troubleshooting/` | `<symptom>.md` |
| **Brief** — captured user intent / requirements not yet implemented. | `fdc/briefs/` | `<topic>.md` |
| **Note** — a short message to a person, the team, or yourself on another machine. Delivered by `fdc.sh doctor`; closed when acted on. | `fdc/notes/` | `<topic>.md` |
| **Plan / spec** (ephemeral) — implementation plans, design specs, session scratch. Not read by default; archived when done. | `fdc/work/` | `YYYY-MM-DD-<topic>.md` |

### Frontmatter and linking

Every non-index `/fdc/` doc starts with YAML frontmatter (`type`, `title`, `description`, `tags`, `timestamp`; decisions, briefs, troubleshooting notes, and plans also need `status`; notes need `from`, `to`, `status`), ends with a `## See also` section, is linked from at least one folder doc, and is listed in its subfolder index. The full rules and the per-type templates live in `fdc/fdc.md` — read that before creating one. The hook validates them.

### Relationship between folder docs and `/fdc/`

| Folder doc (`<folder>/<folder>.md`) | `/fdc/...` file |
|---|---|
| Quick reference: what's in this folder, how to build/test/run, gotchas. | Full long-form: rationale, alternatives, full procedure with rollback, history. |
| Always loaded when working in the folder. | Loaded on demand. |
| Short — under ~150 lines ideally. | Can be as long as needed. |

---

## Overview

{{PROJECT_OVERVIEW}}  <!-- 1-3 sentences. What this project is, what it does, who it serves. -->

## Tech stack

{{TECH_STACK}}  <!-- Bulleted list. Languages, frameworks, runtimes, key dependencies. -->

## Navigation

Folder docs are the source of truth. Drill into per-folder `*.md` for code conventions and gotchas.

{{FOLDER_NAVIGATION_LIST}}

<!-- One line per top-level folder, e.g.
- `src/src.md` — application source; entry points and module layout.
- `infrastructure/infrastructure.md` — deployment, IaC, environments.
- `fdc/fdc.md` — decisions / runbooks / troubleshooting / briefs.
-->

## Build / Test / Run

{{BUILD_TEST_RUN}}

<!-- The real commands for this repo (see LLM_PROMPT.md → project-type-specific guidance for per-stack defaults). Monorepos: per-stack commands go in each app's folder doc, not here. -->

---

## Repo-analysis workflow

**Goals:** understand the repo with minimal file reads, prefer deterministic search/tool output over guessing, keep answers grounded in exact file paths.

1. **Read the relevant folder doc first.** Find it: `find <folder> -maxdepth 1 -name '*.md'`.
2. Narrow with fast search: `rg` for text, `fd` for filenames.
3. Inspect structured files: `yq` for YAML, `jq` for JSON.
4. Use `ast-grep` / `semgrep` for structural matches when grep is noisy.
5. Read only the small set of relevant code files.
6. Summarise findings with exact paths and short reasoning.

Do not start by reading many files blindly. Do not skip the folder doc.

## Editing rules

**Before editing:**
- Read the folder's `<folder>.md` first.
- Identify the real source-of-truth file.
- Check for duplicate or legacy versions nearby.

**After editing:**
- Update the folder doc in the same change (per TOP PRIORITY rule).
- Mention exact files changed.
- Note any build / deploy / test command if relevant.
- Run `bash scripts/check-docs-fresh.sh` before finishing.

## Output expectations

When reporting findings:
- Include exact file paths.
- Say what is defined where.
- Separate facts from assumptions.
- Keep it short unless asked for more.

---

## FDC tooling (`scripts/fdc.sh`)

One entry point; every subcommand is a sibling script. Settings live in `scripts/fdc.conf` (the only file you edit; the scripts are upstream copies replaced by `update`). The pre-commit hook is the versioned `.githooks/pre-commit`, activated per clone by `install-hook` / `doctor`.

```bash
bash scripts/fdc.sh doctor        # session start: hook, version, identity, open notes/briefs — self-heals
bash scripts/fdc.sh check         # the drift check (what the hook runs; changed files only)
bash scripts/fdc.sh update        # pull scripts + hook from FDC_UPSTREAM at the newest tag (keeps fdc.conf)
bash scripts/fdc.sh stale         # staleness + trust-tier report (never fails)
bash scripts/fdc.sh index         # regenerate the ## Index lists in fdc/*/ from frontmatter
bash scripts/fdc.sh notes         # open notes addressed to you
bash scripts/fdc.sh findings      # open troubleshooting notes = known, unresolved problems
bash scripts/fdc.sh budget        # lines per area, largest docs, over-budget docs — the token-cost report
bash scripts/fdc.sh archive --dry-run   # end-state docs older than FDC_ARCHIVE_DAYS → fdc/archive/ (never read by default)
bash scripts/fdc.sh log | graph   # fdc/log.md from git; graphify-out/fdc-graph.json
```

Audit the whole `/fdc/` tree: `FDC_VALIDATE_ALL=1 bash scripts/fdc.sh check`.

Bypass for a single commit when the change genuinely does not affect documented behaviour. Leave the reason as a commit trailer — the CI backstop accepts the range only with a non-empty reason:

```bash
SKIP_DOC_CHECK=1 git commit -m "refactor: ..." -m "Skip-Doc-Check: pure rename, no documented behaviour changed"
```

**CI backstop (teams).** Because the hook is bypassable locally, run `bash scripts/check-docs-ci.sh` in CI — it re-checks the whole change (`base...HEAD`) with full-tree metadata validation. It is provider-neutral (resolves the base branch from common CI env vars, or `FDC_CI_BASE`).

**Knowledge graph (optional).** `bash scripts/fdc-graph.sh` extracts the `/fdc/` frontmatter + `## See also` links into `graphify-out/fdc-graph.json`. It is optional, never part of the hook, and safe to ignore if you have no graph tooling. Set `FDC_GRAPH_CMD` to post-process the JSON with your own tool.

**Portability.** These scripts run on stock macOS `/bin/bash` (3.2) and Linux, with BSD or GNU `awk`/`grep`/`sed`. Keep them bash-3.2-safe (no associative arrays) so they work on every contributor's machine.

---

## For Claude Code users

If you are Claude Code, `CLAUDE.md` adds:
- Slash commands defined in `.claude/commands/` (if any).
- Any Claude-only tooling (e.g. graphify slash recipes).

Other agents must invoke the underlying tools manually.

## Keep this file lean

If this file grows, move detailed notes into adjacent docs and reference them. **The TOP PRIORITY section MUST remain at the top of this file.**
