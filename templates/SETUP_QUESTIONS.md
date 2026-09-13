# Bootstrap questions

Ask these in **three rounds**, in this order. Each round waits for answers before the next one is shown, because later options depend on earlier answers. Present every block **as written here**: the question, all options with their consequence line, the default, and what changes later. Do not shorten the options to a word or two, and do not add examples taken from the repository you are bootstrapping — describe a conflict with the repo's existing files in one neutral sentence, never by quoting them.

Each block names the config field it writes (`scripts/fdc.conf`) so the answer lands in exactly one place.

---

## Round 1 — Scope

### Q1. Which folders get an index doc?

> The folders I will create `<folder-name>.md` in are: `[list from Step 0]`.
> Anything to add or remove?

- **Why it matters:** every listed folder gets a doc the pre-commit hook will insist on keeping in sync. Folders left out are invisible to future agent sessions.
- **Default:** every top-level folder that holds code or configuration. Never build caches, dependency folders, or generated output.
- **Later change:** cheap. Add a folder doc any time; the hook starts enforcing it on the next commit.
- **Writes:** nothing in the config; it decides which files Step 3 creates.

### Q2. Any folders I must not touch?

> Are there folders I should leave exactly as they are, such as vendored third-party code, git submodules, or generated trees?

- **Why it matters:** those folders get no index doc and are excluded from the drift check, so a change there never asks for a doc update.
- **Default:** none beyond the standard skip list (dependency and build folders).
- **Later change:** cheap. Add the path to `SKIP_FOLDER_REGEX` in the config.
- **Writes:** `SKIP_FOLDER_REGEX` (only when the answer is not empty).

---

## Round 2 — Who works here

### Q3. Solo or team?

> Does more than one person commit to this repository?

- **Solo** — one person commits, possibly through several agents and machines. The pre-commit hook alone is enough enforcement.
- **Team** — two or more people commit. Consequences: the CI backstop script becomes a required check, a pull-request template with the definition of done is added, the generated `fdc/log.md` is gitignored (each machine regenerates it), and in Round 3 the credentials question changes shape.
- **Why it matters:** this answer decides which credential options are safe to offer and how much of the enforcement has to live outside a single developer's machine.
- **Default:** none; the answer must be explicit.
- **Later change:** solo to team is a normal upgrade (run the update prompt). Team to solo is just a config edit.
- **Writes:** `FDC_TEAM`.

### Q4. How many machines?

> Will you (or your agents) work on this repository from more than one machine?

- **One machine** — local-only files are acceptable.
- **More than one** — everything under `fdc/` must be tracked in git, because briefs and notes are the hand-off between machines.
- **Why it matters:** decides whether the knowledge layer can live outside git at all.
- **Default:** more than one.
- **Later change:** cheap; start tracking the folder.
- **Writes:** nothing; it constrains Q5.

### Q5. What is tracked in git?

> Should `fdc/`, `AGENTS.md`, and `CLAUDE.md` be committed, or kept local and gitignored?

- **Track everything** — the docs travel with the code; every clone, teammate, and agent sees the same rules. This is the normal choice.
- **Gitignore `fdc/` only** — the rules files are shared but the knowledge layer stays on this machine. Only sensible for a single machine and a repo you do not want to carry documentation history.
- **Gitignore all three** — FDC becomes a private, per-machine layer on top of a repo you do not control. Nothing is enforced for anyone else.
- **Why it matters:** an untracked knowledge layer cannot be the hand-off between sessions on different machines, and an untracked rules file means other contributors and agents never see the contract.
- **Default:** track everything. Required when Q4 is "more than one" or Q3 is "team".
- **Later change:** moving from gitignored to tracked is one commit; the other direction loses history for everyone else.
- **Writes:** `.gitignore` entries in Step 5.

---

## Round 3 — How agents behave

Offer only the options that Round 2 allows.

### Q6. Credentials policy

> Where do credentials for the infrastructure in this repo go?

- **A — real values in the docs.** Each ops folder doc has an `## Access` table with host, user, the actual secret, and a rotation date. An agent can find and use a credential without a vault round-trip. This puts secrets in git: it is only defensible when the repo is private, the infrastructure is reachable only over VPN or a local network, credentials rotate regularly, and one person holds the repo. Every disk that holds the repo should be encrypted.
- **B — vault references only.** The table holds `<vault: item-name>` pointers to a password manager or secrets store. Values never enter git. Any plaintext credential found during bootstrap is replaced by a reference and reported to you. This is the only safe choice for anything shared or public.
- **Why it matters:** this is the single biggest security decision in the setup, and the hard-to-undo one: a secret that has been committed stays in history until it is rotated.
- **Default:** B. For a solo repo with LAN-only infrastructure, A is a legitimate trade.
- **Team repos:** A is refused by the pre-commit check. If the user still wants A, the config must carry `FDC_CREDENTIALS_OVERRIDE="<reason>"`, for example the number of people with access and the disk encryption in use. Ask for that reason, write it verbatim, and say in the report that the repo runs under an override. Do not invent a reason and do not write a free-text "deviation note" anywhere else.
- **Later change:** B to A is a config edit. A to B means rotating every credential ever committed.
- **Writes:** `FDC_CREDENTIALS_POLICY`, and `FDC_CREDENTIALS_OVERRIDE` when applicable; the matching paragraph in `AGENTS.md` rule 8.

### Q7. Commit policy

> Who runs `git commit` during normal work?

- **A — the agent commits verified milestones.** After a coherent, verified piece of work the agent stages only the files it touched, runs the checks, commits with a descriptive message, and pushes when the push is a fast-forward. It never amends, rebases, resets, or forces, and never switches to `main` unasked. Best when several sessions or machines share the repo and you want the hand-off to be in git.
- **B — you commit.** The agent never runs `git commit`. When work is done it shows `git status` and `git diff --stat` and stops. Best when you want to read every diff before it enters history.
- **Why it matters:** decides whether an agent session can leave durable state behind without you at the keyboard.
- **Default:** A for solo work across machines, B when you review every change.
- **Later change:** cheap; swap the paragraph in `AGENTS.md` rule 9 and the config field.
- **Writes:** `FDC_COMMIT_POLICY`; the matching paragraph in `AGENTS.md` rule 9.

---

## Derived, not asked

State these as consequences in your summary instead of asking:

| Answer | Consequence |
|---|---|
| Team | `scripts/check-docs-ci.sh` wired into CI; PR template installed; `fdc/log.md` gitignored. |
| More than one machine | all of `fdc/` tracked in git. |
| Credentials A on a team | `FDC_CREDENTIALS_OVERRIDE` set, reported as an override in the final report. |
| Any policy left unanswered | leave the config field empty; `fdc.sh doctor` keeps warning until it is filled. Never fill a policy with a default. |
