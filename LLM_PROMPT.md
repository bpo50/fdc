<!-- GENERATED FILE — do not edit LLM_PROMPT.md directly. Edit LLM_PROMPT.src.md or the files under templates/, then run: bash tools/build-prompt.sh -->
# LLM Prompt — Apply the Folder-Doc Convention (FDC) to This Repo

Paste this entire file into a fresh LLM session inside the target repository (Claude Code, Codex CLI, Copilot CLI, Cursor agent, Gemini CLI, etc.). The prompt is self-contained — it includes every template you'll need.

---

# YOUR TASK

You are going to set up the **Folder-Doc Convention (FDC)** in this repository. FDC is a documentation discipline for software repos where LLMs are regular contributors. The goal is to give every future agent session reliable, scoped, self-updating context, and to mechanically enforce that the docs stay in sync with the code.

Read this entire prompt before doing anything. Then follow the steps in order.

**Fast path.** If `scripts/fdc.sh` already exists (the user ran `install.sh`), the tooling is in place: skip the script-copying parts of Step 4 and only fill `scripts/fdc.conf`, then continue with the documentation steps. If it does not exist and the machine has `git` and `curl`, offer to run `curl -fsSL https://raw.githubusercontent.com/bpo50/fdc/main/install.sh | bash -s -- init` instead of copying the inlined scripts by hand — same result, fewer lines to paste. The inlined copies below are the offline fallback.

# THE CONVENTION IN ONE PARAGRAPH

Every folder gets one index doc named `<folder-name>.md`. The repo root has `AGENTS.md` (canonical operating rules for all agents) and `CLAUDE.md` (thin Claude-only addendum that points back to AGENTS.md). Long-form knowledge lives in `/fdc/{decisions,runbooks,troubleshooting,briefs}/`; every non-index long-form doc has required YAML frontmatter (`type`, `title`, `description`, `tags`, `timestamp`) and Markdown links to related docs. A pre-commit hook (`scripts/check-docs-fresh.sh`) fails any commit that touches code without touching the owning doc, and it validates all `/fdc/` long-form metadata. Doc updates are part of "definition of done" — a task is not complete until docs match.

# STEP 0 — Detect the project, confirm scope with the user

Before creating any files, run these commands and report the results to the user. Then ask for confirmation on what you'll create and where.

```bash
# Repo state
pwd
git rev-parse --is-inside-work-tree 2>/dev/null || echo "(not a git repo yet)"
git log --oneline -5 2>/dev/null || true
git status --short 2>/dev/null || true

# Existing rules files
ls -la AGENTS.md CLAUDE.md GEMINI.md .cursorrules .github/copilot-instructions.md 2>/dev/null || echo "(none yet)"

# Project type signals
ls -la
find . -maxdepth 2 -type f \( \
  -name 'package.json' -o -name 'Cargo.toml' -o -name 'composer.json' \
  -o -name '*.csproj' -o -name '*.fsproj' -o -name '*.sln' \
  -o -name 'angular.json' -o -name 'next.config.*' -o -name 'nuxt.config.*' \
  -o -name 'pyproject.toml' -o -name 'go.mod' -o -name 'Gemfile' \
  -o -name 'pubspec.yaml' \
  -o -name 'Dockerfile' -o -name 'docker-compose*.yml' -o -name 'compose*.y*ml' \
  -o -name '*.tf' -o -name 'ansible.cfg' -o -name 'inventory*' -o -name 'Chart.yaml' -o -name 'kustomization.y*ml' \
  \) -not -path './node_modules/*' -not -path './target/*' \
     -not -path './vendor/*' -not -path './bin/*' -not -path './obj/*' 2>/dev/null

# Folder structure to depth 3
find . -maxdepth 3 -type d \
  -not -path '*/.git/*' -not -path '*/node_modules/*' \
  -not -path '*/target/*' -not -path '*/vendor/*' \
  -not -path '*/dist/*' -not -path '*/build/*' \
  -not -path '*/.next/*' -not -path '*/.nuxt/*' \
  -not -path '*/bin/*' -not -path '*/obj/*' \
  | sort

# Planning-tool output (plans/specs that belong in fdc/work/, not in the knowledge layer)
ls -d docs/superpowers docs/plans .planning 2>/dev/null || echo "(no planning-tool folders)"

# Any existing markdown
find . -type f -name '*.md' \
  -not -path './node_modules/*' -not -path './vendor/*' \
  -not -path './target/*' -not -path './.git/*' \
  2>/dev/null | head -30
```

Then **report**:

1. **Detected project type(s).** One or more of: `.NET`, `Rust`, `Next.js`, `Angular`, `PHP`, `Python`, `Go`, `Ruby`, `Flutter/Dart`, `Ops/Infrastructure` (Ansible, Terraform, Helm, Kubernetes, Compose), `Monorepo`, `Other`. List them explicitly. Note if it's a polyglot monorepo with multiple stacks (e.g. Rust backend + Next.js frontend + Flutter mobile).

2. **Top-level folders you'll create indexes for.** Exclude `.git`, build/dependency caches, generated output. Show the user the list.

3. **Existing rules files.** If `AGENTS.md`, `CLAUDE.md`, `.cursorrules` etc. already exist with content, name them — you'll merge with them, not overwrite.

4. **Existing markdown that may conflict.** Especially `README.md` / `readme.md` files in subfolders that should be renamed under FDC.

5. **Planning-tool folders** (`docs/superpowers/`, `docs/plans/`, `.planning/`): their contents move to `fdc/work/` in Step 2 and the tool is pointed there from now on (`AGENTS.md` rule 15).

Keep the report to what the commands showed. If an existing rules file or config already states a policy, mention that a conflict exists in one neutral sentence; do not paste the file's wording into your report or your questions, and do not treat a value that shipped in `scripts/fdc.conf` as a decision — the policy fields there are empty until the user answers below.

Then **ask the questions below, exactly as written, in three rounds**. Wait for each round's answers before showing the next. If your tool offers a structured question widget, put the full option text (the bold label plus its consequence sentence) into the option, not a two-word summary. Do not create files speculatively.

# Bootstrap questions

Ask these in **three rounds**, in this order. Each round waits for answers before the next one is shown, because later options depend on earlier answers. Present every block **as written here**: the question, all options with their consequence line, the default, and what changes later. Do not shorten the options to a word or two, and do not add examples taken from the repository you are bootstrapping — describe a conflict with the repo's existing files in one neutral sentence, never by quoting them.

Each block names the config field it writes (`scripts/fdc.conf`) so the answer lands in exactly one place.

---

## Round 1 — Scope

### Q1. Which folders get an index doc?

> The folders I will create `<folder-name>.md` in are: `[list from Step 0]`.
> Anything to add or remove?

- **Why it matters:** every listed folder gets a doc the pre-commit hook will insist on keeping in sync. Folders left out are invisible to future agent sessions.
- **Default:** every top-level folder that holds code or configuration. Never build caches, dependency folders, or generated output.
- **Later change:** cheap. Add a folder doc any time; the hook starts enforcing it on the next commit.
- **Writes:** nothing in the config; it decides which files Step 3 creates.

### Q2. Any folders I must not touch?

> Are there folders I should leave exactly as they are, such as vendored third-party code, git submodules, or generated trees?

- **Why it matters:** those folders get no index doc and are excluded from the drift check, so a change there never asks for a doc update.
- **Default:** none beyond the standard skip list (dependency and build folders).
- **Later change:** cheap. Add the path to `SKIP_FOLDER_REGEX` in the config.
- **Writes:** `SKIP_FOLDER_REGEX` (only when the answer is not empty).

---

## Round 2 — Who works here

### Q3. Solo or team?

> Does more than one person commit to this repository?

- **Solo** — one person commits, possibly through several agents and machines. The pre-commit hook alone is enough enforcement.
- **Team** — two or more people commit. Consequences: the CI backstop script becomes a required check, a pull-request template with the definition of done is added, the generated `fdc/log.md` is gitignored (each machine regenerates it), and in Round 3 the credentials question changes shape.
- **Why it matters:** this answer decides which credential options are safe to offer and how much of the enforcement has to live outside a single developer's machine.
- **Default:** none; the answer must be explicit.
- **Later change:** solo to team is a normal upgrade (run the update prompt). Team to solo is just a config edit.
- **Writes:** `FDC_TEAM`.

### Q4. How many machines?

> Will you (or your agents) work on this repository from more than one machine?

- **One machine** — local-only files are acceptable.
- **More than one** — everything under `fdc/` must be tracked in git, because briefs and notes are the hand-off between machines.
- **Why it matters:** decides whether the knowledge layer can live outside git at all.
- **Default:** more than one.
- **Later change:** cheap; start tracking the folder.
- **Writes:** nothing; it constrains Q5.

### Q5. What is tracked in git?

> Should `fdc/`, `AGENTS.md`, and `CLAUDE.md` be committed, or kept local and gitignored?

- **Track everything** — the docs travel with the code; every clone, teammate, and agent sees the same rules. This is the normal choice.
- **Gitignore `fdc/` only** — the rules files are shared but the knowledge layer stays on this machine. Only sensible for a single machine and a repo you do not want to carry documentation history.
- **Gitignore all three** — FDC becomes a private, per-machine layer on top of a repo you do not control. Nothing is enforced for anyone else.
- **Why it matters:** an untracked knowledge layer cannot be the hand-off between sessions on different machines, and an untracked rules file means other contributors and agents never see the contract.
- **Default:** track everything. Required when Q4 is "more than one" or Q3 is "team".
- **Later change:** moving from gitignored to tracked is one commit; the other direction loses history for everyone else.
- **Writes:** `.gitignore` entries in Step 5.

---

## Round 3 — How agents behave

Offer only the options that Round 2 allows.

### Q6. Credentials policy

> Where do credentials for the infrastructure in this repo go?

- **A — real values in the docs.** Each ops folder doc has an `## Access` table with host, user, the actual secret, and a rotation date. An agent can find and use a credential without a vault round-trip. This puts secrets in git: it is only defensible when the repo is private, the infrastructure is reachable only over VPN or a local network, credentials rotate regularly, and one person holds the repo. Every disk that holds the repo should be encrypted.
- **B — vault references only.** The table holds `<vault: item-name>` pointers to a password manager or secrets store. Values never enter git. Any plaintext credential found during bootstrap is replaced by a reference and reported to you. This is the only safe choice for anything shared or public.
- **Why it matters:** this is the single biggest security decision in the setup, and the hard-to-undo one: a secret that has been committed stays in history until it is rotated.
- **Default:** B. For a solo repo with LAN-only infrastructure, A is a legitimate trade.
- **Team repos:** A is refused by the pre-commit check. If the user still wants A, the config must carry `FDC_CREDENTIALS_OVERRIDE="<reason>"`, for example the number of people with access and the disk encryption in use. Ask for that reason, write it verbatim, and say in the report that the repo runs under an override. Do not invent a reason and do not write a free-text "deviation note" anywhere else.
- **Later change:** B to A is a config edit. A to B means rotating every credential ever committed.
- **Writes:** `FDC_CREDENTIALS_POLICY`, and `FDC_CREDENTIALS_OVERRIDE` when applicable; the matching paragraph in `AGENTS.md` rule 8.

### Q7. Commit policy

> Who runs `git commit` during normal work?

- **A — the agent commits verified milestones.** After a coherent, verified piece of work the agent stages only the files it touched, runs the checks, commits with a descriptive message, and pushes when the push is a fast-forward. It never amends, rebases, resets, or forces, and never switches to `main` unasked. Best when several sessions or machines share the repo and you want the hand-off to be in git.
- **B — you commit.** The agent never runs `git commit`. When work is done it shows `git status` and `git diff --stat` and stops. Best when you want to read every diff before it enters history.
- **Why it matters:** decides whether an agent session can leave durable state behind without you at the keyboard.
- **Default:** A for solo work across machines, B when you review every change.
- **Later change:** cheap; swap the paragraph in `AGENTS.md` rule 9 and the config field.
- **Writes:** `FDC_COMMIT_POLICY`; the matching paragraph in `AGENTS.md` rule 9.

---

## Derived, not asked

State these as consequences in your summary instead of asking:

| Answer | Consequence |
|---|---|
| Team | `scripts/check-docs-ci.sh` wired into CI; PR template installed; `fdc/log.md` gitignored. |
| More than one machine | all of `fdc/` tracked in git. |
| Credentials A on a team | `FDC_CREDENTIALS_OVERRIDE` set, reported as an override in the final report. |
| Any policy left unanswered | leave the config field empty; `fdc.sh doctor` keeps warning until it is filled. Never fill a policy with a default. |

# STEP 1 — Create the rules files

## File 1: `AGENTS.md` at repo root

Use the template below. Fill placeholders (`{{ … }}`) with project-specific values. Keep section ordering.

For `{{CREDENTIALS_POLICY}}` and `{{COMMIT_POLICY}}` in "How to work in this repo": paste the **A** or **B** paragraph the user chose in Step 0 (both are in the HTML comment under each placeholder), then delete that comment. Do not leave the placeholder, and do not pick for the user. A team repo on credentials policy A gets the extra override sentence named in that comment and nothing else — no ad-hoc deviation notes.

> If `AGENTS.md` already exists with content, merge: keep existing content, prepend the FDC TOP PRIORITY section and the conventions, slot existing content into the right sections (Overview, Navigation, etc.).

````markdown
# AGENTS.md
<!-- fdc-version: 2026.09.14 — compare with the upstream FDC repo's templates/AGENTS.md; see LLM_UPDATE_PROMPT.md there. -->

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
````markdown

## File 2: `CLAUDE.md` at repo root (thin Claude addendum)

````markdown
# CLAUDE.md

