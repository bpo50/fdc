# AGENTS.md
<!-- fdc-version: 2026.09.11 -->

**Canonical operating rules for this repo.** Applies to every LLM / agent working on it. If you are Claude Code, also read `CLAUDE.md` afterwards.

This repo *is* the Folder-Doc Convention (FDC) reference, and it follows FDC itself. Every rule below is the same rule the templates impose on other repos.

---

## TOP PRIORITY — Keep documentation in sync with code AND user intent

> Non-negotiable and highest priority. A change that ships code without the corresponding doc update is an **incomplete task**. Do not report it as done.

1. **Code → docs.** Modify any script, template, or config and you MUST update the `<folder>.md` that owns it, plus every cross-referenced doc (`rg <changed-identifier>`).
2. **User intent → docs.** A decision, procedure, diagnosed problem, or new constraint discussed in a session goes into `/fdc/` *during* the work.

`scripts/check-docs-fresh.sh` (pre-commit hook) enforces the code side.

### Definition of done

- [ ] `<folder>.md` in every touched folder reflects the new reality.
- [ ] Cross-referenced docs updated (`rg <changed-identifier>`).
- [ ] `/fdc/` entries created when warranted, with frontmatter and a `## See also`, linked from a folder doc.
- [ ] `bash scripts/check-docs-fresh.sh` exits 0.
- [ ] `for t in templates/scripts/tests/*.test.sh; do bash $t; done` all pass (this also checks the prompt is regenerated and `scripts/` is in sync).

### Triggers specific to this repo

| You did this | You MUST also do this |
|---|---|
| Changed anything under `templates/` | `bash tools/build-prompt.sh` (regenerates `LLM_PROMPT.md`); if it was a script, also `cp templates/scripts/*.sh scripts/`. |
| Changed `templates/scripts/*.sh`, `templates/scripts/fdc.conf`, or `templates/.githooks/` | Copy to `scripts/` / `.githooks/` here; rebuild the prompt. |
| Changed `templates/scripts/*.sh` behaviour | Add or adjust a test in `templates/scripts/tests/` first (red → green). |
| Changed a template script or `templates/AGENTS.md` materially | Bump `fdc-version` in all six scripts and the AGENTS template to today's date (`YYYY.MM.DD`); rebuild the prompt; copy to `scripts/`. |
| Changed prompt prose (not a template) | Edit `LLM_PROMPT.src.md`, never `LLM_PROMPT.md`, then rebuild. |
| Changed a convention (naming, frontmatter, layout) | Update `METHODOLOGY.md` and the relevant template in the same commit. |
| Decided *why* something is the way it is | ADR in `fdc/decisions/` with `status`. |
| Deferred an idea | `BACKLOG.md` (root), not a brief. |

### Self-check ritual

Read the folder's `<folder>.md` before touching anything in it. Before saying "done":

```bash
git diff --name-only
bash scripts/check-docs-fresh.sh
rg <old-identifier>
```

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
8. **Credentials.** This repo holds no infrastructure and no credentials. Policy B applies: never write a credential value into any file here; if one appears in a template or example, it is a placeholder.


9. **Commits.** Policy A: commit verified milestones yourself. A milestone here is a green run of every suite under `templates/scripts/tests/` plus `FDC_VALIDATE_ALL=1 bash scripts/fdc.sh check`, with `LLM_PROMPT.md` regenerated and `scripts/` in sync. Stage only the files you touched, never `git add -A`. Push when fast-forward; never amend, rebase, reset, or force.


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

- Every folder has exactly one index doc named `<folder-name>.md`.
- Root keeps `README.md` (human landing page, the only README in the repo).
- Long-form knowledge lives in `fdc/`; see `fdc/fdc.md` for frontmatter and linking rules.

## Overview

A documentation discipline for repos where LLMs are regular contributors: per-folder index docs, a typed `/fdc/` knowledge layer, and a pre-commit hook that blocks code changes that don't touch their owning doc. `METHODOLOGY.md` is the spec; `LLM_PROMPT.md` is the self-contained bootstrap prompt; `templates/` holds the copyable files.

## Tech stack

- Markdown for everything human-facing.
- Bash 3.2-compatible shell scripts (must run on stock macOS and Linux, BSD or GNU tools). No `declare -A`, `mapfile`, `${var,,}`, `sed -i` without an arg, `grep -P`.

## Navigation

- `README.md` — public landing page.
- `METHODOLOGY.md` — the full spec, rationale, limitations, related work.
- `LLM_PROMPT.md` — bootstrap prompt, **generated**; edit `LLM_PROMPT.src.md` and `templates/` instead.
- `tools/tools.md` — the prompt generator.
- `LLM_UPDATE_PROMPT.md` — update prompt for downstream repos; relies on the `fdc-version` stamps.
- `BACKLOG.md` — deferred ideas.
- `templates/templates.md` — copyable templates and scripts (source of truth for scripts).
- `scripts/scripts.md` — the installed FDC tooling this repo runs on itself.
- `fdc/fdc.md` — decisions, runbooks, troubleshooting, briefs for this repo.

## Build / Test / Run

```bash
for t in templates/scripts/tests/*.test.sh; do bash "$t"; done   # all suites
bash tools/build-prompt.sh                              # regenerate LLM_PROMPT.md
bash -n templates/scripts/*.sh                          # syntax check
bash scripts/check-docs-fresh.sh                        # drift check on the working tree
```

## Editing rules

- Source of truth: `templates/` (+ `LLM_PROMPT.src.md` for prompt prose). `LLM_PROMPT.md`, `scripts/`, and `fdc/` are derived. Edit upstream, regenerate/copy downstream.
- Keep this file lean; the TOP PRIORITY section stays at the top.
