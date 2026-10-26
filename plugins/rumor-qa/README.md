# rumor-qa

The QA pass before Sarah and Gemma's QA pass.

```
/plugin install rumor-qa@rumor
/rumor-qa:pre-pass RUM-1234                     # one ticket
/rumor-qa:pre-pass https://github.com/.../pull/5  # one PR
/rumor-qa:pre-pass "Venue Discover Feed (Tao)"  # a whole project, before a demo
```

Run it before you move a ticket to In UAT.

## What a run does

1. Collects what was agreed: the project spec and prototype, every ticket and
   comment, Slack threads the tickets came from, Figma. The newest explicit
   ruling wins; anything undecided becomes a question, with "match the regular
   RSVP flow" assumed.
2. Reads the code path for each rule in every repo, including every other
   screen that shows the same data.
3. Writes a test grid: every role (host, venue host, co-host, collaborator,
   check-in, member, table lead, table guest, guest, signed-out) against every
   screen (portal, host app, member app, `/p/` page, admin, CSV, email/SMS).
4. Walks the grid on UAT web and the Rumor Staging app with its own
   `QA-pre-pass` test-phone accounts and events, mixing states the way Gemma
   does (request then buy, confirm then edit, ...).
5. Attacks money and inventory on its own events (two buyers, double refund,
   expired hold, fee rounding).
6. Runs the thermos bug and code-quality reviews on the diffs.
7. Re-verifies every finding, then publishes a private report page:
   bugs, drift, questions for Sarah/Yehuda, code review, stress results, the
   grid, and what it left behind on UAT.

It fixes nothing until you say which items to fix.

## What it will never do

- Log in as a real person (Gemma, Sarah, a host), or change data it did not
  create.
- Write to prod. Prod is read-only SQL through the `rumor-db` plugin.
- Solve a CAPTCHA, or use "View as host" support sessions for QA.
- Post to Linear or Slack, or open a PR, without your go.

## Needs

- `rumor-db` (prod/UAT read-only SQL), `thermos` (code review), and for app
  testing `rumor-ui` (simulator loop) plus Xcode.
- A local `grapevine` checkout (it reuses the e2e login helpers).
- For features that need staff setup (approved members, venue groups,
  Spotlight), you sign in to UAT admin yourself in the browser pane once; it
  does the setup on its own QA accounts only.

Feature notes with past bug classes live in
`skills/pre-pass/references/features/`. Add to them after each run.
