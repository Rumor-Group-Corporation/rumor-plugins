# Worktree isolation — the Rumor way

Rumor isolates every code change in a **sibling worktree**, never on the shared
primary checkout (LAW 2). This file owns that mechanic. `rce-work` and `rce-lfg`
load it before any branch move or edit.

## The convention: sibling `<repo>-worktrees/<slug>`

```
~/Desktop/Rumor-Engineering/
  rumor-backend-services/                     <- shared primary checkout (leave alone)
  rumor-backend-services-worktrees/           <- isolation lives here
    dem-519-chat-channel/                      <- one worktree per branch
```

This is **not** the in-repo `.worktrees/` pattern some harnesses use. The sibling
dirs already exist for the active repos and hold 10+ live worktrees each.

## Order of operations

**1. Detect existing isolation first.** If `PWD` is already a linked worktree,
work in place — do not nest a worktree inside a worktree.

```bash
GITDIR="$(git -C "$PWD" rev-parse --absolute-git-dir 2>/dev/null)"
COMMON="$(cd "$(git -C "$PWD" rev-parse --git-common-dir)" && pwd -P)"
# GITDIR != COMMON and not a submodule -> already in a linked worktree: work here.
```

**2. Reuse a worktree for this issue if one exists.** One branch = one worktree.

```bash
git -C "$REPO_ROOT" worktree list        # is <slug> / the issue branch already checked out?
```

If the branch is already checked out somewhere, `cd` there (address by path) and
work in place. Never force a second worktree for the same branch.

**3. Create the worktree (sibling dir).** From the shared primary checkout, but
addressed with `-C` (LAW 3 — never `cd` then relative):

```bash
WT_PARENT="$REPO_ROOT/../$REPO_NAME-worktrees"
mkdir -p "$WT_PARENT"
SLUG="dem-519-chat-channel"                 # from the Linear id + short title
BRANCH="chris/$SLUG"                          # Rumor branch convention: chris/<key>-<num>-<slug>
git -C "$REPO_ROOT" fetch origin             # non-fatal if no origin / offline
git -C "$REPO_ROOT" worktree add -b "$BRANCH" "$WT_PARENT/$SLUG" origin/main
#   base off the repo's real default branch (main / master) -- check with:
#   git -C "$REPO_ROOT" symbolic-ref refs/remotes/origin/HEAD
WT="$WT_PARENT/$SLUG"                          # <- every later git/file op uses -C "$WT"
```

For an **existing branch / PR** instead of new work:
- existing branch: `git -C "$REPO_ROOT" worktree add "$WT_PARENT/$SLUG" <branch>`
- PR #N: `git -C "$REPO_ROOT" fetch origin pull/N/head:pr-N` then
  `worktree add "$WT_PARENT/pr-N" pr-N` (a real local branch, never detached
  `FETCH_HEAD` — that orphans your fix commits instead of updating the PR).

**4. Warm the checkout.** A fresh worktree has no `node_modules`. Install with the
repo's detected package manager (see `repos.md`) before the verify command can run:
`bun install` / `pnpm install` / `yarn install` / `npm install`, addressed with the
worktree path.

**5. Report** the worktree path and branch, then do all work addressed to `$WT`.

## If worktree creation fails

A sandbox or permission error means the isolation the user asked for does not
exist. **Do not silently fall back to editing the shared checkout** — that is
exactly LAW 2's failure. Report the failure and ask whether to work in the current
checkout or stop and resolve permissions.
