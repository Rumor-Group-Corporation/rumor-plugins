---
name: rce-babysit
description: "Watch a Rumor PR to a CI-decided, merge-ready state: track checks, answer EVERY bot-review finding (OCR, Bugbot, thermos), fix or rebut each, and verify what actually merged. Use after opening a PR or when asked to watch/drive a PR to green. Rumor compound-engineering loop."
argument-hint: "[PR url or number; blank uses the current branch's PR] [mode:pipeline for rce-lfg]"
---

# rce-babysit — drive the PR to merge-ready, answer every bot

**Done:** the PR is merge-ready — checks decided, **every** bot-review finding
fixed or explicitly rebutted, residuals durable — and either merged (with the
merged tree verified) or handed back to Chris for the merge, per the merge law.

## Load first (required)

1. `../rumor-compound/references/laws.md` — LAWS 4, 5, 8 are the whole point here.
2. `../rumor-compound/references/linear.md` — move the issue on merge.
3. `../rumor-compound/references/repos.md` — merge/deploy law is repo-specific.

## Step 1 — Find the PR and its state

`gh pr view <ref> --json number,url,state,isDraft,statusCheckRollup,reviewDecision`.
Blank ref → the current branch's PR. A draft is not babysat — say so and stop.

## Step 2 — Watch checks to decided

Poll checks (do not force extra runs — OCR is metered). When a check **fails**,
read its log, diagnose, fix in the worktree (path-limited, LAW 2/3), re-verify
locally with the repo's command, then push the fix. Do not spin: one fix per real
failure.

## Step 3 — Answer EVERY bot finding (LAW 4)

This is the law that most often gets skipped. Read **all** PR review comments —
OpenCodeReview (OCR), Cursor Bugbot, thermos, CodeRabbit where enabled — with
`gh pr view <ref> --comments` and the reviews API. For **each** finding:

- **Fix it** (commit the fix, path-limited), **or**
- **Rebut it** with a reply that says why it is not a problem here.

None is left unanswered. A finding you fixed still gets a one-line reply pointing at
the fix commit, so the bot and a human can see it was handled.

## Step 4 — Re-check comments in the same breath as the merge (LAW 4)

Bots post late. **Immediately before merging, read the PR's comments again** — a
finding that landed after your last pass, but before merge, still counts. Green
checks are not enough; re-read the reviews right at the merge point.

## Step 5 — Merge, per the law (LAW 5)

- Move any accepted residual into a durable sink first (PR body, or a Linear
  comment per LAW 9).
- Merge only when merge-ready **and** the merge is authorized: on `web-2.0` / web
  repos **never `--admin`** / bypass protection unless Chris explicitly said so
  this session. When merge needs Chris, hand it back with a one-line status rather
  than forcing it.

## Step 6 — Verify what actually merged (LAW 8)

After merge, **re-verify the merged tree contains your change** — a squash can drop
a commit pushed after approval. Check the squash SHA / the file diff on the base
branch, not just the PR's "merged" badge.

Then move the Linear issue to **Done** (`save_issue`, forward-only, LAW 9) and
attach the merge commit. Offer **`rce-compound`** to capture the learning — closing
the loop is what makes the next issue cheaper.

## mode:pipeline (rce-lfg)

Run non-interactively: watch to CI-decided, answer bots, and return
`{ status, fixes_applied, residuals, merge_state }`. Do not `--admin`-merge; if the
merge needs Chris, return merge-ready with that noted rather than forcing it.
