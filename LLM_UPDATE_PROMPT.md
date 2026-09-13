# LLM Prompt — Update an existing FDC install to the current upstream version

Paste this file into an LLM session inside a repository that **already** uses the Folder-Doc Convention (FDC). It brings the installed tooling and rules file up to date with the upstream FDC repo without touching the repo's own content (folder docs, `/fdc/` entries, project-specific sections of `AGENTS.md`).

For a repo that does not have FDC yet, use `LLM_PROMPT.md` instead.

---

# YOUR TASK

Update this repo's FDC install to the version shipped by the upstream FDC repo. Upstream is the folder or clone the user points you at (default: `~/PROJECTS/llm-icm`; ask if it is not there). Read this whole prompt first, then follow the steps in order.

**Version stamps.** Every upstream script carries `# fdc-version: YYYY.MM.DD` on line 2, and the upstream `templates/AGENTS.md` carries `<!-- fdc-version: YYYY.MM.DD -->` on line 2. Installed copies carry the stamp they were installed with, or none if they predate stamping. Newer date wins.

# STEP 0 — Run doctor and report the gap

```bash
bash scripts/fdc.sh doctor 2>/dev/null || echo "NO fdc.sh — this repo predates the entry point (pre-2026.09.11 install)"
cat scripts/fdc.conf 2>/dev/null || echo "NO fdc.conf"
git status --short
```

**Report** the installed version, the newest upstream version doctor found, and whether `fdc.sh` / `fdc.conf` exist. Then **ask** the user to confirm before changing anything. If the working tree is dirty, ask them to commit or stash first.

# STEP 1 — Update the tooling

**If `scripts/fdc.sh` exists:** one command, nothing to merge — scripts are upstream copies and settings live in `fdc.conf`.

```bash
bash scripts/fdc.sh update          # or: bash scripts/fdc.sh update <version>
bash scripts/fdc.sh doctor
```

**If it does not exist (older install):** the repo still has the five regex settings inside `scripts/check-docs-fresh.sh`. Capture them first, then bootstrap the new layout:

```bash
grep -nE '^(CODE_REGEX|CODE_BASENAME_REGEX|DOC_REGEX|SKIP_FILE_REGEX|SKIP_FOLDER_REGEX)=' scripts/check-docs-fresh.sh
curl -fsSL https://raw.githubusercontent.com/bpo50/fdc/main/install.sh | bash -s -- init     # or FDC_UPSTREAM=<path-or-url> …
```

Then write the captured values into `scripts/fdc.conf` **only where they differ from the shipped defaults** (top of the new `check-docs-fresh.sh`), fill `FDC_TEAM` and the two policies if they are empty (ask; see Step 2), and if the file says `FDC_TEAM="team"` with `FDC_CREDENTIALS_POLICY="A"` and no `FDC_CREDENTIALS_OVERRIDE`, ask the user for the reason (or to switch to B) — the pre-commit check refuses commits until one of the two is done, and delete the old `.git/hooks/pre-commit` wrapper if `install.sh` reported `core.hooksPath=.githooks` (the old file is harmless but confusing). Show the user the diff of `fdc.conf` before moving on.

# STEP 2 — Update `AGENTS.md` rules sections, keep project sections

The upstream `templates/AGENTS.md` has two kinds of sections:

- **Rules sections** (owned by upstream): `TOP PRIORITY …`, `How to work in this repo`, `Naming convention for docs`, `Creating docs in /fdc/`, `Repo-analysis workflow`, `Editing rules`, `Output expectations`, `Doc-drift check`, `For Claude Code users`, `Keep this file lean`.
- **Project sections** (owned by the repo): `Overview`, `Tech stack`, `Navigation`, `Build / Test / Run`, plus anything the repo added.

Replace each rules section in the installed `AGENTS.md` with the upstream text, fill the `{{ … }}` placeholders the same way they were filled before, and leave project sections untouched. If `How to work in this repo` is new to this repo (installs before 2026.09.11), **ask the user** the Round 2 and Round 3 questions from `LLM_PROMPT.md` Step 0 (solo/team, credentials policy, commit policy — full option text, not summaries), then paste the chosen paragraphs; do not choose for them. Team + credentials A requires `FDC_CREDENTIALS_OVERRIDE` in `scripts/fdc.conf`. Update the `<!-- fdc-version -->` line. Show the user the diff before writing.

Do the same for `fdc/fdc.md` and the four subfolder index files **only** for their template and rules text; never touch the `## Index` lists.

Do **not** modify per-folder `<folder>.md` files or any non-index `/fdc/` document.

# STEP 3 — Re-install the hook and verify

```bash
bash scripts/fdc.sh doctor
FDC_VALIDATE_ALL=1 bash scripts/fdc.sh check && echo "full audit: OK"
bash scripts/fdc.sh index      # regenerate the fdc/*/ index lists (they are generated from now on)
```

If the repo has no `fdc/notes/notes.md`, `fdc/work/work.md`, or `fdc/runbooks/onboard-developer.md`, copy them from upstream `templates/fdc/`.

# STEP 3b — Compaction (repos that predate Convention 8)

Run `bash scripts/fdc.sh budget` and show the user the numbers. Then, **with the user confirming each list**:

1. Every long-form doc gets a `status` (troubleshooting: `open` / `resolved` / `accepted`; decisions `accepted` / `superseded`; briefs `open` / `claimed` / `done`). Infer where the body makes it obvious; ask otherwise.
2. Plans, specs, transcripts (e.g. `docs/superpowers/plans/`, `docs/superpowers/specs/`) move to `fdc/work/` with `type: plan` and `status: done` when complete. For each completed plan, check its conclusion exists as an ADR or a doc update; if not, write it (one ADR at most) before marking done.
3. A findings register (one file with many entries) becomes one `fdc/troubleshooting/<symptom>.md` per entry, `status: open` or `resolved`, with the register's ID kept in `tags`. Delete the register; `fdc.sh doctor` replaces it. Update `AGENTS.md` if it told sessions to read the register.
4. `bash scripts/fdc.sh archive --dry-run` → show → `archive` on yes → `fdc.sh index` → commit. Report the before/after from `budget`.

If the full audit now fails on `/fdc/` docs that passed before, the upstream validator got stricter. List the failing files and offer to fix their frontmatter; do not weaken the validator. Known stricter rules since 2026.09.11: decisions and briefs need a `status` field (`accepted` / `open` are safe defaults for existing docs — confirm with the user); notes need `from`, `to`, `status`.

If the drift check fails because of the new basename rule (an uncommitted `Dockerfile` or `Makefile`, say), explain that this is the intended new behaviour.

# STEP 4 — Report, then stop

Remind the user: every other clone of this repo needs one `bash scripts/fdc.sh doctor` to activate the versioned hook.

Tell the user:

- Previous version → new version, per file.
- Which local regex values were preserved and any new variables with their defaults.
- Which `AGENTS.md` sections changed.
- Whether the full audit passes.

Show `git status --short` and `git diff --stat`. **Do not commit.** The user decides. If they ask you to, the commit touches `scripts/scripts.md` as well (the drift check requires it), with a message like `chore: update FDC tooling to <version>`.

# RULES OF ENGAGEMENT

1. Never overwrite project content: folder docs, `/fdc/` entries, project sections of `AGENTS.md`, index lists.
2. Never drop a local customisation without showing it and asking.
3. Never weaken the validator to make an audit pass.
4. Never commit unprompted.
5. If upstream cannot be found or has no version stamps, stop and ask.

# END OF PROMPT
