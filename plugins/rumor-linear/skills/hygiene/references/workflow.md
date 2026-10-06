# Rumor's Linear workflow — what each status means and what proves it

Every Rumor team (Rumor `RUM`, Services `SERVE`, Pod 1 Supply `SUP`, Pod 2 Demand
`DEM`, Platform `PLAT`, Design) inherits ONE workflow from the Rumor parent team,
so the status names below are identical everywhere. State IDs differ per team:
always resolve a name to an ID with `list_issue_statuses <team>` at run time, never
hardcode IDs. If a name below is missing from a team, stop and say so — someone
renamed a state and every rule here needs re-checking.

## The ladder

Tickets move **forward** on evidence. Rank is what "forward" means.

| Rank | Status | Means | Evidence that puts a ticket here |
|---|---|---|---|
| 0 | `Backlog`, `Planned for Design`, `Design in Progress`, `Design in Review`, `Design Approved`, `PRD`, `Planned for Devs`, `Todo` | Not started. Design/PRD stages are owned by design and product — never set them. | — (human only) |
| 10 | `In Progress` | Someone is building it. | A branch exists, a PR is open as draft, or the assignee says so. Never set from a deploy. |
| 20 | `In Review` | A PR is open and waiting on review. | A linked PR is **OPEN** (not draft). Linear's GitHub integration sets this on PR open. |
| 30 | `In Preview` | Legacy: set by the retired ship-signal bot on PR open. Treat exactly like `In Review`. | Never target it. |
| 40 | `In UAT` | The code is **merged to main AND deployed to UAT**. Linear's GitHub integration sets this on merge — merged is not always deployed (see caveats). | `where-is-pr.sh` → every required PR `uat: yes`. |
| 50 | `Approved` | A human QA'd it on UAT and signed off. Linear types it `completed`, not `started`. | **Human only.** Never set it, never remove it. |
| 60 | `In Production` | Live for real users in production. | Every required PR `prod: yes`, and no feature flag gates it. |
| 60 | `In Production — Feature OFF` | Code is live in prod but hidden behind a flag that is off (or 0%, or staff-only) in prod. | Every required PR `prod: yes` + the gating flag verified off in prod. |
| 60 | `In Production — Feature ON` | Code is live in prod and its flag is on for real users. | Every required PR `prod: yes` + the flag verified on (>0% for non-staff) in prod. |
| −1 | `Canceled`, `Duplicate`, `Unable to Reproduce`, `Figma Merge` | Terminal / human judgment. | **Never touch.** A commit mentioning a cancelled ticket does not resurrect it. |

A ticket already at rank 60 may move **sideways** between the three
In Production states when the flag changes (OFF → ON after a rollout). That is
the only sideways move allowed without asking.

## Required PRs — what "the ticket's code" is

A ticket is as far along as its **least** advanced required PR.

1. Collect the ticket's GitHub PR attachments (`get_issue` → `attachments` whose
   url is `github.com/Rumor-Group-Corporation/<repo>/pull/<n>`). These are
   authoritative: Linear made them from the `[KEY-123]` title prefix, the branch
   name, or a human link.
