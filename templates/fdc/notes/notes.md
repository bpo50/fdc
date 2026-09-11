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
