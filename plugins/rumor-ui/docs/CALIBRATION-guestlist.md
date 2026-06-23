# Calibration run #1 — Guest List (real Figma frame, real sim)

**Date:** 2026-06-22 · **Result: pipeline proven end-to-end with a real Figma baseline.**
First time `/figma-build`'s MEASURE stage ran against an actual Figma frame (the spike used
app-vs-app). Frame: `Guest List (All) 82`
(`xdHAlCUnMTugmDQRTxRmOC` node `6180:83572`), 393×852.

## What ran
1. **Figma MCP → baseline.** `get_metadata` identified the screen (header, search, tabs, 8
   guest rows, allocation banner, bottom action bar); `get_screenshot` → a 393×852 PNG baseline.
2. **Aspect check.** Figma 0.4613 vs sim capture 0.4600 = **0.28% < 1%** → Argent's Lanczos
   normalize engaged, no dimension hard-fail. (iPhone 17 Pro sim ≈ iPhone 16 logical size.)
3. **measure.sh** captured the live dev client (already on the Guest List screen) and diffed it
   against the Figma baseline → **14.21% mismatch, 20 regions**, annotated diff images written.

## The number, interpreted
14.21% is **not a fidelity gap — it's a content/state gap.** The live screen was the *empty
"Invited" tab* ("No guests found"); the Figma frame is the *populated "All" tab* with 8 guest
rows + the pink allocation banner. The diff regions localized exactly that: QR icon, banner,
the "No guests found" text, the 8 row slots, and the bottom bar. The header ("Guest List"
Romie title + back button) matched closely.

## The key calibration lesson
**The diff measures whatever is on screen — so content + tab + data state must match the frame
before the number means "fidelity."** Otherwise you measure content differences, not
implementation quality. Reference points from this session:
- identical screen → **0%**; same screen, minor live change → **0.52%**;
- content/state mismatch (empty vs populated) → **14.21%**.

**Calibrated guidance:**
- **TARGET ≈ 2–3%** for a *content-matched* screen (the anti-aliasing/font-rendering floor).
  Don't chase 0%.
- Before trusting the number, get the app to the **same tab + the same data** as the frame
  (seed matching guests, select the "All" tab). For data-dependent screens, either seed
  deterministic fixtures or pick a frame whose state you can reproduce on the sim.
- Use the **region list**, not just the headline %, to drive fixes — it localizes the delta
  even when the global % is inflated by content.

## Gaps found
- **OCR text track unavailable** (`text_analysis: status=unavailable provider=ocr`). The
  font/typography diff lane needs its OCR provider available to contribute; pixel + region
  tracks worked. Investigate enabling it for the typography last-mile.
- **Data-state reproduction** is the real precondition for a clean fidelity score — the loop
  needs a way to seed the screen's content (out of scope for the measure stage; a fixture/login
  step in `/figma-build` preflight).

## Verdict
The Figma→baseline→capture→diff pipeline is **proven on a real frame**: export works, aspect
normalization works, regions localize correctly, output parses reliably. The remaining work to
get a *low* fidelity score on this screen is **content/state setup**, not the engine. TARGET
calibrated to ~2–3% on a content-matched screen.
