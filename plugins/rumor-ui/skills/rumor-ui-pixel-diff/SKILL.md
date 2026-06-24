---
name: rumor-ui-pixel-diff
description: Numeric visual-fidelity measurement for Figma->code in rumor-mobile-expo, using Argent's screenshot-diff against a Figma frame export. Use when measuring how closely a built screen matches its Figma design, capturing the sim screen, computing a pixel-mismatch %, or locating which regions are wrong. The MEASURE stage of the convergence loop.
---

# Rumor UI Pixel Diff (the MEASURE stage)

Turns "does it match the design?" into a **number + a region list**, using
[Argent](https://github.com/software-mansion/argent) (verified working against the real
Rumor dev client — see `docs/SPIKE-argent.md`). Baseline = the **Figma frame export**;
current = a live sim capture.

## The one command you need

`scripts/measure.sh` wraps Argent's CLI, handles the cold-start retry, and prints one JSON
line the loop parses:
```bash
${CLAUDE_PLUGIN_ROOT}/scripts/measure.sh \
  --udid <sim-udid> --outdir .rumor-ui/runs/<id> \
  --baseline <figma-frame.png> \
  [--bundle com.alaboparallel.rumor-mobile-expo --launch] [--route "therumorapp://…"]
# -> {"mismatch_pct": 3.4, "status": "changed", "current": "...", "diffPath": "...", "contextDiffPath": "..."}
```
`mismatch_pct` is the primary metric; `diffPath` is the annotated full-size diff
(green = brighter in current, red = darker, yellow boxes = changed regions); `contextDiffPath`
is a downscaled version safe to Read into context.

## How it works (under the hood)

- **launch + navigate** (`launch-app`, then `open-url`/gestures) to reach the screen, ideally
  wrapped as an Argent `flow` recording so before/after capture at byte-identical state.
- **capture** `screenshot --downscaler lanczos3` (retry 2-4×; the first call on a cold
  tool-server returns "no image to export").
- **diff** `screenshot-diff --baselinePath <figma> --currentPath <capture>` →
  `{summary, diffPath, contextDiffPath}`. The summary carries `status`, `pixel_mismatch %`,
  `changed_areas`, a per-region list in normalized [0,1] coords, and an OCR `text_analysis`
  track. The fixed top status-bar band is auto-ignored.

## Reading the result for DIAGNOSE

- **`mismatch_pct`** → the headline. Drives the stop check.
- **Regions** (normalized coords) → cluster into fix categories: a region near the top with a
  color delta = wrong header bg; a thin tall region = a spacing/gap error; text-track hits =
  wrong copy/line-height/font.
- **`describe` / `debugger-inspect-element`** are the **numeric tie-break**: when a pixel
  delta is ambiguous (anti-aliasing, sub-pixel), read the on-device computed frame/spacing/
  color and compare against the Figma token directly. Assert the number; don't eyeball it.

## Getting the Figma baseline via the Figma MCP (the lightweight path)

When you just need the frame PNG (no full Argent run), pull it straight from the Figma MCP:

- **Recover the `fileKey`.** `get_screenshot` needs `fileKey` + `nodeId`, but links shared in
  chat are often `?node-id=…` only. The `fileKey` is the segment after `/design/` in any
  earlier full URL this session (e.g. `figma.com/design/xdHAlCUnMTugmDQRTxRmOC/…` →
  `xdHAlCUnMTugmDQRTxRmOC`). If it's not in context, `grep` the session transcript for a
  `figma.com/design/<key>` URL before asking the user. Keep a running `nodeId → screen` map.
- **Fetch + download.** `get_screenshot({ fileKey, nodeId, maxDimension: 2048 })` returns a
  **short-lived** asset URL (treat it like a secret). `curl -o <node>.png "<url>"` immediately —
  don't re-read the URL, it expires — then Read the PNG and compare to a live sim capture.
- `node-id` in a URL is `1-2`; the tool accepts `1-2` or `1:2`.

## Is it a fidelity gap or a DATA gap? (diagnose before "fixing" the UI)

A screen that doesn't match the frame is often **correct UI rendering absent data**, not a
defect — and "fixing" the component would be wrong. Before touching layout:

- **Figma shows populated content the build doesn't** (e.g. `@handle • 999K followers`, attendee
  counts, badges) → suspect the **data/seed layer**, not the component. The mock frame always has
  rich data; your QA env may not (`instagram_user_name` unset; the default list query omits social
  stats unless `sortBy` requests them).
- **Prove the component is right**: feed it the data in a unit test (a row test rendering
  `@joshzip • 999K`). If it renders correctly with data, the gap is backend/seed — surface it as
  a separate-PR decision, don't silently restyle the screen.
- Only after data + tab + state match the frame is a residual delta a real fidelity bug.

## Getting a usable Figma baseline (calibration)

- Export the frame at a resolution that **shares the capture's aspect ratio** — Argent's
  Lanczos normalize matches differing resolutions but **hard-fails on aspect mismatch**. Pin
  a reference device (e.g. iPhone 17 Pro) and export the frame to that logical size.
- **Threshold:** font anti-aliasing inflates raw `mismatch_pct`. Don't chase 0%. **Calibrated
  TARGET ≈ 2–3%** for a *content-matched* screen (calibration run #1, `docs/CALIBRATION-guestlist.md`:
  identical=0%, minor live change=0.52%, empty-vs-populated content gap=14.21%). Lean on the
  OCR/font track + numeric tie-break for the last mile rather than raw pixels.
- **Match content + state first.** The diff measures whatever is on screen — a high % often
  means the app is on the wrong tab or has different data, NOT poor fidelity. Get the app to the
  same tab + the same data as the frame (seed deterministic fixtures or pick a reproducible
  frame) before trusting the number. Use the **region list** to localize the real delta even
  when the global % is inflated by content.
- **OCR track:** the text/typography lane reported `provider=ocr unavailable` in calibration —
  pixel + region tracks work regardless; enable OCR for the typography last-mile.

## Gotchas (from the spike)

- Cold-start capture race → the script already retries; if you call Argent directly, retry.
- Both diff inputs must exist on the tool-server host before diffing.
- Flags are camelCase (`--baselinePath`, `--captureCurrent`, `--outputDir`).
- Route deep-linking via `open-url` is wired but was not e2e-verified in the spike — confirm
  the scheme (`therumorapp://`) reaches the right route, else navigate via gestures + a `flow`.

Feeds [[rumor-ui-convergence-loop]]; pairs with [[rumor-ui-verify-loop]] for the manual loop.
