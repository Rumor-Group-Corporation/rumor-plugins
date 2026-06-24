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

**Deep-link with a scheme the dev build actually registered** — `rumorexpo`,
`com.alaboparallel.rumor-mobile-expo` (the bundle id), or `exp+rumor`. The *production* app
schemes (`rumor://`, `therumorapp://`) are NOT in the dev client, so `rumor://events/…`
fails with `LSApplicationWorkspaceErrorDomain code=115` and you silently stay on the current
screen. Discover the registered set from the installed app:
`plutil -extract CFBundleURLTypes json -o - "$(xcrun simctl get_app_container $U $BID)/Info.plist"`.

Prefer the **XcodeBuild MCP** tools when available (boot/build/run/screenshot/UI
automation); fall back to `xcrun simctl` + `idb` for anything they don't cover. Note:
XcodeBuild MCP `snapshot_ui`/`record_sim_video` need session defaults
(`session-set-defaults { simulatorId }`) first, and its `tap` may be gated off — `simctl io
$U recordVideo --codec h264 --force out.mp4` (SIGINT to finalize) + Argent taps is a reliable
fallback for capturing a transition video.

## Drive interactions + find targets

```bash
idb ui describe-all --udid $U          # raw AX dump (JSON) — pipe through the parser below
idb ui tap  --udid $U <x> <y>
idb ui swipe --udid $U <x1> <y1> <x2> <y2>
idb ui text --udid $U "search query"
```

**Argent `gesture-tap` uses NORMALIZED coords** (`--x 0.5 --y 0.9` = center-bottom), unlike
`idb`'s points — so an Argent tap is resolution-independent and handy when you only have a
screenshot to eyeball from (estimate the fraction of width/height). `idb` taps still need the
AX-frame center in points (below).

**`idb` coordinates are POINTS, not screenshot PIXELS.** A simulator screenshot is 2×/3×
the logical size, so a coord measured off `/tmp/shot.png` lands in the wrong place. Always
tap the **center of the element's AX frame** (already in points), never a pixel read off the
PNG. Drop this parser at `/tmp/uidesc.py` and feed it the describe dump — it prints
`type | 'label' | cx cy` (frame centers, ready to `tap`):

```python
# /tmp/uidesc.py — usage: idb ui describe-all --udid $U | python3 /tmp/uidesc.py [filter]
import sys, json, re
rows = json.load(sys.stdin)
needle = (sys.argv[1] if len(sys.argv) > 1 else "").lower()

def center(el):
    # idb versions differ: most emit a numeric `frame` object; some only the
    # `AXFrame` string "{{x, y}, {w, h}}". Handle both so coords are never (0,0).
    f = el.get("frame") or {}
    if all(k in f for k in ("x", "y", "width", "height")):
        return f["x"] + f["width"] / 2, f["y"] + f["height"] / 2
    nums = re.findall(r"-?\d+\.?\d*", el.get("AXFrame", ""))
    if len(nums) == 4:
        x, y, w, h = map(float, nums)
        return x + w / 2, y + h / 2
    return 0, 0

for el in rows:
    cx, cy = center(el)
    label = el.get("AXLabel") or el.get("AXValue") or el.get("title") or ""
    t = el.get("type") or el.get("role") or "?"
    line = f"{t} | '{label}' | cx={int(cx)} cy={int(cy)}"
    if needle in line.lower():
        print(line)
```

```bash
idb ui describe-all --udid $U | python3 /tmp/uidesc.py "Remove"   # -> tap cx/cy directly
```

Re-describe after every tap to confirm navigation actually happened — a tap that "did
nothing" is usually wrong coords (points-vs-pixels) or the element scrolled off-screen.

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
  `pod install`.) The rebuild is also the only fix when `dev` adds a native dep mid-branch
  (`expo-print`, `expo-sharing`, `expo-audio`, Intercom) and your old binary redboxes on its
  import. **Write the import defensively so a stale/absent binary degrades instead of
  hard-crashing:** type-only import the SDK and lazy-`require()` it behind a null-guard, so
  the whole app doesn't redbox at module-eval before any guard runs.
  ```ts
  import { type UserAttributes } from '@intercom/intercom-react-native'; // types only
  let cached: IntercomModule | null = null, tried = false;
  const getIntercom = () => {
    if (!tried) { tried = true; try { const m = require('@intercom/intercom-react-native'); cached = m?.default ?? m; } catch { cached = null; } }
    return cached;
  };
  // every call: const x = getIntercom(); if (!x) { logSkip(); return; }
  ```
  A top-level `import X from 'native-module'` evaluates the native module's constants at
  import time and crashes the entire bundle when the native side is missing.
- **Transient media errors latched as permanent.** A flat dark circle where a video should
  be was a transient `expo-video` `error` status treated as terminal. Fix: self-heal — on
  `error`, `player.replace(src)` + `play()` a bounded number of times before falling back.
- **Env config drift.** A merge that adds a required `EXPO_PUBLIC_*` key crashes at
  `env.ts` import on cold start — looks like an app bug, is a local `.env` gap. Check
  `env.ts`'s required keys first.
- **Fast refresh lies under churn.** If hot reload won't apply, do a full terminate +
  dev-client reconnect before debugging your code.

## Merging `dev` into a long-lived UI branch

- **Adopt upstream, re-apply only net-new fixes.** When `dev` has rebuilt the same files more
  completely, don't fight it file-by-file — take dev's version and re-apply only the changes
  dev lacks. Resolve conflicts toward dev's tokens/mechanisms; keep your distinct fixes.
- **A clean (no-conflict) merge can still be a semantic break.** Git merges text, not meaning:
  dev refactoring a prop away (e.g. row navigation moved to a whole-row `Pressable`, deleting
  `onAvatarPress`) leaves your call site referencing a name that no longer exists — zero
  conflicts, red typecheck. **Always run the full gate after any merge, even one with no
  conflicts**, and fold the post-merge fixes into the merge commit so history has no broken
  intermediate:
  ```bash
  git merge origin/dev --no-edit            # auto-commits if no conflicts...
  yarn install                              # ...the merge may have pulled new deps
  # the full CI gate (same five, same order) — a clean text-merge won't tell you it broke:
  yarn lint && yarn typecheck && yarn format:check && yarn test --ci && yarn build
  git add -A && git commit --amend --no-edit
  ```

## Watch CI deterministically

```bash
RID=$(gh run list --branch <branch> --limit 1 --json databaseId -q '.[0].databaseId')
until [ "$(gh run view "$RID" --json status -q .status)" = "completed" ]; do sleep 15; done
gh run view "$RID" --json conclusion -q .conclusion
```
