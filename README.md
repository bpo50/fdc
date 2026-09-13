# Folder-Doc Convention (FDC)

**Documentation that stays true, because a hook won't let it rot.**

FDC is a lightweight discipline for repositories where LLMs (Claude, Codex, Copilot,
Cursor, Gemini, Aider, …) are regular contributors. Every folder owns one index doc,
long-form knowledge is typed and linkable, and **code can't be committed without
updating the doc that owns it** — enforced by a pre-commit hook and a CI backstop, not
by good intentions.

> **TL;DR** — Put a `<folder>.md` in every folder, keep canonical rules in `AGENTS.md`,
> keep long-form knowledge in `/fdc/`, and let a pre-commit hook block any commit that
> changes code without updating its owning doc. Drop the [bootstrap prompt](LLM_PROMPT.md)
> into an LLM session and it sets the whole thing up for you.

It's complementary to the [`AGENTS.md`](https://agents.md) convention, not a competitor:
FDC *uses* `AGENTS.md` as the canonical rules file and adds the per-folder docs, the
long-form layer, and — the part most conventions lack — **mechanical enforcement**.

---

## The problem it solves

When LLMs work on a codebase, three failures recur:

1. **Context starvation** — the agent doesn't know where things live or why, loads too
   much, and proposes broken changes.
2. **Documentation drift** — code ships, docs don't. Months later the docs actively
   mislead the next session into wrong work.
3. **Lost intent** — a constraint or decision explained mid-conversation never survives
   the session, so the next one re-litigates it.

Most "keep your docs updated" advice is aspirational and therefore ignored. FDC's bet is
that **enforcement is the only thing that makes a doc convention survive** a real repo.

## How it works (one minute)

1. **Per-folder index docs.** Every folder has exactly one `<folder-name>.md`. The
   filename matches the folder, so a `grep` hit tells you its scope without opening it.
2. **`AGENTS.md` is canonical**; `CLAUDE.md` is a thin pointer to it. Other agents get
   thin stubs too. Rules are never duplicated.
3. **`/fdc/` holds long-form knowledge** in five kinds: `decisions/` (ADRs),
   `runbooks/` (procedures), `troubleshooting/` (symptom → cause → fix), `briefs/`
   (intent not yet built, and session handoffs), `notes/` (messages to a person, the
   team, or yourself on another machine).
4. **Long-form docs are typed.** Each carries YAML frontmatter (`type`, `title`,
   `description`, `tags`, `timestamp`) and a `## See also` link section — which doubles
   as a knowledge graph (`scripts/fdc-graph.sh` extracts it; `FDC_GRAPH_CMD` feeds your
   own tool). Runbooks carry a `verified` date; `scripts/fdc-stale.sh` reports the ones
   nobody has re-run in 180 days.
5. **Code change → doc change in the same commit.** A pre-commit hook
   (`scripts/check-docs-fresh.sh`) blocks commits that change code without updating the
   doc that *owns* it (the nearest ancestor folder with an index doc).
6. **Knowledge has an end state.** Every `/fdc/` doc carries a `status`; plans live in an
   ephemeral `work/` folder; `fdc.sh archive` moves finished docs out of the default read
   path and `fdc.sh budget` reports what a session would load — so a two-year-old repo
   costs the same tokens per session as a two-week-old one.
7. **A provider-neutral CI backstop** (`scripts/check-docs-ci.sh`) re-runs the check on
   the whole change at merge time, so a local `--no-verify` is caught in review. Works
   with any CI (GitLab, Gitea/Forgejo, Drone, Jenkins, Buildkite, …) — no GitHub assumed.

Full spec, rationale, and limitations: **[`METHODOLOGY.md`](METHODOLOGY.md)**.

## Quick start

**One-liner** (bash, git, curl; no package manager). Run it **inside the repository you want
to document** — any directory within that repo works, the installer finds the root itself — not
inside a clone of this FDC repo:

```bash
cd /path/to/your-project          # an existing git repo (run `git init` first if it is not one yet)
```
```bash
curl -fsSL https://raw.githubusercontent.com/bpo50/fdc/main/install.sh | bash -s -- init
```
```bash
bash scripts/fdc.sh doctor
```

What it does to `your-project`: creates `scripts/` (the tooling and `fdc.conf`), `.githooks/pre-commit`,
and the `/fdc/` skeleton (all six subfolders, including `work/`, plus the onboarding runbook), then
activates the hook for this clone. The only existing file it may change is `.gitignore` (adds
`graphify-out/`). Pin a
release with `bash -s -- init 2026.09.11`.

Then let an LLM write the folder docs and fill the policies: open a session in `your-project` and
paste `LLM_PROMPT.md` — it detects the existing install and skips straight to the documentation steps.

**Then let an LLM do the documentation.** In a Claude Code session (or any agent that can fetch a
URL) opened inside `your-project`, type one line:

```
Follow https://raw.githubusercontent.com/bpo50/fdc/latest/LLM_PROMPT.md step by step.
```

`latest` is a tag that always points at the newest release (substitute a date such as `2026.09.11` to pin one). The prompt detects the tooling you just installed and goes straight to the documentation steps: it
asks the Step 0 questions (stack, solo/team, machines, credentials and commit policy), writes
`AGENTS.md` and `CLAUDE.md`, creates one `<folder>.md` per folder, migrates any existing long-form
docs into `fdc/` with frontmatter and statuses, and stops before committing. You can pre-answer
Step 0 in the same line, e.g. `… Step 0 answers: Ops/Infrastructure, solo, 4 machines, credentials
policy A, commit policy A, everything tracked. Do not push.`

**Prompt only, no curl** (offline machines, or an agent without shell access): paste the whole of
[`LLM_PROMPT.md`](LLM_PROMPT.md) into the session — every script and template is inlined, so it
installs the tooling too.

