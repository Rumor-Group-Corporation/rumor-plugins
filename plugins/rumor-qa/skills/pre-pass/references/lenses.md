# Lenses: how Sarah and Gemma find bugs

Built from ~250 of their tickets (Tao venue + tables, Host Reports, Ticket
Sales, Oct 2026). Use every lens on every flow. Each lens lists the bug class it
catches and real tickets that show it.

## 1. Play every role, one after another, on the same event

Roles seen in their tickets (pick the ones the feature touches, then add one
role it should NOT touch, to check for leaks):

| Role | Surfaces |
|---|---|
| Admin / staff | `/admin` on web |
| Host (owner) | Host Portal (web), Host App |
| Venue-group host | Portal, App (venue filter, venue feed) |
| Co-host | Portal, App |
| Guest-list collaborator (GLC, full view and link-only) | Portal, App |
| Check-in team | Event Collaborator App / check-in screens |
| Member: pre-approved, approved, waitlisted, not a member | member app, `/p/` pages |
| Guest who requested; guest who bought; comped guest | `/p/`, app, ticket view, emails/SMS |
| Table lead; each table guest; plus-one; additional guest | app, `/p/`, ticket/QR |
| Signed-out visitor | `/p/`, shared links |

For each role ask: what can they SEE (counts, names, contact info, other
guests, sources), what can they DO, and does anything leak to a role that should
not see it (contact info of plus-ones, admin waivers, who else checked in).

## 2. Same data, every screen

The single most common bounce: fixed on one screen, still wrong on its sibling.
For every number or status, list every place it appears and compare them after
each state change:

- Host Portal vs Host App (RUM-13465, RUM-13461, RUM-13109)
- Spotlight vs venue feed vs Events dashboard vs Upcoming (RUM-13471, RUM-13473)
- Dashboard preview vs opened screen vs guest list (RUM-13458: "2 requested" →
  0 when opened; RUM-10366: 175 confirmed vs 94)
- On-screen vs CSV/PDF export vs email vs SMS vs push (RUM-12993, RUM-13596,
  RUM-13478: contact info hidden on screen, present in CSV)
- Summary card vs edit screen ("Update Application" used a different card,
  RUM-13453)
- Timeline/activity feed and request source ("Rumor Network" dropped in 6
  places)

## 3. Mix states: two actions in a row

Engineers test one action. Gemma tests the second action on top of the first.
For every pair of actions the feature allows, try A then B and B then A:

- request then buy; buy then comp; buy then host re-invites; buy then a guest-
  list ticket is assigned (RUM-9321, RUM-9320, RUM-9268, RUM-10117)
- check in then edit (RUM-9320)
- shortlist then add guest; confirm then edit; confirm then swap a guest;
  request extras after approval (RUM-13349, RUM-13614, RUM-13370, RUM-12984)
- host approves a different count than requested (RUM-13467)
- the event leaves Spotlight / venue feed / sale after someone acted on it
  (RUM-13283)
- one person in two roles: on a table AND requesting alone; buyer AND comped
  (RUM-13608)
- created on one surface, used on another (ticket type made on mobile can't be
  bought, RUM-9325)
- change quantity after verification (RUM-9264)
- cancel/undo after the irreversible step (Cancel RSVP after paying, RUM-13169)
- un-do every toggle: shortlist then un-shortlist (RUM-13072), publish then
  unpublish, flag on then off

## 4. Units: a group is not a person

Tables, parties and plus-ones are groups. Every action on the group must move
every member, and no member's own action may split the group (RUM-13349: one
moved, nine stayed). Check counts in persons AND in groups everywhere.

## 5. Numbers must make sense

Read every number like a skeptic: over 100% (RUM-13287 "1418% requested"),
negative, the same person in two exclusive lists (RUM-13291), a 0 shown as a
stat ("0 accepted · 0%"), a rate from 3 requests ranked against real ones
(RUM-13592), totals that don't equal the sum of their parts, a count that
changes when you open it. Recompute key numbers yourself from UAT SQL
(`rumor-db --env uat`) and from the API, and compare.

## 6. Edges of the account and the data

- Account shape: brand-new host, host with 1 event, 2, 4+; venue-group host vs
  plain host (RUM-13292); venue with no group; group with one venue (RUM-13523)
- Empty: no events, no requests, no confirmed guests, empty feed (RUM-12960,
  RUM-13502); the empty state must be the standard one (RUM-13595)
- Time: past vs upcoming vs live-now (RUM-13581); data created before the
  feature shipped (RUM-13506)
- Missing fields: no venue, no flyer, no Instagram, optional questions skipped
  (RUM-13288, RUM-10116, RUM-13596)
- Gates: password-protected event (RUM-9528), event with no terms (RUM-9263),
  phone verification skipped on another path (RUM-9265), Stripe not set up
  (RUM-13117)

## 7. Entry points and navigation

Open the same thing from every way in (notification, feed card, deep link,
`/p/` link, dashboard, search) and compare. Swipe back and forth; open, leave,
return (RUM-13468 "swiped back and venues were gone", RUM-13280 nav bar gone).

## 8. Is the fix really on this build?

Before calling a fix verified or a bug real: check the latest successful
"Deliver" workflow run on rumor-backend-services includes the commit (the
`delivered-main` tag is stale), the web UAT deployment includes it, and the Staging app
is on the OTA update that has it. A fresh TestFlight install gets the OTA only
on its SECOND launch (RUM-13104). Kill and relaunch the app twice. Cached
screens can stay stale for 10–20 minutes (RUM-13331, RUM-13527).

## 9. Flags

Test with the feature flag ON and OFF for the role. With it off, nothing of the
feature may show (Gemma asked that the app side stay hidden, RUM-13106). Note
the UAT and prod flag state; a flag flip mid-run invalidates the run (RUM-13109).

## 10. Design and copy

Compare against the ledger's design source (prototype, Figma, mockup in the
ticket). Check: copy word for word (Gemma writes exact replacement copy),
standard components, spacing and clipping at 390 px phone and a 13-inch laptop
at 100% zoom (RUM-10707), long names, tap targets, tooltips that open on tap on
mobile (RUM-13186).
