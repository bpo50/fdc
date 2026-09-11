# tools

**Purpose:** Repo-only build tooling for the FDC reference repo. Nothing here is distributed to downstream repos (that is `templates/`).

## Key files

| File | Purpose |
|---|---|
| `build-prompt.sh` | Assembles `LLM_PROMPT.md` from `LLM_PROMPT.src.md` by expanding `{{include:templates/...}}` lines. `--check` exits 1 if the generated file is stale. |

## Commands

```bash
bash tools/build-prompt.sh           # regenerate LLM_PROMPT.md after editing templates/ or LLM_PROMPT.src.md
bash tools/build-prompt.sh --check   # what the test suite runs
```

## Depends on

- `templates/templates.md` — the files that get inlined.

## Gotchas

- Never edit `LLM_PROMPT.md` by hand; the next build overwrites it. Edit `LLM_PROMPT.src.md` for prose, `templates/` for anything inlined.
- `fdc.sh update` and `install.sh` clone the release tag with `advice.detachedHead=false`, so the temporary clone does not print git's detached-HEAD lecture; the target repo never leaves its branch.
- Included Markdown files are wrapped in four-backtick fences in the source so their own three-backtick code blocks nest correctly.
