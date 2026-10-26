# Tao: venue feeds, Spotlight, table requests

Linear project "Venue Discover Feed (Tao)" (P-RUM-204, lead Gemma). Spec: Linear
doc "Tao Spotlight: Engineering Review (Admin, Member, Host Portal, Host App)"
(Gemma, 10-05) plus the prototype artifacts it links. ~110 QA tickets, mostly
Gemma, rounds 10-08 → 10-23. Launch: NYC (Tao) then Miami (Riviera Dining
Group) with the Nov 2 member launch.

## Agreed behaviour (summary; rebuild the ledger from sources every run)

- **Admin**: curates the Spotlight "drops" carousel (spec: a drop expires when
  its event starts; code keeps it until the event ends, Q27); creates venue groups with a per-city Discover feed; links hosts
  (one group per host; every event of a linked host joins the feed; only admin
  removes); sets whether Rumor-network requests are comped.
- **Member**: finds nights in Spotlight or a venue feed. RSVP alone (0–3
  additional guests) or request a table of exactly 10 (head + 9). Head adds
  guests from contacts or by hand (first/last name, Instagram, phone or email).
  Table guests need no account and hear nothing until approval. After approval
  the head may request more guests (no limit).
- **Venue host** (Portal + App): reviews by Event Fit and reach, shortlists,
  confirms/declines tables as a whole with one ticket type for all; Confirm is
  disabled until a ticket type is picked. Never sees guests' phone/email.
  Declining an additional guest removes them. Check-in is per person.
- **Tao**: creates events in its own host account and approves every request.
  Approved tables held until one hour after doors.

## Bug classes that hit this feature (check every one again)

1. Same screen differs by entry point: Spotlight vs venue feed vs Events
   dashboard; Portal vs App (RUM-13471 event page differs by entry point,
   RUM-13473 ticket view, RUM-13461 locked-requests UI, RUM-13465 timeline).
2. Group vs person: table actions moving one person (RUM-13349 shortlist moved
   1 of 10; RUM-13370 extras put party in Confirmed and Requested).
3. Request source lost: "Rumor Network" missing on timeline, export, confirmed
   tab, venue+Spotlight events (RUM-13559, RUM-13536, RUM-13560, RUM-12993).
4. Privacy applied to the lead only: plus-ones' contact info in host network
   and CSV (RUM-13478); admin waiver visible to host (RUM-13464); share button
   for feed-access guests (RUM-13616).
5. Table state machine: swap before approval → ghost Declined (RUM-12984);
   edit confirmed table → back to Requested, event vanishes from guests' apps
   (RUM-13614); pending-table guests see the event as lead (RUM-13577);
   confirmed guest shown "Request a table" (RUM-13578); add someone already on
   the table (RUM-13617); can't un-shortlist (RUM-13072).
6. Data not carried across screens: questionnaire answers (RUM-13537),
   approved plus-one count (RUM-13467), existing profiles not matched from
   phone/email (RUM-13282), Instagram prefill (RUM-13528).
7. Hard blockers: requests could not submit at one venue (RUM-13526), table
   head QR scan fails (RUM-13369), error toast on every event open (RUM-13303),
   pre-approved members blocked from RSVP (RUM-13613).
8. Role views: check-in team blocked (RUM-13462), collaborator sees all
   requests (RUM-13466), request count differs across Host/Co-host/GLC/Check-in
   (RUM-13458), table guests see who checked in (RUM-12986).
9. Table-only UI leaking onto normal events ("+1 to review" tag, RUM-13472).

10. Other roles acting through the API while the screen hides it: a link-only
    guest-list collaborator and a check-in member with "Invite guests" could
    list, shortlist and decline every table (pre-pass 10-26). The table guest
    API returned the whole roster of a pending table while the list was hidden
    (RUM-13577 fix covered lists only).
11. Identity: the roster edit swaps the typed name for the matched account's
    real name with no rate limit; a guest typed by phone who signs up and
    requests alone blocks the table's confirm (409, no name).
12. Gates skipped on the table path: the Instagram check runs on solo requests
    only.

## Edge cases to always include

Venue host creating a non-venue event (RUM-13384); group with one venue / venue
with no group (RUM-13274, RUM-13523); venue with no events, empty feed
(RUM-12960, RUM-13271); event removed from Spotlight after a request
(RUM-13283); one person on a table and requesting alone (RUM-13608); host
approves a different plus-one count (RUM-13467); re-confirming a table sends
the right email/SMS again (RUM-13614); two devices editing one table
(RUM-13072); stale build or app cache (RUM-13559, RUM-13527, RUM-13331).

## Questions the first run should not have asked

The 10-26 run sent 8 product questions; the team read most as feature
requests. Two were bugs the spec already answered (a table guest requesting
alone: the spec's dev note; collaborators deciding tables: earlier rulings).
Four were ideas with nothing broken (partial re-review on a swap, a change log
for lead edits, host removing one guest, table sizes other than 10). Only the
Spotlight end time (spec vs build) and the Instagram check that differs
between table and solo requests needed anyone's attention.

## Setup for a run

Needs staff setup once (the runner signs in at betahost and opens admin): a
`QA-pre-pass Venue Group` with a venue location and the QA venue host linked,
"Visible in Discover" on, the comp setting you want, a Spotlight drop for your
QA event only, and QA member accounts approved (and Instagram verified if you
need the Discover screens). There is no "enable tables" switch: an event the
linked host creates at the group's venue address joins the feed and takes
tables automatically; admin only overrides the size (keep 10). Do not use the
"Tao Group" venue group or its events: they are Gemma's test data. After the
run, turn "Visible in Discover" off and remove the drop. Relevant API routes:
`rumor-backend-services/apps/events/src/routes/venue-table.routes.ts`
(`/admin/venue-groups...`, `/admin/spotlight-curation...`,
`/admin/events/:eventId/table-rsvp`, `/discover/...table-application...`,
`/events/:eventId/table-applications/...review`). Only the feed, policy and
submit routes check the `spotlight-venue-table-rsvp` flag; own-table read,
roster edit, cancel, extras and every host route skip it. Calls are in
`scripts/tables.mjs`.