**Claude Code-specific addendum.** The canonical operating rules for this repo live in `AGENTS.md` — read it first. This file only adds Claude Code's slash commands and any Claude-only tooling; everything else is in AGENTS.md and is NOT duplicated here.

> If you are a non-Claude agent reading this by mistake: ignore this file and read `AGENTS.md` instead.

## Read AGENTS.md first

Before doing anything in this repo, read `AGENTS.md`. It contains:

- The **TOP PRIORITY** rule (keep documentation in sync with code AND user intent).
- The **definition of done** checklist.
- **Triggers** (code-side + user-request-side).
- **Naming convention** for folder docs.
- **Creating docs in `/fdc/`**.
- **Navigation**, **build/test/run**, **repo-analysis workflow**, **editing rules**.
- **Doc-drift check** install instructions.

## Claude Code slash commands (this repo)

{{CLAUDE_SLASH_COMMANDS}}

<!-- If `.claude/commands/*.md` exist, list them with one-line descriptions.
If none, write: "No repo-specific slash commands. Use Claude Code's defaults." -->

## Plugins and skills

If the **superpowers** plugin (or any planning/process skill) is installed in this Claude Code, use it — but its plans and specs are written to `fdc/work/` (see `AGENTS.md` → rule 15), not to `docs/superpowers/`. Nothing in this repo depends on the plugin: another machine or another model without it follows the same four habits by hand. Skill instructions never override `AGENTS.md`.

## Claude-specific notes on the TOP PRIORITY rule

Same rule as AGENTS.md, with two Claude-specific reinforcements:

1. **The TodoWrite / task list is not a substitute for doc updates.** Closing a TodoWrite item does not mean the task is done if the relevant `*.md` hasn't been touched — see AGENTS.md "Definition of done".
2. **At end of a non-trivial session**, regenerate the knowledge graph if you maintain one (`/graphify --update` or equivalent), so cross-folder impact answers stay accurate for the next session.
````markdown

## File 3: `readme.md` at repo root (human entry point)

Short, human-facing. Links to AGENTS.md, CLAUDE.md, the top-level folder docs, and `fdc/fdc.md`. Project description in 1-3 sentences. Build/test/run commands. Nothing else — long stuff goes into the folder docs and `/fdc/`.

# STEP 2 — Create the `/fdc/` structure

```
fdc/
├── fdc.md
├── decisions/decisions.md
├── runbooks/runbooks.md
├── runbooks/onboard-developer.md      # shipped runbook: new teammate / new machine
├── troubleshooting/troubleshooting.md
├── briefs/briefs.md
├── notes/notes.md
└── work/work.md                       # ephemeral plans/specs — point planning tools here
```

Use these templates.

