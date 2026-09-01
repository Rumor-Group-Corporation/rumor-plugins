---
name: rce-review
description: "Review a Rumor change with the reviewers Rumor actually runs (opus-reviewer, thermos, rams, /code-review) against the 8-class defect checklist, before a PR. Report-only by default; apply:local to fix. Use before shipping or when asked to review. Not for answering feedback already on a PR (that is rce-babysit). Rumor compound-engineering loop."
argument-hint: "[blank reviews the current branch diff] [apply:local] [mode:agent for rce-lfg]"
---

# rce-review — Rumor's real reviewers, reconciled

**Report-only by default.** A bare invocation produces findings and does **not**
change the tree. Applying requires `apply:local` or an explicit "fix these" in the
prompt. Never push, open PRs, or move Linear status from here.

## Load first (required)

1. `../rumor-compound/references/laws.md`
2. `../rumor-compound/references/review-stack.md` — the reviewers, how to route,
   and the 8-class defect checklist.
3. `../rumor-compound/references/repos.md` — repo context (a UI diff routes
   differently than a migration).

## Stage 1 — Scope the diff

Resolve the reviewed diff from the current branch against its base
(`git -C "$WT" diff origin/main...HEAD` — use the repo's real default base). Do
**not** switch branches or check anything out; review the tree where the work
lives. Classify the change: UI / backend logic / migration / auth / infra — this
drives the roster.

## Stage 2 — Write the intent summary

One short paragraph every reviewer receives: what the change is for (the Linear
issue goal), and the plan's task ids it implements. Discover the plan in
`docs/plans/` so Stage 4 can check requirements against it.

## Stage 3 — Select the roster (risk-driven, `review-stack.md`)

- Always: `/code-review` at an effort matched to risk.
- Add one **independent adversarial context**: `opus-reviewer` for
  correctness/security-heavy or migration/auth/payments diffs (mandatory there,
  default BLOCK on an unruleable blocker); `thermos` branch-audit for large or
  structural ones.
- UI diff (`web-2.0` / `rumor-mobile-expo`): add `rams`; on expo add the
  `rumor-ui` standards reviewer.

## Stage 4 — Dispatch as one concurrent batch

Launch the roster as independent contexts in one batch (the `Agent` tool for the
agent reviewers, the `Skill` tool for `/code-review`), sized to the host's agent
cap. For thermos/opus-reviewer, gather the diff + touched file contents first and
pass them in. Collect **every** verdict before synthesizing — a reviewer that
errors or returns malformed output is a failed reviewer, noted, not silently
dropped.

## Stage 5 — Reconcile and report

Fold the returns into one report, most-severe first. Two independently-dispatched
reviewers raising the same finding **promote** it; a lone high-confidence blocker
still blocks. Verify each finding against the actual diff before reporting it —
drop the ones that do not survive. For each finding: the defect class (1-8), the
file:line, the failure it causes, and the fix. End with a verdict:
**ship-ready / fix-first / blocked**, and the coverage you ran (name the reviewers,
not the plumbing — LAW 10).

## Stage 6 — Apply, if asked

Only with `apply:local` (or an explicit fix request): apply the confirmed fixes to
the worktree, path-limited (LAW 2/3 write gate — name the files, never `add -A`),
re-run the verify command, and re-report. Still no push, no PR, no Linear write.

## Residuals

Any finding accepted-but-not-fixed is a **residual** and must reach a durable sink
before this run claims done — the PR body (if a PR exists) or, per LAW 9, a comment
on the Linear issue. A residual that lives only in this session is lost.

## Handoff

Standalone: present the verdict and offer **`rce-ship`** (if ship-ready) or another
`rce-work` pass (if fix-first). In `mode:agent` (from `rce-lfg`): return the
structured findings + verdict and stop; the caller applies and ships.
