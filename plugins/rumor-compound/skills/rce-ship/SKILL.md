---
name: rce-ship
description: "Commit (named files only), push, and open a PR for a Rumor change, linked to its Linear issue, honoring Rumor's merge and deploy laws. Use when asked to ship / open a PR. Then hands off to rce-babysit. Rumor compound-engineering loop."
argument-hint: "[PR ref to update] [mode:pipeline for rce-lfg] [babysit:off]"
---

# rce-ship — commit, push, PR, linked to Linear

**Goal:** the reviewed work committed, pushed, and in an open PR whose URL you
hold, linked to its Linear issue, then handed to `rce-babysit`. Reporting the PR
URL alone is **not** done.

## Load first (required)

1. `../rumor-compound/references/laws.md` — LAWS 5, 6, 7, 8, 9 all bite here.
2. `../rumor-compound/references/linear.md` — PR ⇄ issue linking.
3. `../rumor-compound/references/repos.md` — repo (deploy law is web-specific).

## Preconditions

`rce-review` must have run and be ship-ready (or its residuals recorded). Never
ship on a red verify or an unanswered blocker. Every `git`/`gh` command is its own
argv call addressed with `-C "$WT"` (LAW 3), and its exit status is control flow.

## Step 1 — Confirm the branch and base

Confirm you are on the isolated feature branch in the worktree, never the shared
default branch. A detached HEAD or work on the default branch means create a branch
first. Re-verify branch and remote right before the push (probe output is a
snapshot).

## Step 2 — Commit the offered work only (write gate)

Group the change into clear commits. **Name the files** on both add and commit —
**never `git add -A` / `git add .`** (LAW 2 write gate — `.env`, build output, and
anyone's pre-existing dirty set must not ride along). Honor any `exclude:<paths>`.
Conventional commits; default `fix:` over `feat:` when ambiguous.

## Step 3 — Push

`git -C "$WT" push -u origin <branch>`. If there is **no** `origin` remote, this is
local-only: make the commits and **stop** — skip push/PR (terminal, not an error).

## Step 4 — Compose the PR

Title and body:
- Put the **Linear id** in the title or body (`DEM-519`) so Linear auto-links.
- Body: what changed and why, the verify evidence, the plan link, and a
  **`## Residuals`** checklist of any accepted-but-unfixed review findings (LAW 10
  — residuals must be durable; the PR body is their sink).
- No Compound-Engineering branding unless asked.

## Step 5 — Open the PR, link Linear, respect the laws

Create with `gh pr create --body-file <path>` (never stdin — `gh` exits 0 on an
empty stdin body). Re-run the existing-PR check right before create and route on
it: a matching open PR → edit it; exit-0 `[]` → create; non-zero → **unknown**,
resolve auth/connectivity and stop, never treat as "none".

Then:
- `create_attachment` the PR URL onto the Linear issue, and move the issue forward
  to **In Review** (`save_issue`, forward-only per LAW 9).
- **Web deploy law (LAW 6):** if this ships `web-2.0` to prod, deploy via the
  Vercel CLI **without `--prebuilt`** — never a prebuilt local bundle. Let Vercel
  build remotely.
- **Merge policy (LAW 5):** you open the PR and drive it to merge-ready. You do
  **not** `gh pr merge --admin` / bypass protection on web repos unless Chris says
  so. Merging itself waits for `rce-babysit` and Chris.

## Step 6 — Hand off to babysit (completion gate)

**`mode:pipeline` (rce-lfg) returns here — do not babysit.** The pipeline caller
owns the next stage and runs babysit itself; starting it here would double the CI
polling and bot handling and could run a second pass against an already-merged PR.
In `mode:pipeline`, return the PR URL to the caller and stop.

Otherwise (standalone) the run is **not done** until `rce-babysit` owns the PR
(LAW 4/8 live there). Invoke **`rce-babysit <pr-url>`** unless `babysit:off` or the
PR is a draft. If babysit cannot start, stop and report it blocked — no other
watcher substitutes.
