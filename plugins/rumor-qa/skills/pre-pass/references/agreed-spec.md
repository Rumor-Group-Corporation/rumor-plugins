# Building the agreed-behaviour ledger

"What we agreed" is spread across many places and they disagree. Collect all of
them, then resolve in this order (newest explicit ruling first):

1. A ruling in a Linear comment or Slack thread by Sarah, Gemma, Yehuda (design)
   or Josh ("JZ"): "we decided", "should", "expected:", "ya that was
   intentional", "Yehuda and I have decided on this logic". Newest wins.
2. The prototype artifact the spec links (Claude artifacts, Silvia's or
   Gemma's prototypes). The Reports PRD calls its prototype "the source of
   truth for layout and behavior".
3. The PRD / spec doc in the Linear project (Linear documents, Claude Docs).
4. Figma frames linked from tickets.
5. Nothing says: use **the house rule** as the expected behaviour. That is not
   a Question; see "What counts as a Question" below.

**The house rule** (what Gemma writes as "expected" when nothing was decided):
match the regular RSVP flow, the standard component (standard EmptyState,
standard request card, drawer vs modal as elsewhere), and the sibling screen
(portal = app; Spotlight = venue feed = Events dashboard; dashboard count =
guest list count).

## Where to look

- Linear: the project description, every project document, every ticket in the
  project including Canceled ones (cancel reasons are rulings), and all comments.
  Inline comments on docs carry `quotedText`.
- Tickets created from Slack ("@Linear create a ticket") link the thread. Read
  the thread (Slack MCP, read-only, `slack_read_thread`); decisions often stop
  there. Also search Slack for the feature name in release-blocker channels.
- The PR descriptions and their review threads: engineers sometimes record a
  product decision ("Gemma said X") only there.
- Prototype artifacts: read with the Artifact tool (`action: read`), never fetch.
  A multi-file prototype whose root read says "Loading…": list it with
  `scope: "files"` and read the board files with `paths`. One that says "not
  found" is not shared with this account: list it under "Unreadable sources",
  lower the confidence of rows only it would decide, and ask the runner for
  access before driving the grid.
- Slack beyond linked threads: few tickets link Slack, and rulings sit in the
  project channel. Read the project channel's full history, and search the
  project name in #membership-community and #release-blockers.
- Mockups attached to tickets: look at them (images), they are often the
  "expected".

## Ledger format

| # | Rule (one testable sentence) | Applies to (roles, surfaces) | Source + date | Confidence |
|---|---|---|---|---|
| 1 | A table request is approved or declined as a whole | host portal, host app | Spec doc 10-05; RUM-13349 comment 10-16 | ruled |
| 2 | Declined extra guest disappears from the list | portal, app, CSV | RUM-12992 | ruled |
| 3 | Empty feed shows the standard EmptyState | member app | none: house rule | house rule |

- One rule per row, written so a test can PASS or FAIL it.
- Conflicts between sources: keep the winner (newest explicit ruling) and
  test against it. Note the losing source in the row. It becomes a Question
  only when the order above cannot pick a winner (two rulings of the same date,
  or the newer one is ambiguous).
- Hidden thresholds the code enforces but no source mentions (e.g. "Reports tab
  only after 2 completed events", "Not ranked under 10") go in "Hidden rules"
  so the runner knows them. Gemma was surprised by both. They are Drift only
  when they contradict a source or the house rule.
- Scope adds that came after the spec (a ticket saying "add X") are rules too.

## What counts as a Question

A Question costs Sarah and Yehuda a decision, and a list of them reads as a
feature request list (the first Tao run sent 8; 2 were real). Before you write
one, sort the item through this, in order, and stop at the first match:

1. **A source answers it** (ruling, prototype, PRD, Figma, a ticket's
   Expected, a dev note in the spec): it is a **Bug** or **Drift** against
   that source. Do not ask again because a newer ticket repeats the question.
2. **The house rule answers it** (regular RSVP, standard component, sibling
   screen): test against the house rule. A FAIL is a Bug or Drift with
   "Expected: house rule". Not a Question.
3. **Nothing is broken today**, and the item is "should it also do X", "should
   the host be able to Y", "do we ever need Z", a change log, a new control, a
   new role, a narrower or wider scope: it is an **Idea**. It goes in the
   report's "Ideas, not asked" list and is never forwarded.
4. What is left may be a **Question**, and only if one of these is true:
   - **Sources conflict** and the order above cannot pick a winner; or
   - **The build contradicts a source on purpose**: a PR description, code
     comment or ticket shows the different behaviour was chosen (otherwise it
     is plain Drift); or
   - **A real person is stuck or harmed today** (cannot finish the flow, sees
     data they should not, loses money or a seat, two screens disagree) and
     no source or house rule says what should happen instead.

Every Question names the person hurt or the two sources that disagree, in one
line. If you cannot write that line, it is an Idea. Expect 0 to 3 Questions on
a normal run; more than 5 means you are asking about features.

Hidden rules (HR rows) follow the same sort: Drift when they contradict a
source or the house rule, a Question only under step 4, otherwise listed in
"Hidden rules" for awareness and nothing more.

## Required closing sections

- **Hidden rules**: behaviour the code enforces that no source mentions (a size
  limit, a cap, a time a thing expires, a role that passes a check). Number them
  HR1, HR2… with file:line. Sort each one with "What counts as a Question".
- **Unreadable sources**: every linked doc or prototype you could not open.

## Big projects: per-ticket extraction template

Extract in batches of ~50 tickets (one agent per batch), one block per ticket:

```
RUM-1234 · status · assignee · created → last activity
What happens: <plain words>
Expected: <as written by QA>
Rulings: <who, date, exact decision> (none → "none")
PRs: <repo#n, merged?>   Flags: <name>   Surfaces: <portal/app/admin/CSV/msg>
Open questions: <only a conflict or a stuck user; "should it also…" is an Idea>
```
