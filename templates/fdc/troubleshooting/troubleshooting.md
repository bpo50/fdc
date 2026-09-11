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
