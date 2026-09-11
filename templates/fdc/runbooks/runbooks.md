# runbooks

**Purpose:** Step-by-step operational procedures that need to be reliable under pressure.

**Naming:** `<action>-<thing>.md` (e.g. `deploy-staging.md`, `rotate-db-password.md`, `recover-failed-migration.md`). Verb first, noun second, kebab-case.

## Template

```markdown
---
type: runbook
title: <Runbook title>
description: One sentence describing the procedure and when to use it.
tags: [operations]
timestamp: YYYY-MM-DD
verified: { by: human:<you>, at: YYYY-MM-DD }   # or a bare date; list form for several checks
owners: [anyone]
---

# <Runbook title>

**When to use:** the trigger condition.
**Owner / on-call:** who runs this. If anyone, say "anyone".
**Estimated time:** ballpark.
**Last verified:** update `verified:` each time you actually run this end to end (`{ by: human:<you>, at: <date> }`). `scripts/fdc-stale.sh` flags it after 180 days, or after `stale_after:` if you set one (e.g. yearly cert rotation → `stale_after` = next rotation).

## Prerequisites
- Access requirements
- Tools / credentials needed

## Steps
1. Step with the exact command.
   ```bash
   <command>
   ```
   Expected output: …
2. Next step.

## Verification
How to confirm success.

## Rollback
If a step fails, how to undo.

## See also

- `<folder>/<folder>.md` — system area this procedure operates on.
- `fdc/troubleshooting/<related>.md` — failure mode this procedure resolves, if any.
```

## Index

_No runbooks yet._
