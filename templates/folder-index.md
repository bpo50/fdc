# <folder-name>

**Purpose:** _one or two sentences — what this folder is for and who consumes it._

## Subfolders

<!-- omit this section if no subfolders -->

| Folder | Contains | Index doc |
|---|---|---|
| `sub1/` | _purpose_ | `sub1/sub1.md` |

## Key files

<!-- One row per file, append-only, never reorder: several people and sessions edit this file and row-level appends merge cleanly. -->

| File | Purpose |
|---|---|
| `<file>` | _purpose_ |

## Commands

<!-- omit if folder is data-only -->

```bash
<the one or two commands someone would actually run from this folder>
```

## Targets

<!-- ops folders only: omit for pure code -->

| Target | Environment | Reached via |
|---|---|---|
| `<host / cluster / account>` | `<prod / staging>` | `<ssh alias, kubeconfig context, cloud profile>` |

## Access

<!-- ops folders only. Under credentials policy A the Secret column holds the value; under policy B it holds `<vault: item>`. See AGENTS.md → "How to work in this repo" → Credentials. -->

| Service | Host | User | Secret | Rotated on |
|---|---|---|---|---|
| `<service>` | `<canonical host:port>` (alias optional; aliases differ per machine) | `<user>` | `<value or <vault: item>>` | `YYYY-MM-DD` |

## Depends on

<!-- omit if standalone -->

- `<other-folder>/<other-folder>.md` — _what the dependency is._

## Gotchas

- _The non-obvious things. The "easy to get wrong" things._

## See also

<!-- omit if no related docs yet -->

- `fdc/decisions/<file>.md`
- `fdc/runbooks/<file>.md`
- `fdc/troubleshooting/<file>.md`
