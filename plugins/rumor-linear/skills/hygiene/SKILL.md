---
name: hygiene
description: "Sweep Rumor's Linear board and put every ticket in the status it should be in, from evidence: which PRs are merged, deployed to UAT, promoted to prod, and whether a feature flag hides them. Moves forward on proof, asks before anything backward, and produces per-person reminders (stale work, missing links, untracked PRs, waiting on QA or a promote). Use when someone says 'linear hygiene', 'clean up Linear', 'sweep the board', 'are my tickets in the right status', 'what's stuck', or runs /rumor-linear:hygiene."
argument-hint: "[mine | team <name> | project <name> | person <name> | all] [--dry-run] [--yes] [--days N]"
---

# Linear hygiene

Make Linear tell the truth. Every ticket ends the run in the status its code has
actually reached, and every person gets a short list of what only they can fix.

**Accuracy beats coverage.** A wrong move is worse than a missed one: it hides
work, or tells a host something is live when it isn't. So: move only on proof,
never on a hunch, and when the proof is missing say exactly what's missing.

Read these before the first evaluation — they hold the rules, this file holds the
procedure:

- `references/workflow.md` — the status ladder, what proves each status, override
  labels, feature flags, per-repo deploy caveats.
- `references/checks.md` — every check, and whether it's MOVE, ASK or REMIND.

## Arguments

| Arg | Scope |
|---|---|
| *(none)* or `mine` | tickets assigned to the person running it |
| `team <name or key>` | one team: Rumor/RUM, Services/SERVE, Pod 1 (Supply)/SUP, Pod 2 (Demand)/DEM, Platform/PLAT, Design |
| `project <name>` | one project |
| `person <name or email>` | one teammate's tickets |
| `all` | every team — use subagents (step 3) |
| `--dry-run` | report only, change nothing |
| `--yes` | apply the MOVE batch without the confirmation prompt (ASKs still ask) |
| `--days N` | look-back for recently-shipped tickets and untracked PRs (default 7) |

## Step 0 — Preflight (stop if any fails, say which)

1. **Linear MCP.** Find the tools by capability with the host's tool search
   (query `linear`): you need `list_issues`, `get_issue`, `list_issue_statuses`,
   `list_teams`, `list_users`, `save_issue`, `save_comment`. No Linear tools →
   stop: "connect the Linear connector, then rerun".
2. **GitHub.** `gh auth status` must show access to `Rumor-Group-Corporation`;
   `jq` must exist. Without them there is no evidence → stop.
3. **Statuses.** `list_issue_statuses` for each team in scope. Confirm every name
   in `references/workflow.md` exists. A missing or renamed state → stop and
   report it; the rules would be wrong.
4. **Who's running.** `get_user me` → name, email. "mine" means this person.
5. **PostHog (optional).** Tool search `posthog`. The PostHog connector is one
   `exec` tool; its default project is **Rumor-UAT (471885)**. Flag state for
   status purposes must come from **Rumor-Prod (471884)** — switch project before
   reading a flag, and say which project every reading came from. No PostHog →
   flag-gated tickets get REMINDs instead of moves.
6. **GitHub login** for untracked PRs: `gh api user --jq .login` (it is not the
   Linear name).

Scripts live next to this file. Resolve their absolute path from this skill's
directory and call them by full path:

- `scripts/where-is-pr.sh <pr-url>...` → one JSON line per PR: `state`,
  `surfaces`, `uat`, `prod` (`yes`/`no`/`n/a`/`unknown`), `evidence`, `caveats`.
- `scripts/untracked-prs.sh [days] [github-login]` → PRs with no ticket key.

## Step 1 — Collect candidates

Pull, for the scope, with `fields` set to keep responses small
(`title,status,statusType,team,assignee,project,labels,updatedAt,priority,dueDate,parentId,cycleId,createdBy`)
and `limit: 250`, paginating with `cursor` until `hasNextPage` is false.
`list_issues` takes ONE `state` per call, so this is several calls:

1. `state: started` — In Progress, In Review, In Preview, In UAT.
2. `state: Approved` **by name** — Linear types Approved as `completed`, so the
   `started` pull misses it, and an Approved ticket stuck for weeks is exactly
   what B5 exists to catch. No date filter.
3. `state: unstarted` and `state: backlog`, `updatedAt: -P30D` (A5/A6: a PR
   opened on a Todo ticket).
4. The three In Production states by name, `updatedAt: -P<days>D` — only for A7
   (marked live too early). Skip their B–D checks; they're done.

Never fetch or touch `canceled` / `duplicate` types.

Write the candidate list to a scratch file (id, title, status, team, assignee,
updatedAt). Say the count before going further: "142 tickets in scope: 61 started,
53 to-do, 28 recently done."

## Step 2 — Enrich each ticket

For each candidate, `get_issue <id>`. `includeRelations: true` returns
blocks / related / duplicates but **not** parent or children, so for D-checks
build the parent map from the step-1 `parentId` field, and call
`list_issues {parentId}` only for tickets that some other candidate names as
its parent (or whose title says "parent"). Keep:

- `attachments` → the GitHub PR urls (`github.com/Rumor-Group-Corporation/*/pull/*`)
- `stateHistory` → when it entered its current status (for stale thresholds)
- `labels` → override labels, `feature-flagged`, retired delivery labels
- `description` → flag keys, PRs mentioned but not attached
- relations → parent/children/blocks/duplicates

