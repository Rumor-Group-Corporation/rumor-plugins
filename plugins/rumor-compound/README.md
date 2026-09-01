# rumor-compound

Compound engineering for the Rumor stack — a Claude Code plugin.

A Rumor-native port of [EveryInc's compound-engineering plugin](https://github.com/EveryInc/compound-engineering-plugin).
Same idea: structure work so each unit makes the next one easier, and capture what
you learn as you go. Rewired for how Rumor actually works:

- **Linear, not GitHub Issues.** Ideas are grounded in open Linear issues, plans are
  anchored to an issue, PRs auto-link, and residuals + learnings post back to the
  issue. Your branch names (`chris/dem-519-…`) are the anchor.
- **Any main Rumor repo.** Detects the repo, its package manager, and its real
  verify command at runtime (backend=npm, expo/web-2.0=yarn, platform/cli=bun,
  dispatch/relay=pnpm) — nothing hardcoded.
- **Rumor's laws enforced.** Worktree isolation (sibling `<repo>-worktrees/`),
  `git -C` not `cd`, answer every bot-review finding, no `--admin` on web merges,
  no `--prebuilt` web deploy, verify what actually merged.

## The loop

```
/rce-ideate → /rce-plan → /rce-work → /rce-review → /rce-ship → /rce-babysit → /rce-compound
```

| Command | Does |
|---------|------|
| `/rce-ideate` | Grounded ideas from the repo **and** open Linear issues; critiques all, explains survivors. |
| `/rce-plan` | A durable plan in `docs/plans/`, anchored to a Linear issue. Decides, never implements. |
| `/rce-work` | Builds the plan in an isolated **sibling worktree**, path-limited commits, real verify command. |
| `/rce-review` | Rumor's real reviewers (opus-reviewer, thermos, rams, `/code-review`) vs the 8-class checklist. Report-only unless `apply:local`. |
| `/rce-ship` | Commit (named files), push, open a PR linked to Linear. Honors merge & deploy laws. |
| `/rce-babysit` | Watch the PR to merge-ready; **answer every bot finding**; re-check at merge; verify what merged. |
| `/rce-compound` | Capture the solved problem as a durable learning in `docs/solutions/`. The compounding step. |
| `/rce-lfg` | The whole loop, hands-off, for one Linear issue. Opens a PR without stopping (won't force a merge). |
| `/rce-setup` | Health-check a repo and write its optional config. |

Each stage works alone; you don't have to run them all or in order. But the payoff
only compounds if you close the loop — **`/rce-compound` is what makes the next
issue cheaper.**

## Install

Already in the local `rumor` marketplace. In Claude Code:

```
/plugin
```

pick **rumor** → **rumor-compound** → install. Then, in any Rumor repo:

```
/rce-setup
```

to confirm the verify command, worktrees, `docs_root`, and Linear reachability.

## Architecture

- `skills/rumor-compound/` — the spine: the loop overview plus the shared
  `references/` every stage reads (`laws.md`, `repos.md`, `linear.md`,
  `worktree.md`, `review-stack.md`, `config.md`).
- `skills/rce-*/` — the seven loop stages plus `lfg` and `setup`, as lean
  phase-loaded kernels that load only the references they need. Each skill is its
  own `/rce-*` entry point (invoke by name, or let it auto-fire from its
  description) — no separate command wrappers.
- `templates/config.example.yaml` — the optional per-repo config.

The Rumor knowledge lives in `references/` (DRY — one copy, every stage loads it).
Change a law once, every stage picks it up.

## Config (optional)

Per repo, commit `.compound-engineering/config.yaml` (see
`templates/config.example.yaml`): `docs_root`, `linear_team`, `verify_cmd`,
`default_base`, `reviewers`, `merge_policy`. No config → sensible defaults.

## Laws

The non-negotiables live in `skills/rumor-compound/references/laws.md` — read it.
They come from Chris's standing rulings and outrank convenience. A stage that would
violate one stops and surfaces the conflict instead of working around it.
