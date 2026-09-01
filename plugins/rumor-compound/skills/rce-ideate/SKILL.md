---
name: rce-ideate
description: "Generate and critique grounded improvement ideas for a Rumor repo, grounded in the code AND open Linear issues, before committing to one. Use when the user wants ideas, directions, or 'what should we do about X' before planning. Not for refining one chosen idea (that is rce-plan). Rumor compound-engineering loop."
argument-hint: "[focus area, repo, or Linear team] [issue id to ground on]"
---

# rce-ideate — grounded ideas, the Rumor way

**Done:** a ranked ideation artifact in `<docs_root>/ideation/`, every idea
critiqued, survivors explained, and the user left holding a next-steps menu that
routes into `rce-plan`. No plans, no code.

## Load first (required)

1. `../rumor-compound/references/laws.md` — the laws bind even ideation (LAW 9:
   any Linear issue you create is autonomous but must not duplicate an existing
   one; LAW 1: propose teardowns, never perform them).
2. `../rumor-compound/references/repos.md` — which repo you are grounding in.
3. `../rumor-compound/references/linear.md` — Linear is a **grounding source**
   here, replacing GitHub Issues.

If the subject names no identifiable repo or area, ask once (numbered options,
keep "surprise me" real) — do not dispatch on an unidentified subject.

## Phase 1 — Ground before ideating

No advice detached from the repo. Gather grounding in parallel, in the foreground:

- **Repo scan.** The current repo (`repos.md` step 1): its structure, recent
  commits, the area the focus hint names, existing `docs/solutions/` learnings
  (do not re-propose a solved problem).
- **Linear scan** (this is the GitHub-Issues swap). Pull open issues for the
  relevant team with `list_issues` (filter by `team`, `state`, `query`, or the
  focus hint). Read them as signal: what is already filed, what is in flight, what
  keeps recurring. If an issue id was passed, `get_issue` it and its comments as
  the anchor. Grounding in what the team has *already said it wants* is what keeps
  ideas real instead of generic.

Warn and proceed if a grounding source is unreachable (e.g. no Linear MCP this
session) — say what you lost.

## Phase 2 — Generate many, critique all, explain survivors

Decompose the focus into 3-5 orthogonal axes, then generate the **full** candidate
list before critiquing any of it. Then critique every candidate against the repo
and the Linear signal — rejection is explicit and carries a reason (already filed,
infeasible here, violates a law, low leverage). Explain only the survivors.

Rank survivors by leverage × fit-to-what-Linear-shows-the-team-needs.

## Phase 3 — Write the artifact and route to planning

Resolve `docs_root` (`config.md`), create `<docs_root>/ideation/` if absent, and
write `YYYY-MM-DD-<topic>-ideation.md`: the grounding summary (repo + the Linear
issues consulted), the axes, each survivor with its critique, and the rejected
list with reasons.

Then present the **next-steps menu** and wait:
- **Plan one** → hand the chosen idea to `rce-plan` (invoke the `rce-plan` skill).
- **File it in Linear** → `save_issue` to create the idea as a tracked issue on the
  right team (autonomous per LAW 9; first confirm it is not already `get_issue`-able
  as an existing id, to avoid a duplicate).
- **Refine one** → hand to `rce-plan` for the requirements pass.
- **Stop.**

Never skip from ideation straight to code. Ideas become plans become worktrees.
