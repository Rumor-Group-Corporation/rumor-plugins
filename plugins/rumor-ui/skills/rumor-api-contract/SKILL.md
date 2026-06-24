---
name: rumor-api-contract
description: Verify a rumor-mobile-expo screen's backend contract with curl before/after wiring the data layer — prove the route exists, is auth-gated, and takes the right HTTP method. Use when a screen calls an endpoint, when a fix changes a request body/status, or when "the endpoint 404s" needs disambiguating from a method mismatch.
---

# Rumor API Contract Verify

A screen is only as correct as the contract behind it. Before trusting (or blaming) a hook,
probe the real endpoint with `curl`. This is cheap, needs no token, and catches wrong paths,
wrong methods, and missing routes in seconds.

## What the status codes mean

Against the local gateway (`EXPO_PUBLIC_API_BASE_URL`, e.g. `http://localhost:8080`):

- **401** — route **exists and is auth-gated**. For a regression/contract check this is
  **success**: the path + method are wired; auth middleware fired before the handler.
- **404** — route **not matched**. Could be a genuinely missing path **or a method mismatch**
  (see below). Always include a deliberately-bogus path as a 404 control.
- **400 / 422** — route + auth fine, body failed validation — you reached the handler.

```bash
BASE=http://localhost:8080
EID=<event-uuid>
probe() { curl -s -o /dev/null -w "%{http_code}  $1 $2\n" -X "$1" "$BASE/$2" "${@:3}"; }

probe GET  "events/v1/collaborator/allocation/events/$EID"
probe POST "events/v1/collaborator/events/$EID/request-ticket" -H 'content-type: application/json' -d '{}'
probe GET  "events/v1/collaborator/allocation/events/$EID/NOPE-not-real"   # 404 control
```

## A 404 is often a METHOD mismatch, not a missing route

Nest/Express return **404 for an unmatched method**, not 405. So `POST`ing a `PUT`-only route
looks identical to a missing path. **Before concluding "endpoint missing," grep the service for
the actual verb** and re-probe:

```bash
# in rumor-mobile-expo
grep -n "manageGuests(" src/lib/guests/service.ts      # -> method: 'PUT'
```
```bash
probe POST "events/v1/events/manage-guests?eventId=$EID"   # -> 404 (misleading)
probe PUT  "events/v1/events/manage-guests?eventId=$EID" -H 'content-type: application/json' \
  -d '{"action":"DELETE","currentStatus":"APPLIED","inclusiveIds":["x"]}'   # -> 401 (route IS wired)
```

## Match the request body to the DTO exactly

The contract is the path **+ method + body shape**. When a fix changes what you send (a new
`currentStatus`, a normalized status, a trimmed strict body), confirm the keys match the
backend DTO — a non-strict body (extra keys) or a raw/display status (`SHORTLIST` where the API
wants `APPLIED`) is rejected even though the route is "right". Read the endpoint map in
`src/lib/<feature>/service.ts` and the service call's `method` + `body` before wiring the hook.

## When to run it

- **Before** wiring a TanStack hook to a new endpoint — confirm path + method first.
- **After** a fix that changes a request body or status mapping — confirm the new shape is what
  the route accepts (pair with the unit test that asserts the body).
- As a **regression check** in a verify pass: every endpoint the screen touches should 401, and a
  bogus control should 404. If a real route 404s, it's a path or method bug, not auth.

Pairs with [[rumor-ui-verify-loop]] (UI side) and [[rumor-behavior-testing]] (the unit test that
locks the body shape in).
