# decisions

**Purpose:** Architecture Decision Records (ADRs). Each file captures one significant choice: context, options considered, decision, consequences.

**Naming:** `YYYY-MM-DD-<short-kebab-title>.md`.

**Status (required):** `proposed` → `accepted` (or `rejected`); `superseded` when a later ADR replaces it (set `superseded_by`).

## Template

```markdown
---
type: decision
title: <Decision title>
description: One sentence describing the choice and the problem it resolves.
tags: [architecture]
timestamp: YYYY-MM-DD
status: proposed
# sources: [{ id: <key>, resource: <url|path>, title: <label> }]   # optional provenance; cite in body as [^<key>]
# not: [{ term: <rejected approach>, why: <reason>, instead: <what to do> }]   # optional; stops re-litigation
---

# <Decision title>

## Context
What problem are we solving? What constraints apply?

## Options considered
- **Option A** — pros / cons.
- **Option B** — pros / cons.

<!-- Rejected options belong in `not:` too, so an agent grepping frontmatter sees them without reading the body. -->

## Decision
What was chosen and why.

## Consequences
What changes downstream. What we now have to maintain or watch for.

## See also

- `<folder>/<folder>.md` — affected implementation area.
- `fdc/runbooks/<related>.md` — related procedure, if any.
```

## Index

- 2026-09-11 — [Run FDC on the FDC reference repo itself](2026-09-11-dogfood-fdc-in-reference-repo.md) — The reference repo installs its own convention so the enforcement claim is demonstrated, not just described. (`accepted`)
- 2026-09-13 — [Credentials override for team repos](2026-09-13-credentials-override-for-team-repos.md) — Team repos that insist on credentials policy A must record the reason in FDC_CREDENTIALS_OVERRIDE; without it the drift checker refuses every commit. (`accepted`)
