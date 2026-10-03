# Hygiene checks

Every check has an **action class**:

- **MOVE** — evidence-backed forward move. Goes in the batch the user approves once.
- **ASK** — a change that might be right but needs a human: backward moves,
  Canceled/Duplicate, closing parents, reassigning. Listed individually; applied
  only on an explicit yes for that ticket.
- **REMIND** — nothing to change in Linear; someone needs to do something. Goes
  in the per-person reminder list.

Thresholds are calendar days from `updatedAt` / the state's `startedAt` in
`stateHistory`. "Stale" never means "wrong" — it means "ask the owner".

## A. Status vs. reality (the core — needs `where-is-pr.sh`)

| # | Finding | Class | Target |
|---|---|---|---|
| A1 | Ticket at rank < 40, every required PR `uat: yes` | MOVE | `In UAT` (subject to predates-work) |
| A2 | Ticket at rank < 60, every required PR `prod: yes`, no flag evidence | MOVE | `In Production` |
| A3 | Same as A2 but flag-gated and flag state verified | MOVE | `In Production — Feature ON/OFF` |
| A4 | Same as A2, flag-gated, flag state unknown | REMIND (owner) | "live in prod behind `<key>` — flip status once you know" |
| A5 | Ticket at rank < 20, at least one required PR OPEN (not draft) | MOVE | `In Review` |
| A6 | Ticket at rank 0, a required PR is OPEN as draft | MOVE | `In Progress` |
| A7 | Ticket at `In Production*` but some required PR `prod: no` | ASK | back to `In UAT` (someone moved it early, or a revert) |
| A8 | Ticket at `In UAT`/`Approved` but some required PR is still OPEN | ASK | back to `In Review` — or confirm the open PR is a follow-up that should get its own ticket |
| A9 | Ticket at `In Review`, all its PRs CLOSED unmerged, none open | ASK | back to `In Progress`, or `Canceled` if the work was dropped |
| A9b | Started ticket below In Review whose attached PRs are **all** CLOSED unmerged with nothing open or merged | REMIND (assignee): "PRs were closed — link the replacement or cancel". Check sibling tickets' PRs for the likely replacement and name it |
| A10 | Started ticket (rank 10–50) with no PR attachment, and a PR in `untracked-prs.sh`-style output (or one you already fetched) carries `[THIS-KEY` in its title | MOVE | attach the PR link (additive), then re-evaluate. **Don't** full-text search GitHub for keys — `gh search prs SUP-729` matches PR #729 and bodies, and the search API rate-limits at 30/min. Linear auto-attaches any PR whose title or branch has the key, so a missing attachment is rare. |
| A11 | PR mentioned in description/comments, not attached | REMIND | "link the PR so status can follow it" |
| A12 | `prod: unknown` because of a native mobile change, a lambda, or a repo with no oracle | REMIND (owner) | name exactly what to confirm |
| A13 | Only PR is a merged **web-2.0** PR (frozen repo) | ASK | was it ported to grapevine? If not, it never shipped |
| A16 | Ticket at `In UAT` or later with no PR because the work is an operation (a backfill, a data fix, a config change) | REMIND (assignee): "is the operation done? Close it with a comment saying when and where it ran". Never move it yourself |
| A15 | Ticket at an In Production state with **no** attached PR | REMIND (assignee): "link the PR that shipped this, or reopen it". Look in the bodies of PRs you already fetched for the ticket key first (e.g. grapevine#336 naming web-next#4324) and suggest that link. Bulk moves to done are where these come from |
| A14 | Ticket carries a stale delivery label (`Pushed to Production`, `Merge to Production`, `Ready for Production`) that disagrees with the status | REMIND | the label is retired; status is the source of truth |

## B. Stalled work

| # | Finding | Class |
|---|---|---|
| B1 | `In Progress` > 7 days with no linked PR and no update | REMIND (assignee): still on it? |
| B2 | `In Review` (now, or after this sweep's move) > 3 days, PR open with no review / unresolved requested changes | REMIND (PR author + reviewers) |
| B3 | `In Review` (now, or after this sweep's move) PR has failing checks > 2 days | REMIND (PR author) |
| B4 | `In UAT` > 7 days, all PRs `prod: no` | REMIND (assignee / release owner): waiting on a promote? Backend needs a `Deliver` promote, web a Vercel prod promote, mobile an OTA or store release |
| B5 | `Approved` > 3 days, not in prod (Approved is state type `completed` — fetch it by name) | REMIND (release owner): QA passed — ship it |
| B6 | `In UAT` > 5 days, not `Approved`, and it's user-facing (not `eng-technical`) | REMIND (QA / ticket creator): needs QA on UAT |
| B7 | `Todo` / `Planned for Devs` / `PRD` > 30 days in its current status (clock from the latest entry in `stateHistory`), with or without a cycle | REMIND (assignee): still planned? |

## C. Ownership and fields

| # | Finding | Class |
|---|---|---|
| C1 | Started ticket (rank 10–60 not done) with no assignee | ASK: assign to the PR author |
| C2 | Ticket assignee ≠ PR author on every required PR | REMIND — informational, often fine (pairing, handoff) |
| C3 | Assignee is a deactivated/removed Linear user (`list_users` → inactive) | ASK: reassign |
| C4 | Started ticket not in the team's current cycle while the team uses cycles | MOVE (additive): add to current cycle |
| C5 | Completed ticket still in a future cycle (needs `list_cycles` per team to know which cycles are future) | REMIND |
| C6 | Ticket with no project while its siblings / parent / PR-mates share one | REMIND (suggest the project) |
| C7 | Due date in the past and not done | REMIND (assignee) |
| C8 | **Started** ticket with priority Urgent/High and not updated in 3 days (pre-work tickets are covered by B7 — don't double-nag) | REMIND (assignee) |
| C9 | Ticket in **Triage** > 2 days (only if a team has turned Triage on — none had as of 2026-10) | REMIND (team triage owner) |

## D. Structure

| # | Finding | Class |
|---|---|---|
| D1 | Parent with every child done (rank ≥ 50, i.e. Approved/In Production*, or terminal) and parent not done | ASK: move parent to the least-advanced child's status. If that is `Approved`, ask the human to set it (the sweep never sets Approved) or offer the lowest In Production state instead |
| D2 | Parent done, a child still open | ASK: cancel/move the child, or reopen the parent |
| D2b | Parent at rank 0 while any child is at rank ≥ 10 (children are being built, parent still says Backlog/Todo) | ASK: move parent to `In Progress` |
| D3 | Ticket `blockedBy` an issue that is done | REMIND: unblocked |
| D4 | Two open tickets with an identical (normalised) title | ASK: mark one `Duplicate`. Sharing a PR is **not** duplication — one parity PR often ships several distinct tickets |
| D5 | One PR attached to > 4 tickets | REMIND: probably a grab-bag PR; tickets may be reporting each other's progress |

## E. Untracked work (from `untracked-prs.sh`)

| # | Finding | Class |
|---|---|---|
| E1 | Non-routine PR, no ticket key in title/branch, url not a Linear attachment | REMIND (PR author): create or link a ticket, title `[KEY-123] …` |
| E2 | Routine PR (deps, CI, release, bot) with no ticket | summarised in one line, never chased |

## One reminder per ticket per person

C8 (stale high priority) only appears when no other row already covers that
ticket — otherwise fold "(Urgent)" into the existing row. The point is a list a
person can clear, not a wall of repeats.

## What is never a finding

- Missing estimates — Rumor doesn't estimate.
- Date-style labels (`8.25 NA`, `7.18`, …) — historical, leave alone.
- Tickets in `Canceled`, `Duplicate`, `Unable to Reproduce`, `Figma Merge`.
- Design-stage statuses (`Design in Progress` etc.) — design owns them.