**Already installed? Updating an existing repo.** Two layers update separately: the scripts (plain
copies, safe to overwrite) and the docs (`AGENTS.md`, templates — merged by an LLM, never
overwritten).

1. See whether you are behind:

   ```bash
   bash scripts/fdc.sh doctor      # prints installed vs newest tag, and warns on unset policies
   ```

2. Update the tooling. This replaces `scripts/*.sh` and the hook with the newest tagged versions and
   keeps your `scripts/fdc.conf`. Review the diff, then commit it:

   ```bash
   bash scripts/fdc.sh update      # or: bash scripts/fdc.sh update 2026.09.13 to pin
   git diff --stat
   ```

3. Update the rules text and templates. In a Claude Code session (or any agent that can fetch a
   URL) opened inside the repo, type one line:

   ```
   Follow https://raw.githubusercontent.com/bpo50/fdc/latest/LLM_UPDATE_PROMPT.md step by step.
   ```

   It compares the `fdc-version` stamps, merges the new rules sections into `AGENTS.md` without
   touching your project sections, and asks any bootstrap question your `scripts/fdc.conf` does not
   answer yet (solo/team, credentials and commit policy, or the `FDC_CREDENTIALS_OVERRIDE` reason for a
   team repo on policy A). Offline: paste [`LLM_UPDATE_PROMPT.md`](LLM_UPDATE_PROMPT.md) instead.

Skipping step 2 and running only step 3 also works: the update prompt runs `fdc.sh update` itself
when the scripts are behind.

**Several machines or several people?** `doctor` at session start self-heals a fresh clone (hook,
version, identity), briefs carry handoffs between sessions, and notes carry messages between people.
See `METHODOLOGY.md` → Convention 7.

## Supported stacks

The bootstrap prompt includes per-stack guidance for **.NET, Rust, Next.js, Angular,
PHP, Flutter/Dart, Ops/Infrastructure (Ansible, Terraform, Helm, Kubernetes, Compose)**, and **polyglot monorepos** (e.g. a Rust backend + Next.js frontend +
Flutter app in one repo). The drift checker is language-agnostic — you set one
`CODE_REGEX` — and ships sensible defaults, lockfile skips, and nested-folder skips so
generated dirs (`node_modules/`, `target/`, `.next/`, `.dart_tool/`) never trip it,
even when nested in a monorepo.

Scripts are written for **portability**: they run on stock macOS `/bin/bash` (3.2) and
Linux, with BSD or GNU `awk`/`grep`/`sed` — so the hook works on every contributor's
machine, not just yours.

## What's in this repo

| File | What it is |
|---|---|
| [`METHODOLOGY.md`](METHODOLOGY.md) | The full spec — conventions, rationale, what it solves, when it doesn't fit. |
| [`LLM_PROMPT.md`](LLM_PROMPT.md) | Self-contained prompt to apply FDC to any repo. Paste into any LLM session. Generated from `templates/`. |
| [`LLM_UPDATE_PROMPT.md`](LLM_UPDATE_PROMPT.md) | Prompt to bring an existing FDC install up to the current upstream version, preserving local config. |
| [`install.sh`](install.sh) | `curl \| bash -s -- init\|update` — installs or refreshes the tooling from a tagged release. |
| [`templates/`](templates/) | **Source of truth.** Ready-to-copy files: `AGENTS.md`, `CLAUDE.md`, `readme.md`, `folder-index.md`, `fdc/*` indexes, and the `scripts/` (drift checker, hook installer, CI backstop, graph extractor). |
| [`BACKLOG.md`](BACKLOG.md) | Deferred ideas, kept honest. |
| [`AGENTS.md`](AGENTS.md), [`scripts/`](scripts/scripts.md), [`fdc/`](fdc/fdc.md) | This repo runs FDC on itself — the same rules file, hook, and knowledge layer the templates install elsewhere. |

## When FDC fits — and when it doesn't

**Good fit:** multi-folder repos with distinct domains, LLMs contributing regularly, a
lifespan measured in months-to-years, and a real cost to an agent misunderstanding the
codebase.

**Overkill:** one-shot scripts, throwaway prototypes, or a solo dev who rarely revisits
old code. FDC is a human-in-the-loop discipline, not an autonomous-agent framework, and
it does not enforce that docs are *correct* — only that they were *touched* alongside the
code. The rest is human discipline. See [`METHODOLOGY.md`](METHODOLOGY.md) §7 for the
honest limitations.

## Security note

FDC can, by explicit per-repo choice (credentials policy **A**), store real credentials in folder
docs. That is only for a **private, single-user** repo whose infrastructure is reachable over
VPN/LAN alone and whose credentials rotate. For team repos the pre-commit check refuses it unless `FDC_CREDENTIALS_OVERRIDE` states why; `doctor`
warns if the two are combined. Default is **B**: vault references only. Encrypt any disk that
holds a policy-A repo.

## Status

Opinionated and early. The ideas are battle-tested on real polyglot repos but not yet
across many teams — treat it as a sharp starting point you adapt, not a finished product.
Issues and PRs welcome; deferred work is tracked in [`BACKLOG.md`](BACKLOG.md).

## Related work

The optional provenance and trust fields in `/fdc/` (`generated`, `verified`, `stale_after`,
`sources`, `status`) follow the [Open Knowledge Format](https://github.com/GoogleCloudPlatform/open-knowledge-format)
v0.2 conventions, so an `/fdc/` tree can be read by OKF tooling. ADRs follow Nygard's format.
Full list in [`METHODOLOGY.md`](METHODOLOGY.md) → "Related work and reading".

## License

MIT — use, fork, modify, share. No warranty.
