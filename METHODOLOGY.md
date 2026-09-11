# Folder-Doc Convention (FDC) — Methodology

A documentation discipline for software repos where one or more LLMs (Claude, Codex, Copilot, Cursor, Gemini, Aider) are regular contributors. FDC treats *documentation as the interface to every future agent session* and enforces that interface mechanically.

This file is the spec. For a one-paragraph summary, see `README.md`. For the bootstrap prompt, see `LLM_PROMPT.md` (generated from `LLM_PROMPT.src.md` + `templates/` by `tools/build-prompt.sh`; `templates/` is the single source for everything it inlines).

---

## 1. What problem FDC solves

When LLMs work on a codebase, three failure modes recur:

1. **Context starvation.** The agent doesn't know where things are or why they were built that way, so it loads too much, gets distracted, and proposes broken changes.
2. **Documentation drift.** Code changes ship, docs don't. Six months later the docs are actively misleading — worse than no docs, because the agent trusts them and produces wrong work.
3. **Lost user intent.** The user explains a constraint, a decision, a procedure, or a bug fix mid-conversation. None of it survives the session. The next session re-litigates the same ground.

FDC addresses all three by making documentation:

- **Co-located** with the code it describes (per-folder index docs, not a central wiki).
- **Mandatory** to update in the same commit as the code (mechanically enforced via pre-commit hook).
- **Categorized** for long-form content (`/fdc/decisions/`, `runbooks/`, `troubleshooting/`, `briefs/`).
- **Structured** enough for indexing and graphing (required frontmatter on every long-form `/fdc/` document).
- **The first thing every agent reads** (`AGENTS.md` is auto-loaded by most agent CLIs).

---

## 2. Core conventions

FDC has eight conventions. They are not optional — together they are what makes the system work.

### Convention 1 — Every folder has exactly one index doc, named `<folder-name>.md`

- The filename matches the folder's actual name (kebab-case, snake_case, whatever the folder uses).
- Examples: `src/src.md`, `infrastructure/infrastructure.md`, `applications/grafana/grafana.md`.
- **No `README.md` for folder indexes.** The repo root has a single `readme.md` (human-facing entry); every other folder uses `<folder>.md`.
- Why folder-name-matching: when `rg` returns a hit, the filename itself tells you which folder's doc you're looking at. No ambiguity, no need to read the file just to know its scope.
- **One disambiguation exception:** when two parallel folder trees describe the same domain entity from different angles (e.g. `applications/grafana/` holds deploy playbooks, `resources/grafana/` holds compose templates), the second one suffixes its index with the disambiguator: `grafana/grafana.md` + `grafana/grafana-resources.md`.

### Convention 2 — `AGENTS.md` is the canonical rules file; `CLAUDE.md` is a thin addendum

