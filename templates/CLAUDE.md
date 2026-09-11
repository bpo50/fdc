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