If this repo already has long-form docs (under `fdc/`, `docs/`, or a planning tool's output folder such as `docs/superpowers/plans/`), migrate every non-index file now:

- Add required YAML frontmatter (`type`, `title`, `description`, `tags`, `timestamp`).
- Ensure `type` matches the containing folder.
- Add or rename the relationship section to `## See also`.
- Link the doc from at least one relevant folder index doc.
- List the doc in the matching subfolder index (`bash scripts/fdc.sh index` does it).
- Give it a `status`. Ask the user for anything you cannot infer: a troubleshooting note is `resolved` if the fix section is filled and the problem is gone, `open` if it is a known-unresolved finding; a decision is `accepted` unless a later one replaces it (`superseded`); a brief is `done` if shipped.
- **Plans, specs, transcripts, and any "open findings register" are not knowledge.** Move plans/specs to `fdc/work/` with `type: plan` and `status: done` when complete. Split a findings register into one `fdc/troubleshooting/<symptom>.md` per item (`status: open` for unresolved, `resolved` for fixed) — `fdc.sh doctor` becomes the register. Then `bash scripts/fdc.sh archive --dry-run`, show the user the list, and archive on their yes.

Do not treat old files as grandfathered. FDC setup is incomplete until old and
new `/fdc/` long-form docs follow the same rules.

## `fdc/fdc.md`

````markdown
# fdc

**Purpose:** The FDC knowledge layer — long-form knowledge that doesn't belong inside any single folder's index doc: architectural decisions, operational runbooks, troubleshooting playbooks, and requirement briefs.

> Named `fdc/` (not `docs/`) on purpose: it won't collide with an existing `docs/` doc-site, it names exactly what it is, and it stays *visible* (a hidden `.fdc/` would be skipped by `rg`/`find` defaults, breaking the cross-reference checks this convention depends on).

**Tracking:** {{TRACKED_OR_GITIGNORED}}. <!-- "Tracked in git" or "Local-only, gitignored". Pick per repo. -->

## Subfolders

| Folder | Holds | Naming convention |
|---|---|---|
| `decisions/` | ADRs — architectural decisions with rationale and tradeoffs. | `YYYY-MM-DD-<short-title>.md` |
| `runbooks/` | Step-by-step operational procedures. | `<action>-<thing>.md` |
| `troubleshooting/` | Symptom → cause → fix pages for issues that have happened. | `<symptom>.md` |
| `briefs/` | Requirement briefs / scoping docs not yet implemented; also session handoffs (`status: claimed`). | `<topic>.md` |
| `notes/` | Short messages to a person, the team, or yourself on another machine. Delivered by `fdc.sh doctor`, closed when acted on. | `<topic>.md` |
| `work/` | **Ephemeral**: plans, specs, session scratch. Not read by default. Done plans leave a ≤1-ADR outcome and get archived. | `YYYY-MM-DD-<topic>.md` |
| `archive/<type>/` | End-state docs moved by `fdc.sh archive`. Kept for history; **never read, validated, indexed, or audited by default.** | mirrors the source folder |

## When to create a doc here

See `AGENTS.md` → "Creating docs in /fdc/" for the full rule. In short:

- **Decision** — significant architectural / operational choice with tradeoffs.
- **Runbook** — multi-step operational procedure.
- **Troubleshooting** — a problem has been diagnosed; capture it.
- **Brief** — a feature/setup described but not yet built, or work you are handing off (`claimed`, with `## Where I stopped` / `## Next steps`).
- **Note** — something a specific person (or the team, or you-on-another-machine) must read. Not a wiki page; see `notes/notes.md` for the exit rules.

**Rule:** every non-index doc MUST have required YAML frontmatter, a `## See also` section, a link from at least one folder index doc, and an entry in the matching subfolder's index.

## Required frontmatter

Every non-index Markdown file under these subfolders is a typed concept:

```yaml
---
type: decision | runbook | troubleshooting | brief
title: Short human title
description: One sentence describing what this document captures.
tags: [tag-one, tag-two]
timestamp: YYYY-MM-DD
---
```

The `type` must match the containing folder:

- `decisions/` → `type: decision`
- `runbooks/` → `type: runbook`
- `troubleshooting/` → `type: troubleshooting`
- `briefs/` → `type: brief`
- `notes/` → `type: note` (also requires `from`, `to`, `status`)
- `work/` → `type: plan` (requires `status`)
- `archive/**` → exempt; frontmatter is whatever it was when archived

`status` is **required** on decisions (`proposed | accepted | superseded | rejected`) and briefs (`open | done | dropped`); it is what gives `supersedes` / `superseded_by` meaning. Other optional fields when useful: `status`, `owners`, `related`, `resource`, `supersedes`, `superseded_by`, and `verified` (date a runbook/troubleshooting note was last confirmed to work; audited by `scripts/fdc-stale.sh`).

## Lifecycle and compaction

Every doc has a `status`; the status decides whether it is *current knowledge* or *history*:

| Type | Current | End state (archives after `FDC_ARCHIVE_DAYS`) |
|---|---|---|
| decision | `proposed`, `accepted` | `superseded`, `rejected` |
| troubleshooting | `open` (= a finding, surfaced by `doctor`), | `resolved`, `accepted` |
| brief | `open`, `claimed` | `done`, `dropped` |
| note | `open` | `read`, `done` |
| plan (`work/`) | `open` | `done`, `dropped` |
| runbook | (no status, or `active`) | `retired` |

`bash scripts/fdc.sh archive --dry-run` shows what would move; `archive` moves it (`git mv`) into `fdc/archive/<type>/`. `fdc.sh prune --yes` deletes archive entries older than `FDC_PRUNE_DAYS` — git history keeps them. `fdc.sh budget` reports lines per area and docs over budget; `doctor` warns when the active layer exceeds `FDC_BUDGET_TOTAL_LINES`. The goal: a session's default context is a few hundred lines, however old the repo gets.

## Provenance, trust, and freshness (optional, OKF-aligned)

These optional fields follow the [Open Knowledge Format](https://github.com/GoogleCloudPlatform/open-knowledge-format) v0.2 conventions so an `/fdc/` tree can be read by OKF tooling and so an agent can tell *who* stands behind a doc:

```yaml
generated: { by: claude-code/fable-5.1, at: 2026-09-11 }   # who/what wrote the current content
verified:                                                  # who confirmed it against reality (latest wins)
  - { by: claude-code/fable-5.1, at: 2026-09-01 }
  - { by: human:alice, at: 2026-09-11 }
stale_after: 2027-03-01          # absolute date; overrides the global staleness threshold for this doc
sources:                         # what this doc was derived from (ticket, vendor page, commit, another fdc doc)
  - { id: incident-42, resource: https://tracker/…/42, title: Incident 42 }
  - { id: rb, resource: fdc/runbooks/rotate-db-password.md, title: Rotation runbook }
not:                             # what this is NOT — stops the next session re-proposing a rejected approach
  - { term: "restart the pod", why: "masks the leak; recurred within an hour", instead: "raise the memory limit and fix the retry loop" }
```

- **Actors:** `human:<id>` for people, `<agent>/<version>` for LLM agents, `process:<id>` for automation. `scripts/fdc-stale.sh` derives a trust tier from `verified`: no entry → *unverified*; only non-human actors → *machine-confirmed*; any `human:` → *human-reviewed*. A bare date (`verified: 2026-09-11`) is still accepted and counts as machine-confirmed.
- **Per-claim attribution:** cite a source in the body with a footnote keyed to its `id`: `…the export is sharded daily.[^incident-42]`.
- **`timestamp`** may be a date or a full ISO datetime (`2026-09-11T10:00:00Z`); only the date part is validated.
- `sources[].resource` values become edges in `scripts/fdc-graph.sh`; `fdc/log.md` (generated by `scripts/fdc-log.sh`) is the newest-first change history of this folder.

## Relationship links

Each long-form doc ends with `## See also` and normal Markdown links to related folder docs or other `/fdc/` docs. These links are the project knowledge graph.

## Index files

- `decisions/decisions.md` — list of ADRs.
- `runbooks/runbooks.md` — list of runbooks.
- `troubleshooting/troubleshooting.md` — list of troubleshooting pages.
- `briefs/briefs.md` — list of open briefs.
- `notes/notes.md` — list of notes.

The `## Index` section of each is **generated** by `bash scripts/fdc.sh index` from frontmatter — do not hand-edit it (hand-maintained lists are the most conflict-prone file in a team repo).
````markdown

## `fdc/decisions/decisions.md`

````markdown
# decisions

**Purpose:** Architecture Decision Records (ADRs). Each file captures one significant choice: context, options considered, decision, consequences.

**Naming:** `YYYY-MM-DD-<short-kebab-title>.md`.

**Status (required):** `proposed` → `accepted` (or `rejected`); `superseded` when a later ADR replaces it (set `superseded_by`). An agent may write a `proposed` ADR; only a human changes the status after that. In team repos add `owners: [human:<id>]`.

## Template

```markdown
---
type: decision
title: <Decision title>
description: One sentence describing the choice and the problem it resolves.
tags: [architecture]
timestamp: YYYY-MM-DD
status: proposed
# sources: [{ id: <key>, resource: <url|path>, title: <label> }]   # optional provenance; cite in body as [^<key>]
# not: [{ term: <rejected approach>, why: <reason>, instead: <what to do> }]   # optional; stops re-litigation
---

# <Decision title>

## Context
What problem are we solving? What constraints apply?

## Options considered
- **Option A** — pros / cons.
- **Option B** — pros / cons.

<!-- Rejected options belong in `not:` too, so an agent grepping frontmatter sees them without reading the body. -->

## Decision
What was chosen and why.

## Consequences
What changes downstream. What we now have to maintain or watch for.

## See also

- `<folder>/<folder>.md` — affected implementation area.
- `fdc/runbooks/<related>.md` — related procedure, if any.
```

## Index

_No ADRs yet. Add entries below as `YYYY-MM-DD — title — short summary`._
````markdown

## `fdc/runbooks/runbooks.md`

````markdown
# runbooks

**Purpose:** Step-by-step operational procedures that need to be reliable under pressure.

**Naming:** `<action>-<thing>.md` (e.g. `deploy-staging.md`, `rotate-db-password.md`, `recover-failed-migration.md`). Verb first, noun second, kebab-case.

## Template

```markdown
---
type: runbook
title: <Runbook title>
description: One sentence describing the procedure and when to use it.
tags: [operations]
timestamp: YYYY-MM-DD
verified: { by: human:<you>, at: YYYY-MM-DD }   # or a bare date; list form for several checks
owners: [anyone]
---

# <Runbook title>

**When to use:** the trigger condition.
**Owner / on-call:** who runs this. If anyone, say "anyone".
**Estimated time:** ballpark.
**Last verified:** update `verified:` each time you actually run this end to end (`{ by: human:<you>, at: <date> }`). `scripts/fdc-stale.sh` flags it after 180 days, or after `stale_after:` if you set one (e.g. yearly cert rotation → `stale_after` = next rotation).

## Prerequisites
- Access requirements
- Tools / credentials needed

## Steps
1. Step with the exact command.
   ```bash
   <command>
   ```
   Expected output: …
2. Next step.

## Verification
How to confirm success.

## Rollback
If a step fails, how to undo.

## See also

- `<folder>/<folder>.md` — system area this procedure operates on.
- `fdc/troubleshooting/<related>.md` — failure mode this procedure resolves, if any.
```

## Index

_No runbooks yet._
````markdown

## `fdc/troubleshooting/troubleshooting.md`

````markdown
# troubleshooting

**Purpose:** Symptom → cause → fix pages for issues that have actually happened — **and the register of what is still broken.** A note with `status: open` is a *finding*: diagnosed, not fixed (needs a window, another team owns it, out of scope). `fdc.sh doctor` lists open findings at every session start, so nothing is left only in chat.

**Status (required):** `open` (finding, unresolved) → `resolved` (fixed; say what fixed it) or `accepted` (deliberately not fixing; say who decided). Resolved/accepted notes older than `FDC_ARCHIVE_DAYS` are moved by `fdc.sh archive`.

**Naming:** `<symptom>.md` — describe the symptom as a future agent would search for it.

## Template

```markdown
---
type: troubleshooting
title: <Symptom>
description: One sentence describing the observed failure and likely cause.
tags: [troubleshooting]
timestamp: YYYY-MM-DD
status: open                 # open | resolved | accepted
owners: [human:<id>]         # who is on it (open) / who decided (accepted)
verified: { by: human:<you>, at: YYYY-MM-DD }   # or a bare date; list form for several checks
severity: unknown
# not: [{ term: <fix that did NOT work>, why: <what happened>, instead: <the real fix> }]   # optional
---

# <Symptom>

**First seen:** YYYY-MM-DD
**Affected components:** which parts of the system.
**Severity:** how broken things get.

## Symptom
What you observe. Logs, error messages, UI state. Copy actual strings — future grep depends on it.

## Root cause
What was actually wrong.

## Diagnosis
How to confirm this is the cause.

## Fix
Commands in order. (While `status: open`: what you *recommend*, and why it is not done yet.)

## Resolution
<!-- fill when status becomes resolved/accepted: date, what fixed it or who accepted the risk -->

## Prevention
What change would stop this recurring.

## See also

- `<folder>/<folder>.md` — affected implementation area.
- `fdc/runbooks/<related>.md` — procedure used to recover, if any.
```

## Index

_No entries yet._
````markdown

## `fdc/briefs/briefs.md`

````markdown
# briefs

**Purpose:** Requirement briefs / scoping docs the user has described but not yet implemented.

**Naming:** `<topic>.md`. Move into `decisions/` (if a decision was made) or delete when implementation lands.

**Status (required):** `open` while unclaimed; `claimed` when someone (or some session) is working on it — set `owners: [human:<id>]` so two people don't build the same thing; `done` when shipped (then delete or move to `decisions/`); `dropped` if abandoned. Only a human sets `done` / `dropped`.

## Template

```markdown
---
type: brief
title: <Brief title>
description: One sentence describing the requested outcome.
tags: [brief]
timestamp: YYYY-MM-DD
status: open
---

# <Brief title>

## Intent
What does the user want? Their words verbatim where possible.

## Scope
- In scope: …
- Out of scope: …

## Known constraints
Tools, environments, hard limits.

## Open questions
- …

## Where I stopped
<!-- handoff: what is done, what is half-done, what to be careful about -->

## Next steps
1. …

## See also

- `<folder>/<folder>.md` — affected implementation area, if any.
- `fdc/decisions/<related>.md` — decision that resolved this brief, if any.
```

## Index

_No briefs yet._
````markdown

## `fdc/notes/notes.md`

````markdown
# notes

**Purpose:** Short messages addressed to a person, to the team, or to yourself on another machine. A note is a *message with a lifecycle*, not a wiki page: it is delivered by `fdc.sh doctor` at session start, it has an exit (see below), and it is closed.

**Naming:** `<topic>.md`. **Visibility:** notes are in git — the whole team can read a note addressed to one person. Nothing private here.

**Every note has an exit.** When you act on one:

| The note was… | It becomes… | Then |
|---|---|---|
| a warning / gotcha | a line in the relevant `<folder>.md` Gotchas | `status: done` |
| a handoff of unfinished work | a brief in `fdc/briefs/` | `status: done`, link the brief |
| a question | an answer appended under `## Answer` in the same file | `status: done` |
| a discussion starting | an ADR in `fdc/decisions/` | `status: done` |

Notes open longer than `FDC_NOTE_DAYS` (30) are flagged by `fdc.sh stale`. No threads, no replies beyond one answer.

## Template

```markdown
---
type: note
title: <Short subject>
description: One sentence — what the reader should know or do.
tags: [note]
timestamp: YYYY-MM-DD
from: human:<you>            # or <agent>/<version> when an agent leaves it
to: human:<id> | team | me   # `me` = the author, on any machine
status: open                 # open | read | done
---

# <Short subject>

What, why, and what you want the reader to do. Link the folder doc or fdc doc it concerns.

## See also

- `<folder>/<folder>.md`
```

## Index

_No notes yet._
````

## `fdc/work/work.md`

````markdown
# work

**Purpose:** Ephemeral working material — implementation plans, design specs, session transcripts, investigation scratch. Useful *while the work is in flight*, dead weight afterwards. This is the folder that keeps the durable layer small.

**Naming:** `YYYY-MM-DD-<topic>.md` (plans/specs) or `<topic>/` with its own `<topic>.md` for multi-file plans.

## The rule

1. Everything here has `type: plan` and a `status` (`open | done | dropped`).
2. When a plan completes, its **durable outcome** is written into the knowledge layer: at most one ADR in `decisions/`, plus runbook / troubleshooting / folder-doc updates. The plan itself gets `status: done`.
3. `bash scripts/fdc.sh archive` moves done/dropped plans older than `FDC_ARCHIVE_DAYS` into `fdc/archive/work/`. Git keeps the text; the knowledge layer keeps the conclusion.
4. Agents do not read this folder unless the user asks or a brief points at a specific file (see `AGENTS.md` → read budget).

Tools that write plans elsewhere (e.g. `docs/superpowers/plans/`) should be pointed here, or their output moved here at the end of the session.

## Template

```markdown
---
type: plan
title: <Plan title>
description: One sentence — what this plan achieves.
tags: [plan]
timestamp: YYYY-MM-DD
status: open
owners: [human:<id>]
---

# <Plan title>

## Goal

## Steps
1. …

## Outcome (fill when done)
- ADR: `fdc/decisions/<file>.md`
- Runbooks / docs updated: …

## See also

- `fdc/briefs/<brief>.md` — the intent this plan implements, if any.
```

## Index

_No entries yet._
````

## `fdc/runbooks/onboard-developer.md`

Copy as-is; adjust the toolchain line if needed.

````markdown
---
type: runbook
title: Onboard a developer (or a new machine)
description: Clone, activate the FDC hook, read the rules, verify the toolchain — the same steps for a new teammate and for your own second laptop.
tags: [onboarding, fdc]
timestamp: 2026-09-11
owners: [anyone]
---

# Onboard a developer (or a new machine)

**When to use:** first checkout of this repo on any machine.
**Owner / on-call:** anyone.
**Estimated time:** 5 minutes.

## Prerequisites
- git, bash (Git Bash on Windows), and the project toolchain from `AGENTS.md` → Build / Test / Run.
- `git config user.email` set to your real address — `fdc.sh whoami` derives your `human:<id>` from it and every `verified:` / `from:` uses it.

## Steps
1. Clone and enter the repo.
2. Activate the versioned pre-commit hook and check the clone:
   ```bash
   bash scripts/fdc.sh doctor
   ```
   Expected: `hook FIXED set core.hooksPath=.githooks` on the first run, `OK` afterwards; your identity printed; no `WARN` about a newer upstream version (if there is one, run `bash scripts/fdc.sh update`).
3. Read `AGENTS.md` top to bottom once. It is short on purpose. Note the credentials and commit policies in "How to work in this repo".
4. Open the folder docs for the areas you will work in; each `<folder>/<folder>.md` is a two-minute read.
5. Check for anything addressed to you:
   ```bash
   bash scripts/fdc.sh notes
   ```

## Verification
`bash scripts/fdc.sh check` exits 0 on a clean tree, and a deliberate code-only change (touch a source file, `git add`, `git commit`) is blocked by the hook. Undo the test change.

## Rollback
Nothing to roll back; `git config --unset core.hooksPath` deactivates the hook.

## See also

- `AGENTS.md` — the rules this runbook points you at.
- `fdc/fdc.md` — the knowledge layer you will read and write.
````

# STEP 3 — Create per-folder index docs

For every top-level folder in scope (per Step 0 confirmation), create `<folder-name>/<folder-name>.md` using the template below. Don't fabricate facts — for unknown sections, write a placeholder like `_TODO: describe X._`.

For deeper folders that contain non-trivial code or distinct concerns, recursively create indexes. Stop when a folder is purely data (`assets/`, `images/`, generated content) — that folder can share its parent's doc.

## Folder index template

````markdown
# <folder-name>

**Purpose:** _one or two sentences — what this folder is for and who consumes it._

## Subfolders

<!-- omit this section if no subfolders -->

| Folder | Contains | Index doc |
|---|---|---|
| `sub1/` | _purpose_ | `sub1/sub1.md` |

## Key files

<!-- One row per file, append-only, never reorder: several people and sessions edit this file and row-level appends merge cleanly. -->

| File | Purpose |
|---|---|
| `<file>` | _purpose_ |

## Commands

<!-- omit if folder is data-only -->

```bash
<the one or two commands someone would actually run from this folder>
```

## Targets

<!-- ops folders only: omit for pure code -->

| Target | Environment | Reached via |
|---|---|---|
| `<host / cluster / account>` | `<prod / staging>` | `<ssh alias, kubeconfig context, cloud profile>` |

## Access

<!-- ops folders only. Under credentials policy A the Secret column holds the value; under policy B it holds `<vault: item>`. See AGENTS.md → "How to work in this repo" → Credentials. -->

| Service | Host | User | Secret | Rotated on |
|---|---|---|---|---|
| `<service>` | `<canonical host:port>` (alias optional; aliases differ per machine) | `<user>` | `<value or <vault: item>>` | `YYYY-MM-DD` |

## Depends on

<!-- omit if standalone -->

- `<other-folder>/<other-folder>.md` — _what the dependency is._

## Gotchas

- _The non-obvious things. The "easy to get wrong" things._

## See also

<!-- omit if no related docs yet -->

- `fdc/decisions/<file>.md`
- `fdc/runbooks/<file>.md`
- `fdc/troubleshooting/<file>.md`
````markdown

# STEP 4 — Create the tooling

Six scripts, one config file, one versioned hook. **Never edit the scripts** in a downstream repo — they are upstream copies replaced by `fdc.sh update`; all settings go in `scripts/fdc.conf`.

## File: `scripts/fdc.conf` (the only file you configure)

Fill `FDC_UPSTREAM`, `FDC_TEAM`, the two policies, and (team + credentials A only) `FDC_CREDENTIALS_OVERRIDE` from the Step 0 answers. Leave a policy empty if the user did not answer it — `fdc.sh doctor` will keep asking. Add `CODE_REGEX` / `SKIP_*` overrides only if the shipped defaults (top of `check-docs-fresh.sh`) don't fit — see "Project-type-specific guidance".

```bash
# scripts/fdc.conf — per-repo FDC settings. Plain bash, sourced by every
# scripts/*.sh. This is the ONLY file you edit to configure FDC; the scripts
# themselves are verbatim upstream copies and are overwritten by `fdc.sh update`.
#
# fdc-version: 2026.09.14

# Where updates come from and what is installed. `fdc.sh doctor` compares
# FDC_VERSION with the newest tag at FDC_UPSTREAM; `fdc.sh update` pulls it.
FDC_UPSTREAM="https://github.com/bpo50/fdc.git"
FDC_VERSION="2026.09.14"

# Chosen at bootstrap (LLM_PROMPT.md Step 0; the same choices are pasted into
# AGENTS.md → "How to work in this repo"). They ship EMPTY on purpose: an empty
# value means "not decided yet" — `fdc.sh doctor` warns until all three are set.
FDC_TEAM=""                   # solo | team   (team = more than one person commits here ⇒ CI backstop, fdc/log.md gitignored)
FDC_CREDENTIALS_POLICY=""     # A = real values in ## Access tables (private, LAN-only, one user) | B = vault references only
FDC_COMMIT_POLICY=""          # A = agent commits verified milestones | B = user commits, agent stops at git status
# Team + credentials A is refused by the pre-commit check unless you state why
# it is acceptable here (e.g. "two admins, private LAN, encrypted disks").
FDC_CREDENTIALS_OVERRIDE=""

# Audit thresholds.
FDC_STALE_DAYS=180            # runbooks / troubleshooting unverified longer than this are stale
FDC_NOTE_DAYS=30              # open notes older than this are stale
FDC_ARCHIVE_DAYS=90           # end-state docs (resolved, done, superseded, …) older than this → fdc.sh archive
FDC_PRUNE_DAYS=365            # fdc/archive/ entries older than this → fdc.sh prune --yes (git keeps them)
FDC_BUDGET_FOLDER_LINES=150   # fdc.sh budget flags folder docs longer than this
FDC_BUDGET_DOC_LINES=300      # … and fdc/ docs longer than this
FDC_BUDGET_TOTAL_LINES=6000   # doctor warns when the active layer (folder docs + fdc/, excl. work/archive) exceeds this

# Drift-checker classification. Uncomment to override the shipped defaults
# (see the top of scripts/check-docs-fresh.sh for the default values).
# CODE_REGEX='\.(ts|tsx|rs|py|sh|yml|yaml|json|toml|Dockerfile)$'
# CODE_BASENAME_REGEX='^(Dockerfile|Makefile|Justfile)$'
# DOC_REGEX='\.md$'
# SKIP_FILE_REGEX='(^|/)(package-lock\.json|Cargo\.lock)$'
# SKIP_FOLDER_REGEX='(^|/)(\.git/|node_modules/|target/)'
```

## File: `.githooks/pre-commit` (versioned hook)

```bash
#!/usr/bin/env bash
# .githooks/pre-commit — versioned FDC hook. Activated per clone by
# `bash scripts/fdc.sh install-hook` (or `doctor`), which sets
# `git config core.hooksPath .githooks`. Lives in git so a hook change reaches
# every clone on the next pull.
exec "$(git rev-parse --show-toplevel)/scripts/check-docs-fresh.sh"
```

## File: `scripts/fdc.sh` (entry point)

```bash
#!/usr/bin/env bash
# scripts/fdc.sh
# fdc-version: 2026.09.14
#
# Single entry point for the Folder-Doc Convention tooling. Every subcommand
# is a thin wrapper over the sibling scripts; `doctor` is the one an agent
# runs at session start to self-heal a clone.
#
#   fdc.sh doctor          hook installed? version behind upstream? tools? who am I? open notes/briefs?
#   fdc.sh check           run the drift check (what the pre-commit hook runs)
#   fdc.sh install-hook    activate .githooks/ via core.hooksPath (idempotent)
#   fdc.sh update [ref]    pull scripts + .githooks from FDC_UPSTREAM at <ref> (default: newest tag)
#   fdc.sh stale           staleness + trust-tier report
#   fdc.sh log             regenerate fdc/log.md from git
#   fdc.sh graph           build graphify-out/fdc-graph.json
#   fdc.sh index           regenerate the ## Index lists in fdc/*/<type>.md from frontmatter
#   fdc.sh notes           open notes addressed to me or to the team
#   fdc.sh findings        open troubleshooting notes (known, unresolved problems)
#   fdc.sh archive [--dry-run]   move end-state docs older than FDC_ARCHIVE_DAYS into fdc/archive/
#   fdc.sh prune [--dry-run|--yes]  delete fdc/archive/ entries older than FDC_PRUNE_DAYS (git keeps them)
#   fdc.sh budget          lines per area, largest docs, docs over budget — the token-cost report
#   fdc.sh whoami          the actor id used for verified:/from:/to:
#
# Portable: stock macOS bash 3.2 and Linux (Git Bash on Windows).
set -euo pipefail
root=$(git rev-parse --show-toplevel 2>/dev/null || pwd); cd "$root"
S="$root/scripts"
# shellcheck disable=SC1090
[[ -f "$S/fdc.conf" ]] && . "$S/fdc.conf"

usage() { echo "usage: bash scripts/fdc.sh <subcommand>"; echo; sed -n '8,22p' "$0" | sed 's/^# \{0,1\}//'; }

whoami_actor() {
    local e n
    e=$(git config --get user.email 2>/dev/null || true)
    if [[ -n "$e" ]]; then echo "human:${e%%@*}"; return; fi
    n=$(git config --get user.name 2>/dev/null || true)
    if [[ -n "$n" ]]; then echo "human:$(printf '%s' "$n" | tr 'A-Z ' 'a-z-')"; return; fi
    echo "human:${USER:-unknown}"
}

fm_get() { awk -v key="$2" '{ sub(/\r$/,"") } NR==1 { if ($0!="---") exit; next } $0=="---" { exit } index($0, key ":")==1 { v=$0; sub(/^[^:]*:[[:space:]]*["'"'"']?/,"",v); sub(/["'"'"'][[:space:]]*$/,"",v); print v; exit }' "$1"; }

list_notes() {  # open notes to me / team / me-as-author
    local me f to st from
    me=$(whoami_actor)
    [[ -d fdc/notes ]] || return 0
    while IFS= read -r f; do
        [[ "$f" == fdc/notes/notes.md ]] && continue
        st=$(fm_get "$f" status); [[ "$st" == open ]] || continue
        to=$(fm_get "$f" to); from=$(fm_get "$f" from)
        if [[ "$to" == "$me" || "$to" == team || ( "$to" == me && "$from" == "$me" ) ]]; then
            echo "   $f  — $(fm_get "$f" title)  (from $from, $(fm_get "$f" timestamp))"
        fi
    done < <(find fdc/notes -maxdepth 1 -type f -name '*.md' | sort)
}

list_findings() {  # troubleshooting notes with status: open
    local f st
    [[ -d fdc/troubleshooting ]] || return 0
    while IFS= read -r f; do
        [[ "$f" == fdc/troubleshooting/troubleshooting.md ]] && continue
        st=$(fm_get "$f" status); [[ "$st" == open ]] || continue
        echo "   $f  — $(fm_get "$f" title)  (since $(fm_get "$f" timestamp)$( o=$(fm_get "$f" owners); [[ -n "$o" ]] && echo ", owners: $o"))"
    done < <(find fdc/troubleshooting -maxdepth 1 -type f -name '*.md' | sort)
}

# Age of a doc: its frontmatter timestamp ("created or last materially updated"
# per the convention), falling back to the git commit date when there is none.
# Frontmatter first on purpose — a migration or a mass rename touches every
# file in git without changing what the docs say.
doc_age_epoch() {
    local f="$1" t d e=0
    d=$(fm_get "$f" timestamp); d=${d:0:10}
    [[ -n "$d" ]] && e=$(date -j -f '%Y-%m-%d' "$d" +%s 2>/dev/null || date -d "$d" +%s 2>/dev/null || echo 0)
    [[ "$e" -gt 0 ]] && { echo "$e"; return; }
    t=$(git log -1 --format=%ct -- "$f" 2>/dev/null || true)
    echo "${t:-0}"
}

# End-state statuses per subfolder: docs in these states are not current knowledge.
end_state() {
    case "$1/$2" in
        decisions/superseded|decisions/rejected|troubleshooting/resolved|troubleshooting/accepted|briefs/done|briefs/dropped|notes/done|notes/read|work/done|work/dropped|runbooks/retired) return 0 ;;
    esac
    return 1
}

cmd_archive() {
    local dry=0 days="${FDC_ARCHIVE_DAYS:-90}" cutoff sub f st n=0
    [[ "${1:-}" == --dry-run ]] && dry=1
    cutoff=$(( $(date +%s) - days*86400 ))
    for sub in decisions runbooks troubleshooting briefs notes work; do
        [[ -d "fdc/$sub" ]] || continue
        while IFS= read -r f; do
            [[ "$f" == "fdc/$sub/$sub.md" ]] && continue
            st=$(fm_get "$f" status); end_state "$sub" "$st" || continue
            [[ "$(doc_age_epoch "$f")" -lt "$cutoff" ]] || continue
            n=$((n+1))
            if [[ $dry -eq 1 ]]; then echo "   would archive  $f  ($st)"; continue; fi
            mkdir -p "fdc/archive/$sub"
            if git ls-files --error-unmatch "$f" >/dev/null 2>&1; then git mv -k "$f" "fdc/archive/$sub/"; else mv "$f" "fdc/archive/$sub/"; fi
            echo "   archived  $f  → fdc/archive/$sub/  ($st)"
        done < <(find "fdc/$sub" -maxdepth 1 -type f -name '*.md' | sort)
    done
    [[ $dry -eq 1 ]] && echo "[fdc archive] dry run: $n candidate(s) older than ${days}d in an end state. Run without --dry-run to move them." \
                     || { echo "[fdc archive] $n doc(s) moved. fdc/archive/ is never read by default, validated, indexed, or audited. Commit the move; run 'fdc.sh index'."; [[ $n -gt 0 ]] && cmd_index >/dev/null; }
    return 0
}

cmd_prune() {
    local mode="${1:---dry-run}" days="${FDC_PRUNE_DAYS:-365}" cutoff f n=0
    [[ -d fdc/archive ]] || { echo "[fdc prune] no fdc/archive/."; return 0; }
    cutoff=$(( $(date +%s) - days*86400 ))
    while IFS= read -r f; do
        [[ "$(doc_age_epoch "$f")" -lt "$cutoff" ]] || continue
        n=$((n+1))
        if [[ "$mode" == --yes ]]; then
            if git ls-files --error-unmatch "$f" >/dev/null 2>&1; then git rm -q "$f"; else rm -f "$f"; fi
            echo "   deleted  $f"
        else echo "   would delete  $f"; fi
    done < <(find fdc/archive -type f -name '*.md' | sort)
    [[ "$mode" == --yes ]] && echo "[fdc prune] $n file(s) deleted (still in git history). Commit the deletion." \
                           || echo "[fdc prune] dry run: $n archived file(s) older than ${days}d. Run with --yes to delete."
    return 0
}

cmd_budget() {
    local fl="${FDC_BUDGET_FOLDER_LINES:-150}" dl="${FDC_BUDGET_DOC_LINES:-300}" tl="${FDC_BUDGET_TOTAL_LINES:-6000}" total=0 over=0 area n lines
    echo "[fdc budget] lines per area (what a session may load):"
    area_lines() { local sum=0 c=0; while IFS= read -r f; do [[ -z "$f" ]] && continue; n=$(wc -l < "$f" | tr -d ' '); sum=$((sum+n)); c=$((c+1)); done; echo "$sum $c"; }
    read -r lines n < <(git ls-files '*.md' 2>/dev/null | grep -v '^fdc/' | grep -v '^AGENTS.md$\|^CLAUDE.md$\|^readme.md$\|^README.md$' | area_lines)
    printf '   %-22s %6s lines %4s files\n' "folder docs" "$lines" "$n"; total=$((total+lines))
    for area in decisions runbooks troubleshooting briefs notes; do
        [[ -d "fdc/$area" ]] || continue
        read -r lines n < <(find "fdc/$area" -maxdepth 1 -type f -name '*.md' | area_lines)
        printf '   %-22s %6s lines %4s files\n' "fdc/$area" "$lines" "$n"; total=$((total+lines))
    done
    read -r lines n < <(find fdc/work -maxdepth 1 -type f -name '*.md' 2>/dev/null | area_lines)
    printf '   %-22s %6s lines %4s files   (ephemeral — not read by default)\n' "fdc/work" "$lines" "$n"
    read -r lines n < <(find fdc/archive -type f -name '*.md' 2>/dev/null | area_lines)
    printf '   %-22s %6s lines %4s files   (never read by default)\n' "fdc/archive" "$lines" "$n"
    echo "   active layer total      $total lines  (budget FDC_BUDGET_TOTAL_LINES=$tl)$( [[ $total -gt $tl ]] && echo '  ← over budget')"
    echo "[fdc budget] largest active docs:"
    { git ls-files '*.md' 2>/dev/null | grep -v '^fdc/archive/\|^fdc/work/'; } | while IFS= read -r f; do [[ -f "$f" ]] && printf '%6s %s\n' "$(wc -l < "$f" | tr -d ' ')" "$f"; done | sort -rn | head -10 | sed 's/^/   /'
    echo "[fdc budget] over budget (folder docs > $fl, fdc docs > $dl):"
    while IFS= read -r f; do
        [[ -f "$f" ]] || continue
        n=$(wc -l < "$f" | tr -d ' ')
        case "$f" in fdc/archive/*|fdc/work/*) continue ;; fdc/*) [[ $n -gt $dl ]] && { echo "   $f  $n lines  over $dl"; over=$((over+1)); } ;; *) [[ $n -gt $fl ]] && { echo "   $f  $n lines  over $fl"; over=$((over+1)); } ;; esac
    done < <(git ls-files '*.md' 2>/dev/null; git ls-files --others --exclude-standard '*.md' 2>/dev/null)
    [[ $over -eq 0 ]] && echo "   none"
    echo "[fdc budget] archive candidates now: $(cmd_archive --dry-run | grep -c 'would archive' || true)   (fdc.sh archive --dry-run)"
    return 0
}

newest_upstream_tag() {
    [[ -n "${FDC_UPSTREAM:-}" && "$FDC_UPSTREAM" != *"{{"* ]] || return 1
    git ls-remote --tags --refs "$FDC_UPSTREAM" 2>/dev/null | sed 's#.*/tags/##' | grep -E '^[0-9]{4}\.[0-9]{2}\.[0-9]{2}' | sort | tail -1
}

cmd_index() {
    local sub type f title desc st date line tmp
    for sub in decisions runbooks troubleshooting briefs notes work; do
        [[ -f "fdc/$sub/$sub.md" ]] || continue
        tmp=$(mktemp)
        # keep everything up to and including the "## Index" heading
        awk '{ print } /^## Index[[:space:]]*$/ { exit }' "fdc/$sub/$sub.md" > "$tmp"
        grep -q '^## Index' "$tmp" || printf '\n## Index\n' >> "$tmp"
        echo >> "$tmp"
        local n=0
        while IFS= read -r f; do
            [[ "$f" == "fdc/$sub/$sub.md" ]] && continue
            title=$(fm_get "$f" title); [[ -z "$title" ]] && title=$(basename "$f" .md)
            desc=$(fm_get "$f" description); st=$(fm_get "$f" status); date=$(fm_get "$f" timestamp)
            line="- [$title]($(basename "$f"))"
            [[ "$sub" == decisions && -n "$date" ]] && line="- ${date:0:10} — [$title]($(basename "$f"))"
            [[ -n "$desc" ]] && line="$line — $desc"
            [[ -n "$st" ]] && line="$line (\`$st\`)"
            echo "$line" >> "$tmp"; n=$((n+1))
        done < <(find "fdc/$sub" -maxdepth 1 -type f -name '*.md' | sort)
        [[ $n -eq 0 ]] && echo "_No entries yet._" >> "$tmp"
        mv "$tmp" "fdc/$sub/$sub.md"
        echo "[fdc index] fdc/$sub/$sub.md — $n entries"
    done
}

cmd_update() {
    local ref="${1:-}" tmp
    [[ -n "${FDC_UPSTREAM:-}" && "$FDC_UPSTREAM" != *"{{"* ]] || { echo "[fdc update] FDC_UPSTREAM is not set in scripts/fdc.conf"; exit 1; }
    [[ -z "$ref" ]] && ref=$(newest_upstream_tag || true)
    [[ -n "$ref" ]] || { echo "[fdc update] no version tags found at $FDC_UPSTREAM"; exit 1; }
    tmp=$(mktemp -d)
    echo "[fdc update] fetching $FDC_UPSTREAM @ $ref"
    git -c advice.detachedHead=false clone -q --depth 1 --branch "$ref" "$FDC_UPSTREAM" "$tmp/up" || { echo "[fdc update] clone failed"; rm -rf "$tmp"; exit 1; }
    [[ -d "$tmp/up/templates/scripts" ]] || { echo "[fdc update] upstream has no templates/scripts — wrong URL?"; rm -rf "$tmp"; exit 1; }
    mkdir -p scripts .githooks
    cp "$tmp/up"/templates/scripts/*.sh scripts/
    [[ -f "$tmp/up/templates/.githooks/pre-commit" ]] && cp "$tmp/up/templates/.githooks/pre-commit" .githooks/
    chmod +x scripts/*.sh .githooks/pre-commit 2>/dev/null || true
    if [[ -f scripts/fdc.conf ]]; then
        sed "s#^FDC_VERSION=.*#FDC_VERSION=\"$ref\"#" scripts/fdc.conf > scripts/fdc.conf.tmp && mv scripts/fdc.conf.tmp scripts/fdc.conf
    else
        cp "$tmp/up/templates/scripts/fdc.conf" scripts/fdc.conf
        sed "s#^FDC_VERSION=.*#FDC_VERSION=\"$ref\"#; s#^FDC_UPSTREAM=.*#FDC_UPSTREAM=\"$FDC_UPSTREAM\"#" scripts/fdc.conf > scripts/fdc.conf.tmp && mv scripts/fdc.conf.tmp scripts/fdc.conf
    fi
    rm -rf "$tmp"
    bash scripts/install-hook.sh >/dev/null 2>&1 || true
    echo "[fdc update] scripts/ and .githooks/ now at $ref (fdc.conf kept; FDC_VERSION set). Review with: git diff --stat"
    echo "[fdc update] Docs/templates (AGENTS.md rules, fdc/ index templates) are NOT touched — run LLM_UPDATE_PROMPT.md from upstream for those."
}

cmd_doctor() {
    local fixed=0 warn=0 me t hp latest
    me=$(whoami_actor)
    echo "[fdc doctor] repo: $root"
    echo "   identity   $me   (used for verified:/from:/to:; from git config user.email)"
    echo "   version    ${FDC_VERSION:-unknown}   team=${FDC_TEAM:-?} credentials=${FDC_CREDENTIALS_POLICY:-?} commits=${FDC_COMMIT_POLICY:-?}"
    # hook
    hp=$(git config --get core.hooksPath || true)
    if [[ -f .githooks/pre-commit ]]; then
        if [[ "$hp" == ".githooks" ]]; then echo "   hook       OK  core.hooksPath=.githooks"
        elif [[ -z "$hp" ]]; then git config core.hooksPath .githooks; chmod +x .githooks/pre-commit 2>/dev/null || true; echo "   hook       FIXED  set core.hooksPath=.githooks"; fixed=$((fixed+1))
        else echo "   hook       WARN  core.hooksPath=$hp (another manager) — add scripts/check-docs-fresh.sh to its pre-commit stage"; warn=$((warn+1)); fi
    else
        local h; h="$(git rev-parse --git-path hooks)/pre-commit"
        if [[ -x "$h" ]] && grep -q check-docs-fresh "$h"; then echo "   hook       OK  $h"
        else bash "$S/install-hook.sh" >/dev/null 2>&1 && { echo "   hook       FIXED  installed $h"; fixed=$((fixed+1)); } || { echo "   hook       WARN  could not install (run: bash scripts/install-hook.sh)"; warn=$((warn+1)); }; fi
    fi
    # version vs upstream
    if [[ -z "${FDC_UPSTREAM:-}" || "$FDC_UPSTREAM" == *"{{"* ]]; then echo "   upstream   WARN  FDC_UPSTREAM not set in scripts/fdc.conf — updates disabled"; warn=$((warn+1))
    else
        latest=$(newest_upstream_tag || true)
        if [[ -z "$latest" ]]; then echo "   upstream   --  unreachable or no tags (offline?) — skipped"
        elif [[ "$latest" != "${FDC_VERSION:-}" && "$latest" > "${FDC_VERSION:-}" ]]; then echo "   upstream   WARN  newer version $latest available (installed ${FDC_VERSION:-?}) — run: bash scripts/fdc.sh update"; warn=$((warn+1))
        else echo "   upstream   OK  $latest"; fi
    fi
    # docs layer (AGENTS.md rules text) vs tooling version
    if [[ -f AGENTS.md ]]; then
        local ds; ds=$(sed -n 's/.*fdc-versio[n]: *\([0-9][0-9.]*\).*/\1/p' AGENTS.md | head -1)
        if [[ -z "$ds" ]]; then echo "   docs       WARN  AGENTS.md has no fdc-version stamp — run LLM_UPDATE_PROMPT.md from upstream"; warn=$((warn+1))
        elif [[ "$ds" != "${FDC_VERSION:-}" ]]; then echo "   docs       WARN  AGENTS.md rules text is $ds, tooling is ${FDC_VERSION:-?} — run LLM_UPDATE_PROMPT.md from upstream to merge the newer templates"; warn=$((warn+1))
        else echo "   docs       OK  AGENTS.md rules text $ds matches tooling"; fi
    else echo "   docs       WARN  no AGENTS.md — bootstrap (LLM_PROMPT.md) not run yet"; warn=$((warn+1)); fi
    # tools
    local missing=""; for t in rg fd jq yq; do command -v "$t" >/dev/null 2>&1 || missing="$missing $t"; done
    [[ -z "$missing" ]] && echo "   tools      OK  rg fd jq yq" || echo "   tools      --  missing:$missing (fall back to grep/find; see AGENTS.md)"
    # team safety
    if [[ -z "${FDC_TEAM:-}" || -z "${FDC_CREDENTIALS_POLICY:-}" || -z "${FDC_COMMIT_POLICY:-}" ]]; then echo "   policy     WARN  FDC_TEAM / FDC_CREDENTIALS_POLICY / FDC_COMMIT_POLICY not set in scripts/fdc.conf — bootstrap (LLM_PROMPT.md Step 0) not finished"; warn=$((warn+1))
    elif [[ "$FDC_TEAM" == team && "$FDC_CREDENTIALS_POLICY" == A ]]; then
        if [[ -n "${FDC_CREDENTIALS_OVERRIDE:-}" ]]; then echo "   policy     WARN  team repo with credentials policy A, override: $FDC_CREDENTIALS_OVERRIDE"; warn=$((warn+1))
        else echo "   policy     ERROR team repo with credentials policy A and no FDC_CREDENTIALS_OVERRIDE — commits are blocked until you set it or switch to B"; warn=$((warn+1)); fi
    fi
    # log: regenerate if gitignored (team mode) so it is fresh locally
    if [[ -d fdc ]] && git check-ignore -q fdc/log.md 2>/dev/null; then bash "$S/fdc-log.sh" >/dev/null 2>&1 && echo "   log        OK  fdc/log.md regenerated (gitignored)"; fi
    # notes + briefs
    local notes; notes=$(list_notes)
    if [[ -n "$notes" ]]; then echo "   notes      open notes for you:"; printf '%s\n' "$notes"; else echo "   notes      none open for $me"; fi
    local fnd; fnd=$(list_findings)
    if [[ -n "$fnd" ]]; then echo "   findings   open (known, unresolved — read before diagnosing):"; printf '%s\n' "$fnd"; fi
    if [[ -d fdc/briefs ]]; then
        local b; b=$(for f in fdc/briefs/*.md; do [[ "$f" == fdc/briefs/briefs.md || ! -f "$f" ]] && continue; st=$(fm_get "$f" status); [[ "$st" == open || "$st" == claimed ]] && echo "   $f  ($st$( [[ "$st" == claimed ]] && echo ", owners: $(fm_get "$f" owners)"))  — $(fm_get "$f" title)"; done)
        [[ -n "$b" ]] && { echo "   briefs     open/claimed:"; printf '%s\n' "$b"; }
    fi
    if [[ -d fdc ]]; then
        local tl="${FDC_BUDGET_TOTAL_LINES:-6000}" act; act=$(cmd_budget | awk '/active layer total/ { print $4 }')
        [[ -n "$act" && "$act" -gt "$tl" ]] && { echo "   budget     WARN  active knowledge layer is $act lines (budget $tl) — run: bash scripts/fdc.sh budget / archive --dry-run"; warn=$((warn+1)); }
    fi
    echo "[fdc doctor] $fixed fixed, $warn warnings."
    return 0
}

case "${1:-}" in
    doctor)       cmd_doctor ;;
    check)        exec bash "$S/check-docs-fresh.sh" ;;
    install-hook) exec bash "$S/install-hook.sh" ;;
    update)       shift; cmd_update "$@" ;;
    stale)        exec bash "$S/fdc-stale.sh" ;;
    log)          exec bash "$S/fdc-log.sh" ;;
    graph)        exec bash "$S/fdc-graph.sh" ;;
    index)        cmd_index ;;
    notes)        list_notes ;;
    findings)     list_findings ;;
    archive)      shift; cmd_archive "$@" ;;
    prune)        shift; cmd_prune "$@" ;;
    budget)       cmd_budget ;;
    whoami)       whoami_actor ;;
    -h|--help|help|"") usage; [[ -n "${1:-}" ]] ;;
    *)            echo "fdc.sh: unknown subcommand '$1'"; echo; usage; exit 2 ;;
esac
```

## File: `scripts/check-docs-fresh.sh`

Use the template below. Adjust `CODE_REGEX` to match the project's language extensions (see "Project-type-specific guidance" further down).

```bash
#!/usr/bin/env bash
# scripts/check-docs-fresh.sh
# fdc-version: 2026.09.14
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
```bash

## File: `scripts/install-hook.sh`

Worktree- and submodule-safe installer (don't use a raw `ln -sf` symlink — it
breaks when `.git` is a file rather than a directory, and ignores `core.hooksPath`).

```bash
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
```bash

Then activate:

```bash
chmod +x scripts/*.sh .githooks/pre-commit
bash scripts/fdc.sh install-hook      # sets core.hooksPath=.githooks for this clone
```

## File: `scripts/check-docs-ci.sh` (CI backstop — provider-neutral, recommended for teams)

The pre-commit hook is bypassable (`SKIP_DOC_CHECK=1` or `git commit --no-verify`).
On a shared repo, run this in CI to re-check the whole change at merge time, so a
local bypass is caught in review. It is **not** tied to any provider — it resolves
the base branch from common CI env vars (or `FDC_CI_BASE` / an argument) and works
in GitLab CI, Gitea/Forgejo, Woodpecker, Drone, Jenkins, Buildkite, Bitbucket, a
server-side hook, or a cron box. Skip it for solo repos.

```bash
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
```bash

Wire it into whatever CI the repo uses — the job is one line. Generic examples
(adapt to your system; do **not** assume GitHub):

```yaml
# GitLab CI (.gitlab-ci.yml)
check-docs-fresh:
  stage: test
  script: [ "bash scripts/check-docs-ci.sh" ]
```

```bash
# Any runner / server hook / cron — just call it; non-zero exit fails the job:
bash scripts/check-docs-ci.sh
```

## File: `scripts/fdc-graph.sh` (optional — knowledge graph from `/fdc/` metadata)

The typed frontmatter + `## See also` links in every `/fdc/` doc *are* a relationship
graph. This script extracts them into a dependency-free `graphify-out/fdc-graph.json`
that any graph tool can ingest. It is **optional and never part of the hook** — a
teammate with no graph tooling can ignore it; FDC works without it. If `FDC_GRAPH_CMD`
is set, the script hands the JSON to that command (wire your own tool, e.g. graphify);
teammates who don't set it just get the JSON. Portable (stock macOS bash 3.2 + Linux).

```bash
#!/usr/bin/env bash
# scripts/fdc-graph.sh
# fdc-version: 2026.09.14
#
# Build a portable knowledge graph from the /fdc/ layer. The graph is the thing
# FDC already mandates: every long-form concept doc has typed frontmatter
# (type/title/tags) and a `## See also` section of links — those links ARE the
# relationship graph. This script extracts them into a dependency-free JSON that
# any graph tool can ingest.
#
# IMPORTANT — this is OPTIONAL and is NOT part of the pre-commit hook. It never
# blocks a commit. A teammate who has no graph tooling installed can ignore it
# entirely; FDC still works without it. Run it when you want a fresh graph.
#
# Portability: stock macOS /bin/bash (3.2) and Linux bash; BSD or GNU awk/sed.
# Output goes to graphify-out/ (gitignored by convention), so it is never shared
# state and never trips the drift checker.
#
# Optional richer rendering: if you set FDC_GRAPH_CMD, this runs it with the JSON
# path appended — wire your own tool there (e.g. graphify). Teammates who do not
# set it just get the JSON. Example:
#     FDC_GRAPH_CMD="graphify --input" bash scripts/fdc-graph.sh

set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
# --- per-repo settings (scripts/fdc.conf overrides the defaults above) -------
fdc_root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
# shellcheck disable=SC1090
[[ -f "$fdc_root/scripts/fdc.conf" ]] && . "$fdc_root/scripts/fdc.conf"

out_dir="${FDC_GRAPH_OUT:-graphify-out}"
json="$out_dir/fdc-graph.json"

if [[ ! -d fdc ]]; then
    echo "[fdc-graph] no fdc/ directory — nothing to graph."
    exit 0
fi
mkdir -p "$out_dir"

# Minimal JSON string escaping (backslash + double quote).
esc() { printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'; }

# A flat, non-index fdc concept doc? (mirrors check-docs-fresh.sh)
is_concept() {
    local f="$1" rest
    case "$f" in
        fdc/decisions/*)       rest=${f#fdc/decisions/} ;;
        fdc/runbooks/*)        rest=${f#fdc/runbooks/} ;;
        fdc/troubleshooting/*) rest=${f#fdc/troubleshooting/} ;;
        fdc/briefs/*)          rest=${f#fdc/briefs/} ;;
        *) return 1 ;;
    esac
    case "$rest" in */*) return 1 ;; *.md) ;; *) return 1 ;; esac
    case "$rest" in decisions.md|runbooks.md|troubleshooting.md|briefs.md|notes.md|work.md) return 1 ;; esac
    return 0
}

