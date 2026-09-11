#!/usr/bin/env bash
# (#14) LLM_PROMPT.md must be exactly what tools/build-prompt.sh generates.
set -u
here=$(cd "$(dirname "$0")" && pwd); root=$(cd "$here/../../.." && pwd); cd "$root"
if bash tools/build-prompt.sh --check >/dev/null; then echo "PASS  LLM_PROMPT.md is generated from templates"; echo; echo "1 passed, 0 failed"
else echo "FAIL  LLM_PROMPT.md is stale — run: bash tools/build-prompt.sh"; echo; echo "0 passed, 1 failed"; exit 1; fi
