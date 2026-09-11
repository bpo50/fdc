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
