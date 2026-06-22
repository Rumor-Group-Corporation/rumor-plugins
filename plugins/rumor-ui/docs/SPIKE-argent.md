# Phase 2 spike — Argent against the real Rumor Expo dev client

**Date:** 2026-06-22 · **Result: GREEN.** The biggest unknown ("does Argent drive an Expo
dev client and produce a consumable visual diff?") is retired. The convergence loop's
MEASURE stage is buildable on Argent as-is.

## Environment
- Argent **v0.12.1** via `npx -y @swmansion/argent@latest` (no install needed to spike).
- Booted sim: **iPhone 17 Pro**, iOS 26.5, udid `C11AFBF7-…B023F1`.
- Real Rumor Expo **dev client** installed: bundle `com.alaboparallel.rumor-mobile-expo`.
- `idb` present; node/npx via hermes toolchain.

## Key finding: Argent has a CLI, not just an MCP server
`argent run <tool> [--flags] [--json] [--out <path>]` invokes any tool-server tool directly,
and `argent tools` lists them. **This means the convergence loop can shell out to Argent**
(scriptable from a command/hook) instead of only via MCP tool calls — simpler orchestration,
and it works headless. `--args -` also accepts a full JSON payload on stdin.

## What was verified live

| Test | Result |
|---|---|
| `argent run list-devices` | ✅ returns the booted iPhone 17 Pro + all sims as JSON |
| `argent run launch-app --bundleId com.alaboparallel.rumor-mobile-expo` | ✅ `{ "launched": true }` — **launches the Expo dev client** (the #1 unknown) |
| `argent run screenshot --downscaler lanczos3 --out a.png` | ✅ writes a 150 KB PNG (after warm-up — see gotcha) |
| `argent run screenshot-diff --baselinePath a --currentPath b --json` | ✅ returns the structured summary below |

### screenshot-diff output shape (what MEASURE consumes)
```json
{
  "summary": "Overall:\n- status: unchanged\n- pixel_mismatch: 0% - no pixel change\n- changed_areas: shown=0 total=0 omitted=0\n ... Text changes: status=skipped provider=ocr\n Regions: shown=0 total=0 omitted=0",
  "diffPath": "/tmp/argentdiff/argent_b-diff.png",
  "contextDiffPath": "/tmp/argentdiff/argent_b-context-diff.png"
}
```
Confirmed: `status`, `pixel_mismatch` %, `changed_areas`, per-region list (normalized [0,1]
coords matching `describe`), an OCR `text_analysis` track, and two diff images
(full + downscaled context). Status-bar band is auto-ignored. This is exactly the numeric +
region signal the loop's DIAGNOSE stage needs to cluster fixes. (Diff was A-vs-B of the same
screen → 0%, which proves the *shape*; fidelity-threshold calibration still pending — see below.)

## Gotchas found (fold into the loop's pixel-diff skill)
1. **Cold-start race:** the first `screenshot` after a fresh tool-server returned
   `Screenshot failed: no image to export`. The next succeeded. **Fix: retry capture 2–3×**;
   or warm the server with `argent server start` / a throwaway capture before the loop.
2. **Diff inputs must exist on the tool-server host:** a missing `baselinePath` fails with a
   clear "not found / not uploaded" error — capture both frames before diffing.
3. Flags are camelCase (`--baselinePath`, `--captureCurrent`, `--outputDir`); use `--out` to
   save an image result to a known path, `--json` for the raw result.

## Still-open (carry into Phase 3 build)
- **Route deep-linking:** `launch-app` opens the app; driving to a *specific JS route* needs
  `open-url` with a scheme (`therumorapp://…`) or `gesture-*` nav — then wrap the nav as an
  `argent flow-*` recording for deterministic capture state. Not yet tested end-to-end.
- **Figma frame as baseline + threshold calibration:** not yet tested with a real Figma
  export. Need to (a) export a frame at a resolution sharing the iPhone 17 Pro aspect ratio
  so Argent's Lanczos normalize engages (different aspect = hard fail), and (b) calibrate the
  "pixel-perfect enough" TARGET — font anti-aliasing will inflate raw %, so lean on the OCR/
  font track + the `describe`/`inspect-element` numeric tie-break, not raw % alone.
- **Dev-client vs release:** verified against a dev client; confirm `flow` replay survives a
  dev-client JS reload.

## Verdict
Build Phase 3 (the convergence loop) on the Argent CLI. MEASURE =
`launch-app` → (flow replay to route) → `screenshot` (retry) → `screenshot-diff` vs the Figma
frame → parse `summary` for `pixel_mismatch` + regions. The only real calibration work left is
the TARGET threshold against a real Figma export, which is a tuning task, not a feasibility risk.
