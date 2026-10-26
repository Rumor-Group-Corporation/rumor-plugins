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
5. Nothing says: assume **the house rule** and log a Question.

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
- Mockups attached to tickets: look at them (images), they are often the
  "expected".

## Ledger format

| # | Rule (one testable sentence) | Applies to (roles, surfaces) | Source + date | Confidence |
|---|---|---|---|---|
| 1 | A table request is approved or declined as a whole | host portal, host app | Spec doc 10-05; RUM-13349 comment 10-16 | ruled |
| 2 | Declined extra guest disappears from the list | portal, app, CSV | RUM-12992 | ruled |
| 3 | Empty feed shows the standard EmptyState | member app | none: house rule | assumed → Q3 |

- One rule per row, written so a test can PASS or FAIL it.
- Conflicts between sources: keep the winner, and list the conflict in the
  report's Questions ("PRD says one row per event and source; Gemma's RUM-13596
  says one row per event. Using RUM-13596.").
- Hidden thresholds the code enforces but no source mentions (e.g. "Reports tab
  only after 2 completed events", "Not ranked under 10") are Drift until a
  source agrees. Gemma was surprised by both.
- Scope adds that came after the spec (a ticket saying "add X") are rules too.
