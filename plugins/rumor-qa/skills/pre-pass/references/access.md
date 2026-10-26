# Access: environments, logins, accounts

## Where you may act

| Env | What you may do | How |
|---|---|---|
| UAT web | Log in as your QA accounts, create and change `QA-pre-pass` events and their guests, buy with Stripe test mode | `https://uathost.therumor.com` (also `betahost`), API `https://uatapi.therumor.com` |
| UAT admin | Only with a staff session the person running you signs into themselves (see below) | `https://uathost.therumor.com/admin` |
| Rumor Staging app | Log in as your QA accounts on the iOS simulator | dev client with `APP_VARIANT=staging` |
| Prod | Read-only SQL. Nothing else | `rumor-db` plugin (`"$DB" query ...`) |
| Local | Anything; mock harness for admin screens | `grapevine/apps/web/e2e/helpers/admin-local-harness.ts` |

Before the first request, copy the allow-list shape from
`grapevine/apps/web/e2e/flows/guard.ts`: only UAT origins, never
`api.therumor.com`. If a URL is not on it, stop.

Do NOT use "View as host" support sessions for QA. The runbook
(`rumor-backend-services/docs/SUPPORT-ACCESS-RUNBOOK.md`) forbids browsing; they
are for a host who asked for help.

## Logging in on UAT (test phones)

UAT test numbers have the shape `+1 <area> 555 01NN` (regex
`^\+1[2-9]\d{2}55501\d{2}$`). For these, UAT sends no SMS, skips the
Turnstile check on the backend, and derives the code:

- Guest RSVP code (and app login): the last four digits.
- Host web-login code: `00` + the last four digits.

Never print a code or a token. Prod never does any of this.

**Host session in a browser** (the web login form keeps Continue disabled until
Turnstile passes, and you never solve a CAPTCHA, so log in through the API and
hand the browser the cookies):

1. `POST https://uatapi.therumor.com/users/v1/auth/otp/send` with
   `{phoneNumber, purpose:"login", clientType:"web", roleHint:"host"}`.
2. `POST .../users/v1/auth/otp/verify` with the same fields plus `code` and
   `sessionScopeId: "web:<32 hex>"`. Response `data.token`, `data.hostDetails`,
   `data.roles`.
3. Set the cookies the portal sets (copy `qaHostCookies` in
   `grapevine/apps/web/e2e/flows/host-web.ts`: `access-token`, `host-id`,
   `roles`, `company-details`, `current-user-role=host`, ...) in a Playwright
   context for `uathost.therumor.com`, then open the portal.

Working code: `grapevine/apps/web/e2e/flows/qa-host.ts` (`loginQaHost`) and
`host-web.ts` (`openHostContext`). Prefer running a small Node/Playwright
script that imports these helpers, over hand-driving the login.

**Guest / member on web**: the `/p/<code>` RSVP flow takes a test phone and
its 4-digit guest code in the browser (helpers in `e2e/flows/guest-web.ts`,
`phones.ts`). Use a NEW number per fresh guest (`newPhone` in `phones.ts`);
re-using one number on two accounts merges them.

**Member/guest in the app**: Rumor Staging on the simulator, phone login with a
test number, code = last four. Driving the simulator: follow
`rumor-ui:rumor-ui-verify-loop` (deep links, taps, screenshots). TestFlight
builds do not install on a simulator; build a dev client:
`cd rumor-mobile-expo && APP_VARIANT=staging npx expo run:ios`. First build
takes ~20 min. Check the bundle is the latest main (see lenses.md §8).

## Your QA accounts

Use one account per role, all on test phones, all named `QA-pre-pass <role>`.
Keep the registry in `qa-accounts.md` next to this file (phone numbers of UAT
test accounts are not secrets; codes and tokens are). Reuse before creating.
Check a number is free first (`phoneHolder` in `e2e/flows/qa-api.ts`).

Roles that need staff action once (approved member, venue-group host, Spotlight
curation, table RSVP enabled on an event, `support_operator`): the
`/admin/...` and `/events/v1/admin/...` endpoints require a real staff session
(an `@therumor.com` account that signed in with an email code). You cannot get
one. Ask the person running you to sign in to UAT admin in the browser pane
themselves, then do only the setup steps on your own QA accounts and events,
and say exactly which ones you did. Never touch other venue groups or curation
slots (e.g. "Tao Group" belongs to Gemma's testing).

## Test data hygiene

- Every event, venue group, table and guest name you create starts with
  `QA-pre-pass` (the e2e suite's `QA-e2e` prefix is theirs).
- Ticket purchases: Stripe test mode on UAT only, Stripe's published test cards
  only. If checkout shows a live-mode key, stop.
- At the end: cancel/soft-delete your events (`removeQaEvent` pattern in
  `qa-api.ts`), leave accounts for reuse, list everything you left behind in the
  report.

## Prod reads

`rumor-db` plugin only (`"$DB" --env prod query ...`, read-only, agent_bot).
Use it to check real-data shapes the feature will meet: how many hosts are in
venue groups, events with no venue, guests with no Instagram, largest party
sizes. Report counts, never rows with PII.
