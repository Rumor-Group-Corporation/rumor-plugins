---
name: rumor-ui-verify-loop
description: The pixel-tight simulator verify loop for rumor-mobile-expo, plus the native/runtime "it's not your code" gotchas. Use when verifying a UI change on the iOS simulator, deep-linking to a screen, driving taps/swipes, screenshotting to compare against Figma, or debugging a native module / dev-client / env crash.
---

# Rumor UI Verify Loop

The highest-leverage habit after a UI change: **look at it.** Don't trust the diff.

## The loop

```bash
U=<sim-udid>; BID=<bundle-id>; SCHEME=rumorexpo
# clean reload of the dev client, then deep-link straight to the screen under test
xcrun simctl terminate $U $BID
xcrun simctl openurl $U "$SCHEME://expo-development-client/?url=http%3A%2F%2F127.0.0.1%3A8081"
sleep 15
xcrun simctl openurl $U "$SCHEME://profile/rumor-mutuals"   # the target route
xcrun simctl io $U screenshot /tmp/shot.png                  # then Read /tmp/shot.png
```

Prefer the **XcodeBuild MCP** tools when available (boot/build/run/screenshot/UI
automation); fall back to `xcrun simctl` + `idb` for anything they don't cover.

## Drive interactions + find targets

```bash
idb ui describe-all --udid $U          # list elements; filter by AXLabel to find targets
idb ui tap  --udid $U <x> <y>
idb ui swipe --udid $U <x1> <y1> <x2> <y2>
idb ui text --udid $U "search query"
```

## Exercise the state matrix on a real device surface

```bash
xcrun simctl privacy $U reset contacts $BID   # pre-grant gate / empty state
xcrun simctl privacy $U grant contacts $BID   # granted path
xcrun simctl io $U recordVideo --codec h264 /tmp/demo.mp4   # ^C to stop -> PR demo
```

GitHub has no API to attach a video to a PR comment — record it, then drag the file into
the PR in the web UI.

## Measure, don't guess

When "the spacing looks off," pull exact values from Figma `get_design_context` and, if
needed, compute the rendered pitch from `idb ui describe-all` element frames to prove the
gap. (A real bug we caught: a virtualized-list `gap` silently didn't apply -> ~2px instead
of 12px -> fixed with an `ItemSeparatorComponent`, not a `className` tweak.)

## Native / runtime gotchas — the "it's not your code" file

If behavior doesn't match the code you wrote, suspect the **runtime** before the diff:

- **Native dep bumps need a dev-client rebuild.** Symptom: red screen
  `Cannot find native module 'ExpoXxx'` after merging in a branch that added a native
  module. Fix: rebuild the dev client.
  ```bash
  ( cd ios && rm -rf Pods Podfile.lock && pod install ) && npx expo run:ios --device "$U"
  ```
  (A stale `ExpoModulesCore` podspec is why the full `rm -rf` is needed, not a plain
  `pod install`.)
- **Transient media errors latched as permanent.** A flat dark circle where a video should
  be was a transient `expo-video` `error` status treated as terminal. Fix: self-heal — on
  `error`, `player.replace(src)` + `play()` a bounded number of times before falling back.
- **Env config drift.** A merge that adds a required `EXPO_PUBLIC_*` key crashes at
  `env.ts` import on cold start — looks like an app bug, is a local `.env` gap. Check
  `env.ts`'s required keys first.
- **Fast refresh lies under churn.** If hot reload won't apply, do a full terminate +
  dev-client reconnect before debugging your code.

## Watch CI deterministically

```bash
RID=$(gh run list --branch <branch> --limit 1 --json databaseId -q '.[0].databaseId')
until [ "$(gh run view "$RID" --json status -q .status)" = "completed" ]; do sleep 15; done
gh run view "$RID" --json conclusion -q .conclusion
```
