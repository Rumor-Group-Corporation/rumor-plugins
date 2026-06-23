---
description: Run the rumor-mobile-expo simulator verify loop — deep-link to a screen, screenshot, and report what actually rendered.
argument-hint: "[route or deep-link path]"
---

# /ui-verify — see it running

Verify the current change on the simulator for: **$ARGUMENTS** (default: the screen you
just edited). Follow the `rumor-ui-verify-loop` skill.

## Steps

1. Confirm the sim UDID + bundle id + Metro are up. Boot/launch via the XcodeBuild MCP if
   available; otherwise `xcrun simctl`.
2. Clean-reload the dev client and deep-link straight to the target route.
3. Screenshot and **Read the image** — describe what actually rendered, not what the diff
   implies.
4. If asked, drive the key interaction with `idb` (tap/swipe/text) and re-screenshot.
5. Exercise the relevant state(s) — e.g. `simctl privacy reset/grant` for permission gates.
6. If the screen doesn't match the code, run the **native/runtime gotcha** checklist before
   blaming the diff (dev-client rebuild, transient media error, env drift, stale fast
   refresh).

Report: rendered vs expected, any mismatch with the likely cause, and the next action.
Never claim "it works" without a screenshot you actually looked at.
