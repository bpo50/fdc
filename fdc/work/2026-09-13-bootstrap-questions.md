---
type: plan
title: Bootstrap questions redesign
description: Steps to ship the SETUP_QUESTIONS block, unset policies in fdc.conf, and the credentials override.
tags: [plan]
timestamp: 2026-09-13
status: done
owners: [human:bogdanpopa50]
---

# Bootstrap questions redesign

## Goal
See `fdc/briefs/bootstrap-questions-redesign.md`.

## Steps
1. Tests: checker fails on team + A without override; passes with override; doctor reports unset policies.
2. `fdc.conf`: policies unset, `FDC_CREDENTIALS_OVERRIDE` added.
3. `check-docs-fresh.sh` + `fdc.sh doctor`: enforce and report.
4. `templates/SETUP_QUESTIONS.md`; Step 0 / Step 1 / rules of engagement in `LLM_PROMPT.src.md`.
5. `templates/AGENTS.md` policy A comment mentions the override; `human:alice` placeholders.
6. Bump stamps, rebuild prompt, copy scripts, update docs, run suites.

## Outcome (fill when done)
- ADR: `fdc/decisions/2026-09-13-credentials-override-for-team-repos.md`
- Docs updated: `templates/templates.md`, `scripts/scripts.md`, `METHODOLOGY.md`, `README.md`.

## See also

- `fdc/briefs/bootstrap-questions-redesign.md`
