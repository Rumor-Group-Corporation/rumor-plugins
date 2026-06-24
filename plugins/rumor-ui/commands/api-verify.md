---
description: Probe a rumor-mobile-expo screen's backend endpoints with curl — prove each route exists, is auth-gated, and takes the right HTTP method before/after wiring the data layer.
argument-hint: "[feature or service file, e.g. guests]"
---

# /api-verify — prove the contract

Verify the backend contract for the endpoints behind: **$ARGUMENTS** (default: the feature
you just wired). Follow the `rumor-api-contract` skill.

## Steps

1. Find the endpoints + their methods in `src/lib/<feature>/service.ts` (the endpoint map and
   each call's `method` + `body`). List path + method for everything the screen touches.
2. Probe each against the local gateway (`EXPO_PUBLIC_API_BASE_URL`) with the **correct method**:
   `curl -s -o /dev/null -w "%{http_code}"`. Include one deliberately-bogus path as a 404 control.
3. Interpret: **401 = wired + auth-gated (pass)**, **404 = missing path OR method mismatch** —
   if a real route 404s, re-grep the verb and re-probe before concluding it's missing.
4. If a fix changed the request body/status, confirm the new shape matches the backend DTO
   (strict body, normalized `currentStatus`) and that a unit test locks it in.

Report a small table: `method path -> code (verdict)`, and flag any real route returning 404
(path/method bug) or any body that won't match the DTO. Don't claim the data layer is correct
without having probed it.
