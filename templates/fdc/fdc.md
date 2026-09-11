# fdc

**Purpose:** The FDC knowledge layer — long-form knowledge that doesn't belong inside any single folder's index doc: architectural decisions, operational runbooks, troubleshooting playbooks, and requirement briefs.

> Named `fdc/` (not `docs/`) on purpose: it won't collide with an existing `docs/` doc-site, it names exactly what it is, and it stays *visible* (a hidden `.fdc/` would be skipped by `rg`/`find` defaults, breaking the cross-reference checks this convention depends on).

**Tracking:** {{TRACKED_OR_GITIGNORED}}. <!-- "Tracked in git" or "Local-only, gitignored". Pick per repo. -->

## Subfolders

| Folder | Holds | Naming convention |
|---|---|---|
| `decisions/` | ADRs — architectural decisions with rationale and tradeoffs. | `YYYY-MM-DD-<short-title>.md` |
| `runbooks/` | Step-by-step operational procedures. | `<action>-<thing>.md` |
| `troubleshooting/` | Symptom → cause → fix pages for issues that have happened. | `<symptom>.md` |
| `briefs/` | Requirement briefs / scoping docs not yet implemented; also session handoffs (`status: claimed`). | `<topic>.md` |
| `notes/` | Short messages to a person, the team, or yourself on another machine. Delivered by `fdc.sh doctor`, closed when acted on. | `<topic>.md` |
| `work/` | **Ephemeral**: plans, specs, session scratch. Not read by default. Done plans leave a ≤1-ADR outcome and get archived. | `YYYY-MM-DD-<topic>.md` |
| `archive/<type>/` | End-state docs moved by `fdc.sh archive`. Kept for history; **never read, validated, indexed, or audited by default.** | mirrors the source folder |

## When to create a doc here

See `AGENTS.md` → "Creating docs in /fdc/" for the full rule. In short:

- **Decision** — significant architectural / operational choice with tradeoffs.
- **Runbook** — multi-step operational procedure.
- **Troubleshooting** — a problem has been diagnosed; capture it.
- **Brief** — a feature/setup described but not yet built, or work you are handing off (`claimed`, with `## Where I stopped` / `## Next steps`).
- **Note** — something a specific person (or the team, or you-on-another-machine) must read. Not a wiki page; see `notes/notes.md` for the exit rules.

**Rule:** every non-index doc MUST have required YAML frontmatter, a `## See also` section, a link from at least one folder index doc, and an entry in the matching subfolder's index.

## Required frontmatter

Every non-index Markdown file under these subfolders is a typed concept:

```yaml
---
type: decision | runbook | troubleshooting | brief
title: Short human title
description: One sentence describing what this document captures.
tags: [tag-one, tag-two]
timestamp: YYYY-MM-DD
---
```

The `type` must match the containing folder:

- `decisions/` → `type: decision`
- `runbooks/` → `type: runbook`
- `troubleshooting/` → `type: troubleshooting`
- `briefs/` → `type: brief`
- `notes/` → `type: note` (also requires `from`, `to`, `status`)
- `work/` → `type: plan` (requires `status`)
- `archive/**` → exempt; frontmatter is whatever it was when archived

`status` is **required** on decisions (`proposed | accepted | superseded | rejected`) and briefs (`open | done | dropped`); it is what gives `supersedes` / `superseded_by` meaning. Other optional fields when useful: `status`, `owners`, `related`, `resource`, `supersedes`, `superseded_by`, and `verified` (date a runbook/troubleshooting note was last confirmed to work; audited by `scripts/fdc-stale.sh`).

## Lifecycle and compaction

Every doc has a `status`; the status decides whether it is *current knowledge* or *history*:

| Type | Current | End state (archives after `FDC_ARCHIVE_DAYS`) |
|---|---|---|
| decision | `proposed`, `accepted` | `superseded`, `rejected` |
| troubleshooting | `open` (= a finding, surfaced by `doctor`), | `resolved`, `accepted` |
| brief | `open`, `claimed` | `done`, `dropped` |
| note | `open` | `read`, `done` |
| plan (`work/`) | `open` | `done`, `dropped` |
| runbook | (no status, or `active`) | `retired` |

`bash scripts/fdc.sh archive --dry-run` shows what would move; `archive` moves it (`git mv`) into `fdc/archive/<type>/`. `fdc.sh prune --yes` deletes archive entries older than `FDC_PRUNE_DAYS` — git history keeps them. `fdc.sh budget` reports lines per area and docs over budget; `doctor` warns when the active layer exceeds `FDC_BUDGET_TOTAL_LINES`. The goal: a session's default context is a few hundred lines, however old the repo gets.

## Provenance, trust, and freshness (optional, OKF-aligned)

These optional fields follow the [Open Knowledge Format](https://github.com/GoogleCloudPlatform/open-knowledge-format) v0.2 conventions so an `/fdc/` tree can be read by OKF tooling and so an agent can tell *who* stands behind a doc:

```yaml
generated: { by: claude-code/fable-5.1, at: 2026-09-11 }   # who/what wrote the current content
verified:                                                  # who confirmed it against reality (latest wins)
  - { by: claude-code/fable-5.1, at: 2026-09-01 }
  - { by: human:bogdan, at: 2026-09-11 }
stale_after: 2027-03-01          # absolute date; overrides the global staleness threshold for this doc
sources:                         # what this doc was derived from (ticket, vendor page, commit, another fdc doc)
  - { id: incident-42, resource: https://tracker/…/42, title: Incident 42 }
  - { id: rb, resource: fdc/runbooks/rotate-db-password.md, title: Rotation runbook }
not:                             # what this is NOT — stops the next session re-proposing a rejected approach
  - { term: "restart the pod", why: "masks the leak; recurred within an hour", instead: "raise the memory limit and fix the retry loop" }
```

- **Actors:** `human:<id>` for people, `<agent>/<version>` for LLM agents, `process:<id>` for automation. `scripts/fdc-stale.sh` derives a trust tier from `verified`: no entry → *unverified*; only non-human actors → *machine-confirmed*; any `human:` → *human-reviewed*. A bare date (`verified: 2026-09-11`) is still accepted and counts as machine-confirmed.
- **Per-claim attribution:** cite a source in the body with a footnote keyed to its `id`: `…the export is sharded daily.[^incident-42]`.
- **`timestamp`** may be a date or a full ISO datetime (`2026-09-11T10:00:00Z`); only the date part is validated.
- `sources[].resource` values become edges in `scripts/fdc-graph.sh`; `fdc/log.md` (generated by `scripts/fdc-log.sh`) is the newest-first change history of this folder.

## Relationship links

Each long-form doc ends with `## See also` and normal Markdown links to related folder docs or other `/fdc/` docs. These links are the project knowledge graph.

## Index files

- `decisions/decisions.md` — list of ADRs.
- `runbooks/runbooks.md` — list of runbooks.
- `troubleshooting/troubleshooting.md` — list of troubleshooting pages.
- `briefs/briefs.md` — list of open briefs.
- `notes/notes.md` — list of notes.

The `## Index` section of each is **generated** by `bash scripts/fdc.sh index` from frontmatter — do not hand-edit it (hand-maintained lists are the most conflict-prone file in a team repo).
