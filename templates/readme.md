<!-- Root readme.md template. The ONLY README in the repo (all other folders use
     <folder>.md). Keep it short and human-facing. Fill the {{ ... }} placeholders. -->

# {{PROJECT_NAME}}

{{ONE_TO_THREE_SENTENCE_DESCRIPTION}}

## Quick start

```bash
{{INSTALL_AND_RUN_COMMANDS}}
```

## How this repo is organized

This repo follows the **Folder-Doc Convention (FDC)**: every folder owns one
`<folder>.md` index doc, and code changes ship with their doc updates in the
same commit (enforced by a pre-commit hook).

- **`AGENTS.md`** — canonical operating rules for any LLM/agent working here. **Read first.**
- **`CLAUDE.md`** — thin Claude Code addendum; points back to `AGENTS.md`.
- **`fdc/fdc.md`** — long-form knowledge: decisions, runbooks, troubleshooting, briefs.
- Per-folder docs: see the Navigation section of `AGENTS.md`.

## Contributing

Install the doc-drift pre-commit hook once after cloning:

```bash
bash scripts/install-hook.sh
```

Any code change must update its owning `<folder>.md` in the same commit, or the
hook blocks it. See `AGENTS.md` → "TOP PRIORITY" for the full rule.
