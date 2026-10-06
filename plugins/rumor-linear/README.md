# rumor-linear

Keeps the Linear board telling the truth.

```
/plugin install rumor-linear@rumor
/rumor-linear:hygiene              # your tickets
/rumor-linear:hygiene team Services
/rumor-linear:hygiene all --dry-run
```

## What a run does

1. Pulls every in-flight ticket in scope, plus to-do tickets touched in the last
   30 days and tickets marked done in the last 14.
2. For each ticket, reads its linked PRs and asks GitHub where that code is
   actually live: merged? deployed to UAT? promoted to prod? (`scripts/where-is-pr.sh`)
3. Works out the status the ticket should be in. The least-advanced PR wins, so
   backend live + web still in review means the ticket is In Review.
4. Shows you the plan: moves, decisions, reminders by person, PRs with no ticket.
5. On your yes, moves tickets forward and leaves a one-line comment on each with
   the proof. Anything backward (or Canceled/Duplicate) is asked one by one.
6. Optionally posts the reminders as Linear comments or drafts Slack DMs.

## Where "live" comes from

| Repo | UAT | Production |
|---|---|---|
| rumor-backend-services | `delivered-main` tag | newest `release/prod-*` release (Deliver promote) |
| grapevine | Vercel `uat – rumor-web` / `uat – rumor-studio` deployment | `Production – rumor-web` / `Production – rumor-studio` deployment |
| rumor-mobile-expo | merged to main (staging OTA) | JS: last `production-ota.yml` run · native: App Store (asks a human) |
| rumor-web-next | `uat` deployment | `Production` deployment |
| anything else | — | asks a human |

## What it will never do

- Move a ticket on a commit message, a comment saying "shipped", or a guess.
- Move a ticket backward, cancel it, or mark it a duplicate without asking.
- Set or clear `Approved` — that's QA's call.
- Touch Canceled / Duplicate / Unable to Reproduce / Figma Merge tickets, or
  design/PRD statuses.
- Override `Back to In Progress`, `Design Review`, `Do Not Auto-Advance`,
  `Leave in Dev` (all moves) or `HOLD FROM PROD PUSH`, `Blocked by PROD team`
  (prod moves).

## Needs

- The Linear connector in Claude Code.
- `gh` logged in with access to Rumor-Group-Corporation, and `jq`.
- Optional: the PostHog connector, to tell `In Production — Feature ON` from
  `Feature OFF`. Without it, flagged tickets get a reminder instead of a move.

## Relationship to rumor-ship-signal

`rumor-ship-signal` did the same job on a 15-minute cron, but its reconciler has
not advanced a watermark since 2026-08-05 (its last scheduled runs failed), it only watches web-2.0 (not grapevine), and
its ticket regex skips `SERVE-`. This skill reuses its rules (forward-only,
override labels, predates-work, lane-aware mobile) and runs on demand instead.
