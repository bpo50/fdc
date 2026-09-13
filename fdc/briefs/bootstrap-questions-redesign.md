---
type: brief
title: Redesign the bootstrap questions
description: Make the Step 0 questions of LLM_PROMPT self-describing, ordered by dependency, free of project-specific example text, with a machine-readable override for team + credentials A.
tags: [brief, bootstrap, prompt]
timestamp: 2026-09-13
status: done
owners: [human:bogdanpopa50]
---

# Redesign the bootstrap questions

## Intent
User: "I need the questions asked by the LLM to have more description and to not have text from my projects as example." Observed in a real bootstrap: eight one-line questions asked in one round, options compressed to two words, team and credentials A colliding after the fact, the LLM improvising a "deviation note", and the installer pre-filling policies before Step 0.

## Scope
- In scope: a `templates/SETUP_QUESTIONS.md` block inlined into the prompt (three rounds, consequences, defaults, config field per question); prompt rules to present it verbatim and never quote the target repo; `fdc.conf` ships with policies unset; `FDC_CREDENTIALS_OVERRIDE` as the only escape for team + A, enforced by the checker and reported by doctor; neutral `human:alice` placeholders in shipped templates.
- Out of scope: interactive prompts in `install.sh` (curl | bash has no tty); the update prompt flow beyond pointing at the new block.

## Known constraints
Bash 3.2; every template change must rebuild `LLM_PROMPT.md` and re-copy `scripts/`.

## Open questions
None.

## See also

- `fdc/decisions/2026-09-13-credentials-override-for-team-repos.md` — the override decision.
- `fdc/work/2026-09-13-bootstrap-questions.md` — the plan.
- `templates/templates.md` — where the question block lives.
