<!-- GENERATED FILE — do not edit LLM_PROMPT.md directly. Edit LLM_PROMPT.src.md or the files under templates/, then run: bash tools/build-prompt.sh -->
# LLM Prompt — Apply the Folder-Doc Convention (FDC) to This Repo

Paste this entire file into a fresh LLM session inside the target repository (Claude Code, Codex CLI, Copilot CLI, Cursor agent, Gemini CLI, etc.). The prompt is self-contained — it includes every template you'll need.

---

# YOUR TASK

You are going to set up the **Folder-Doc Convention (FDC)** in this repository. FDC is a documentation discipline for software repos where LLMs are regular contributors. The goal is to give every future agent session reliable, scoped, self-updating context, and to mechanically enforce that the docs stay in sync with the code.

Read this entire prompt before doing anything. Then follow the steps in order.

**Fast path.** If `scripts/fdc.sh` already exists (the user ran `install.sh`), the tooling is in place: skip the script-copying parts of Step 4 and only fill `scripts/fdc.conf`, then continue with the documentation steps. If it does not exist and the machine has `git` and `curl`, offer to run `curl -fsSL https://raw.githubusercontent.com/bpo50/fdc/main/install.sh | bash -s -- init` instead of copying the inlined scripts by hand — same result, fewer lines to paste. The inlined copies below are the offline fallback.

# THE CONVENTION IN ONE PARAGRAPH

Every folder gets one index doc named `<folder-name>.md`. The repo root has `AGENTS.md` (canonical operating rules for all agents) and `CLAUDE.md` (thin Claude-only addendum that points back to AGENTS.md). Long-form knowledge lives in `/fdc/{decisions,runbooks,troubleshooting,briefs}/`; every non-index long-form doc has required YAML frontmatter (`type`, `title`, `description`, `tags`, `timestamp`) and Markdown links to related docs. A pre-commit hook (`scripts/check-docs-fresh.sh`) fails any commit that touches code without touching the owning doc, and it validates all `/fdc/` long-form metadata. Doc updates are part of "definition of done" — a task is not complete until docs match.

# STEP 0 — Detect the project, confirm scope with the user

Before creating any files, run these commands and report the results to the user. Then ask for confirmation on what you'll create and where.

```bash
# Repo state
pwd
git rev-parse --is-inside-work-tree 2>/dev/null || echo "(not a git repo yet)"
git log --oneline -5 2>/dev/null || true
git status --short 2>/dev/null || true

# Existing rules files
ls -la AGENTS.md CLAUDE.md GEMINI.md .cursorrules .github/copilot-instructions.md 2>/dev/null || echo "(none yet)"

# Project type signals
ls -la
find . -maxdepth 2 -type f \( \
  -name 'package.json' -o -name 'Cargo.toml' -o -name 'composer.json' \
  -o -name '*.csproj' -o -name '*.fsproj' -o -name '*.sln' \
  -o -name 'angular.json' -o -name 'next.config.*' -o -name 'nuxt.config.*' \
  -o -name 'pyproject.toml' -o -name 'go.mod' -o -name 'Gemfile' \
  -o -name 'pubspec.yaml' \
  -o -name 'Dockerfile' -o -name 'docker-compose*.yml' -o -name 'compose*.y*ml' \
  -o -name '*.tf' -o -name 'ansible.cfg' -o -name 'inventory*' -o -name 'Chart.yaml' -o -name 'kustomization.y*ml' \
  \) -not -path './node_modules/*' -not -path './target/*' \
     -not -path './vendor/*' -not -path './bin/*' -not -path './obj/*' 2>/dev/null

# Folder structure to depth 3
find . -maxdepth 3 -type d \
  -not -path '*/.git/*' -not -path '*/node_modules/*' \
  -not -path '*/target/*' -not -path '*/vendor/*' \
  -not -path '*/dist/*' -not -path '*/build/*' \
  -not -path '*/.next/*' -not -path '*/.nuxt/*' \
  -not -path '*/bin/*' -not -path '*/obj/*' \
  | sort

# Planning-tool output (plans/specs that belong in fdc/work/, not in the knowledge layer)
ls -d docs/superpowers docs/plans .planning 2>/dev/null || echo "(no planning-tool folders)"

# Any existing markdown
find . -type f -name '*.md' \
  -not -path './node_modules/*' -not -path './vendor/*' \
  -not -path './target/*' -not -path './.git/*' \
  2>/dev/null | head -30
```

Then **report**:

1. **Detected project type(s).** One or more of: `.NET`, `Rust`, `Next.js`, `Angular`, `PHP`, `Python`, `Go`, `Ruby`, `Flutter/Dart`, `Ops/Infrastructure` (Ansible, Terraform, Helm, Kubernetes, Compose), `Monorepo`, `Other`. List them explicitly. Note if it's a polyglot monorepo with multiple stacks (e.g. Rust backend + Next.js frontend + Flutter mobile).

