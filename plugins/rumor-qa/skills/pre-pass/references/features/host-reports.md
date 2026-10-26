# Host Reports

Linear project "Reports Dashboard" (P-RUM-214, lead Gemma). Spec: "PRD: Rumor
Reports" (Claude Doc, Gemma, 10-12) + its prototype (the PRD calls the
prototype the source of truth for layout and behaviour). Yehuda's v1 redesign
(grapevine #682) later changed parts (Page views tile, follower bands,
Standouts); later tickets treat the redesign as the spec. Flag `host-reports`.
QA rounds: 10-15/16, 10-20/22, 10-23.

## Agreed behaviour (summary)

- Hosts and venue hosts only; no collaborators, promoters or guests.
- Views = clicks on any request link (now including Spotlight opens in the app,
  RUM-13506). Requests = primary form + collaborator links + Rumor Network, not
  direct invites. Accepted = requests accepted. Invites = Confirmed − Accepted.
  Checked in = everyone scanned. Check-in rate = checked in ÷ confirmed.
- Change chips only when both periods have events; never on All time.
- 4+ events: default last 30 days, venue filter (venue-group hosts only, 2+
  venues). Fewer: All time, no chips, no venue filter.
- Export: CSV one row per event (RUM-13596 overrode the PRD's per-source rows),
  PDF in v1 per PRD (RUM-13293, not built).
- Mobile layout below 760 px; panels become bottom sheets.

## Bug classes

1. Impossible numbers: views < requests → "1418% requested" (RUM-13287);
   0-value pills; same guest in Best attendance and No-shows (RUM-13291); tiny
   samples ranked (RUM-13592).
2. Definitions narrower than the reader's model: Spotlight views missing
   (RUM-13506), upcoming events missing (RUM-13581), venue = city (RUM-13596).
3. Hidden thresholds not in the spec: tab only after 2 completed events
   (RUM-13322), "Not ranked: under 10" (RUM-13592).
4. Venue-only rules shown to every host (RUM-13292).
5. Counts that differ between dashboard, guest list and roles (RUM-13458,
   RUM-10366).
6. Empty states not standard (RUM-13595, RUM-13502).
7. Web-only fixes: CSV, empty copy, upcoming events, Standouts never reached the
   app.

Recompute every tile for one QA host from UAT SQL and compare with the screen.
