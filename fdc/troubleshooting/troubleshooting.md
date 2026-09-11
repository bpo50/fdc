# troubleshooting

**Purpose:** Symptom → cause → fix pages for issues that have actually happened.

**Naming:** `<symptom>.md` — describe the symptom as a future agent would search for it.

## Template

```markdown
---
type: troubleshooting
title: <Symptom>
description: One sentence describing the observed failure and likely cause.
tags: [troubleshooting]
timestamp: YYYY-MM-DD
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
Commands in order.

## Prevention
What change would stop this recurring.

## See also

- `<folder>/<folder>.md` — affected implementation area.
- `fdc/runbooks/<related>.md` — procedure used to recover, if any.
```

## Index

_No entries yet._