2. Drop PRs that are **CLOSED unmerged** if another merged or open PR on the
   ticket does the same job (same repo **or its successor**: web-2.0 →
   grapevine, rumor-studio → grapevine; order of opening doesn't matter).
   Closed reverts that were never needed drop silently. Any other closed PR
   with no replacement is a finding, not a dropped PR.
2b. Drop **OPEN PRs in web-2.0** (frozen — they will never merge). Each one is
   an ASK: "close web-2.0#N? (port: grapevine#M / none found)". Without this
   one stale frozen PR pins a ticket at In Review while its grapevine port is
   live in prod.
2c. A PR whose title carries a **different** ticket key (`[RUM-10362]` attached
   to RUM-10342) still counts, but add a REMIND: "attached PR is titled for
   another ticket — intended?". If it's the only thing holding the ticket
   back, say so.
3. Drop PRs whose `surfaces` is `["none"]` (nothing deploys — docs, CI, tests,
   dev tooling). If **every** merged PR on the ticket is `none` and none are
   open, the ticket is tooling work that is live the moment it merges (CI runs
   from main): target `In Production` (check A17).
4. The rest are required. One open PR holds the whole ticket at `In Review`,
   even if a sibling PR is live in prod. (Backend live + web not merged = the
   user can't see it yet.)

A ticket that only *mentions* a PR in its description or comments, with no
attachment, has no required PRs. Report it ("PR mentioned but not linked") —
don't move on it. A commit message that names a ticket is not a delivery: this is
exactly how Backlog tickets got swept to In Production by the old bot.

## The predates-work rule

`In UAT` and `In Production` may only be set on a ticket that is already at
`In Progress` or beyond, **or** whose required PR was authored for it (the PR
title starts with `[THIS-KEY` or the branch contains `this-key`). A pre-work
ticket (rank 0) whose only link is a PR made for some other ticket stays put and
is reported.

## A human moved it backward — respect that

If `stateHistory` shows the ticket moved to a **lower** rank *after* the PR
that would now push it forward was opened (or merged), a person deliberately
pulled it back: a QA kickback, a design rejection, "parking" it. Any forward
move on that ticket becomes **ASK**, not MOVE, and the question quotes the
demotion ("moved In Progress → Backlog on 09-26, 8 min after backend#5147
opened — move it to In Review anyway?").

## Override labels — a human has taken control

| Label | Blocks |
|---|---|
| `Back to In Progress` | every automatic move |
| `Design Review` | every automatic move |
| `Do Not Auto-Advance` | every automatic move |
| `Leave in Dev` | every automatic move |
| `HOLD FROM PROD PUSH` | moves to any In Production state (UAT is fine) |
| `Blocked by PROD team` | moves to any In Production state |
| `no-loop` | nothing here — it only tells agent build loops to skip the ticket. Hygiene still applies. |

Labels can be workspace- or team-level; match by name, case-insensitive.

## Feature flags

Rumor gates risky work with PostHog flags (one project for UAT, one for prod) and
a backend flag table for some server features. A ticket is flag-gated when ANY of:

- it carries the `feature-flagged` label;
- its description, a comment, or a required PR body names a flag key (look for
  `flag`, `PostHog`, `feature flag`, a kebab-case key in backticks, "UAT 100%,
  Prod 0%");
- its title says "behind a flag" / "flagged" / "dark launch".

**Flags travel with the PR.** If any ticket attached to a PR is flag-gated,
treat every ticket whose deciding PR is that one as flag-gated too, and resolve
them together (four Ticket Sales tickets on one mobile PR, only two of which
say "flag" — they share one gate).

For a flag-gated ticket whose code is live in prod:

1. Find the key. If you can't, the target is undetermined → report, don't move.
2. If PostHog is connected, read the flag in **Rumor-Prod (project 471884)** —
   the connector defaults to Rumor-UAT (471885), so switch first. A UAT reading
   says nothing about prod:
   - inactive, 0% rollout, or only staff / internal / test-account conditions → `In Production — Feature OFF`
   - active with a non-zero rollout to real users → `In Production — Feature ON`
3. No PostHog access → report "live in prod behind `<key>`, flag state unknown",
   don't move. Never guess ON vs OFF.

A ticket with no flag evidence goes to plain `In Production`.

**A flag means a real flag key.** "flag" in a PR body that refers to a CLI
option (`--flag`), a DB column (`dont_recommend` flag) or a pause switch quoted
in a test scenario is not gating. Count it only when you can name the PostHog /
backend flag key and the PR or ticket says the feature sits behind it.

**Staff access gates are not feature flags.** The new admin sits behind
staff-only gates (`admin-users-table`, `admin-events`, the `/admin/staff/*`
guards). Those decide *who may use an internal tool*, not whether a feature is
dark-launched — a staff tool behind them that's live in prod is plain
`In Production`. Only flags that hide a feature from the users it's built for pick ON vs OFF.
For a tool built **for staff** (the admin, staff mobile admin, Member Review),
staff *are* those users: flag on for staff = `Feature ON`.

`In Production — Feature OFF` → plain `In Production` when the PRs say
explicitly there is no flag ("not PostHog-gated") is an **ASK** — someone chose
that status, maybe for a reason the PRs don't show.

## Deploy caveats the script surfaces (read them, they change the answer)

- **Backend docs/CI/test-only merges never deploy.** `Deliver` skips them; the
  script returns `surfaces: ["none"]` so they drop out of the required set.
- **Backend lambdas (`apps/lambda/**`) are not shipped by the prod promote.**
  `prod` comes back `unknown`. Ask the owner whether the lambda was deployed.
- **Backend prod moves only on a `Deliver` promote** (a `release/prod-*` GitHub
  Release). A merged-but-unpromoted PR is correctly `In UAT`, however old.
- **Mobile native changes** (ios/, android/, app.json, package.json, …) are live
  only when the App Store build is released. `prod: unknown` → report with
  "confirm the App Store version", don't move.
- **Mobile JS changes** are live when the next production OTA runs.
- **grapevine** deploys each app separately (`apps/web` → therumor.com,
  `apps/studio` → Studio). A shared-package change counts as both.
- **grapevine web prod** is promoted by a CLI redeploy and GitHub can miss
  recording one. `prod: no` on a change that looks visibly live → say so and let
  a human confirm; don't move.
- **web-2.0 is frozen** (grapevine replaced it on 2026-09-24, importing its
  history). The script reads web-2.0 merges against grapevine's web deploys, so
  pre-freeze work shows as live correctly. Only a web-2.0 merge that is *not*
  in grapevine history comes back `no` with a "may never ship" caveat.
- **Any repo without an oracle** (ask-rumor, enrichment, data-platform, infra,
  dispatch, …) returns `uat: yes` once merged to main (the same rule Linear's
  own automation uses) and `prod: unknown`. Past In UAT needs the owner.
- **rumor-infra** is terraform: merged ≠ applied. Always `unknown`; ask the
  owner whether the apply ran in each env.
- **Test-only changes** (e2e fixtures, `*.spec.ts`, playwright, CI) in grapevine
  or backend return `surfaces: ["none"]` — they ship nothing, so they never
  decide a ticket's status.
- **PRs merged into a branch other than main** (`dev`, `uat`, `development`)
  return `unknown` — that branch may never reach main.