Then call `where-is-pr.sh` **once** with every distinct PR url (it caches deploy
heads per call — one call with 80 urls is far cheaper than 80 calls). Save the
JSON lines to scratch and join them back to tickets.

For `untracked-prs.sh`, run it once for the scope's people (or everyone for
`team`/`all`), then drop any PR whose url appears as an attachment on any ticket.

## Step 3 — Big scopes: fan out

More than ~60 tickets (common even for `mine` — an active engineer can have 200):
split by team, or by assignee / status for one big team, ~40 tickets per slice,
and give each slice to a subagent. Each subagent must call `where-is-pr.sh` once
for its whole slice (it runs 8 PRs in parallel; ~4s per PR serially would blow
the 10-minute Bash timeout on a big slice) with a Bash timeout of 600000. Each subagent gets:
the absolute path of this skill directory, its slice of ticket ids, the status
name→ID map for its team, and the instruction "do steps 2 and 4 only; return the
plan rows as JSON; change nothing". You merge the plans and do steps 5–8 yourself
so there is one approval and one report.

## Step 4 — Evaluate

For each ticket, in this order (first matching rule wins for the status target):

1. Terminal state, or override label that blocks this move → skip the move (still
   run B–D checks for reminders).
2. Work out the required PRs (workflow.md → "Required PRs").
3. Compute the target from the least-advanced required PR:
   - any OPEN non-draft → `In Review`; any OPEN draft → `In Progress`
   - all merged, any `uat: no` → stays where it is if ≥ `In Review`
   - all `uat: yes`, any `prod: no` → `In UAT`
   - all `prod: yes` → `In Production` (or the flag variant, workflow.md → flags)
   - any `unknown` at the deciding step → no move; REMIND with the caveat text
4. Compare target rank with current rank:
   - target higher → **MOVE** (apply predates-work rule first)
   - target lower → **ASK** (A7/A8/A9), never automatic
   - same → nothing
   - current is `Approved` and target is `In UAT` → nothing (Approved outranks it;
     never remove an approval)
5. Run every B, C, D, E check from `references/checks.md` and record the
   findings with their class and the person they're for.

Each plan row: `ticket, title, assignee, current → target, class, reason`, where
**reason names the proof**: "grapevine#451 live on therumor.com (deploy
648b19c, 10-02); backend#5293 in release/prod-8f4c8ef". A row with no concrete
reason is a bug — drop it.

## Step 5 — Show the plan

One message, scannable, in this order:

1. **Counts.** "Checked 142 · 23 moves · 6 need a decision · 31 reminders for 7 people · 12 untracked PRs."
2. **Moves** (MOVE), grouped by target status, one line each:
   `RUM-10508 Tastemaker counts — In UAT → In Production · backend#5293 in release/prod-8f4c8ef, grapevine#451 live`
3. **Decisions** (ASK), numbered, each with the proposed change and why.
4. **Reminders** (REMIND), grouped **by person**, most urgent first. Each line is
   an action that person can take in under a minute, with the ticket link.
5. **Untracked PRs**, grouped by author; routine ones as one count line.
6. **Couldn't verify**: tickets left alone because evidence was `unknown`, with
   the exact thing a human must confirm.

If `--dry-run`, stop here.

## Step 6 — Apply

1. Unless `--yes`, ask once: "Apply these N moves?" (yes / no / let me pick).
   "Let me pick" → multi-select by ticket.
2. For each approved MOVE: re-read the ticket's current status first (someone may
   have moved it while you were working — if it changed, re-evaluate, don't
   overwrite), then `save_issue {id, state: <target name>}`.
   Then `save_comment` on the ticket, one short line with the proof:
   > Status → In Production. backend#5293 is in release/prod-8f4c8ef (10-02) and grapevine#451 is live on therumor.com. _(Linear hygiene sweep)_
3. Additive fixes approved with the batch: attach a missing PR link
   (`save_issue {id, links:[{url,title}]}`), add to current cycle.
4. ASKs: one question per decision (batch up to 4 per `AskUserQuestion` call).
   Apply only what was answered yes. Same re-read-then-write rule.
5. Never: delete, archive, change priority, change assignee without a yes, set
   `Approved`, set design/PRD statuses, touch a terminal ticket, remove labels.

## Step 7 — Reminders out

Ask how to deliver the reminders (default: just the report):

- **Report only** — the per-person list in chat. Done.
- **Linear comment** — one comment per ticket that has a REMIND, mentioning the
  owner (`@displayName`) with the one-line action. Additive, but it notifies
  people: confirm the count first ("post 31 comments to 7 people?").
- **Slack** — draft one DM per person (or one channel post) with their list.
  Use a draft/send-later tool if one exists; never send without an explicit yes.

## Step 8 — Verify and close

Re-read every ticket you moved and confirm the status stuck. Then report:

- moved: N (list ids) · skipped by override: N · decisions applied: N
- anything that failed to write, with the error
- the "couldn't verify" list again — that's the human's to-do

## Rules that never bend

- **Forward on proof only.** Proof = `where-is-pr.sh` output for an attached PR.
  A commit message, a comment saying "shipped", or a ticket's age is not proof.
- **Backward always asks.** Including In Production → In UAT.
- **Least-advanced PR wins.** Backend live + web unmerged = not live.
- **Approved is human.** Never set, never cleared.
- **Unknown means no move.** Say what's unknown and who can resolve it.
- **Re-read before write.** The board is live; other people and bots edit it.
- **Don't paste prod data** (member names, emails, phone numbers) into Linear or
  Slack. Ticket titles and PR numbers only.
