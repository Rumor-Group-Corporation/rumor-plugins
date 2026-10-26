---
name: pre-pass
description: "Use before a Rumor feature, ticket or PR goes to Sarah/Gemma's QA pass or a demo, or before moving a ticket to In UAT: 'pre-pass', 'QA this before Gemma does', 'find every bug before the demo', 'does this match what we agreed', 'review this project end to end'. Covers web host portal, guest pages, admin, the Rumor Staging app, and the code. Not for answering PR review comments (rce-babysit) or a code-only review (thermos)."
argument-hint: "<PR url | RUM-1234 | Linear project name> [--web-only] [--no-stress]"
---

# pre-pass: find it before Gemma does

You are doing the QA pass that Sarah and Gemma would do, one round earlier, so
their pass finds nothing new. You find two kinds of problems:

1. **Bugs**: it breaks, the numbers are wrong, data leaks, state gets stuck.
2. **Drift**: it works, but not the way it was agreed.

**The bar: every finding is proven, and every cell of the test grid is marked
PASS, FAIL or BLOCKED with evidence. "Looks fine from the code" is not PASS.**

Violating the letter of these rules is violating the spirit. Be extremely
thorough: Gemma is.

## Rules that never bend

1. **Report first. No fixes, no commits, no PRs, no Linear or Slack writes**
   until the person who ran you says go, and then only for the items they pick.
2. **Look deeper before you call it a bug.** Before reporting anything, trace
   it end to end (UI → API → service → SQL), check sibling code that shows the
   same data, and search tickets/Slack for a ruling that made it intended. A
   finding with no repro and no traced cause is a hunch: put it in "Unverified",
   never in "Bugs".
3. **Your own QA accounts and your own `QA-pre-pass` events only, on UAT.**
   Never log in as Gemma, Sarah or any real person. Never edit data you did not
   create. Prod is read-only SQL through the `rumor-db` plugin; nothing else.
4. **Never solve or evade a CAPTCHA.** Log in through the API (see
   `references/access.md`).
5. **No customer PII** (names, phones, emails from prod) in the report.

## The run

Track these as tasks. Do them in order; each feeds the next.

1. **Intake.** Resolve the target to: tickets (with comments), PRs and their
   diffs per repo, feature flags and their UAT/prod state, the Linear project
   and its docs, prototype links, Figma links. Note which builds are live on
   UAT: backend = the latest successful GitHub "Deliver" workflow run on
   rumor-backend-services (`gh-axi run list -R <org>/rumor-backend-services
   --workflow Deliver`; the `delivered-main` tag is stale), web = the betahost
   deployment, app = the Rumor Staging build or OTA. For every ticket marked
   Approved, check each linked PR is merged and the fix covers the API, not only
   the screen (RUM-13577 was Approved while the API still sent the roster).
   A project with 50+ tickets: extract in batches of ~50 with the per-ticket
   template in `references/agreed-spec.md`.
2. **Agreed-behaviour ledger.** Build it from every source, newest ruling wins.
   Follow `references/agreed-spec.md`. Every row: rule, source, date. Gaps
   become questions, with "match regular RSVP" as the assumed answer. The
   ledger must end with a "Hidden rules" section (behaviour in code that no
   source mentions) and an "Unreadable sources" line.
3. **Read the logic.** For each flow in the ledger, read the code path in every
   repo it touches, including the screens and endpoints that show the SAME data
   (portal vs app vs admin vs export vs email/SMS). Write down where each
   rule is enforced. Missing enforcement is a lead to test, not yet a bug.
4. **Test grid.** Before touching UAT, write the grid: roles × surfaces × states,
   using `references/lenses.md`. Include every state-mix and every entry point,
   and an **API** column: the worst holes (another role acting, data sent but
   hidden on screen) only show up in direct calls.
   Show it to the user if it has more than ~60 cells and ask nothing else.
