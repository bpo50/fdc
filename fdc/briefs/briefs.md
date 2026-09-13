# briefs

**Purpose:** Requirement briefs / scoping docs the user has described but not yet implemented.

**Naming:** `<topic>.md`. Move into `decisions/` (if a decision was made) or delete when implementation lands.

**Status (required):** `open` while unbuilt; `done` when shipped (then delete or move to `decisions/`); `dropped` if abandoned.

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

## See also

- `<folder>/<folder>.md` — affected implementation area, if any.
- `fdc/decisions/<related>.md` — decision that resolved this brief, if any.
```

## Index

- [Redesign the bootstrap questions](bootstrap-questions-redesign.md) — Make the Step 0 questions of LLM_PROMPT self-describing, ordered by dependency, free of project-specific example text, with a machine-readable override for team + credentials A. (`done`)
