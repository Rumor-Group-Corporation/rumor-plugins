# Config resolution

Config is optional. Every setting has a working default, so a repo with no config
file runs the loop fine. A repo opts into overrides with a tracked file at
`<REPO_ROOT>/.compound-engineering/config.yaml`.

## Resolution

```bash
CFG="$REPO_ROOT/.compound-engineering/config.yaml"
# read a key: first active (non-commented) value wins, else the skill default.
```

There is no `config.local.yaml` layer in this plugin (the estate shares checkouts;
one tracked file per repo keeps every worktree consistent). Read only the tracked
`config.yaml`.

## Keys

| Key | Default | Meaning |
|-----|---------|---------|
| `docs_root` | `docs` | Root for `plans/`, `solutions/`, `ideation/`. Must be a repo-relative dir inside the repo, not the root, not under `.git/`. An invalid value **stops** — it does not fall back (a typo must not silently scatter artifacts). |
| `linear_team` | inferred | Default Linear team key (RUM / DEM / PLAT / …) for issue creation when the branch carries no id. Inferred from the branch or asked when unset. |
| `verify_cmd` | derived | Override the verify command. Default is derived from `package.json` per `repos.md`. Set only when the standard scripts do not capture "verified" for this repo. |
| `default_base` | origin default | Base branch new worktrees fork from. Default is `origin/HEAD` (main/master). |
| `reviewers` | risk-driven | Comma list to force a reviewer roster (`opus-reviewer,thermos,rams`). Default lets `rce-review` pick by risk. |
| `merge_policy` | `pr` | `pr` = open PR and stop at merge-ready (default, safest). Never implies `--admin` (LAW 5). |

## Where the loop writes

- `docs_root/plans/` — plans (`rce-plan`)
- `docs_root/solutions/` — learnings (`rce-compound`)
- `docs_root/ideation/` — ideation artifacts (`rce-ideate`)

`rce-setup` prints the resolved values so an operator can confirm them before a run.
