---
type: runbook
title: Onboard a developer (or a new machine)
description: Clone, activate the FDC hook, read the rules, verify the toolchain — the same steps for a new teammate and for your own second laptop.
tags: [onboarding, fdc]
timestamp: 2026-09-11
owners: [anyone]
---

# Onboard a developer (or a new machine)

**When to use:** first checkout of this repo on any machine.
**Owner / on-call:** anyone.
**Estimated time:** 5 minutes.

## Prerequisites
- git, bash (Git Bash on Windows), and the project toolchain from `AGENTS.md` → Build / Test / Run.
- `git config user.email` set to your real address — `fdc.sh whoami` derives your `human:<id>` from it and every `verified:` / `from:` uses it.

## Steps
1. Clone and enter the repo.
2. Activate the versioned pre-commit hook and check the clone:
   ```bash
   bash scripts/fdc.sh doctor
   ```
   Expected: `hook FIXED set core.hooksPath=.githooks` on the first run, `OK` afterwards; your identity printed; no `WARN` about a newer upstream version (if there is one, run `bash scripts/fdc.sh update`).
3. Read `AGENTS.md` top to bottom once. It is short on purpose. Note the credentials and commit policies in "How to work in this repo".
4. Open the folder docs for the areas you will work in; each `<folder>/<folder>.md` is a two-minute read.
5. Check for anything addressed to you:
   ```bash
   bash scripts/fdc.sh notes
   ```

## Verification
`bash scripts/fdc.sh check` exits 0 on a clean tree, and a deliberate code-only change (touch a source file, `git add`, `git commit`) is blocked by the hook. Undo the test change.

## Rollback
Nothing to roll back; `git config --unset core.hooksPath` deactivates the hook.

## See also

- `AGENTS.md` — the rules this runbook points you at.
- `fdc/fdc.md` — the knowledge layer you will read and write.
