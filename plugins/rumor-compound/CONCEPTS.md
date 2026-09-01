# Concepts

Shared vocabulary for the Rumor compound loop. Glossary, not a spec.

## Compound engineering
Structuring engineering work so each unit makes the next one easier, capturing
reusable knowledge as you go so the toolset gets smarter with every use. The loop
only compounds if it is closed — the learning must be captured (`rce-compound`).

## The loop / pipeline
The chained stages that carry work from idea to shipped, learned change:
ideate → plan → work → review → ship → babysit → compound. Each hands a durable
artifact to the next (an ideation doc, a plan, a verified branch, a review verdict,
a PR, a merge, a learning).

## Learning
A documented solution to a past problem — a bug fix, a convention, a trap avoided —
written to `docs/solutions/` in the repo it came from, so the next agent on that
repo finds and reuses it. The unit of compounded knowledge. Carries category, tags,
and the Linear id it links to.

## Issue of record
The Linear issue a piece of work is anchored to — the canonical requirement. Parsed
from the branch (`chris/dem-519-…` → `DEM-519`), passed as an argument, or created.
Every stage links back to it rather than opening a second record.

## Isolated worktree
A sibling `<repo>-worktrees/<slug>` checkout where a change is built, so the shared
primary checkout is never disturbed (LAW 2). One branch lives in one worktree.

## Write gate
The rule that only offered work is committed: commits are path-limited to named
files, never `git add -A`, so `.env`, build output, and a pre-existing dirty set
cannot ride along.

## Residual
A review finding accepted or deferred rather than fixed. It must reach a durable
sink — the PR body or a Linear comment — before a run claims done. A residual that
lives only in the session is lost.

## Bot finding
An automated review comment from a CI reviewer (OpenCodeReview / OCR, Cursor
Bugbot, thermos). LAW 4: every one is fixed or rebutted, and the comments are
re-read in the same breath as the merge, because bots post late.

## Law
A standing ruling from Chris that outranks the task. The ten are in
`references/laws.md`. A stage that would break one stops and surfaces the conflict.

## Stage skill vs spine
The spine skill (`rumor-compound`) holds the loop overview and the shared
`references/` (laws, repos, linear, worktree, review-stack, config). The stage
skills (`rce-*`) are lean kernels that load only the references they need. One copy
of each fact, every stage reads it.

## Verify command
The repo's real proof-of-working command, derived at runtime from its
`package.json` scripts and detected package manager (typecheck → lint → test →
check). Never hardcoded — the estate mixes npm, yarn, pnpm, and bun.
