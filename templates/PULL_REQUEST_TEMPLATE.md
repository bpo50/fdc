<!-- Team repos: copy to .github/PULL_REQUEST_TEMPLATE.md, .gitlab/merge_request_templates/default.md, or your forge's equivalent. Mirrors the AGENTS.md definition of done so reviewers check docs like code. -->

## What

<!-- one paragraph -->

## Definition of done (AGENTS.md → TOP PRIORITY)

- [ ] Every touched folder's `<folder>.md` reflects the new reality.
- [ ] Cross-references updated (`rg <changed-identifier>`).
- [ ] New decision / runbook / troubleshooting / brief in `fdc/` where warranted, with frontmatter and `## See also`.
- [ ] `bash scripts/fdc.sh check` passes; CI backstop green.
- [ ] Any `Skip-Doc-Check:` trailer carries a reason a reviewer agrees with.
- [ ] Runbooks touched here have been **run**, and `verified:` says by whom.

## Reviewer notes

<!-- CODEOWNERS tip: map each `<folder>/<folder>.md` to the folder's owners so doc changes route to the people who know the area. -->