2. **Top-level folders you'll create indexes for.** Exclude `.git`, build/dependency caches, generated output. Show the user the list.

3. **Existing rules files.** If `AGENTS.md`, `CLAUDE.md`, `.cursorrules` etc. already exist with content, name them — you'll merge with them, not overwrite.

4. **Existing markdown that may conflict.** Especially `README.md` / `readme.md` files in subfolders that should be renamed under FDC.

5. **Planning-tool folders** (`docs/superpowers/`, `docs/plans/`, `.planning/`): their contents move to `fdc/work/` in Step 2 and the tool is pointed there from now on (`AGENTS.md` rule 15).

Then **ask the user**:

- "The folders I'll create indexes for are: \[list]. Anything to add or remove?"
- "Should `/fdc/` be tracked in git or gitignored (local-only)?"
- "Should `AGENTS.md` / `CLAUDE.md` themselves be tracked or gitignored?"
- "Are there folders I should explicitly NOT touch (third-party submodules, vendored code)?"
- "Solo or team? (**team** = more than one person commits here. Team ⇒ credentials policy must be B, the CI backstop is required, `fdc/log.md` is gitignored.)"
- "How many machines will you work from? (More than one ⇒ track all of `fdc/` in git; briefs and notes are the cross-machine handoff.)"
- "Credentials policy — **A** (write real values in each folder doc's `## Access` table; only for a private repo whose infrastructure is VPN/LAN-only and rotates often) or **B** (vault references only)?"
- "Commit policy — **A** (I commit verified milestones on the current branch, push when fast-forward, never rewrite history) or **B** (you commit; I stop at `git status`)?"

If the answer is **team**, do not accept credentials policy A — explain why (Convention 7) and use B.

**Wait for answers before proceeding.** Do not create files speculatively.

# STEP 1 — Create the rules files

## File 1: `AGENTS.md` at repo root

Use the template below. Fill placeholders (`{{ … }}`) with project-specific values. Keep section ordering.

For `{{CREDENTIALS_POLICY}}` and `{{COMMIT_POLICY}}` in "How to work in this repo": paste the **A** or **B** paragraph the user chose in Step 0 (both are in the HTML comment under each placeholder), then delete that comment. Do not leave the placeholder, and do not pick for the user.

> If `AGENTS.md` already exists with content, merge: keep existing content, prepend the FDC TOP PRIORITY section and the conventions, slot existing content into the right sections (Overview, Navigation, etc.).

````markdown
{{include:templates/AGENTS.md}}
````markdown

## File 2: `CLAUDE.md` at repo root (thin Claude addendum)

````markdown
{{include:templates/CLAUDE.md}}
````markdown

## File 3: `readme.md` at repo root (human entry point)

Short, human-facing. Links to AGENTS.md, CLAUDE.md, the top-level folder docs, and `fdc/fdc.md`. Project description in 1-3 sentences. Build/test/run commands. Nothing else — long stuff goes into the folder docs and `/fdc/`.

# STEP 2 — Create the `/fdc/` structure

```
fdc/
├── fdc.md
├── decisions/decisions.md
├── runbooks/runbooks.md
├── runbooks/onboard-developer.md      # shipped runbook: new teammate / new machine
├── troubleshooting/troubleshooting.md
├── briefs/briefs.md
├── notes/notes.md
└── work/work.md                       # ephemeral plans/specs — point planning tools here
```

Use these templates.