5. **Drive it live.** Reuse or create accounts from `references/qa-accounts.md`
   and set up events (`references/access.md`), then walk the grid on UAT web and
   the Rumor Staging app. `scripts/uat.mjs` (login, sign-up, export),
   `scripts/tables.mjs` (venue tables) and `scripts/portal-shot.mjs` (portal
   screenshot as a QA host) do the calls; append every call's result to a run
   log as you go. Screenshot every FAIL and one PASS per screen. Check counts
   across screens after every state change.
6. **Stress money and inventory** (skip only with `--no-stress` or when the
   feature has no money/limits): `references/stress.md`.
7. **Code review.** For a PR or a ticket: run
   `thermos:thermo-nuclear-review-subagent` on each PR's diff. For a project
   (dozens of PRs that supersede each other): audit the current code on main,
   one module per repo (backend / web / mobile), one subagent at a time,
   starting from the feature's routes. Feed it the ledger and your list of
   leads so it flags code that contradicts what was agreed. The code-quality
   subagent is optional here. If the thermos plugin is missing, do the same
   audit yourself. Re-trace every high finding end to end before it enters the
   report.
8. **Verify findings.** For each: reproduce once more from a clean state,
   confirm the build under test contains the latest code, and check it is not
   already ticketed (search Linear by symptom). Classify: Bug / Drift / Question
   / Already ticketed / Not a bug.
9. **Report.** Build the page in `references/report.md`, publish it privately,
   give the link. Then stop and wait for go.

Keep at most 2 background agents running at once. Good splits: one agent
gathers the ledger while you read code; thermos runs while you drive UAT. On a
big project, split ledger and code into separate agents from the start: both
together overflow one context.

## Gotchas from past runs

- Files over ~350 lines are blocked by the read-size hook. Read a slice:
  `git show origin/main:<path> | sed -n 'a,bp'` (`guest.service.ts` is ~40k lines).
- `gh pr list` silently stops at 400; pass `--limit 1000`.
- Branch names don't always carry the ticket ID; map ticket → PR by title too.
- The installed Rumor Staging app runs its own bundle (UAT), not Metro. Record
  its build or OTA id in the header. Deep link: `therumorapp://event/<id>`.
- Members made by API have no verified Instagram: the app stops them at
  "Almost in. Complete my profile", so Discover/Spotlight cells are BLOCKED for
  them. Ask the runner to verify Instagram for those QA accounts in admin, or
  drive those screens with an account that has it.

## Red flags: stop and do the real thing

| Thought | Reality |
|---|---|
| "The code handles it, no need to click through" | Gemma's #1 bounce reason is a fix that exists in code but not on the screen she used. Click it. |
| "Couldn't log in as that role, I'll read the code instead" | Mark the cell BLOCKED with the reason. Never PASS. |
| "Probably intended" | Find the ruling or make it a Question. Never silently drop it. |
| "The PR only changed one screen" | Every screen that shows the same data is in scope: portal, app, admin, CSV, email, SMS. |
| "Web works, the app uses the same API" | Portal vs app drift is the most common Tao bug class. Test both. |
| "It's just copy/spacing, Gemma won't care" | She files those. They count. |
| "Too many cells, I'll sample" | Collapse cells with the same code path only after proving it in code, and say so in the grid. |
| "I'll fix this small one while I'm here" | Report only. Fixes wait for go. |
| "This is a bug" (after reading one file) | Trace it end to end and look for the ruling first. |
| "UAT is broken, so it's not our bug" | Prove it: same failure on an untouched event, or a deploy log. Otherwise it's a finding. |

## Feature notes

Known history and past bug classes for features Rumor has shipped. Read the
one that matches before building the grid; past bugs regress:
`references/features/tao-venue-tables.md`, `host-reports.md`, `ticket-sales.md`.
After a run, add what you learned to the matching file (new bug classes,
account setup steps, gotchas) in the same PR as any fix.
