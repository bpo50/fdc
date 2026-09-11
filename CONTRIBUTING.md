# Contributing

This repo runs FDC on itself, so the rules in `AGENTS.md` apply to you and to any agent you use.

- **Source of truth is `templates/`.** `LLM_PROMPT.md` is generated (`bash tools/build-prompt.sh`); `scripts/`, `.githooks/`, and `fdc/` here are installed copies. Edit upstream, regenerate/copy downstream.
- **Scripts are test-first.** Every behaviour change to `templates/scripts/*.sh` starts with a failing test in `templates/scripts/tests/`. Run them all: `for t in templates/scripts/tests/*.test.sh; do bash "$t"; done`.
- **Portability is a hard rule.** Stock macOS `/bin/bash` 3.2, BSD *and* GNU awk/sed/grep, Git Bash on Windows. No `declare -A`, `mapfile`, `${var,,}`, `sed -i` without an argument, `grep -P`.
- **Version stamps.** A material change to a script or to `templates/AGENTS.md` bumps `fdc-version` everywhere to today's date (`YYYY.MM.DD`) and `FDC_VERSION` in `templates/scripts/fdc.conf`; `version-stamps.test.sh` fails otherwise. A release is a git tag with that value, **and the `latest` tag moved to the same commit** (`git tag -f latest <version> && git push -f origin latest`); the README's LLM one-liner fetches `latest`.
- **Commits.** Imperative subject, body says what changed and what was verified.
- **Friction budget.** A change that makes the hook fail more often needs a stronger reason than one that makes it fail less. Hard gates only where a wrong answer is expensive; everything else is a report.