If this repo already has long-form docs (under `fdc/`, `docs/`, or a planning tool's output folder such as `docs/superpowers/plans/`), migrate every non-index file now:

- Add required YAML frontmatter (`type`, `title`, `description`, `tags`, `timestamp`).
- Ensure `type` matches the containing folder.
- Add or rename the relationship section to `## See also`.
- Link the doc from at least one relevant folder index doc.
- List the doc in the matching subfolder index (`bash scripts/fdc.sh index` does it).
- Give it a `status`. Ask the user for anything you cannot infer: a troubleshooting note is `resolved` if the fix section is filled and the problem is gone, `open` if it is a known-unresolved finding; a decision is `accepted` unless a later one replaces it (`superseded`); a brief is `done` if shipped.
- **Plans, specs, transcripts, and any "open findings register" are not knowledge.** Move plans/specs to `fdc/work/` with `type: plan` and `status: done` when complete. Split a findings register into one `fdc/troubleshooting/<symptom>.md` per item (`status: open` for unresolved, `resolved` for fixed) — `fdc.sh doctor` becomes the register. Then `bash scripts/fdc.sh archive --dry-run`, show the user the list, and archive on their yes.

Do not treat old files as grandfathered. FDC setup is incomplete until old and
new `/fdc/` long-form docs follow the same rules.

## `fdc/fdc.md`

````markdown
{{include:templates/fdc/fdc.md}}
````markdown

## `fdc/decisions/decisions.md`

````markdown
{{include:templates/fdc/decisions/decisions.md}}
````markdown

## `fdc/runbooks/runbooks.md`

````markdown
{{include:templates/fdc/runbooks/runbooks.md}}
````markdown

## `fdc/troubleshooting/troubleshooting.md`

````markdown
{{include:templates/fdc/troubleshooting/troubleshooting.md}}
````markdown

## `fdc/briefs/briefs.md`

````markdown
{{include:templates/fdc/briefs/briefs.md}}
````markdown

## `fdc/notes/notes.md`

````markdown
{{include:templates/fdc/notes/notes.md}}
````

## `fdc/work/work.md`

````markdown
{{include:templates/fdc/work/work.md}}
````

## `fdc/runbooks/onboard-developer.md`

Copy as-is; adjust the toolchain line if needed.

````markdown
{{include:templates/fdc/runbooks/onboard-developer.md}}
````

# STEP 3 — Create per-folder index docs

For every top-level folder in scope (per Step 0 confirmation), create `<folder-name>/<folder-name>.md` using the template below. Don't fabricate facts — for unknown sections, write a placeholder like `_TODO: describe X._`.

For deeper folders that contain non-trivial code or distinct concerns, recursively create indexes. Stop when a folder is purely data (`assets/`, `images/`, generated content) — that folder can share its parent's doc.

## Folder index template

````markdown
{{include:templates/folder-index.md}}
````markdown

# STEP 4 — Create the tooling

Six scripts, one config file, one versioned hook. **Never edit the scripts** in a downstream repo — they are upstream copies replaced by `fdc.sh update`; all settings go in `scripts/fdc.conf`.

## File: `scripts/fdc.conf` (the only file you configure)

Fill `FDC_UPSTREAM`, `FDC_TEAM`, and the two policies from Step 0. Add `CODE_REGEX` / `SKIP_*` overrides only if the shipped defaults (top of `check-docs-fresh.sh`) don't fit — see "Project-type-specific guidance".

```bash
{{include:templates/scripts/fdc.conf}}
```

## File: `.githooks/pre-commit` (versioned hook)

```bash
{{include:templates/.githooks/pre-commit}}
```

## File: `scripts/fdc.sh` (entry point)

```bash
{{include:templates/scripts/fdc.sh}}
```

## File: `scripts/check-docs-fresh.sh`

Use the template below. Adjust `CODE_REGEX` to match the project's language extensions (see "Project-type-specific guidance" further down).

```bash
{{include:templates/scripts/check-docs-fresh.sh}}
```bash

## File: `scripts/install-hook.sh`

Worktree- and submodule-safe installer (don't use a raw `ln -sf` symlink — it
breaks when `.git` is a file rather than a directory, and ignores `core.hooksPath`).

```bash
{{include:templates/scripts/install-hook.sh}}
```bash

Then activate:

```bash
chmod +x scripts/*.sh .githooks/pre-commit
bash scripts/fdc.sh install-hook      # sets core.hooksPath=.githooks for this clone
```

## File: `scripts/check-docs-ci.sh` (CI backstop — provider-neutral, recommended for teams)

The pre-commit hook is bypassable (`SKIP_DOC_CHECK=1` or `git commit --no-verify`).
On a shared repo, run this in CI to re-check the whole change at merge time, so a
local bypass is caught in review. It is **not** tied to any provider — it resolves
the base branch from common CI env vars (or `FDC_CI_BASE` / an argument) and works
in GitLab CI, Gitea/Forgejo, Woodpecker, Drone, Jenkins, Buildkite, Bitbucket, a
server-side hook, or a cron box. Skip it for solo repos.

```bash
{{include:templates/scripts/check-docs-ci.sh}}
```bash

Wire it into whatever CI the repo uses — the job is one line. Generic examples
(adapt to your system; do **not** assume GitHub):

```yaml
# GitLab CI (.gitlab-ci.yml)
check-docs-fresh:
  stage: test
  script: [ "bash scripts/check-docs-ci.sh" ]
```

```bash
# Any runner / server hook / cron — just call it; non-zero exit fails the job:
bash scripts/check-docs-ci.sh
```

## File: `scripts/fdc-graph.sh` (optional — knowledge graph from `/fdc/` metadata)

The typed frontmatter + `## See also` links in every `/fdc/` doc *are* a relationship
graph. This script extracts them into a dependency-free `graphify-out/fdc-graph.json`
that any graph tool can ingest. It is **optional and never part of the hook** — a
teammate with no graph tooling can ignore it; FDC works without it. If `FDC_GRAPH_CMD`
is set, the script hands the JSON to that command (wire your own tool, e.g. graphify);
teammates who don't set it just get the JSON. Portable (stock macOS bash 3.2 + Linux).

```bash
{{include:templates/scripts/fdc-graph.sh}}
```bash

Add `graphify-out/` to `.gitignore` (it's generated, per-user output — not shared).

## File: `scripts/fdc-stale.sh` (optional — staleness audit for runbooks and troubleshooting)

The drift checker proves a doc was *touched*; it cannot tell whether a runbook still works. This lists runbooks and troubleshooting notes whose `verified:` date (or `timestamp:` if absent) is older than `FDC_STALE_DAYS` (default 180). It never fails the build. Run it in CI for the report, or before an on-call rotation.

```bash
{{include:templates/scripts/fdc-stale.sh}}
```bash

## File: `scripts/fdc-log.sh` (optional — regenerate `fdc/log.md` from git)

Newest-first, date-grouped history of every commit that touched `/fdc/`, so an agent reading the knowledge layer sees what changed recently without running git. Generated, never hand-edited, never part of the hook.

```bash
{{include:templates/scripts/fdc-log.sh}}
```

And create `scripts/scripts.md`:

```markdown
# scripts

**Purpose:** Utility scripts, including the doc-drift check that enforces the TOP PRIORITY rule from `AGENTS.md`.

## Files

| Script | Purpose |
|---|---|
| `check-docs-fresh.sh` | Doc-drift + fdc-metadata check. Fails if code changes without updating the doc that owns it, or if a changed `/fdc/` doc lacks required frontmatter / `## See also`. |
| `install-hook.sh` | Installs `check-docs-fresh.sh` as a pre-commit hook (worktree- and submodule-safe). |
| `check-docs-ci.sh` | Provider-neutral CI backstop. Re-runs the check across the whole change (`base...HEAD`) with full-tree metadata validation. |
| `fdc-graph.sh` | Optional. Builds a portable knowledge graph (`graphify-out/fdc-graph.json`) from `/fdc/` frontmatter + `## See also` links. Not part of the hook; set `FDC_GRAPH_CMD` to post-process with your own tool. |
| `fdc-stale.sh` | Optional, never fails. Lists runbooks / troubleshooting notes whose `verified:` (or `timestamp:`) is older than `FDC_STALE_DAYS` (default 180) or past `stale_after:`; reports trust tier (unverified / machine-confirmed / human-reviewed) from `verified` actors. |
| `fdc-log.sh` | Optional. Regenerates `fdc/log.md` — newest-first history of `/fdc/` from git. |
| `fdc.sh` | Entry point for all of the above plus `doctor` (session-start self-heal), `update` (pull a tagged upstream release), `index` (regenerate `fdc/*/` index lists), `notes`, `whoami`. |
| `fdc.conf` | Per-repo settings. The only file to edit in this folder. |

`fdc.sh` also has `findings` (open troubleshooting notes), `archive --dry-run` / `archive` (end-state docs → `fdc/archive/`), `prune --dry-run` / `prune --yes` (delete old archive entries), and `budget` (the token-cost report).

## Daily use

```bash
bash scripts/fdc.sh doctor               # session start — hook, version, identity, open notes/briefs
bash scripts/fdc.sh check                # changed files only (what the hook runs)
FDC_VALIDATE_ALL=1 bash scripts/fdc.sh check   # audit the whole fdc/ tree
bash scripts/fdc.sh update               # newest tagged upstream scripts + hook; keeps fdc.conf
```

Run in CI (any provider):

```bash
bash scripts/check-docs-ci.sh
bash scripts/fdc-stale.sh     # optional report, never fails
```

Bypass for one commit (use sparingly, document why):

```bash
SKIP_DOC_CHECK=1 git commit -m "..."
```
```

# STEP 5 — Update `.gitignore`

Add the entries the user confirmed in Step 0. Common patterns:

```gitignore
# OS
.DS_Store
Thumbs.db

# Editor
.vscode/
.idea/

# LLM / agent session state (local-only)
.claude/
.remember/
.planning/

# Generated knowledge-graph output (per-user, not shared)
graphify-out/

# Team repos only: generated history conflicts on every merge; doctor regenerates it locally
# fdc/log.md

# (optional, per user choice)
# fdc/
# CLAUDE.md
# AGENTS.md
```

Don't add `fdc/`, `CLAUDE.md`, or `AGENTS.md` to gitignore without the user's explicit answer in Step 0.

# STEP 6 — Verify

Run these checks and report:

```bash
# 1. No stray README files for folder indexes (root readme.md is OK).
find . -type f \( -iname 'README.md' -o -iname 'readme.md' \) \
  -not -path './.git/*' -not -path './node_modules/*' \
  -not -path './vendor/*' -not -path './target/*' \
  -not -path './bin/*' -not -path './obj/*'

# 2. Every top-level folder has an index doc.
for d in $(find . -maxdepth 1 -type d -not -path '.' -not -name '.git' -not -name 'node_modules' -not -name 'vendor' -not -name 'target' -not -name 'bin' -not -name 'obj' -not -name 'dist' -not -name 'build' -not -name '.next' -not -name '.nuxt'); do
    base=$(basename "$d")
    if [ -f "$d/$base.md" ]; then
        echo "✓ $d/$base.md"
    else
        echo "✗ MISSING: $d/$base.md"
    fi
done

# 3. /fdc/ structure complete.
for f in fdc/fdc.md fdc/decisions/decisions.md fdc/runbooks/runbooks.md fdc/troubleshooting/troubleshooting.md fdc/briefs/briefs.md; do
    [ -f "$f" ] && echo "✓ $f" || echo "✗ MISSING: $f"
done

# 4. Existing long-form /fdc/ docs are migrated.
find fdc/decisions fdc/runbooks fdc/troubleshooting fdc/briefs -type f -name '*.md' 2>/dev/null \
  -not -name decisions.md -not -name runbooks.md -not -name troubleshooting.md -not -name briefs.md \
  -print

# 5. Tooling in place, hook active, config filled, drift check passes.
for f in scripts/fdc.sh scripts/fdc.conf scripts/check-docs-fresh.sh .githooks/pre-commit; do [ -e "$f" ] && echo "✓ $f" || echo "✗ MISSING: $f"; done
grep -q '{{' scripts/fdc.conf && echo "✗ scripts/fdc.conf still has placeholders" || echo "✓ fdc.conf filled"
bash scripts/fdc.sh doctor
FDC_VALIDATE_ALL=1 bash scripts/fdc.sh check && echo "✓ drift check passes" || echo "✗ drift check fails"
bash scripts/fdc.sh index >/dev/null && echo "✓ fdc index lists generated"
bash scripts/fdc.sh budget | sed -n '1,12p'
```

Report results. Fix anything marked `✗`. Re-run until clean.

# STEP 7 — Initial commit

If the repo is brand new, suggest staging and committing:

```bash
git add -A
git commit -m "$(cat <<'EOF'
chore: bootstrap Folder-Doc Convention (FDC)

- Add AGENTS.md as canonical agent operating rules.
- Add CLAUDE.md as thin Claude-only addendum.
- Add per-folder <folder>.md index docs across top-level folders.
- Add /fdc/ structure (decisions, runbooks, troubleshooting, briefs).
- Add scripts/check-docs-fresh.sh + pre-commit hook to enforce doc-sync.

See METHODOLOGY.md (in the FDC reference repo) for the full spec.
EOF
)"
```

If the repo already has history, do not commit unprompted — show the user `git status` and `git diff --stat` and ask whether they want you to commit.

---

# PROJECT-TYPE-SPECIFIC GUIDANCE

Use these to tailor the templates above. **Detect the project type from the signals in Step 0, then apply the relevant subsection.**

## .NET (C# / F#)

**Signals:** `*.sln`, `*.csproj`, `*.fsproj`, `Program.cs`, `global.json`, `nuget.config`.

**CODE_REGEX for drift checker:**
```
\.(cs|csproj|sln|fsproj|fs|fsx|json|yml|yaml|sh|ps1|xml|targets|props|Dockerfile|editorconfig)$
```

**Typical folder layout:**
```
src/
  <Project>/
  <Project.Library>/
tests/
  <Project>.Tests/
fdc/
scripts/
```

**Folder doc — Build/Test/Run:**
```bash
dotnet restore
dotnet build
dotnet test
dotnet run --project src/<Project>
dotnet format
```

**Things to surface in `<folder>.md` Gotchas:**
- Target framework (`net8.0`, `net9.0`).
- NuGet feeds (private feeds, auth).
- Build profiles / configurations (Debug, Release, custom).
- EF Core migrations location and command.

## Rust

**Signals:** `Cargo.toml`, `Cargo.lock`, `src/main.rs` or `src/lib.rs`, `rust-toolchain.toml`.

**CODE_REGEX:**
```
\.(rs|toml|yml|yaml|sh|Dockerfile|lock)$
```

**Typical folder layout:**
```
src/
tests/
examples/
benches/
fdc/
scripts/
```

For Cargo workspaces, every member crate is a folder with its own `<crate>.md`.

**Folder doc — Build/Test/Run:**
```bash
cargo build
cargo test
cargo run
cargo clippy --all-targets --all-features -- -D warnings
cargo fmt --check
```

**Things to surface:**
- MSRV (minimum supported Rust version) if pinned.
- Features and feature flags.
- Workspace membership.
- `cargo-nextest` / custom test runners.

## Next.js (App Router or Pages Router)

**Signals:** `next.config.{js,mjs,ts}`, `package.json` with `"next"` dep, `app/` or `pages/` folder.

**CODE_REGEX:**
```
\.(ts|tsx|js|jsx|mjs|cjs|json|yml|yaml|css|scss|html|sh|Dockerfile)$
```

**Typical folder layout (App Router):**
```
app/
components/
lib/
public/         # data-only — share parent's doc
styles/
tests/ (or __tests__/)
fdc/
scripts/
```

**Folder doc — Build/Test/Run:**
```bash
pnpm install        # or npm install / yarn / bun install
pnpm dev            # http://localhost:3000
pnpm build
pnpm start
pnpm test           # if configured
pnpm lint
```

**Things to surface:**
- Package manager (`pnpm` / `npm` / `yarn` / `bun`) — match what the lockfile shows.
- Node version (from `.nvmrc` or `engines`).
- Environment variables (`.env.local`, `.env.production`).
- Deployment target (Vercel, self-hosted, container).
- Server vs client component conventions.
- ISR / SSG / SSR strategy if non-default.

## Angular

**Signals:** `angular.json`, `package.json` with `@angular/core`, `src/app/`.

**CODE_REGEX:**
```
\.(ts|html|scss|sass|less|css|json|yml|yaml|sh|Dockerfile)$
```

**Typical folder layout:**
```
src/
  app/          # main app — has app/app.md
  assets/       # data-only
  environments/
e2e/ (or tests/)
projects/       # for monorepo / library projects
fdc/
scripts/
```

**Folder doc — Build/Test/Run:**
```bash
npm install     # or pnpm
ng serve        # http://localhost:4200
ng build
ng test
ng e2e
ng lint
```

**Things to surface:**
- Angular version (major matters a lot).
- Standalone vs NgModules.
- Workspace projects (`apps/`, `libs/`).
- Build configurations (`development`, `production`, custom).
- SSR (Angular Universal) if configured.

## PHP (vanilla / Symfony / Laravel)

**Signals:** `composer.json`, `composer.lock`, `artisan` (Laravel), `bin/console` (Symfony), `index.php` at root or `public/`.

**CODE_REGEX:**
```
\.(php|json|yml|yaml|blade\.php|twig|env|sh|Dockerfile|sql|xml|neon)$
```

**Typical folder layout (Laravel):**
```
app/
bootstrap/
config/
database/
public/         # data-only
resources/
routes/
storage/        # gitignored mostly
tests/
fdc/
scripts/
```

**Typical folder layout (Symfony):**
```
src/
config/
templates/
public/
tests/
fdc/
scripts/
```

**Folder doc — Build/Test/Run (Laravel):**
```bash
composer install
cp .env.example .env
php artisan key:generate
php artisan migrate
php artisan serve
./vendor/bin/phpunit
./vendor/bin/pint        # formatting if installed
```

**Folder doc — Build/Test/Run (Symfony):**
```bash
composer install
bin/console doctrine:migrations:migrate
symfony server:start
./vendor/bin/phpunit
./vendor/bin/php-cs-fixer fix
```

**Things to surface:**
- PHP version requirement.
- Framework version (Laravel 11, Symfony 7, etc.).
- Database (MySQL, PostgreSQL, SQLite).
- Queue/cache drivers.
- `.env` shape and which keys are required.

## Flutter / Dart

**Signals:** `pubspec.yaml`, `pubspec.lock`, `lib/main.dart`, `.dart_tool/`, `android/` + `ios/` sibling folders, `analysis_options.yaml`.

**CODE_REGEX:**
```
\.(dart|yaml|yml|json|sh|Dockerfile)$
```
Add `kt|kts|gradle|swift|h|m|plist` only if you actually hand-edit the native shells under `android/` and `ios/` (most Flutter work doesn't).

**Skip rules (important — Flutter generates a lot):**
- `SKIP_FILE_REGEX` must include `pubspec\.lock` (generated; never document it).
- `SKIP_FOLDER_REGEX` must include `\.dart_tool/`, `build/`, and `\.fvm/`. Also skip `android/` and `ios/` unless you maintain native code there — they're mostly tool-generated.
- The shipped `check-docs-fresh.sh` defaults already include `dart`, `pubspec.lock`, `.dart_tool/`, and `.fvm/`.

**Typical folder layout:**
```
lib/            # Dart source — lib/lib.md
  src/
  features/
test/           # tests
assets/         # data-only — share parent's doc
android/        # native shell — usually skip
ios/            # native shell — usually skip
fdc/
scripts/
```

**Folder doc — Build/Test/Run:**
```bash
flutter pub get
flutter run                # device/emulator
flutter test
flutter analyze
dart format --output=none --set-exit-if-changed .
flutter build apk          # or appbundle / ios / web
```

**Things to surface in `<folder>.md` Gotchas:**
- Flutter/Dart SDK version (`environment:` in `pubspec.yaml`, or `.fvmrc` / `.fvm/`).
- State management choice (Riverpod, Bloc, Provider, …).
- Codegen: `build_runner` and the `*.g.dart` / `*.freezed.dart` files it produces (generated — don't hand-edit, don't document individually).
- How the app points at the backend (base URL / env / `--dart-define`).
- Platform-specific build steps or signing notes.

## Ops / Infrastructure (Ansible, Terraform, Helm, Kubernetes, Compose, systemd)

**Signals:** `ansible.cfg`, `inventory*`, `playbooks/`, `roles/`, `*.tf`, `*.tfvars`, `.terraform.lock.hcl`, `Chart.yaml`, `values*.yaml`, `kustomization.yaml`, `docker-compose*.yml` / `compose*.yml`, `*.service`, `*.j2`.

**CODE_REGEX (add to whatever app languages are present):**
```
\.(yml|yaml|json|toml|sh|py|tf|tfvars|hcl|tpl|j2|conf|ini|cfg|properties|service|timer|env|Dockerfile)$
```
The shipped default already includes all of these, and `CODE_BASENAME_REGEX` covers `Dockerfile`, `Makefile`, `Justfile`, `Vagrantfile`, and `.env*` without an extension.

**Skip rules:** `.terraform/`, `.vagrant/`, `.ansible/` (facts/retry files), `.venv/`, `__pycache__/` are in the shipped `SKIP_FOLDER_REGEX`. Add `roles/<vendored-role>/` for Galaxy roles you don't maintain, and any `charts/*/charts/` dependency folder.

**Typical folder layout:**
```
inventories/      # per-environment inventories — inventories/inventories.md lists every env
playbooks/        # entry points — one row per playbook with what it touches
roles/            # roles/roles.md; each maintained role gets roles/<role>/<role>.md
terraform/        # or infra/ — one <folder>.md per root module / workspace
helm/ or k8s/     # charts / manifests — per-chart doc
compose/          # per-stack compose files
scripts/          # includes the FDC drift checker
fdc/
```

**Folder doc — Commands (examples; use the repo's real ones):**
```bash
ansible-playbook -i inventories/prod playbooks/site.yml --check --diff
terraform -chdir=terraform/prod plan
helm upgrade --install <release> ./helm/<chart> -f values-prod.yaml --dry-run
kubectl --context prod diff -k k8s/overlays/prod
docker compose -f compose/app.yml config
```

**Fill the `## Targets` and `## Access` sections in every ops folder doc.** Targets: hosts, clusters, accounts, the environment each maps to, and how it is reached (ssh alias, kubeconfig context, cloud profile) — an agent must be able to read the blast radius before it runs anything. Access: one row per service with user, secret (value under credentials policy A, `<vault: item>` under B), and the `Rotated on` date.

**Things to surface in `<folder>.md` Gotchas:**
- Which environments are real and which are safe to break. Which commands are read-only (`--check`, `plan`, `diff`, `--dry-run`) versus mutating.
- State backends (Terraform remote state, locks), and what happens if a run is interrupted.
- Secrets mechanism (Vault, sops, ansible-vault, sealed-secrets) and where the key lives.
- Ordering constraints between folders (network before compute, CRDs before charts).
- Tool version pins (`.terraform-version`, `requirements.yml`, Helm/kubectl versions).

**`/fdc/` usage in ops repos is heavier than in app repos.** Every procedure you run more than once is a runbook with `verified: { by: human:<who>, at: <date> }` (an agent-written runbook nobody has run stays *machine-confirmed* or *unverified* in the audit — that distinction matters at 3 a.m.); every incident becomes a troubleshooting note the same day, with `sources:` pointing at the ticket and `not:` listing the fixes that did not work. Run `bash scripts/fdc-stale.sh` before on-call rotations or in CI to see what has not been verified in 180 days.

## Monorepos (Turborepo / Nx / pnpm workspaces / Cargo workspaces / polyglot)

**Signals:** `turbo.json`, `nx.json`, `pnpm-workspace.yaml`, multiple `package.json` / `Cargo.toml`, top-level `apps/` + `packages/`, or **multiple stacks side by side** (e.g. a Rust/Axum backend + a Next.js frontend + a Flutter app in one repo).

**Apply FDC at two levels:**

1. **At the monorepo root**: standard AGENTS.md, CLAUDE.md, /fdc/, scripts/. Navigation lists the top-level folders (`apps/apps.md`, `packages/packages.md`).
2. **Inside each app / package**: each gets its own `<package-name>.md` plus its own `src/src.md`, `tests/tests.md`, etc.

**CODE_REGEX** should union all the languages present in the monorepo. For a Rust + Next.js + Flutter repo, that's:
```
\.(rs|toml|ts|tsx|js|jsx|mjs|cjs|dart|json|yml|yaml|css|scss|sh|sql|Dockerfile)$
```
And the skip lists must cover every stack's generated artifacts: `SKIP_FILE_REGEX` → the JS lockfiles + `Cargo.lock` + `pubspec.lock`; `SKIP_FOLDER_REGEX` → `node_modules/`, `.next/`, `target/`, `.dart_tool/`, `.fvm/`, `build/`. (The shipped defaults already include all of these.)

**Each app keeps its OWN Build/Test/Run** in its `<folder>.md` — `cargo …` for the backend, the right package manager for the frontend (match the lockfile), `flutter …` for mobile. Don't put a single global build section at the root; per-stack commands belong in per-stack docs.

**Cross-stack contracts are the high-value case.** When the same change spans stacks (e.g. an API field that the Axum backend serves and both the Next.js and Flutter clients consume), record it as an ADR in `fdc/decisions/` and link it from all affected app docs' `## See also`. In one monorepo, an LLM can make that change atomically in a single commit and `rg` the identifier across all stacks; `scripts/fdc-graph.sh` then shows one node with edges into every consumer. This is the main reason a polyglot product is better kept in one repo for LLM-driven work.

**Things to surface in the root AGENTS.md:**
- Workspace tool (turbo, nx, pnpm, lerna, cargo) if any, or just the list of stacks if it's a plain side-by-side layout.
- Cross-package / cross-stack commands.
- Which packages publish, which are internal-only.

---

# RULES OF ENGAGEMENT FOR YOU (THE LLM RUNNING THIS PROMPT)

1. **Confirm before mass-creating files.** Step 0 must complete and the user must answer the questions before Step 1.

2. **Don't fabricate facts.** If you don't know the build command, the database, the env vars, or what a folder does, write `_TODO: describe._` in the doc and surface it in your report. Do not invent.

3. **Preserve existing content.** If `AGENTS.md`, `CLAUDE.md`, `README.md`, or any folder doc already exists with content, merge — don't overwrite. Show the user the merge diff before applying.

4. **Don't commit during bootstrap.** Show `git status` and `git diff --stat` and ask before running `git commit`, whatever commit policy the user chose for daily work — the bootstrap diff is large and they should see it. Exception: if the repo has no commits yet (fresh `git init`), suggest the initial commit but still wait for confirmation.

5. **The credentials policy is the user's choice (Step 0), not yours.** Under policy A, move any credentials you find into the owning folder doc's `## Access` table with a `Rotated on` date. Under policy B, replace them with `<vault: item>` references and tell the user which values you removed.

6. **Respect gitignored areas.** Don't create docs inside `.git/`, `node_modules/`, `target/`, `vendor/`, etc. The drift checker's `SKIP_FOLDER_REGEX` lists the standard ones — match it.

7. **Stop and ask if anything is ambiguous.** It's cheaper to ask than to guess wrong and then redo.

8. **Report at the end.** Tell the user exactly what you created, what's pending, and what they need to verify or run themselves (install pre-commit hook, push to remote, etc.).

After bootstrap, the rules that govern daily work are the ones you just wrote into `AGENTS.md` → "How to work in this repo". Read them back before your report; they apply to you from now on.

---

# WHAT "DONE" LOOKS LIKE

When you finish this prompt's work, the repo should have:

- [ ] `AGENTS.md` at root with the TOP PRIORITY rule, the behaviour contract with both policies filled (no `{{ … }}` left), and a populated Navigation / Build-Test-Run section.
- [ ] `CLAUDE.md` at root pointing back to AGENTS.md.
- [ ] `readme.md` at root — short, human-facing entry point.
- [ ] `fdc/` with seven index files (`fdc.md` + six subindexes incl. `work/`) and the onboarding runbook.
- [ ] Every existing long-form doc has a `status`; plans/specs are in `fdc/work/`; any findings register is split into `fdc/troubleshooting/` notes; `fdc.sh budget` shows the active layer under `FDC_BUDGET_TOTAL_LINES` (or the user has seen the number).
- [ ] Every existing non-index `/fdc/` long-form doc has required frontmatter and `## See also`.
- [ ] Per-folder `<folder>.md` index in every top-level folder in scope.
- [ ] `scripts/fdc.sh`, `scripts/fdc.conf` (no `{{ }}` left), all six sibling scripts (executable), `scripts/scripts.md`, `.githooks/pre-commit`.
- [ ] Hook active: `git config core.hooksPath` = `.githooks` (`fdc.sh doctor` says OK).
- [ ] (Teams) `scripts/check-docs-ci.sh` wired into CI as a required check; PR template in place; `fdc/log.md` gitignored.
- [ ] `graphify-out/` added to `.gitignore` (if `fdc-graph.sh` is used).
- [ ] `.gitignore` updated per user's Step 0 answers.
- [ ] `bash scripts/check-docs-fresh.sh` exits 0.
- [ ] No stray `README.md` / `readme.md` inside subfolders (only root `readme.md`).

Then report to the user:

> FDC bootstrap complete. Files created: \[count]. Folder indexes: \[count]. Drift check: passing. Pre-commit hook: installed.
>
> Next steps for you:
> - On every other machine / clone: `bash scripts/fdc.sh doctor` once (it activates the hook there).
> - Review `AGENTS.md` and fill in any `_TODO:_` placeholders I left.
> - Review folder index docs the same way.
> - Commit when you're ready.
> - If you want `/fdc/` or `CLAUDE.md` / `AGENTS.md` to stay local-only, confirm `.gitignore` entries are present.

---

# END OF PROMPT