- `AGENTS.md` lives at the repo root. It is the *only* place the operating rules are stated. It's the emerging cross-agent standard (the `agents.md` convention) and is read natively by Codex, Copilot CLI, and recent Cursor. Agents that use their own filename (Gemini CLI → `GEMINI.md`, older Cursor → `.cursor/rules`) get a thin stub pointing back to it (see below).
- `CLAUDE.md` at the repo root is short (40-50 lines). It says "read `AGENTS.md` first" and adds only Claude Code-specific bits (slash commands in `.claude/commands/`, IDE integrations, anything that genuinely doesn't apply to other agents).
- **Rules are never duplicated.** If a rule applies to all agents, it lives in `AGENTS.md`. If you find yourself writing the same rule in both files, that's a smell — move it to `AGENTS.md`.
- Other agents' equivalents (`GEMINI.md`, `.cursor/rules`, etc.) can be added as thin stubs pointing back to `AGENTS.md`.

### Convention 3 — `/fdc/` holds long-form knowledge, in five categories plus an ephemeral one

The knowledge folder is named **`fdc/`**, not `docs/`. Three reasons:

- **No collision.** Many repos already use `docs/` for a published documentation site (Docusaurus, mkdocs, Astro Starlight, GitHub Pages). FDC's `decisions/runbooks/troubleshooting/briefs` would pollute it. `fdc/` is its own namespace.
- **It names what it is.** `docs/` is generic; `fdc/` signals "the FDC knowledge layer." A newcomer who opens it finds its own `fdc/fdc.md` index explaining the four categories.
- **It stays visible.** A *hidden* `.fdc/` was considered and rejected: `ripgrep` and many `find`/editor/indexer defaults skip dot-directories, and FDC's self-check ritual (`rg <changed-identifier>`, `rg <old-value> -l`) depends on grep reaching the docs. Hiding the knowledge layer would silently break the cross-reference guarantee. `fdc/` is visible; the dot-prefix is reserved for machine state (`.git/`, `.claude/`, `.planning/`).

| Category | Folder | Naming | What goes here |
|---|---|---|---|
| **Decision** | `fdc/decisions/` | `YYYY-MM-DD-<short-kebab-title>.md` | ADRs — context, options, decision, consequences. |
| **Runbook** | `fdc/runbooks/` | `<action>-<thing>.md` | Multi-step operational procedures (deploy, recover, rotate credentials). |
| **Troubleshooting** | `fdc/troubleshooting/` | `<symptom>.md` | Symptom → cause → fix pages for issues that have happened. |
| **Brief** | `fdc/briefs/` | `<topic>.md` | Captured user intent / requirements not yet implemented; also session handoffs (`claimed`, with *Where I stopped* / *Next steps*). |
| **Note** | `fdc/notes/` | `<topic>.md` | A message to a person, the team, or yourself on another machine. Required `from`, `to`, `status`. Delivered by `fdc.sh doctor`, flagged after 30 days open, closed when acted on. Not a chat: one answer at most, then it becomes a gotcha, a brief, or an ADR. |
| **Plan** (ephemeral) | `fdc/work/` | `YYYY-MM-DD-<topic>.md` | Implementation plans, design specs, session scratch — including what planning tools generate. Required `status`. Not read by default; when done, the outcome goes into ≤1 ADR plus doc updates and the plan archives. |

Each subfolder has its own index doc (`decisions/decisions.md`, `runbooks/runbooks.md`, etc.) whose `## Index` list is **generated** from frontmatter by `fdc.sh index` — hand-maintained lists were the most merge-conflict-prone file in a team repo. A top-level `fdc/fdc.md` indexes the five subfolders.

**Local-or-tracked is a per-repo decision.** Common patterns:

- **Tracked**: ADRs, runbooks, and troubleshooting are kept in git (team needs them).
- **Gitignored**: briefs and personal notes stay local (work-in-progress, not shareable).
- **Fully gitignored `/fdc/`**: a single-machine solo developer who wants long-form notes off git.

Pick once per repo and document it in `fdc/fdc.md`. **If you work from more than one machine, track all of `/fdc/`** — briefs and notes are the cross-machine handoff, and a gitignored layer travels nowhere. Generated files (`fdc/log.md`, `graphify-out/`) are the exception: in team repos gitignore `fdc/log.md` too and let `doctor` regenerate it locally, or every merge conflicts on it.

### Convention 4 — Long-form `/fdc/` docs are typed concepts

Every non-index Markdown file under `fdc/decisions/`, `fdc/runbooks/`, `fdc/troubleshooting/`, and `fdc/briefs/` is a typed knowledge concept. It MUST start with YAML frontmatter so humans, LLMs, search indexes, graph generators, and future export tools can identify what it is without reading the full body.

Index files are exempt:

- `fdc/fdc.md`
- `fdc/decisions/decisions.md`
- `fdc/runbooks/runbooks.md`
- `fdc/troubleshooting/troubleshooting.md`
- `fdc/briefs/briefs.md`

Required frontmatter fields:

```yaml
---
type: decision | runbook | troubleshooting | brief
title: Short human title
description: One sentence describing what this document captures.
tags: [tag-one, tag-two]
timestamp: YYYY-MM-DD
---
```

Rules:

- `type` MUST match the containing folder: `decision` in `fdc/decisions/`, `runbook` in `fdc/runbooks/`, `troubleshooting` in `fdc/troubleshooting/`, `brief` in `fdc/briefs/`.
- `title`, `description`, `tags`, and `timestamp` MUST be present and non-empty.
- `status` MUST be present on decisions (`proposed | accepted | superseded | rejected`) and briefs (`open | done | dropped`). Runbooks and troubleshooting notes don't need one. This is what makes `supersedes` / `superseded_by` mean something and lets the graph tell live decisions from dead ones.
- `timestamp` is the date the document was created or last materially updated. A date (`YYYY-MM-DD`) or a full ISO datetime (`2026-09-11T10:00:00Z`); only the date part is validated.
- Optional fields are allowed when useful: `status`, `owners`, `related`, `resource`, `supersedes`, `superseded_by`, and `verified` (date a runbook/troubleshooting note was last confirmed to work; audited by `scripts/fdc-stale.sh`).
- Frontmatter is metadata, not a replacement for body content. Keep the body readable as a standalone document.

**Provenance, trust, and freshness (optional).** Adopted from OKF v0.2 (§10) so `/fdc/` answers "who wrote this, who confirmed it, is it still true, what was it based on":

| Field | Meaning | Used by |
|---|---|---|
| `generated: { by, at }` | Who/what wrote the current content. | humans, graph |
| `verified` | Bare date, `{ by, at }`, or a list of them. Latest `at` wins. Actor convention: `human:<id>`, `<agent>/<version>`, `process:<id>`. | `fdc-stale.sh` → trust tier: unverified / machine-confirmed / human-reviewed |
| `stale_after: YYYY-MM-DD` | Absolute expiry; overrides the global 180-day threshold for this doc. | `fdc-stale.sh` |
| `sources: [{ id, resource, title }]` | What the doc derives from. Cite in the body as `[^id]`. | `fdc-graph.sh` (edges) |
| `not: [{ term, why, instead }]` | Rejected approaches, so the next session doesn't re-propose them. | agents reading frontmatter |

None of these are required; the validator only checks the base fields. `scripts/fdc-log.sh` regenerates `fdc/log.md`, a newest-first history of the knowledge layer from git, so an agent sees recent changes without running git.

Each long-form `/fdc/` document MUST also have a `## See also` section with normal Markdown links to related folder docs and related `/fdc/` documents. These links are the relationship graph. Do not invent a second relationship syntax unless the repo has a specific tool that requires one.

**Building the graph.** `scripts/fdc-graph.sh` turns this latent graph into a real artifact: it extracts the frontmatter (`type`, `title`, `tags`, `related`, `supersedes`) and the `## See also` links into a dependency-free `graphify-out/fdc-graph.json` that any graph tool can ingest. It is **optional and never part of the pre-commit hook** — a teammate with no graph tooling installed can ignore it entirely; FDC still works. Set `FDC_GRAPH_CMD` to hand the JSON to your own tool (e.g. graphify) for richer rendering; teammates who don't set it just get the JSON. Add `graphify-out/` to `.gitignore` — it's per-user generated output, not shared state.

Example:

```markdown
---
type: decision
title: Keep FDC as the primary software development convention
description: FDC remains the repo operating discipline while typed metadata supports indexing and graphing.
tags: [fdc, llm-context]
timestamp: 2026-06-28
status: accepted
---

# Keep FDC as the primary software development convention

## Context
...

## See also

- `AGENTS.md` — operating rules that enforce this decision.
- `fdc/fdc.md` — long-form knowledge index.
```

**Migration rule:** this applies to old and new projects. When FDC is installed in a repo that already has long-form `/fdc/` docs, migrate every existing non-index `/fdc/` doc to include required frontmatter and a `## See also` section before considering the setup complete.

**Validation scope.** Locally the pre-commit hook only validates the `/fdc/` docs that the current commit *touches* — a stale legacy doc never blocks an unrelated commit (that would just train people to bypass the hook, defeating the mechanism). The full-tree sweep, which catches drift in docs the change didn't touch, runs when `FDC_VALIDATE_ALL=1` is set — which the CI backstop (`scripts/check-docs-ci.sh`, see Convention 6) does on every merge. So you get low-friction local commits *and* a guarantee the whole tree stays clean before merge.

### Convention 5 — Code change → doc change in the same commit (TOP PRIORITY rule)

The single highest-priority rule. Stated in `AGENTS.md` at the very top, in two halves:

1. **Code → docs.** Any change to a code/config artifact (`*.yml`, `*.j2`, `*.cs`, `*.rs`, `*.ts`, `*.tsx`, `*.php`, `*.py`, `*.sh`, etc. — language-specific) MUST update the folder's `<folder>.md` in the same change. Plus every cross-referenced doc found via `rg <changed-identifier>`.

2. **User intent → docs.** When the user explains *why*, describes a procedure, reports a bug, or asks for something new — capture it in `/fdc/<category>/` *during* the work, not after.

A diff or conversation that doesn't update docs is treated as a bug. The task is **not done** until docs match.

Enforced mechanically by `scripts/check-docs-fresh.sh` (pre-commit hook). Bypass with `SKIP_DOC_CHECK=1` only when the change is genuinely orthogonal to documented behavior, and put the reason in a `Skip-Doc-Check: <reason>` commit trailer. The CI backstop honours that trailer — and only with a non-empty reason — so a justified bypass passes review with the justification visible in `git log`, while an unjustified one is caught at merge.

### Convention 6 — Drift checker enforces it pre-commit

A short shell script at `scripts/check-docs-fresh.sh` that:

- Validates that changed non-index long-form `/fdc/` docs have required frontmatter and a `## See also` section (whole tree when `FDC_VALIDATE_ALL=1`).
- Looks at staged changes (pre-commit), a working-tree diff (manual run), or an explicit `CHECK_RANGE` (CI).
- For every changed code file, finds the doc that **owns** it — the nearest ancestor folder (the file's own folder, then its parents) that actually has an index doc. Leaf folders without their own `<folder>.md` are owned by the closest ancestor that has one; root config files are owned by the root `readme.md` / `AGENTS.md`.
- Checks whether a `*.md` in that owning folder also changed. If not, fails with an actionable message naming the owner and the offending files.
- Generated/machine-owned files (lockfiles, `go.sum`) are skipped — documenting them is pointless.
- "Code" is decided by extension (`CODE_REGEX`) **and** by basename (`CODE_BASENAME_REGEX`), so extension-less build/ops files — `Dockerfile`, `Makefile`, `Justfile`, `Procfile`, `.env*` — are enforced too.
- A doc change anywhere *under* an owner folder satisfies that owner (a `src/auth/auth-flow.md` edit covers code owned by `src/src.md`), and deleting a folder together with its own index doc is not a violation — the deletion *is* the doc update.

**CI backstop (teams).** The hook is bypassable locally (`SKIP_DOC_CHECK=1` or `git commit --no-verify`). For shared repos, `scripts/check-docs-ci.sh` re-runs the same check across the whole change (`base...HEAD`, with full-tree metadata validation) at merge time, so a local bypass is caught in review. It is **provider-neutral** — it resolves the base branch from common CI env vars (or `FDC_CI_BASE` / an argument) and is a one-line job in GitLab CI, Gitea/Forgejo, Woodpecker, Drone, Jenkins, Buildkite, Bitbucket, a server-side hook, or cron. No specific CI platform is assumed or required. Solo repos can skip it.

**Why "owner" and not "same folder":** an earlier version required a `*.md` change in the *exact* folder of every changed file. That contradicts the convention's own rule that not every leaf folder needs its own doc (pure-data and thin leaf folders are documented by their parent). The strict version blocked legitimate commits and trained contributors to reflexively `SKIP_DOC_CHECK=1`, defeating the whole mechanism. Walking up to the nearest documented ancestor enforces exactly what the convention promises — no more, no less.

**Configuration lives in `scripts/fdc.conf`**, a sourced bash file holding the upstream URL, the installed version, the team/credentials/commit policies, the audit thresholds, and the five classification regexes. It is the only file a repo edits; every script is a verbatim upstream copy that `fdc.sh update` overwrites, so updating never merges anything.

**One entry point, `scripts/fdc.sh`**: `doctor`, `check`, `install-hook`, `update`, `stale`, `log`, `graph`, `index`, `notes`, `whoami`. `doctor` is what an agent runs at session start: it activates the hook if the clone lacks it, compares the installed version with the newest upstream tag, reports missing tools, prints the actor identity, and lists open notes and claimed briefs. That is how a four-machine setup self-heals: the rule is in `AGENTS.md`, the fix is one script call.

**The hook is versioned.** `.githooks/pre-commit` is committed; `install-hook` (and `doctor`) set `core.hooksPath` to it once per clone, after which hook changes reach every clone on pull. Installed via `scripts/install-hook.sh`, which falls back to writing a pre-commit wrapper into the git hooks dir when a repo has no `.githooks/`. This is worktree- and submodule-safe (where `.git` is a file, not a directory) and honors `core.hooksPath` — a plain relative symlink breaks in all three cases. If a pre-commit hook already exists it is kept and the FDC call is appended (idempotently); if the hook is a symlink owned by a hook manager (husky, pre-commit.com, lefthook) the installer leaves it alone and prints the line to add.

**Portability matters because the hook runs on every contributor's machine, not just yours.** All scripts target **stock macOS `/bin/bash` (3.2)** and Linux bash, with BSD *or* GNU `awk`/`grep`/`sed` — no bash 4 features (no associative arrays), no GNU-only flags. Don't reintroduce `declare -A`, `mapfile`, `${var,,}`, `sed -i` without an empty-arg, or `grep -P`: they silently break for a teammate on a default Mac.

**Staleness and trust audit (optional).** `scripts/fdc-stale.sh` reads `verified:` (falling back to `timestamp:`) and `stale_after:` on every runbook and troubleshooting note, lists the stale ones, and reports each doc's trust tier from the `verified` actors. It never fails a build; it is a report for CI output or a pre-rotation check. This is the answer to the semantic-correctness limitation in §7 for the doc types that rot fastest: a procedure nobody has re-run in six months is treated as unverified.

**Versioning and updates.** Upstream tags releases as `YYYY.MM.DD`; `FDC_VERSION` in `fdc.conf` records what a repo has. `fdc.sh update [ref]` clones the tag, overwrites `scripts/*.sh` and `.githooks/`, keeps `fdc.conf`, and bumps `FDC_VERSION`. Rules text and templates (`AGENTS.md` sections, `fdc/` index templates) are updated by `LLM_UPDATE_PROMPT.md`, which asks for the two policies on repos that predate them. Delivery is git-only on purpose — no package manager, so an Ansible box and a Flutter laptop install the same way — with a `curl | bash` `install.sh` for the first setup and the LLM prompt for filling in the docs.

The list of "code" extensions is project-specific (see `LLM_PROMPT.md` → "Project-type-specific guidance" for per-stack defaults).

### Convention 7 — A behaviour contract every agent reads

`AGENTS.md` carries a short "How to work in this repo" section: ten imperative rules on docs-vs-code conflicts, uncertainty, mutating actions outside the repo, scope, skipping, report shape, language, credentials, commits, and parallel sessions. It exists because different models (Claude, Codex, Gemini, Qwen, DeepSeek, Kimi, …) default differently on exactly these points, and a team that mixes them needs one contract that lives in the repo, not in each vendor's habits. The rules are flat and vendor-neutral on purpose: no tool names, no slash commands, nothing about tone or reasoning style.

Two rules are per-repo choices, filled at bootstrap:

| Policy | A | B |
|---|---|---|
| **Credentials** | *Documented in place*: infrastructure is local (VPN/LAN only) and credentials rotate often, so each folder doc's `## Access` table holds the real value with a `Rotated on` date. Rotation = update the row, `rg` the old value. | *Vault reference*: the table holds `<vault: item>`; values never enter git. |
| **Commits** | *Milestone commits by the agent*: commit when a verified, coherent piece of work is done; stage only your own files (several sessions may share the checkout); never amend/rebase/force/push. | *User commits*: show `git status` / `git diff --stat` and stop. |

Policy A for credentials is a deliberate trade: it puts secrets in git in exchange for an agent that can find and use them without a vault round-trip. It is only defensible when the repo is private, the blast radius is a LAN, **and there is one user** — the bootstrap refuses policy A when `FDC_TEAM=team`, and `doctor` warns if the two are combined later. Every disk holding such a repo should be encrypted.

Commit policy A is written for several sessions on several machines: fetch first, fast-forward when clean, push after a milestone when it is a fast-forward, stop on rejection, never rewrite history, never touch `main` unasked. Rule 11 (handoff via a `claimed` brief) and the notes type are what make a session on one machine resumable on another.

**Team additions** (all rules in the same section): the human behind an agent is `human:<git email local part>` and agents are `<tool>/<model>`; an agent may propose but only a human accepts an ADR or closes a brief; briefs are `claimed` with `owners` so two people don't build the same thing; folder-doc tables are append-only so concurrent edits merge; the CI backstop is mandatory; a PR template mirrors the definition of done and `CODEOWNERS` routes doc changes to folder owners; `fdc/runbooks/onboard-developer.md` is the five-minute setup for a new teammate or a new machine.

### Convention 8 — Compaction: knowledge has an end state, and sessions have a read budget

The first seven conventions say when to *create* a doc. Without this one a repo accumulates every plan, every resolved incident, and every superseded decision as equal citizens, and every session pays for all of them. (The repo that motivated this rule had 268 Markdown files and 53,000 lines, 54% of them completed plans, plus a 1,600-line "open findings" register that `AGENTS.md` told every session to read first.)

Four mechanisms, all in `fdc.sh`:

1. **Lifecycle.** Every `/fdc/` doc has a `status`, and each type has *end states* (table in `fdc/fdc.md`): superseded/rejected decisions, resolved/accepted troubleshooting, done/dropped briefs and plans, done notes, retired runbooks. An end-state doc is history, not knowledge.
2. **Ephemeral versus durable.** Plans and specs live in `fdc/work/`. When one completes, its durable outcome is written into the knowledge layer (at most one ADR, plus runbook / folder-doc updates) and the plan is marked done. Git keeps the text; the layer keeps the conclusion.
3. **Archive, then prune.** `fdc.sh archive` moves end-state docs older than `FDC_ARCHIVE_DAYS` (90) into `fdc/archive/<type>/`, which nothing reads, validates, indexes, or audits. Reversible with `git mv`. `fdc.sh prune --yes` deletes archive entries older than `FDC_PRUNE_DAYS` (365); git history still has them. Both have `--dry-run`.
4. **Registers are views, not files.** A known-but-unresolved problem is a troubleshooting note with `status: open` — a *finding*. `fdc.sh doctor` prints the open ones at session start, `fdc.sh findings` on demand. Resolved ones drop out of the view and archive later. Twenty lines read instead of sixteen hundred.

Rule 15 of the contract makes the four process habits (brief before build, plan in `fdc/work/`, tests first, verify before done) repo rules rather than plugin behaviour: a planning plugin such as Claude Code's *superpowers* may drive them and writes into `fdc/work/`; a machine or model without it follows the same rules by hand.

Plus a **read budget** in the behaviour contract (rule 14): what a session reads by default (`AGENTS.md`, doctor output, the touched folders' docs) and what it does not (archive, work, log, other folders' docs), and size budgets — 150 lines for a folder doc, 300 for a knowledge doc, `FDC_BUDGET_TOTAL_LINES` for the active layer — that `fdc.sh budget` reports and `doctor` warns about. Budgets are reports, never gates: a long doc is a smell to fix, not a blocked commit.

---

## 3. The file layout

```
<repo-root>/
├── readme.md                    # short human entry point
├── AGENTS.md                    # canonical operating rules (TOP PRIORITY rule, navigation, etc.)
├── CLAUDE.md                    # thin Claude addendum, points back to AGENTS.md
├── .gitignore
├── fdc/
│   ├── fdc.md                  # index for /fdc/ (five subfolders)
│   ├── log.md                  # optional, generated: newest-first change history
│   ├── decisions/
│   │   ├── decisions.md         # ADR index
│   │   └── YYYY-MM-DD-*.md
│   ├── runbooks/
│   │   ├── runbooks.md          # runbook index
│   │   └── *.md
│   ├── troubleshooting/
│   │   ├── troubleshooting.md   # troubleshooting index
│   │   └── *.md
│   ├── briefs/
│   │   ├── briefs.md            # brief index (## Index generated)
│   │   └── *.md
│   ├── notes/
│   │   ├── notes.md             # note index
│   │   └── *.md
│   ├── work/                    # ephemeral plans/specs (type: plan) — not read by default
│   │   ├── work.md
│   │   └── YYYY-MM-DD-*.md
│   └── archive/<type>/          # end-state docs moved by fdc.sh archive — never read by default
├── .githooks/
│   └── pre-commit               # versioned hook; activated per clone via core.hooksPath
├── scripts/
│   ├── scripts.md               # folder index
│   ├── fdc.sh                   # entry point: doctor | check | update | stale | index | notes | findings | archive | prune | budget | …
│   ├── fdc.conf                 # per-repo settings (the only file you edit here)
│   ├── check-docs-fresh.sh      # drift + fdc-metadata checker (executable)
│   ├── install-hook.sh          # worktree-safe pre-commit installer
│   ├── check-docs-ci.sh         # provider-neutral CI backstop
│   ├── fdc-graph.sh             # optional: knowledge graph from /fdc/ metadata + sources
│   ├── fdc-stale.sh             # optional: staleness + trust-tier report
│   └── fdc-log.sh               # optional: regenerates fdc/log.md from git
└── <project folders>/
    ├── <folder>/<folder>.md     # one index per folder
    └── ...
```

Replace `<project folders>` with whatever the project actually has: `src/`, `tests/`, `app/`, `apps/`, `packages/`, `services/`, `infrastructure/`, etc. Every one of them gets its own `<folder-name>.md`.

---

## 4. Standard shape of a folder index doc

Every `<folder>.md` follows the same shape so an LLM can predict where information lives:

```markdown
# <folder-name>

**Purpose:** one or two sentences — what this folder is for and who consumes it.

## Subfolders

| Folder | Contains | Index doc |
|---|---|---|
| `sub1/` | … | `sub1/sub1.md` |
| ... | | |

## Key files

| File | Purpose |
|---|---|
| `main.ext` | … |
| ... | |

## Commands / how to use

```bash
<the one or two commands someone would actually run>
```

## Targets            <!-- ops folders only -->

| Target | Environment | Reached via |
|---|---|---|
| `<host / cluster / account>` | `<prod / staging>` | `<ssh alias, kubeconfig context, cloud profile>` |

## Depends on

- `<other-folder>/<other-folder>.md` — what the dependency is.

## Gotchas

- The non-obvious things. The "easy to get wrong" things.

## See also

- `fdc/decisions/YYYY-MM-DD-<related>.md`
- `fdc/runbooks/<related>.md`
```

Not every section is required — drop "Subfolders" if there are none, drop "Commands" if the folder is just data, and use "Targets" only in operations folders (the hosts, clusters, or accounts the folder acts on — an agent must know the blast radius before running anything). But the order and the section names should match across the repo.

**Length target:** ~150 lines max. If it grows past that, move long-form material into a `/fdc/<category>/` file and link to it. The folder doc stays a quick reference.

---

## 5. The TOP PRIORITY rule in detail

The rule that lives at the top of `AGENTS.md`. Stated explicitly so the LLM can't miss it.

### Definition of done

A task is NOT done until ALL of these are true:

- [ ] The `<folder>.md` in every touched folder reflects the new reality.
- [ ] Parent index docs reflect any added / renamed / removed files.
- [ ] Cross-references found by `rg <changed-identifier>` are updated.
- [ ] `/fdc/` entries (decision / runbook / troubleshooting / brief) have been created when warranted, have required frontmatter, and are linked from at least one folder doc.
- [ ] Existing non-index `/fdc/` docs still pass the required-frontmatter and `## See also` rules.
- [ ] `bash scripts/check-docs-fresh.sh` exits 0 (or you've consciously used `SKIP_DOC_CHECK=1` with justification in the commit message).

If any item is unchecked, the work is not complete. The agent must say so explicitly — not silently report success.

### Triggers — code-side

| You did this | You MUST also do this |
|---|---|
| Changed a `*.cs/*.rs/*.ts/*.php/*.py/...` source file or its config (`Cargo.toml`, `package.json`, etc.). | Update the folder's `<folder>.md`. |
| Added / renamed / removed a file. | Update the parent folder's index doc. |
| Changed a public API, an env-var name, a service URL, a port, a database name, a credential field. | `rg <old-value> -l` and update every hit. |
| Changed a cross-folder dependency. | Update "Depends on" in both folder docs. |
| Added a new service, package, route, command, or top-level feature. | Update parent index tables and the root navigation in `AGENTS.md`. |

### Triggers — user-intent-side

| User did this | Agent MUST do this |
|---|---|
| Explained *why* something is done a certain way. | Create an ADR in `fdc/decisions/YYYY-MM-DD-<title>.md`. Link from the affected folder doc. |
| Described a multi-step procedure they want reliable. | Create a runbook in `fdc/runbooks/<action>-<thing>.md`. Link from the affected folder doc. |
| Reported a problem you then diagnosed / fixed. | Create or update `fdc/troubleshooting/<symptom>.md` (symptom → cause → fix). Link from the affected folder doc. |
| Asked for something that needs design before code. | Create a brief in `fdc/briefs/<topic>.md`. Move out of `briefs/` once implemented. |
| Revealed a new constraint, credential, host, or convention. | Update the relevant folder doc's Gotchas / Depends-on section in the same turn. |
| Reported docs are wrong / out of date. | Treat as P0 — `rg` for every cross-reference and fix all of them in the next message. |

### Self-check ritual

**Before** writing any code: read the target folder's `<folder>.md` first. The doc tells you the conventions, gotchas, and dependencies before you touch the code.

**Before** saying "done":

```bash
git diff --name-only                    # what changed
git diff --name-only | grep '\.md$'     # docs changed?
bash scripts/check-docs-fresh.sh        # drift check
rg <old-identifier>                     # stale references?
```

If `git diff` shows code whose owning doc wasn't also updated, **stop** and update docs before proceeding.

### A note on small/atomic commits

The rule is enforced per commit, which is in tension with TDD-style and plan-driven workflows that commit in tiny red-green-refactor steps (a `src/` change and its `tests/` change have different owners, each needing a doc touch).

Two ways to keep the friction low:

- **Update the owning doc as part of the same logical change.** Usually the folder index gets one line, not a rewrite. The cost is small when done continuously and large when batched.
- **Or enforce at merge granularity instead of per commit.** Skip the local hook during rapid iteration and rely on the CI backstop (`scripts/check-docs-ci.sh`), which checks the whole change at merge time. This trades per-commit purity for fewer interruptions. Pick one per repo and state it in `scripts/scripts.md`.

---

## 6. When FDC fits

FDC is a good fit when:

- The repo has multiple top-level folders with different domains/concerns.
- LLMs are regular contributors (you ask Claude/Codex/Cursor/etc. for code, reviews, or analysis at least weekly).
- The repo has a non-trivial lifespan — months to years, not days.
- The cost of an LLM misunderstanding the codebase (and shipping a wrong change) is higher than the cost of writing the docs.
- You want the convention to survive team turnover and tooling churn.

FDC is overkill when:

- A one-shot script or a throwaway prototype.
- A solo developer who only ever uses one LLM and rarely revisits old code.
- A repo where the code itself is the only authoritative documentation (e.g. heavily generated code, infrastructure-as-code with strong primitives, single-purpose libraries).

---

## 7. When FDC doesn't fit (limitations)

FDC has real limits. Be honest about them.

- **It is a convention, not a framework.** Nothing in the structure prevents a human from ignoring the rules. The pre-commit hook catches code/doc-drift but doesn't catch lies in the docs. Trust is built over time by maintaining the discipline.

- **It targets *human* LLM workflows.** If your "agents" are autonomous and don't need a human to read intermediate output, you probably want full agent frameworks (LangGraph, CrewAI, AutoGen). FDC is a human-in-the-loop discipline.

- **It assumes sequential thinking inside each folder.** When a refactor spans many folders simultaneously, FDC doesn't give you a special cross-cutting view — you must navigate folder-by-folder. Pair with a knowledge graph (graphify, gitnexus, or similar) for impact analysis.

- **Folder boundaries become contracts.** Moving a file between folders touches more docs than the file rename alone. This is by design, but it has a cost.

- **It cannot decide what is worth keeping.** `fdc.sh archive` moves what a *status* says is finished; a human still has to set that status, and a doc that nobody marks resolved stays current forever. `budget` makes the cost visible; it does not judge content.

- **It cannot enforce semantic correctness of docs.** A doc that says "the deploy command is X" while the actual deploy command is Y will pass the drift check (the doc file *was* touched) but still mislead. The drift check is a *liveness* signal, not a *correctness* one — it proves a doc was considered, not that it's right. The fix is human discipline + the AGENTS.md rule "if docs and code disagree, trust code and fix the doc in the same change," plus a periodic doc audit (the kind of review that produced this section).

- **The hook is bypassable.** `SKIP_DOC_CHECK=1` and `git commit --no-verify` both skip it locally. The CI backstop closes most of that gap: it re-checks the whole change and accepts a bypass only when a commit carries a `Skip-Doc-Check:` trailer with a reason.

- **The "user intent → docs" half is not mechanically enforced.** No script can know that a conversation produced a decision or diagnosed an incident. The CI backstop prints a *hint* (never a failure) when commit subjects mention fixes, incidents, or decisions and nothing under `fdc/` changed. It is deliberately soft: a hard gate on a heuristic would generate false positives and teach people to ignore it.

---

## 8. FAQ

**Q: Why folder-named docs instead of `CLAUDE.md` per folder?**
A: Because when `rg <topic>` returns three hits in three different `CLAUDE.md` files, you can't tell from the filename which folder they belong to. With `grafana/grafana.md` and `auth/auth.md`, the filename is the breadcrumb.

**Q: Why `AGENTS.md` instead of `CLAUDE.md` as the canonical file?**
A: `AGENTS.md` is the emerging cross-agent standard — read natively by Codex, Copilot CLI, and recent Cursor. Claude Code auto-loads `CLAUDE.md`; Gemini CLI uses `GEMINI.md`; older Cursor uses `.cursor/rules`. By making `AGENTS.md` canonical and giving every other agent a thin stub that points to it (`CLAUDE.md`, `GEMINI.md`, `.cursor/rules`), each agent gets the same rules without duplication. The only cost is one extra cheap Read at session start.

**Q: Doesn't the per-folder doc become stale quickly?**
A: That's exactly what the pre-commit hook prevents. Any folder where code changes must also have a `*.md` change. The hook fails the commit otherwise. Discipline is mechanical, not aspirational.

**Q: What if a refactor genuinely doesn't change documented behavior?**
A: `SKIP_DOC_CHECK=1 git commit -m 'refactor: ...' -m 'Skip-Doc-Check: <reason>'`. The trailer is what CI checks for; without a reason the merge is blocked. Visible in `git log`, like a `--no-verify` should be.

**Q: What if my project has 50+ top-level folders?**
A: You probably don't need a folder doc for every leaf. The convention is: every folder that contains code, config, or distinct domain content gets a doc. Pure-data folders (`assets/`, `images/`, `migrations/`) can share their parent's doc if there's nothing folder-specific to say.

**Q: What about monorepos?**
A: FDC works at the monorepo root (`AGENTS.md`, `CLAUDE.md`, `fdc/`) and inside each package (`packages/<name>/<name>.md`). The drift checker's CODE_REGEX should cover all languages in the monorepo.

**Q: Where do I put credentials?**
A: In the owning folder doc's `## Access` table, either as the value (credentials policy A: private repo, LAN-only infrastructure, frequent rotation) or as a `<vault: item>` reference (policy B: anything shared or public). The choice is made once per repo at bootstrap and written into `AGENTS.md` → "How to work in this repo". See Convention 7.

**Q: Can I rename folder docs `<folder>.md` to something else?**
A: You can, but you give up the grep-disambiguation property. The convention pays off most when filenames carry their scope. If you must rename, do it consistently across the whole repo.

**Q: How does this play with team members who don't use LLMs?**
A: Folder docs benefit human readers too — they're the same shape as good `README.md` files, just named differently. The pre-commit hook helps non-LLM contributors too: it catches the "I forgot to update the docs" mistake every team has.

---

## 9. Related work and reading

- **Interpretable Context Methodology (ICM)** — Van Clief & McDermott. Prior art for folder-as-context in agent pipelines. https://github.com/RinDig/Interpretable-Context-Methodology-ICM-
- **Open Knowledge Format (OKF)** — Google Cloud, v0.2. https://github.com/GoogleCloudPlatform/open-knowledge-format. A vendor-neutral *format* for knowledge: Markdown + YAML frontmatter, one concept per file, links as the graph, `index.md` per directory. Only `type` is required; v0.2 adds optional provenance (`sources`), trust (`generated`, `verified` with an actor convention such as `human:<id>` vs `<agent>/<version>`), and lifecycle (`status`, `stale_after`) fields. FDC's typed `/fdc/` frontmatter and `## See also` graph follow the same shape, so an `/fdc/` tree can be read by OKF tooling. The two are complementary: OKF says nothing about keeping docs in sync with code, and FDC says nothing about who wrote a doc or how much to trust it. FDC adopts OKF's actor-tagged `verified` / `generated`, per-doc `stale_after`, `sources` with footnote attribution, the `not:` block, `log.md`, and ISO datetimes (all optional; see Convention 4). Its attested computations and usage-count credibility signals are data-catalog concerns and out of scope here.
- **Architecture Decision Records (ADRs)** — Michael Nygard. The decisions/ format.
- **The Twelve-Factor App** — Adam Wiggins. Influence on what to surface in folder docs (env vars, config, deps).
- **Unix philosophy / pipe-and-filter** — McIlroy. Folder boundaries as clean interfaces.
- **Make / dependency-tracking build systems** — Feldman 1979. Files as both artifact and coordination mechanism.

FDC stands on all of these. It is not novel; it is opinionated assembly.
