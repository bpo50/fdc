# Backlog — deferred FDC recommendations

Ideas surfaced during review that we consciously decided **not** to implement yet.
Captured here so they aren't lost. None are blocking; the convention works without them.

## 1. Split metadata-validation from drift-checking into separate scripts

**Why:** `check-docs-fresh.sh` now does two jobs — "did you update the owning doc?"
(changed-file scope) and "is each changed `/fdc/` doc well-formed?" (metadata). They
work fine together, but single-responsibility would be cleaner.

**Proposed:** factor metadata validation into `check-fdc-meta.sh`, called by the hook
alongside `check-docs-fresh.sh`. Cosmetic; only worth it if the script grows further.

---

*Implemented already (for reference, not deferred): owner-based drift check, bash-3.2
portability, provider-neutral CI backstop (`check-docs-ci.sh`), changed-vs-all metadata
scoping (`FDC_VALIDATE_ALL`), validator hardening (tags/See-also/CRLF/nested), optional
knowledge-graph extractor (`fdc-graph.sh`), Flutter/Dart support, nested-folder skip
fix for monorepos, staleness audit (`fdc-stale.sh`, `verified:` field), ops-stack guidance, `Targets` section in folder docs, required `status` on decisions/briefs, `Skip-Doc-Check:` trailer honoured in CI, hook installer append/symlink handling, soft intent hint in CI, version-stamp test, prompt generated from `templates/` (`tools/build-prompt.sh`), slimmer AGENTS template, team/solo at bootstrap, `fdc.conf` manifest, `fdc.sh` entry point with `doctor`/`update`/`index`/`notes`, versioned `.githooks/`, notes type, handoff briefs, onboarding runbook, PR template, `install.sh`, compaction (lifecycle end states, `fdc/work/`, `archive`/`prune`, findings view, `budget`, read budget).*
