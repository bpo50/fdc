---
type: decision
title: Run FDC on the FDC reference repo itself
description: The reference repo installs its own convention so the enforcement claim is demonstrated, not just described.
tags: [fdc, dogfooding, enforcement]
timestamp: 2026-09-11
status: accepted
generated: { by: claude-code/fable-5.1, at: 2026-09-11 }
sources:
  - { id: okf, resource: https://github.com/GoogleCloudPlatform/open-knowledge-format, title: Open Knowledge Format v0.2 }
not:
  - { term: "keep the reference repo docs-only", why: "contradicts the enforcement thesis", instead: "install FDC here; templates/ canonical" }
---

# Run FDC on the FDC reference repo itself

## Context

The methodology's thesis is that a doc convention only survives with mechanical enforcement. Until now this repo had no `AGENTS.md`, no installed hook, and no `/fdc/` — a credibility gap for anyone evaluating it.

## Options considered

- **Keep the repo docs-only.** Simpler, but contradicts the thesis.
- **Install FDC here, with `templates/` as source of truth and `scripts/` as the installed copy.** Small duplication, but every change to a template is now exercised by the hook on this repo.

## Decision

Install FDC here. `templates/scripts/` remains canonical; `scripts/` is a verbatim copy; `LLM_PROMPT.md` inlines the same files. `/fdc/` is tracked in git.

## Consequences

- Any script change now requires updating `templates/templates.md` or `scripts/scripts.md`, the inlined prompt, and the copy in `scripts/`. `AGENTS.md` lists these triggers.
- The drift checker has a behavioural test suite at `templates/scripts/tests/`; changes to the checker need a test first.

## See also

- `AGENTS.md` — the repo-specific triggers this decision introduces.
- `scripts/scripts.md` — the installed instance and its propagation rule.
- `templates/templates.md` — the source of truth.
