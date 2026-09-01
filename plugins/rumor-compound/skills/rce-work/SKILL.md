---
name: rce-work
description: "Execute a plan or concrete build request in a Rumor repo, end-to-end, in an isolated sibling worktree with path-limited commits and the repo's real verify command. Use when implementing from a plan or a clear build request; use rce-review before shipping. Rumor compound-engineering loop."
argument-hint: "[plan path, or a build description, or a Linear issue id; blank uses the branch's plan] [mode:return-to-caller for rce-lfg]"
---

# rce-work — build it, verified, in isolation

**Outcome:** a fully implemented, **locally verified** change set, on an isolated
branch, ready for `rce-review`. In `mode:return-to-caller` (used by `rce-lfg`),
implementation and verification only — no review, no PR; the caller owns those.

## Load first (required)

1. `../rumor-compound/references/laws.md` — LAWS 2, 3 (worktree, `git -C`) and the
   write gate bind every step here.
2. `../rumor-compound/references/repos.md` — package manager + verify command.
3. `../rumor-compound/references/worktree.md` — isolation, in full, **before any
   branch move or edit**.
4. `../rumor-compound/references/linear.md` — the issue this work is against.
5. `../rumor-compound/references/config.md` — the repo's optional `verify_cmd`
   override. A repo can pin a non-standard verify command here; miss this read and
   you would derive the wrong command from `repos.md` and report a change verified
   without running the gate the operator configured.

If any required reference cannot be read, stop before editing and report it — do
not reconstruct the worktree or verify mechanics from memory.

## Phase 0 — Intake

Resolve the source: a plan path → read it; a Linear issue id → `get_issue`, and
look for its plan in `docs/plans/`; blank → the plan matching the current branch.
A **trivial** bare request (1-2 files, no behavior change) may skip the task list
but still obeys the worktree and write gates.

## Phase 1 — Establish the isolated workspace (LAW 2)

Follow `worktree.md`: detect existing isolation, reuse the issue's worktree if one
exists, else create the sibling `<repo>-worktrees/<slug>` worktree off the repo's
real default branch, then warm it (install deps with the detected package manager).
**Never edit the shared primary checkout, and never work on the real default
branch** without Chris's explicit same-session say-so.

Record the **pre-work dirty set** — files already modified before you touched
anything. Nothing the user did not offer may be committed (the write gate).

## Phase 2 — Execute the plan, task by task

For each task, in order:

1. **Follow the patterns already in this repo** — the plan named them; match the
   surrounding code's idioms, not a generic best practice.
2. Implement the task.
3. **Verify** with the repo's real command: use `verify_cmd` from
   `.compound-engineering/config.yaml` when the repo sets it (`config.md`),
   otherwise derive it from `package.json` per `repos.md` — typecheck first (the
   cheapest signal; on backend it is the root ratchet), then lint/test as present.
   On `rumor-backend-services`, jest runs **from the worktree root**. Address every
   command with `-C "$WT"` / an explicit path (LAW 3).
4. **Commit path-limited to that task's files** — name the files
   (`git -C "$WT" add path1 path2` then `git -C "$WT" commit path1 path2`). **Never
   `git add -A` / `git add .`** — that sweeps in `.env`, build output, and the
   user's pre-existing dirty set. A file that was already dirty before you started
   is included only if the user says so (standalone: ask once; return-to-caller:
   do not touch it — return blocked with the collision).

Keep going until every in-scope task is done and its done-check passes. Track
progress so a resumed run knows what is left.

## Phase 3 — Finish

- **Standalone:** run the local verify command once more clean, then hand off to
  **`rce-review`** (invoke the skill). The run is **not done** until `rce-review`
  has produced a receipt — never substitute self-review. Then `rce-ship` /
  `rce-compound` per the review outcome.
- **Return-to-caller (`rce-lfg`):** stop after verification. Return a structured
  envelope: `status: complete|blocked`, the worktree path, branch, the commits
  made, the verify evidence (the command and its result), and any residual. Do not
  run review, simplify, PR, or babysit — the caller owns the tail.

Report faithfully (LAW 10): the exact verify command and its real output. If a
test failed, say so with the output — do not report ship-ready on red.
