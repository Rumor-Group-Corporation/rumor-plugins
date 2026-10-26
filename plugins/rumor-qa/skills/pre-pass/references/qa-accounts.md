# QA accounts on UAT

UAT test numbers only (no SMS; codes derived, see access.md). These numbers are
not secrets. Never write codes or tokens here. Reuse before creating; check the
role state first (`rumor-db --env uat`).

| Phone | Name | Role | State (2026-10-26) |
|---|---|---|---|
| +19755550180 | QA-pre-pass Venue Host | host, linked to `QA-pre-pass Venue Group`, comp override on | approved |
| +19755550181 | QA-pre-pass Cohost | host; co-host on the QA event | approved |
| +19755550182 | QA-pre-pass Plain Host | host, NOT in a venue group; contributor (link only) on the QA event | approved |
| +19755550184 | QA-pre-pass CheckIn | member; check-in team with "Invite guests" on | approved |
| +19755550185 | QA-pre-pass Table Lead | member | approved, Instagram not verified |
| +19755550187 | QA-pre-pass Solo Member | member | approved, Instagram not verified |
| +19755550188 | QA-pre-pass Table Guest | member, added to tables by phone | approved, Instagram not verified |
| +19755550190 | QA-pre-pass NewGuest | member sign-up, typed on a table before it existed | NEW_APPLICANT |
| +19755550191 | QA-pre-pass LeadA | member, second lead for stress | approved |
| +19755550195 | QA-pre-pass LeadB | member, second lead for stress | approved |

Free numbers in the same block on 2026-10-26: +19755550197, 0198, 0199. Need
more: pick a new `+1 975 555 01NN` and check it with `phoneHolder` in
`grapevine/apps/web/e2e/flows/qa-api.ts` first.

Roles still worth creating: a guest-list collaborator with Full View, a
waitlisted member, and a member with Instagram verified (for Discover screens).

## How they were made (API, no CAPTCHA involved)

`scripts/uat.mjs`:

- `signupHost(phone, first, last, company, email)`: role starts
  `NEW_APPLICANT`; web login answers "Host not found" until staff approve it.
- `signupMember(phone, first, last, email)`: account starts
  `non_member: NEW_APPLICANT` with no Instagram; app login works right away,
  member features need staff approval.
- Collaborators and check-in team: invited by the QA host
  (`POST /events/v1/collaborator/events/:eventId` with `{phone,
  userFromContact:true, role}`), accepted by the invitee
  (`PUT /events/v1/collaborator/events/:eventId/accept/`).
