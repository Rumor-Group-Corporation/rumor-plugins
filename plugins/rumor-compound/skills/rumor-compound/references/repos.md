# Rumor repos — detection, verify commands, worktrees

Every `rce-*` skill works on **any** main Rumor repo. It never assumes one. This
file is how a skill learns which repo it is in and how that repo is verified.

## Step 1 — Locate the repo root

```bash
REPO_ROOT="$(git -C "$PWD" rev-parse --show-toplevel 2>/dev/null)"   # or -C <named repo dir>
REPO_NAME="$(basename "$REPO_ROOT")"
REMOTE="$(git -C "$REPO_ROOT" remote get-url origin 2>/dev/null)"     # expect Rumor-Group-Corporation/<name>
```

If `REMOTE` is not `Rumor-Group-Corporation/<name>`, this is not a main Rumor repo
— tell the user and stop rather than guessing conventions.

## Step 2 — Detect the package manager (never assume npm)

Read the lockfile, in this order — first hit wins:

| Lockfile present        | Package manager | Run scripts with |
|-------------------------|-----------------|------------------|
| `bun.lock` / `bun.lockb`| bun             | `bun run <s>` / `bun x` |
| `pnpm-lock.yaml`        | pnpm            | `pnpm run <s>` / `pnpm dlx` |
| `yarn.lock`             | yarn            | `yarn <s>` |
| `package-lock.json`     | npm             | `npm run <s>` / `npx` |

Package managers really do vary across the estate — see the table below. **Detect
per repo, every time.** A hardcoded `npm test` is a bug.

## Step 3 — Derive the verify command from package.json

Read `<REPO_ROOT>/package.json` `scripts`. Build the verify command from whichever
of these exist, in this preference order, and run the ones present:

1. `typecheck` (or `type-check`) — the cheapest signal; on backend it is the **root
   ratchet** gate, so it must stay green.
2. `lint`
3. `test` (or `test:unit`)
4. `check` (some repos bundle the above under one script)

Never invent a script that is not in `package.json`. If none of the above exist,
say the repo exposes no standard verify script and ask what "verified" means here.

## Known-repo cheat sheet (verify against package.json — do not trust this blindly)

| Repo | Mgr | Verify scripts seen | Notes |
|------|-----|---------------------|-------|
| `rumor-backend-services` | npm | `test` | Typecheck is the **root ratchet**; **jest runs from the WORKTREE ROOT**, not a package dir. TypeORM: `UPDATE ... RETURNING` yields `[rows, rowCount]`. |
| `rumor-mobile-expo` | yarn | `lint`, `test`, `typecheck` | NativeWind-only styling; RNTL/jest; Maestro E2E; EAS concurrency = 2 whole-account. UI verify via the simulator loop. |
| `web-2.0` | yarn | `lint`, `test`, `typecheck` | Next.js + Vercel; guest list is Algolia-backed; smoke/Meticulous suites; **LAW 5 & 6 apply**. Vitest can flake in parallel on sales tabs. |
| `rumor-web-next` | yarn | `lint` | `development` branch is dead — trunk-based. |
| `rumor-platform` | bun | `typecheck`, `lint`, `test`, `test:unit`, `check` | Bun workspace; Clean-Arch; Railway deploy; watch dist/src shadow. |
| `rumor-dispatch` | pnpm | `typecheck`, `test` | |
| `rumor-cli` | bun | `typecheck`, `test` | |
| `rumor-relay` | pnpm | `typecheck`, `test` | Neon-backed; resilience work in flight. |
| `rumor-finance` | npm | `typecheck` | Cost dashboard (SSO). |
| `rumor-infra` | — | terraform / scripts | IaC — "verify" is `terraform plan`, not jest. |

Repos not listed here are handled by Steps 1-3 generically.

## Step 4 — Worktree location

See `worktree.md`. Short version: isolate in the **sibling** dir
`<REPO_ROOT>/../<REPO_NAME>-worktrees/<slug>`. Those dirs already exist for the
active repos.

## Step 5 — Where artifacts land

- Plans → `<REPO_ROOT>/docs/plans/`
- Learnings → `<REPO_ROOT>/docs/solutions/`
- Ideation → `<REPO_ROOT>/docs/ideation/`

Create the subdir if absent. These live **in the repo the work is in**, so they
travel with it and the next agent on that repo finds them. (This plugin does not
write to `~/.claude` auto-memory — repo `docs/` is the sole learning store, by
Chris's choice.)
