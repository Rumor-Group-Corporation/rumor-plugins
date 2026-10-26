# The report

The reader is the engineer who ran you, and Ruben. It is their to-do list
before handing the feature to Sarah and Gemma. It is not a note to Sarah or
Gemma. Only the Questions section is meant to be forwarded (to Sarah/Yehuda),
and only after the person who ran you has read it.

Publish it as a private page: if the `Artifact` tool exists, load the
`artifact-design` skill, write one HTML file, publish it, and give the link.
Otherwise write `pre-pass-<target>-<YYYY-MM-DD>.html` in the current directory
and give the path. Screenshots: downscale to ~900 px wide JPEG and embed as data
URIs (keep the page under 16 MB) or upload as artifact assets.

Write in plain words (the `rumor-house-style` voice): what happens, not code
jargon. File and line references go in a "Cause" line, not the title.

## Sections, in this order

1. **Header**: target (tickets/PRs/project), builds tested (backend tag, web
   deployment, app OTA update id), flag states, date, and a one-line verdict:
   "7 bugs (2 blockers), 3 drift, 2 questions, 4 ideas, 41/52 cells PASS,
   4 BLOCKED".
2. **Bugs**, blockers first. Each one in Gemma's format:
   - Title: `Area > Sub-area > Symptom` (e.g. `Confirmed Table > Change Guest >
     Table back to Requested`)
   - Severity: Blocker (data loss/leak, money, can't complete the flow) / High /
     Medium / Low (copy, spacing)
   - Current / Expected (expected cites the ledger row)
   - Steps: numbered, from a clean state, with QA account role and event link
   - Evidence: screenshot(s), and the API response or UAT SQL when useful
   - Cause: file:line and why (from the trace), or "not traced" (then it is not
     here, it is in Unverified)
   - Fix idea: one or two lines; sibling screens the fix must also cover
3. **Drift**: works, but not as agreed. Same format, Expected cites the ruling.
4. **Questions for Sarah / Yehuda**: only items that pass "What counts as a
   Question" in `agreed-spec.md` (a source conflict, a deliberate build choice
   against a source, or a person stuck today with no ruling). One per row: the
   person hurt or the two sources that disagree, what you assumed, and which
   tests depend on it. Short enough to paste into Slack as is. None is a fine
   answer; write "No open questions".
5. **Code review**: verified thermos findings only (high first), with file:line.
   Say how many raw findings were dropped as not real.
6. **Stress results**: each attack, PASS/FAIL, what happened.
7. **Test grid**: rows = roles, columns = surfaces, cell = PASS / FAIL (link to
   the finding) / BLOCKED (why) / N/A. Below it, the state-mix list with
   results. Show where cells were collapsed because they share a code path.
8. **Already ticketed**: findings that match an open ticket (ID + plain words).
9. **Unverified**: hunches you could not reproduce or trace, and why.
10. **Ideas, not asked**: "should it also do X" items where nothing is broken
   (step 3 of the sort). One line each. Never forwarded, never fixed on go
   unless the runner picks one as a new ticket.
11. **Ledger**: the agreed-behaviour table you tested against.
12. **Left behind**: QA accounts used, events created and whether cleaned up,
    any admin setup the person running you did for you.

Every ticket or PR ID in the page gets a few plain words next to it.

## After publishing

Reply with: the link, the verdict line, the top 3 blockers in one line each, and
the question "Which of these should I fix?" Then stop. On go: one branch per
repo off `main`, fix only the picked items (plus the sibling screens named in
each), run that repo's gates, open PRs with the ticket ID in the title, and
re-run the affected grid cells on UAT after deploy.
