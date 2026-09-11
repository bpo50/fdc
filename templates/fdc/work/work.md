# work

**Purpose:** Ephemeral working material — implementation plans, design specs, session transcripts, investigation scratch. Useful *while the work is in flight*, dead weight afterwards. This is the folder that keeps the durable layer small.

**Naming:** `YYYY-MM-DD-<topic>.md` (plans/specs) or `<topic>/` with its own `<topic>.md` for multi-file plans.

## The rule

1. Everything here has `type: plan` and a `status` (`open | done | dropped`).
2. When a plan completes, its **durable outcome** is written into the knowledge layer: at most one ADR in `decisions/`, plus runbook / troubleshooting / folder-doc updates. The plan itself gets `status: done`.
3. `bash scripts/fdc.sh archive` moves done/dropped plans older than `FDC_ARCHIVE_DAYS` into `fdc/archive/work/`. Git keeps the text; the knowledge layer keeps the conclusion.
4. Agents do not read this folder unless the user asks or a brief points at a specific file (see `AGENTS.md` → read budget).

Tools that write plans elsewhere (e.g. `docs/superpowers/plans/`) should be pointed here, or their output moved here at the end of the session.

## Template

```markdown
---
type: plan
title: <Plan title>
description: One sentence — what this plan achieves.
tags: [plan]
timestamp: YYYY-MM-DD
status: open
owners: [human:<id>]
---

# <Plan title>

## Goal

## Steps
1. …

## Outcome (fill when done)
- ADR: `fdc/decisions/<file>.md`
- Runbooks / docs updated: …

## See also

- `fdc/briefs/<brief>.md` — the intent this plan implements, if any.
```

## Index

_No entries yet._
