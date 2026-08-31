---
name: rce-plan
description: "Create a structured implementation plan for a Rumor repo, anchored to a Linear issue and written to docs/plans/. Use when asked to plan, break down, or scope work before building. Research and decide only -- never implement (that is rce-work). Rumor compound-engineering loop."
argument-hint: "[feature/task, or a Linear issue id, or a plan path to deepen] [mode:non-interactive for rce-lfg]"
---

# rce-plan — a plan an implementer can start from

**Outcome:** a durable plan in `<docs_root>/plans/`, anchored to a Linear issue,
that `rce-work` can execute without re-deciding anything. `rce-ideate` chose the
idea; this skill decides **how**; `rce-work` builds it.

**Research, decide, write the plan — never implement.** No production code, no
tests, no "change it to see what happens." Directional pseudo-code to communicate
design is fine.

**Interaction mode.** In `mode:non-interactive` (how `rce-lfg` invokes this skill),
ask nothing and pause for nothing: always produce a **Durable** plan, compose the
scope summary for yourself, record every inferred choice under Assumptions, and
proceed straight through to the written plan. Skip the Phase 3 menu — return the
plan path and the issue id instead. Interactive runs behave as written below.

## Load first (required)

1. `../rumor-compound/references/laws.md`
2. `../rumor-compound/references/repos.md` — repo + verify command (the plan must
   name how the change is verified in *this* repo).
3. `../rumor-compound/references/linear.md` — the Linear issue is the plan's
   **source of record**.
4. `../rumor-compound/references/config.md` — resolve `docs_root`.

## Phase 0 — Anchor to a Linear issue and scope

Resolve the active Linear issue (`linear.md`): the argument id, else the branch
id, else ask or offer to create one. `get_issue` it and read its comments — that
is the requirement of record. If there is genuinely no issue and the work is more
than trivial, **create one** (`save_issue`, autonomous per LAW 9) so the plan has
an anchor, and note its id.

Compose a one-paragraph **scope summary** — the issue, the surfaces the change
touches, what is in and out. In an **interactive** run, show it and confirm before
deep research. In **`mode:non-interactive`**, do not pause: record every inferred
scope choice under an Assumptions heading and proceed.

**Size the output** (pick one, fail toward the heavier):
- **Direct** — one-pass change, no decision the user would weigh: state it in a few
  sentences, offer the handoff to `rce-work`, stop.
- **Durable** — everything else, and always for auth / payments / migrations /
  external contracts, or any run with no synchronous user. Continue below.

## Phase 1 — Research (read-only)

Ground in the repo the issue names: the files that change, the patterns already
used there (follow them — do not introduce a new idiom), the relevant
`docs/solutions/` learnings, and the **verify command** from `repos.md`. Note the
laws that will bite `rce-work` (worktree, path-limited commits) and `rce-ship`
(merge policy, deploy). For a migration, note the TypeORM / enum / default-column
traps from the review checklist.

## Phase 2 — Write the plan

Write `<docs_root>/plans/YYYY-MM-DD-<type>-<slug>-plan.md`. Sections:

- **Issue:** the Linear id and one-line goal.
- **Approach:** the how, and why over the alternatives you rejected.
- **Tasks:** ordered, each with the files it touches and its done-check. Stable
  ids (T1, T2…) so `rce-work` and `rce-review` can reference them.
- **Verify:** the exact command(s) from `repos.md` that prove the change works in
  this repo, plus any test to add.
- **Risks & laws:** the specific laws/traps this change must respect.
- **Out of scope / residuals.**

Keep tasks small enough that each is one path-limited commit in `rce-work`.

## Phase 3 — Hand off

Post the plan link onto the Linear issue as a comment (`save_comment`, autonomous),
and move the issue forward to In Progress if it is not already (`list_issue_statuses`
→ `save_issue`; forward-only per LAW 9).

Then, **interactive only**, present exactly: **"Plan ready at `<abs path>`. Next?"**
with a menu: **Build it** (`rce-work <plan-path>`) · **Deepen the plan** ·
**Adjust scope** · **Stop.** Rendering the menu is not done — execute the selection.
In `mode:non-interactive`, present no menu: return the plan path and the issue id
to the caller and stop.