# Echo a scalar frontmatter field's value.
fm_field() {
    awk -v key="$2" '
        { sub(/\r$/, "") }
        NR == 1 { if ($0 != "---") exit; next }
        $0 == "---" { exit }
        index($0, key ":") == 1 { v = $0; sub(/^[^:]*:[[:space:]]*/, "", v); print v; exit }
    ' "$1"
}

# Echo each item of an inline (`key: [a, b]`) or block (`key:` then `- a`) list.
list_values() {
    awk -v key="$2" '
        { sub(/\r$/, "") }
        NR == 1 { if ($0 != "---") exit; next }
        $0 == "---" { exit }
        inblk && /^[[:space:]]*-[[:space:]]*/ {
            v = $0; sub(/^[[:space:]]*-[[:space:]]*/, "", v)
            if (v != "") print v; next
        }
        inblk && /^[^[:space:]]/ { inblk = 0 }
        index($0, key ":") == 1 {
            rest = $0; sub(/^[^:]*:[[:space:]]*/, "", rest)
            if (rest ~ /^\[/) {
                gsub(/^\[|\]$/, "", rest)
                n = split(rest, a, ",")
                for (i = 1; i <= n; i++) {
                    gsub(/^[[:space:]]+|[[:space:]]+$/, "", a[i])
                    if (a[i] != "") print a[i]
                }
            } else if (rest == "") { inblk = 1 }
            next
        }
    ' "$1"
}

# Echo each link target in the `## See also` section: markdown `(target)` and
# backticked `path` tokens that look like paths.
see_also_targets() {
    awk '
        { sub(/\r$/, "") }
        tolower($0) ~ /^##[[:space:]]+see also/ { insec = 1; next }
        insec && /^##[[:space:]]/ { insec = 0 }
        insec {
            s = $0
            while (match(s, /\([^)]+\)/)) { print substr(s, RSTART + 1, RLENGTH - 2); s = substr(s, RSTART + RLENGTH) }
            s = $0
            while (match(s, /`[^`]+`/)) {
                t = substr(s, RSTART + 1, RLENGTH - 2)
                if (t ~ /\// || t ~ /\.md$/) print t
                s = substr(s, RSTART + RLENGTH)
            }
        }
    ' "$1"
}

# resource: values inside a `sources:` block — inline `- { id: x, resource: y }`
# entries or nested `resource:` lines. Bundle paths and URLs alike become edges.
sources_resources() {
    awk '
        { sub(/\r$/, "") }
        NR==1 { if ($0!="---") exit; next }
        $0=="---" { exit }
        /^sources:/ { inblk=1; next }
        inblk && /^[^[:space:]]/ { inblk=0 }
        inblk && match($0, /resource:[[:space:]]*["'"'"']?[^,}"'"'"' ]+/) { v=substr($0,RSTART,RLENGTH); sub(/^resource:[[:space:]]*["'"'"']?/,"",v); print v }
    ' "$1"
}
emit_joined() {  # comma+newline-join the lines of a file (valid JSON array body)
    awk 'NR > 1 { printf ",\n" } { printf "%s", $0 } END { if (NR) printf "\n" }' "$1"
}

nodes_tmp="$out_dir/.nodes.tmp"; edges_tmp="$out_dir/.edges.tmp"
: > "$nodes_tmp"; : > "$edges_tmp"

find fdc -type f -name '*.md' | sort | while IFS= read -r f; do
    is_concept "$f" || continue

    ftype=$(fm_field "$f" type)
    title=$(fm_field "$f" title); [ -z "$title" ] && title="$f"

    tags_json=""
    while IFS= read -r t; do
        [ -z "$t" ] && continue
        tags_json="${tags_json}\"$(esc "$t")\","
    done < <(list_values "$f" tags)
    tags_json="[${tags_json%,}]"

    printf '    {"id":"%s","type":"%s","title":"%s","tags":%s}\n' \
        "$(esc "$f")" "$(esc "$ftype")" "$(esc "$title")" "$tags_json" >> "$nodes_tmp"

    { see_also_targets "$f"; list_values "$f" related; list_values "$f" supersedes; list_values "$f" superseded_by; sources_resources "$f"; } \
    | while IFS= read -r tgt; do
        [ -z "$tgt" ] && continue
        printf '    {"from":"%s","to":"%s"}\n' "$(esc "$f")" "$(esc "$tgt")" >> "$edges_tmp"
    done
done

sort -u "$edges_tmp" -o "$edges_tmp"   # dedup edges (a See-also link + a related: entry can repeat)

node_count=$(grep -c '"id"' "$nodes_tmp" 2>/dev/null || echo 0)
edge_count=$(grep -c '"from"' "$edges_tmp" 2>/dev/null || echo 0)

{
    printf '{\n  "nodes": [\n'
    emit_joined "$nodes_tmp"
    printf '  ],\n  "edges": [\n'
    emit_joined "$edges_tmp"
    printf '  ]\n}\n'
} > "$json"

rm -f "$nodes_tmp" "$edges_tmp"

echo "[fdc-graph] wrote $json — $node_count concept nodes, $edge_count edges."

if [[ -n "${FDC_GRAPH_CMD:-}" ]]; then
    echo "[fdc-graph] FDC_GRAPH_CMD set — handing the graph to your tool..."
    # Intentionally unquoted so FDC_GRAPH_CMD can carry args.
    # shellcheck disable=SC2086
    ${FDC_GRAPH_CMD} "$json"
else
    echo "[fdc-graph] (set FDC_GRAPH_CMD to post-process the JSON with your own graph tool, e.g. graphify.)"
fi
```bash

Add `graphify-out/` to `.gitignore` (it's generated, per-user output — not shared).

## File: `scripts/fdc-stale.sh` (optional — staleness audit for runbooks and troubleshooting)

The drift checker proves a doc was *touched*; it cannot tell whether a runbook still works. This lists runbooks and troubleshooting notes whose `verified:` date (or `timestamp:` if absent) is older than `FDC_STALE_DAYS` (default 180). It never fails the build. Run it in CI for the report, or before an on-call rotation.

```bash
#!/usr/bin/env bash
# scripts/fdc-stale.sh
# fdc-version: 2026.09.14
#
# OPTIONAL staleness + trust audit for operational docs. The drift checker
# proves a doc was TOUCHED alongside code; it cannot tell whether a runbook
# still works or who last confirmed it. This reports, for every runbook and
# troubleshooting note:
#
#   - trust tier (OKF convention): unverified | machine-confirmed | human-reviewed
#     derived from `verified:` actors — `human:<id>` ⇒ human-reviewed,
#     anything else (`<agent>/<version>`, `process:<id>`) ⇒ machine-confirmed.
#   - staleness: `stale_after: YYYY-MM-DD` if present (absolute; stale when
#     today >= it), else latest `verified` date (else `timestamp`) older than
#     FDC_STALE_DAYS (default 180).
#
# `verified` accepts three forms:
#     verified: 2026-09-11
#     verified: { by: human:alice, at: 2026-09-11 }
#     verified:
#       - { by: claude-code/fable-5.1, at: 2026-09-01 }
#       - { by: human:alice, at: 2026-09-11 }
#
# It NEVER fails the build: exit code is always 0. Run it in CI for the report,
# or by hand before an on-call rotation. Decisions and briefs are not audited.
#
# Usage:   bash scripts/fdc-stale.sh
#          FDC_STALE_DAYS=90 bash scripts/fdc-stale.sh
#
# Portable: stock macOS /bin/bash 3.2 and Linux; BSD or GNU date.
set -euo pipefail
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
# --- per-repo settings (scripts/fdc.conf overrides the defaults above) -------
fdc_root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
# shellcheck disable=SC1090
[[ -f "$fdc_root/scripts/fdc.conf" ]] && . "$fdc_root/scripts/fdc.conf"
days="${FDC_STALE_DAYS:-180}"; note_days="${FDC_NOTE_DAYS:-30}"
[[ -d fdc ]] || { echo "[fdc-stale] no fdc/ — nothing to audit."; exit 0; }

to_epoch() { date -j -f '%Y-%m-%d' "$1" +%s 2>/dev/null || date -d "$1" +%s 2>/dev/null || echo 0; }
frontmatter() { awk '{ sub(/\r$/, "") } NR==1 { if ($0!="---") exit; next } $0=="---" { exit } { print }' "$1"; }
fm_date() {  # fm_date <file> <key>  → first 10 chars of the scalar, or empty
    frontmatter "$1" | awk -v key="$2" '
        index($0, key ":")==1 { v=$0; sub(/^[^:]*:[[:space:]]*["'"'"']?/,"",v); if (v ~ /^[0-9]/) print substr(v,1,10); exit }'
}
# Emit one "AT<TAB>BY" line per verified entry (any of the three forms).
verified_entries() {
    frontmatter "$1" | awk '
        function emit(s,   a, b) {
            a = ""; b = ""
            if (match(s, /at:[[:space:]]*["'"'"']?[0-9]{4}-[0-9]{2}-[0-9]{2}/)) { a = substr(s, RSTART, RLENGTH); sub(/^at:[[:space:]]*["'"'"']?/, "", a) }
            if (match(s, /by:[[:space:]]*["'"'"']?[^,}"'"'"']+/))              { b = substr(s, RSTART, RLENGTH); sub(/^by:[[:space:]]*["'"'"']?/, "", b); sub(/[[:space:]]+$/, "", b) }
            print a "\t" b
        }
        /^verified:/ {
            rest = $0; sub(/^verified:[[:space:]]*/, "", rest)
            if (rest ~ /^\{/)            { emit(rest); next }
            if (rest ~ /^["'"'"']?[0-9]{4}-/) { v = rest; gsub(/["'"'"']/, "", v); print substr(v,1,10) "\t"; next }
            inblk = 1; next
        }
        inblk && /^[[:space:]]*-[[:space:]]*\{/ { emit($0); next }
        inblk && /^[^[:space:]]/ { inblk = 0 }
    '
}

now=$(date +%s); today=$(date +%F); cutoff=$(( now - days*86400 ))
stale=0; total=0; t_h=0; t_m=0; t_u=0
while IFS= read -r f; do
    case "$f" in
        fdc/runbooks/runbooks.md|fdc/troubleshooting/troubleshooting.md) continue ;;
        fdc/runbooks/*/*|fdc/troubleshooting/*/*) continue ;;
    esac
    total=$((total+1))

    # --- trust tier + latest verification ---
    tier=unverified; latest=""; latest_e=0
    while IFS=$'\t' read -r at by; do
        [[ -z "$at" && -z "$by" ]] && continue
        if [[ "$by" == human:* ]]; then tier=human-reviewed
        elif [[ "$tier" != human-reviewed ]]; then tier=machine-confirmed; fi
        if [[ -n "$at" ]]; then e=$(to_epoch "$at"); if [[ "$e" -gt "$latest_e" ]]; then latest_e=$e; latest=$at; fi; fi
    done < <(verified_entries "$f")
    case "$tier" in human-reviewed) t_h=$((t_h+1));; machine-confirmed) t_m=$((t_m+1));; *) t_u=$((t_u+1));; esac

    # --- staleness ---
    sa=$(fm_date "$f" stale_after)
    if [[ -n "$sa" ]]; then
        sae=$(to_epoch "$sa")
        if [[ "$sae" -eq 0 ]]; then echo "STALE  $f  (unparseable stale_after: $sa)"; stale=$((stale+1))
        elif [[ "$now" -ge "$sae" ]]; then echo "STALE  $f  (stale_after $sa has passed; $tier)"; stale=$((stale+1))
        else echo "ok     $f  ($tier; stale_after $sa)"; fi
        continue
    fi
    src=verified; d="$latest"
    [[ -z "$d" ]] && { d=$(fm_date "$f" timestamp); src=timestamp; }
    if [[ -z "$d" ]]; then echo "STALE  $f  (no verified/timestamp date; $tier)"; stale=$((stale+1)); continue; fi
    e=$(to_epoch "$d")
    if [[ "$e" -eq 0 ]]; then echo "STALE  $f  (unparseable $src: $d; $tier)"; stale=$((stale+1))
    elif [[ "$e" -lt "$cutoff" ]]; then echo "STALE  $f  ($src: $d, older than ${days}d; $tier)"; stale=$((stale+1))
    else echo "ok     $f  ($tier; $src $d)"; fi
done < <(find fdc/runbooks fdc/troubleshooting -type f -name '*.md' 2>/dev/null | sort)

# --- notes: open longer than FDC_NOTE_DAYS ---
n_open=0; n_stale=0; note_cut=$(( now - note_days*86400 ))
while IFS= read -r f; do
    [[ "$f" == fdc/notes/notes.md ]] && continue
    st=$(frontmatter "$f" | awk '/^status:/ { v=$0; sub(/^status:[[:space:]]*/,"",v); print v; exit }')
    [[ "$st" == open ]] || continue
    n_open=$((n_open+1)); d=$(fm_date "$f" timestamp); e=$(to_epoch "${d:-1970-01-01}")
    if [[ "$e" -lt "$note_cut" ]]; then echo "STALE  $f  (note open since $d, longer than ${note_days}d — act on it or close it)"; n_stale=$((n_stale+1)); fi
done < <(find fdc/notes -maxdepth 1 -type f -name '*.md' 2>/dev/null | sort)
[[ $n_open -gt 0 ]] && echo "[fdc-stale] notes: $n_open open, $n_stale stale (threshold ${note_days}d)."

echo "[fdc-stale] $total audited, $stale stale (threshold ${days}d) — human-reviewed: $t_h, machine-confirmed: $t_m, unverified: $t_u."
echo "[fdc-stale] After re-running a procedure, record it:  verified: { by: human:<you>, at: $today }"
exit 0
```bash

## File: `scripts/fdc-log.sh` (optional — regenerate `fdc/log.md` from git)

Newest-first, date-grouped history of every commit that touched `/fdc/`, so an agent reading the knowledge layer sees what changed recently without running git. Generated, never hand-edited, never part of the hook.

```bash
#!/usr/bin/env bash
# scripts/fdc-log.sh
# fdc-version: 2026.09.14
#
# OPTIONAL. Regenerates fdc/log.md — a newest-first, date-grouped history of
# every commit that touched the /fdc/ knowledge layer (OKF "log.md" idea).
# Git already has this history; the point is that an agent reading fdc/ sees
# "what changed recently" without running git. It is generated, never
# hand-edited, and never part of the pre-commit hook. Commit the result if you
# want it shared (a doc-only change, so the drift checker is happy).
#
# Usage:   bash scripts/fdc-log.sh            # writes fdc/log.md
#          FDC_LOG_MAX=200 bash scripts/fdc-log.sh
#
# Portable: stock macOS /bin/bash 3.2 and Linux.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
# --- per-repo settings (scripts/fdc.conf overrides the defaults above) -------
fdc_root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
# shellcheck disable=SC1090
[[ -f "$fdc_root/scripts/fdc.conf" ]] && . "$fdc_root/scripts/fdc.conf"
[[ -d fdc ]] || { echo "[fdc-log] no fdc/ — nothing to log."; exit 0; }
git rev-parse --verify -q HEAD >/dev/null 2>&1 || { echo "[fdc-log] no commits yet."; exit 0; }
max="${FDC_LOG_MAX:-500}"
out=fdc/log.md

{
    echo "# fdc update log"
    echo
    echo "<!-- Generated by scripts/fdc-log.sh from git history. Do not edit; re-run the script. -->"
    echo
    git log -n "$max" --date=short --format='%x01%ad%x09%h%x09%s' --name-only -- fdc/ \
    | awk -F'\t' '
        function flush() {
            if (subj == "" || files == "") { subj = ""; files = ""; return }
            if (date != last) { if (last != "") print ""; print "## " date; print ""; last = date }
            print "* **" subj "** (`" hash "`): " files
            subj = ""; files = ""
        }
        substr($0, 1, 1) == "\001" { flush(); h = substr($0, 2); n = split(h, p, "\t"); date = p[1]; hash = p[2]; subj = p[3]; for (i = 4; i <= n; i++) subj = subj "\t" p[i]; next }
        /^$/ { next }
        { if ($0 != "fdc/log.md") files = files (files == "" ? "" : ", ") "`" $0 "`" }
        END { flush() }
    '
} > "$out.tmp"
mv "$out.tmp" "$out"
echo "[fdc-log] wrote $out ($(grep -c '^\* ' "$out" | tr -d ' ') entries)."
```

And create `scripts/scripts.md`:

```markdown
# scripts

**Purpose:** Utility scripts, including the doc-drift check that enforces the TOP PRIORITY rule from `AGENTS.md`.

## Files

| Script | Purpose |
|---|---|
| `check-docs-fresh.sh` | Doc-drift + fdc-metadata check. Fails if code changes without updating the doc that owns it, or if a changed `/fdc/` doc lacks required frontmatter / `## See also`. |
| `install-hook.sh` | Installs `check-docs-fresh.sh` as a pre-commit hook (worktree- and submodule-safe). |
| `check-docs-ci.sh` | Provider-neutral CI backstop. Re-runs the check across the whole change (`base...HEAD`) with full-tree metadata validation. |
| `fdc-graph.sh` | Optional. Builds a portable knowledge graph (`graphify-out/fdc-graph.json`) from `/fdc/` frontmatter + `## See also` links. Not part of the hook; set `FDC_GRAPH_CMD` to post-process with your own tool. |
| `fdc-stale.sh` | Optional, never fails. Lists runbooks / troubleshooting notes whose `verified:` (or `timestamp:`) is older than `FDC_STALE_DAYS` (default 180) or past `stale_after:`; reports trust tier (unverified / machine-confirmed / human-reviewed) from `verified` actors. |
| `fdc-log.sh` | Optional. Regenerates `fdc/log.md` — newest-first history of `/fdc/` from git. |
| `fdc.sh` | Entry point for all of the above plus `doctor` (session-start self-heal), `update` (pull a tagged upstream release), `index` (regenerate `fdc/*/` index lists), `notes`, `whoami`. |
| `fdc.conf` | Per-repo settings. The only file to edit in this folder. |

`fdc.sh` also has `findings` (open troubleshooting notes), `archive --dry-run` / `archive` (end-state docs → `fdc/archive/`), `prune --dry-run` / `prune --yes` (delete old archive entries), and `budget` (the token-cost report).

## Daily use

```bash
bash scripts/fdc.sh doctor               # session start — hook, version, identity, open notes/briefs
bash scripts/fdc.sh check                # changed files only (what the hook runs)
FDC_VALIDATE_ALL=1 bash scripts/fdc.sh check   # audit the whole fdc/ tree
bash scripts/fdc.sh update               # newest tagged upstream scripts + hook; keeps fdc.conf
```

Run in CI (any provider):

```bash
bash scripts/check-docs-ci.sh
bash scripts/fdc-stale.sh     # optional report, never fails
```

Bypass for one commit (use sparingly, document why):

```bash
SKIP_DOC_CHECK=1 git commit -m "..."
```
```

# STEP 5 — Update `.gitignore`

Add the entries the user confirmed in Step 0. Common patterns:

```gitignore
# OS
.DS_Store
Thumbs.db

# Editor
.vscode/
.idea/

# LLM / agent session state (local-only)
.claude/
.remember/
.planning/

# Generated knowledge-graph output (per-user, not shared)
graphify-out/

# Team repos only: generated history conflicts on every merge; doctor regenerates it locally
# fdc/log.md

# (optional, per user choice)
# fdc/
# CLAUDE.md
# AGENTS.md
```

Don't add `fdc/`, `CLAUDE.md`, or `AGENTS.md` to gitignore without the user's explicit answer in Step 0.

# STEP 6 — Verify

Run these checks and report:

```bash
# 1. No stray README files for folder indexes (root readme.md is OK).
find . -type f \( -iname 'README.md' -o -iname 'readme.md' \) \
  -not -path './.git/*' -not -path './node_modules/*' \
  -not -path './vendor/*' -not -path './target/*' \
  -not -path './bin/*' -not -path './obj/*'

# 2. Every top-level folder has an index doc.
for d in $(find . -maxdepth 1 -type d -not -path '.' -not -name '.git' -not -name 'node_modules' -not -name 'vendor' -not -name 'target' -not -name 'bin' -not -name 'obj' -not -name 'dist' -not -name 'build' -not -name '.next' -not -name '.nuxt'); do
    base=$(basename "$d")
    if [ -f "$d/$base.md" ]; then
        echo "✓ $d/$base.md"
    else
        echo "✗ MISSING: $d/$base.md"
    fi
done

# 3. /fdc/ structure complete.
for f in fdc/fdc.md fdc/decisions/decisions.md fdc/runbooks/runbooks.md fdc/troubleshooting/troubleshooting.md fdc/briefs/briefs.md; do
    [ -f "$f" ] && echo "✓ $f" || echo "✗ MISSING: $f"
done

# 4. Existing long-form /fdc/ docs are migrated.
find fdc/decisions fdc/runbooks fdc/troubleshooting fdc/briefs -type f -name '*.md' 2>/dev/null \
  -not -name decisions.md -not -name runbooks.md -not -name troubleshooting.md -not -name briefs.md \
  -print

# 5. Tooling in place, hook active, config filled, drift check passes.
for f in scripts/fdc.sh scripts/fdc.conf scripts/check-docs-fresh.sh .githooks/pre-commit; do [ -e "$f" ] && echo "✓ $f" || echo "✗ MISSING: $f"; done
grep -q '{{' scripts/fdc.conf && echo "✗ scripts/fdc.conf still has placeholders" || echo "✓ fdc.conf filled"
bash scripts/fdc.sh doctor
FDC_VALIDATE_ALL=1 bash scripts/fdc.sh check && echo "✓ drift check passes" || echo "✗ drift check fails"
bash scripts/fdc.sh index >/dev/null && echo "✓ fdc index lists generated"
bash scripts/fdc.sh budget | sed -n '1,12p'
```

Report results. Fix anything marked `✗`. Re-run until clean.

# STEP 7 — Initial commit

If the repo is brand new, suggest staging and committing:

```bash
git add -A
git commit -m "$(cat <<'EOF'
chore: bootstrap Folder-Doc Convention (FDC)

- Add AGENTS.md as canonical agent operating rules.
- Add CLAUDE.md as thin Claude-only addendum.
- Add per-folder <folder>.md index docs across top-level folders.
- Add /fdc/ structure (decisions, runbooks, troubleshooting, briefs).
- Add scripts/check-docs-fresh.sh + pre-commit hook to enforce doc-sync.

See METHODOLOGY.md (in the FDC reference repo) for the full spec.
EOF
)"
```

If the repo already has history, do not commit unprompted — show the user `git status` and `git diff --stat` and ask whether they want you to commit.

---

# PROJECT-TYPE-SPECIFIC GUIDANCE

Use these to tailor the templates above. **Detect the project type from the signals in Step 0, then apply the relevant subsection.**

## .NET (C# / F#)

**Signals:** `*.sln`, `*.csproj`, `*.fsproj`, `Program.cs`, `global.json`, `nuget.config`.

**CODE_REGEX for drift checker:**
```
\.(cs|csproj|sln|fsproj|fs|fsx|json|yml|yaml|sh|ps1|xml|targets|props|Dockerfile|editorconfig)$
```

**Typical folder layout:**
```
src/
  <Project>/
  <Project.Library>/
tests/
  <Project>.Tests/
fdc/
scripts/
```

**Folder doc — Build/Test/Run:**
```bash
dotnet restore
dotnet build
dotnet test
dotnet run --project src/<Project>
dotnet format
```

**Things to surface in `<folder>.md` Gotchas:**
- Target framework (`net8.0`, `net9.0`).
- NuGet feeds (private feeds, auth).
- Build profiles / configurations (Debug, Release, custom).
- EF Core migrations location and command.

## Rust

**Signals:** `Cargo.toml`, `Cargo.lock`, `src/main.rs` or `src/lib.rs`, `rust-toolchain.toml`.

**CODE_REGEX:**
```
\.(rs|toml|yml|yaml|sh|Dockerfile|lock)$
```

**Typical folder layout:**
```
src/
tests/
examples/
benches/
fdc/
scripts/
```

For Cargo workspaces, every member crate is a folder with its own `<crate>.md`.

**Folder doc — Build/Test/Run:**
```bash
cargo build
cargo test
cargo run
cargo clippy --all-targets --all-features -- -D warnings
cargo fmt --check
```

**Things to surface:**
- MSRV (minimum supported Rust version) if pinned.
- Features and feature flags.
- Workspace membership.
- `cargo-nextest` / custom test runners.

## Next.js (App Router or Pages Router)

**Signals:** `next.config.{js,mjs,ts}`, `package.json` with `"next"` dep, `app/` or `pages/` folder.

**CODE_REGEX:**
```
\.(ts|tsx|js|jsx|mjs|cjs|json|yml|yaml|css|scss|html|sh|Dockerfile)$
```

**Typical folder layout (App Router):**
```
app/
components/
lib/
public/         # data-only — share parent's doc
styles/
tests/ (or __tests__/)
fdc/
scripts/
```

**Folder doc — Build/Test/Run:**
```bash
pnpm install        # or npm install / yarn / bun install
pnpm dev            # http://localhost:3000
pnpm build
pnpm start
pnpm test           # if configured
pnpm lint
```

**Things to surface:**
- Package manager (`pnpm` / `npm` / `yarn` / `bun`) — match what the lockfile shows.
- Node version (from `.nvmrc` or `engines`).
- Environment variables (`.env.local`, `.env.production`).
- Deployment target (Vercel, self-hosted, container).
- Server vs client component conventions.
- ISR / SSG / SSR strategy if non-default.

## Angular

**Signals:** `angular.json`, `package.json` with `@angular/core`, `src/app/`.

**CODE_REGEX:**
```
\.(ts|html|scss|sass|less|css|json|yml|yaml|sh|Dockerfile)$
```

**Typical folder layout:**
```
src/
  app/          # main app — has app/app.md
  assets/       # data-only
  environments/
e2e/ (or tests/)
projects/       # for monorepo / library projects
fdc/
scripts/
```

**Folder doc — Build/Test/Run:**
```bash
npm install     # or pnpm
ng serve        # http://localhost:4200
ng build
ng test
ng e2e
ng lint
```

**Things to surface:**
- Angular version (major matters a lot).
- Standalone vs NgModules.
- Workspace projects (`apps/`, `libs/`).
- Build configurations (`development`, `production`, custom).
- SSR (Angular Universal) if configured.

## PHP (vanilla / Symfony / Laravel)

**Signals:** `composer.json`, `composer.lock`, `artisan` (Laravel), `bin/console` (Symfony), `index.php` at root or `public/`.

**CODE_REGEX:**
```
\.(php|json|yml|yaml|blade\.php|twig|env|sh|Dockerfile|sql|xml|neon)$
```

**Typical folder layout (Laravel):**
```
app/
bootstrap/
config/
database/
public/         # data-only
resources/
routes/
storage/        # gitignored mostly
tests/
fdc/
scripts/
```

**Typical folder layout (Symfony):**
```
src/
config/
templates/
public/
tests/
fdc/
scripts/
```

**Folder doc — Build/Test/Run (Laravel):**
```bash
composer install
cp .env.example .env
php artisan key:generate
php artisan migrate
php artisan serve
./vendor/bin/phpunit
./vendor/bin/pint        # formatting if installed
```

**Folder doc — Build/Test/Run (Symfony):**
```bash
composer install
bin/console doctrine:migrations:migrate
symfony server:start
./vendor/bin/phpunit
./vendor/bin/php-cs-fixer fix
```

**Things to surface:**
- PHP version requirement.
- Framework version (Laravel 11, Symfony 7, etc.).
- Database (MySQL, PostgreSQL, SQLite).
- Queue/cache drivers.
- `.env` shape and which keys are required.

## Flutter / Dart

**Signals:** `pubspec.yaml`, `pubspec.lock`, `lib/main.dart`, `.dart_tool/`, `android/` + `ios/` sibling folders, `analysis_options.yaml`.

**CODE_REGEX:**
```
\.(dart|yaml|yml|json|sh|Dockerfile)$
```
Add `kt|kts|gradle|swift|h|m|plist` only if you actually hand-edit the native shells under `android/` and `ios/` (most Flutter work doesn't).

**Skip rules (important — Flutter generates a lot):**
- `SKIP_FILE_REGEX` must include `pubspec\.lock` (generated; never document it).
- `SKIP_FOLDER_REGEX` must include `\.dart_tool/`, `build/`, and `\.fvm/`. Also skip `android/` and `ios/` unless you maintain native code there — they're mostly tool-generated.
- The shipped `check-docs-fresh.sh` defaults already include `dart`, `pubspec.lock`, `.dart_tool/`, and `.fvm/`.

**Typical folder layout:**
```
lib/            # Dart source — lib/lib.md
  src/
  features/
test/           # tests
assets/         # data-only — share parent's doc
android/        # native shell — usually skip
ios/            # native shell — usually skip
fdc/
scripts/
```

**Folder doc — Build/Test/Run:**
```bash
flutter pub get
flutter run                # device/emulator
flutter test
flutter analyze
dart format --output=none --set-exit-if-changed .
flutter build apk          # or appbundle / ios / web
```

**Things to surface in `<folder>.md` Gotchas:**
- Flutter/Dart SDK version (`environment:` in `pubspec.yaml`, or `.fvmrc` / `.fvm/`).
- State management choice (Riverpod, Bloc, Provider, …).
- Codegen: `build_runner` and the `*.g.dart` / `*.freezed.dart` files it produces (generated — don't hand-edit, don't document individually).
- How the app points at the backend (base URL / env / `--dart-define`).
- Platform-specific build steps or signing notes.

## Ops / Infrastructure (Ansible, Terraform, Helm, Kubernetes, Compose, systemd)

**Signals:** `ansible.cfg`, `inventory*`, `playbooks/`, `roles/`, `*.tf`, `*.tfvars`, `.terraform.lock.hcl`, `Chart.yaml`, `values*.yaml`, `kustomization.yaml`, `docker-compose*.yml` / `compose*.yml`, `*.service`, `*.j2`.

**CODE_REGEX (add to whatever app languages are present):**
```
\.(yml|yaml|json|toml|sh|py|tf|tfvars|hcl|tpl|j2|conf|ini|cfg|properties|service|timer|env|Dockerfile)$
```
The shipped default already includes all of these, and `CODE_BASENAME_REGEX` covers `Dockerfile`, `Makefile`, `Justfile`, `Vagrantfile`, and `.env*` without an extension.

**Skip rules:** `.terraform/`, `.vagrant/`, `.ansible/` (facts/retry files), `.venv/`, `__pycache__/` are in the shipped `SKIP_FOLDER_REGEX`. Add `roles/<vendored-role>/` for Galaxy roles you don't maintain, and any `charts/*/charts/` dependency folder.

**Typical folder layout:**
```
inventories/      # per-environment inventories — inventories/inventories.md lists every env
playbooks/        # entry points — one row per playbook with what it touches
roles/            # roles/roles.md; each maintained role gets roles/<role>/<role>.md
terraform/        # or infra/ — one <folder>.md per root module / workspace
helm/ or k8s/     # charts / manifests — per-chart doc
compose/          # per-stack compose files
scripts/          # includes the FDC drift checker
fdc/
```

**Folder doc — Commands (examples; use the repo's real ones):**
```bash
ansible-playbook -i inventories/prod playbooks/site.yml --check --diff
terraform -chdir=terraform/prod plan
helm upgrade --install <release> ./helm/<chart> -f values-prod.yaml --dry-run
kubectl --context prod diff -k k8s/overlays/prod
docker compose -f compose/app.yml config
```

**Fill the `## Targets` and `## Access` sections in every ops folder doc.** Targets: hosts, clusters, accounts, the environment each maps to, and how it is reached (ssh alias, kubeconfig context, cloud profile) — an agent must be able to read the blast radius before it runs anything. Access: one row per service with user, secret (value under credentials policy A, `<vault: item>` under B), and the `Rotated on` date.

**Things to surface in `<folder>.md` Gotchas:**
- Which environments are real and which are safe to break. Which commands are read-only (`--check`, `plan`, `diff`, `--dry-run`) versus mutating.
- State backends (Terraform remote state, locks), and what happens if a run is interrupted.
- Secrets mechanism (Vault, sops, ansible-vault, sealed-secrets) and where the key lives.
- Ordering constraints between folders (network before compute, CRDs before charts).
- Tool version pins (`.terraform-version`, `requirements.yml`, Helm/kubectl versions).

**`/fdc/` usage in ops repos is heavier than in app repos.** Every procedure you run more than once is a runbook with `verified: { by: human:<who>, at: <date> }` (an agent-written runbook nobody has run stays *machine-confirmed* or *unverified* in the audit — that distinction matters at 3 a.m.); every incident becomes a troubleshooting note the same day, with `sources:` pointing at the ticket and `not:` listing the fixes that did not work. Run `bash scripts/fdc-stale.sh` before on-call rotations or in CI to see what has not been verified in 180 days.

## Monorepos (Turborepo / Nx / pnpm workspaces / Cargo workspaces / polyglot)

**Signals:** `turbo.json`, `nx.json`, `pnpm-workspace.yaml`, multiple `package.json` / `Cargo.toml`, top-level `apps/` + `packages/`, or **multiple stacks side by side** (e.g. a Rust/Axum backend + a Next.js frontend + a Flutter app in one repo).

**Apply FDC at two levels:**

1. **At the monorepo root**: standard AGENTS.md, CLAUDE.md, /fdc/, scripts/. Navigation lists the top-level folders (`apps/apps.md`, `packages/packages.md`).
2. **Inside each app / package**: each gets its own `<package-name>.md` plus its own `src/src.md`, `tests/tests.md`, etc.

**CODE_REGEX** should union all the languages present in the monorepo. For a Rust + Next.js + Flutter repo, that's:
```
\.(rs|toml|ts|tsx|js|jsx|mjs|cjs|dart|json|yml|yaml|css|scss|sh|sql|Dockerfile)$
```
And the skip lists must cover every stack's generated artifacts: `SKIP_FILE_REGEX` → the JS lockfiles + `Cargo.lock` + `pubspec.lock`; `SKIP_FOLDER_REGEX` → `node_modules/`, `.next/`, `target/`, `.dart_tool/`, `.fvm/`, `build/`. (The shipped defaults already include all of these.)

**Each app keeps its OWN Build/Test/Run** in its `<folder>.md` — `cargo …` for the backend, the right package manager for the frontend (match the lockfile), `flutter …` for mobile. Don't put a single global build section at the root; per-stack commands belong in per-stack docs.

**Cross-stack contracts are the high-value case.** When the same change spans stacks (e.g. an API field that the Axum backend serves and both the Next.js and Flutter clients consume), record it as an ADR in `fdc/decisions/` and link it from all affected app docs' `## See also`. In one monorepo, an LLM can make that change atomically in a single commit and `rg` the identifier across all stacks; `scripts/fdc-graph.sh` then shows one node with edges into every consumer. This is the main reason a polyglot product is better kept in one repo for LLM-driven work.

**Things to surface in the root AGENTS.md:**
- Workspace tool (turbo, nx, pnpm, lerna, cargo) if any, or just the list of stacks if it's a plain side-by-side layout.
- Cross-package / cross-stack commands.
- Which packages publish, which are internal-only.

---

# RULES OF ENGAGEMENT FOR YOU (THE LLM RUNNING THIS PROMPT)

1. **Confirm before mass-creating files.** Step 0 must complete and the user must answer the questions before Step 1.

2. **Don't fabricate facts.** If you don't know the build command, the database, the env vars, or what a folder does, write `_TODO: describe._` in the doc and surface it in your report. Do not invent.

3. **Preserve existing content.** If `AGENTS.md`, `CLAUDE.md`, `README.md`, or any folder doc already exists with content, merge — don't overwrite. Show the user the merge diff before applying.

4. **Don't commit during bootstrap.** Show `git status` and `git diff --stat` and ask before running `git commit`, whatever commit policy the user chose for daily work — the bootstrap diff is large and they should see it. Exception: if the repo has no commits yet (fresh `git init`), suggest the initial commit but still wait for confirmation.

5. **The credentials policy is the user's choice (Step 0), not yours.** Under policy A, move any credentials you find into the owning folder doc's `## Access` table with a `Rotated on` date. Under policy B, replace them with `<vault: item>` references and tell the user which values you removed. Team + A exists only with `FDC_CREDENTIALS_OVERRIDE`; the pre-commit check refuses it otherwise.

5b. **Never quote the target repo inside a question.** The questions are fixed text (Step 0). Describe a conflict with existing files in one neutral sentence; the user knows their own repo and does not need it read back to them.

6. **Respect gitignored areas.** Don't create docs inside `.git/`, `node_modules/`, `target/`, `vendor/`, etc. The drift checker's `SKIP_FOLDER_REGEX` lists the standard ones — match it.

7. **Stop and ask if anything is ambiguous.** It's cheaper to ask than to guess wrong and then redo.

8. **Report at the end.** Tell the user exactly what you created, what's pending, and what they need to verify or run themselves (install pre-commit hook, push to remote, etc.).

After bootstrap, the rules that govern daily work are the ones you just wrote into `AGENTS.md` → "How to work in this repo". Read them back before your report; they apply to you from now on.

---

# WHAT "DONE" LOOKS LIKE

When you finish this prompt's work, the repo should have:

- [ ] `AGENTS.md` at root with the TOP PRIORITY rule, the behaviour contract with both policies filled (no `{{ … }}` left), and a populated Navigation / Build-Test-Run section.
- [ ] `CLAUDE.md` at root pointing back to AGENTS.md.
- [ ] `readme.md` at root — short, human-facing entry point.
- [ ] `fdc/` with seven index files (`fdc.md` + six subindexes incl. `work/`) and the onboarding runbook.
- [ ] Every existing long-form doc has a `status`; plans/specs are in `fdc/work/`; any findings register is split into `fdc/troubleshooting/` notes; `fdc.sh budget` shows the active layer under `FDC_BUDGET_TOTAL_LINES` (or the user has seen the number).
- [ ] Every existing non-index `/fdc/` long-form doc has required frontmatter and `## See also`.
- [ ] Per-folder `<folder>.md` index in every top-level folder in scope.
- [ ] `scripts/fdc.sh`, `scripts/fdc.conf` (no `{{ }}` left; `FDC_TEAM` and both policies filled, `FDC_CREDENTIALS_OVERRIDE` set if team + A), all six sibling scripts (executable), `scripts/scripts.md`, `.githooks/pre-commit`.
- [ ] Hook active: `git config core.hooksPath` = `.githooks` (`fdc.sh doctor` says OK).
- [ ] (Teams) `scripts/check-docs-ci.sh` wired into CI as a required check; PR template in place; `fdc/log.md` gitignored.
- [ ] `graphify-out/` added to `.gitignore` (if `fdc-graph.sh` is used).
- [ ] `.gitignore` updated per user's Step 0 answers.
- [ ] `bash scripts/check-docs-fresh.sh` exits 0.
- [ ] No stray `README.md` / `readme.md` inside subfolders (only root `readme.md`).

Then report to the user:

> FDC bootstrap complete. Files created: \[count]. Folder indexes: \[count]. Drift check: passing. Pre-commit hook: installed.
>
> Next steps for you:
> - On every other machine / clone: `bash scripts/fdc.sh doctor` once (it activates the hook there).
> - Review `AGENTS.md` and fill in any `_TODO:_` placeholders I left.
> - Review folder index docs the same way.
> - Commit when you're ready.
> - If you want `/fdc/` or `CLAUDE.md` / `AGENTS.md` to stay local-only, confirm `.gitignore` entries are present.

---

# END OF PROMPT
