---
name: rce-lfg
description: "Run the full Rumor compound loop hands-off for one Linear issue: plan, work, review, ship, babysit, compound, with no check-ins. Use ONLY when the user explicitly asks to build/ship something autonomously all the way to an open PR, or invokes rce-lfg directly -- it pushes and opens a PR without stopping. Not for in-the-loop work. Rumor compound-engineering loop."
argument-hint: "[Linear issue id, or a feature description]"
---

# rce-lfg — the whole loop, hands-off, for one Linear issue

CRITICAL: execute every step below IN ORDER. Do NOT jump to coding. The plan
(step 1) MUST complete and pass its readiness check BEFORE any work begins.

LFG runs with no user to answer — no step stops to ask. It plans, builds in an
isolated worktree, reviews with Rumor's reviewers, ships a PR linked to Linear, and
babysits it to merge-ready, then captures the learning. It does **not** force a
merge (LAW 5) — merge-ready is its terminal state unless Chris pre-authorized the
merge.

## Load first (required)

`../rumor-compound/references/laws.md`, `repos.md`, `linear.md`, `worktree.md`.
Resolve each named skill against the host's available-skills list and invoke that
exact entry (`rumor-compound:rce-plan`, etc.) — a short-form guess that is not in
the list fails.

## Step 0 — Anchor

Resolve the Linear issue (`linear.md`): the argument id, else create one from the
description (`save_issue`, autonomous per LAW 9). Confirm the target repo. This id
threads through every step and every artifact.

## Step 1 — Plan

Invoke **`rce-plan`** with `mode:non-interactive` and the issue id (the mode is
required — without it `rce-plan` pauses for scope confirmation and stalls this
hands-off run). **GATE — STOP** if it reports the task is non-software, returns
`blocked`, or writes no plan. Record the plan path; it feeds
steps 2 and 3.

## Step 2 — Work (return-to-caller)

Invoke **`rce-work`** with `mode:return-to-caller <plan-path>`. **GATE — STOP** on
any status but `complete`. Read the return envelope: worktree path, branch, commits,
verify evidence. Only a valid `complete` with real verify evidence advances.

## Step 3 — Review

Invoke **`rce-review`** with `mode:agent` on the branch diff. Read the verdict.
**GATE — STOP as blocked** on a confirmed blocker-class finding (correctness,
security, migration, auth) that the fix cannot resolve. Otherwise apply the
confirmed fixes (path-limited, LAW 2/3), re-verify, and commit them.

## Step 4 — Ship

**Shipping precondition:** run `git -C "$WT" remote` once. No remote → local-only:
make every commit but skip push/PR/babysit (terminal, not an error). With a remote,
invoke **`rce-ship`** with `mode:pipeline`. It commits (named files only), pushes,
opens the PR, links Linear, and respects the web deploy/merge laws. Record the PR
URL.

## Step 5 — Babysit

Invoke **`rce-babysit`** with `mode:pipeline <pr-url>`: watch checks, answer **every**
bot finding (LAW 4), re-check comments at the merge point, verify what merged
(LAW 8). It does not `--admin`-merge (LAW 5) — it returns merge-ready when the merge
needs Chris.

## Step 6 — Compound

Invoke **`rce-compound`** with `mode:non-interactive`: write the learning to
`docs/solutions/` and link it on the Linear issue. This closes the loop.

## Step 7 — Report

Output `<promise>DONE</promise>` with: the Linear id and its new status, the PR URL
and merge state, the learning path, and any residual left durable. Report
faithfully (LAW 10) — if a gate stopped the run, say which and why.

Start with step 0 now. Plan FIRST. Never skip the plan, the worktree, or the review.
