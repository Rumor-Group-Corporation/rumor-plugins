# Rumor laws — the non-negotiables

These are standing rulings from Chris. They outrank convenience, speed, and any
inference you make from the tree in front of you. Every `rce-*` skill loads this
file. When a law and a task conflict, the law wins; surface the conflict and stop
rather than working around it.

The laws are grouped by the failure they prevent. Each names its blast radius.

---

## LAW 1 — Additive is free; destructive needs Chris

**Any deletion or teardown is Chris's call.** Creating files, branches, worktrees,
PRs, plans, docs, or Linear issues is free. Deleting or overwriting anything you
did not create in this session — a branch, a file, a Linear issue, a remote ref,
an env var, an environment — stops and asks first.

- Before you delete or overwrite a target, **look at it**. If what you find
  contradicts how it was described, or you did not create it, surface that instead
  of proceeding.
- "Clean up", "remove the old one", "reset it" are requests to *propose* the
  teardown, not to perform it unattended.

## LAW 2 — Work in a worktree; never reset a shared checkout

The primary checkout of a Rumor repo (`~/Desktop/Rumor-Engineering/<repo>`) is
**shared** — other agents and Chris are on it. Never `git reset --hard`,
`git checkout -f`, `git clean`, or switch its branch out from under whoever holds
it.

- Isolate every code change in a **sibling worktree**: `<repo>-worktrees/<slug>`
  (e.g. `rumor-backend-services-worktrees/dem-519-chat-channel`). This is the
  Rumor convention — **not** an in-repo `.worktrees/` dir. See `worktree.md`.
- If a worktree already exists for this issue/branch, reuse it. One branch lives
  in one worktree at a time.

## LAW 3 — `git -C <repo>`, never `cd`

The Bash tool's working directory resets between calls and can reset mid-command.
A `cd` that "worked" last call is gone this call. **Address every git and file
operation with an explicit path** (`git -C "$WT" status`), never a bare `cd`
followed by a relative command. This is proven, not theoretical — it bites this
harness constantly.

## LAW 4 — Fix or rebut ALL bot-review findings, in the same breath as the merge

Rumor PRs draw automated reviewers (OpenCodeReview/OCR, Cursor Bugbot, thermos,
CodeRabbit where enabled). The law:

1. **Every** bot finding is either fixed or explicitly rebutted in a reply. None
   is ignored.
2. **Re-check the PR's comments IN THE SAME BREATH as the merge** — bots post late.
   A finding that lands after your last read, but before merge, still counts.
   Reading checks green is not enough; read the review comments again right before
   merging.

## LAW 5 — web-2.0 / web merge: never `--admin` unless Chris says so

On `web-2.0` (and web repos generally) **never** `gh pr merge --admin` /
bypass branch protection unless Chris explicitly authorizes that merge. Required
checks exist for a reason. If checks are stuck, fix or wait — do not force.

## LAW 6 — Web prod deploy: CLI yes, `--prebuilt` NEVER

For `web-2.0` production, deploy through the Vercel CLI **without** `--prebuilt`.
`vercel deploy --prebuilt --prod` from the Mac ships the darwin build of `sharp`
and **500s every OG image** in prod. Let Vercel build remotely. Never promote web
prod via a prebuilt local bundle.

## LAW 7 — Daily release train, dev-owned QA

Ship on the daily release train; the developer owns QA for their own change. Do
not batch a week of changes into one merge, and do not hand unverified work to
someone else to test. Verify your own change before it ships.

## LAW 8 — Verify what actually merged

A squash-merge can silently drop a commit you pushed after the PR was approved.
**After any merge, re-verify the merged tree contains your change** (the squash
SHA, the file diff on the base branch) — do not assume the PR page's "merged"
badge means your last push landed.

## LAW 9 — Linear writes: additive is autonomous, teardown asks

Chris authorized this plugin to write to Linear autonomously. That authority
covers **additive, forward** writes only:

- **Autonomous:** create an issue, post a comment, attach a link, add a label,
  move status *forward* (Todo → In Progress → In Review → Done).
- **Asks first (LAW 1):** delete or archive an issue/comment/project, move status
  *backward* or to Canceled, reassign away from the current owner, or bulk-edit
  more than a handful of issues.

## LAW 10 — Report outcomes faithfully

If verification failed, say so with the output. If a step was skipped, say that.
When something is done and verified, state it plainly with the evidence (the
passing command, the PR URL, the merged SHA). Never claim ship-complete on a
green badge alone (see LAW 4 and LAW 8).

---

## How the laws bind the loop

| Stage        | Laws that bite hardest |
|--------------|------------------------|
| `rce-work`   | 1, 2, 3 — worktree isolation, path-limited commits, `git -C` |
| `rce-review` | 4, 10 — every finding fixed/rebutted, faithful report |
| `rce-ship`   | 5, 6, 7 — merge policy, no `--prebuilt`, release train |
| `rce-babysit`| 4, 8 — re-check comments at merge, verify what merged |
| any Linear write | 9, 1 — additive autonomous, teardown asks |
