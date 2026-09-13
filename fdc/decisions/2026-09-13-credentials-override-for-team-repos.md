---
type: decision
title: Credentials override for team repos
description: Team repos that insist on credentials policy A must record the reason in FDC_CREDENTIALS_OVERRIDE; without it the drift checker refuses every commit.
tags: [architecture, credentials, bootstrap]
timestamp: 2026-09-13
status: accepted
not:
  - { term: "free-text deviation note in AGENTS.md", why: "invisible to tooling; each bootstrap improvises a different wording", instead: "FDC_CREDENTIALS_OVERRIDE in scripts/fdc.conf" }
  - { term: "unconditional refusal", why: "users overrode it anyway and the LLM had no defined path", instead: "one named escape with a written reason" }
---

# Credentials override for team repos

## Context
The prompt said "do not accept credentials policy A for a team". In practice a user reaffirmed A, the LLM wrote an ad-hoc deviation note, and nothing mechanical recorded it. `doctor` only warned.

## Options considered
- **Hard refusal, no escape** — consistent, but ignored in practice and leaves the LLM improvising.
- **Free-text note in AGENTS.md** — human-readable, invisible to tooling.
- **Config field with a reason, enforced by the checker** — auditable, one place, blocks commits until the choice is explicit.

## Decision
`FDC_CREDENTIALS_OVERRIDE="<reason>"` in `scripts/fdc.conf` is the only way to combine `FDC_TEAM=team` with `FDC_CREDENTIALS_POLICY=A`. `check-docs-fresh.sh` exits 1 without it; `fdc.sh doctor` prints the reason as a warning with it.

## Consequences
The bootstrap questions offer A to a team only with the override field spelled out. Policies ship unset in `fdc.conf` so the LLM cannot mistake a default for a decision.

## See also
- `fdc/briefs/bootstrap-questions-redesign.md`
- `METHODOLOGY.md` — Convention 7.
