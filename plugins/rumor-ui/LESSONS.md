# rumor-ui — Lessons Ledger

The consistently-improve loop. Every screen we ship should leave this plugin smarter than
it was. When something breaks, is manual, or surprises us, `/ui-retro` folds the rule into
the right skill — and the not-yet-categorized one-offs (Figma-node mappings, project quirks)
land here with a date and one-line context.

This file is reviewed like code. Keep entries tight: **symptom -> rule -> where it lives now.**

## Format

```
### YYYY-MM-DD — short title
Symptom: what we observed.
Rule: the durable takeaway.
Home: which skill/hook it was added to (or "ledger only").
```

---

## Ledger

### 2026-06-22 — plugin seeded from the Rumor Mutuals build
Symptom: the entire Figma->code workflow lived in one engineer's head + a markdown doc.
Rule: codify it as skills/commands/hook/agents so every engineer (and the agent) inherits
the accumulated edge cases — reanimated-4 mock, NativeWind babel factory rewrite, dev-client
rebuild after native dep bumps, the staging-table seam, the no-N+1 digest, behavior-only
tests, the pixel-tight sim loop.
Home: seeded across `figma-to-screen`, `rumor-mobile-standards`, `rumor-behavior-testing`,
`rumor-ui-verify-loop`, and the standards hook.

### 2026-06-22 — Argent `server start` is foreground by default
Symptom: `measure.sh` hung indefinitely after adding `argent server start` to warm the
tool-server.
Rule: `argent server start` runs in the FOREGROUND (for process supervisors). To warm it
from a script, guard on `server status` and use `server start --detach`:
`ARGENT server status >/dev/null 2>&1 || ARGENT server start --detach`. Also: the first
`screenshot`/`screenshot-diff` on a cold server can return empty/`no image to export` —
retry 2-4×.
Home: `rumor-ui-pixel-diff` + `scripts/measure.sh` + `docs/SPIKE-argent.md`.

### 2026-06-22 — Argent CLI stdout is lost under `$(...)`; redirect to a file
Symptom: `DIFF_JSON="$(argent run screenshot-diff … --json)"` came back empty *even though the
diff ran* (it wrote `current-diff.png`). Standalone the same call printed JSON fine.
Rule: never capture Argent CLI stdout via command substitution in a script. Redirect to a file
(`argent run … >out.json`) and read the file. After this fix, measure.sh ran 3/3 reliably
(0.52%, 0.52%, 7.74%). Also: `server start` is foreground (use the detached nohup preflight),
and settle ~2s between capture and diff.
Home: `scripts/measure.sh` + `docs/SPIKE-argent.md`.

### 2026-06-22 — Phase 3: convergence loop built
Symptom: Figma->code stopped at "generated once," no objective fidelity signal.
Rule: the loop MEASUREs with Argent `screenshot-diff` vs the Figma frame (numeric mismatch% +
normalized region bounds), diagnoses regions, fixes, re-verifies, and gates on
thermos/code-review/simplify. "Done" = visual ≤ TARGET AND gate clean AND simplified.
Home: `rumor-ui-convergence-loop`, `rumor-ui-pixel-diff`, `/figma-build`, `scripts/measure.sh`.

### 2026-06-22 — Phases 4 & 5: floor raised + compounding library
Symptom: standards covered placement/styling/TS but not RN perf/correctness; solved deltas
weren't captured, so each build re-diagnosed the same mismatches.
Rule: imported RN perf/architecture/correctness rules (state=ground-truth, compound
components, list recycling, GPU-only animation, falsy-`0`, effect cleanup) into
`rumor-mobile-standards`; gave the reviewer BLOCK/HIGH/STYLE tiers + a symptom→cause table;
added `rumor-ui-fix-library` (`docs/solutions/ui-bugs/` + `CONCEPTS.md` + search-FIRST DIAGNOSE)
so every solved delta makes the next build faster.
Home: `rumor-mobile-standards`, `rumor-ui-standards-reviewer`, `rumor-ui-fix-library`, `/ui-retro`.

### 2026-06-22 — Calibration run #1: TARGET ≈ 2–3%; match content before trusting the %
Symptom: live Guest List vs the real Figma frame diffed at 14.21% — but that was the empty
"Invited" tab vs a populated "All" tab + banner, i.e. a content/state gap, not a fidelity gap.
Rule: the diff measures whatever is on screen, so match tab + data state to the frame before the
% means fidelity. Calibrated TARGET ≈ 2–3% on a content-matched screen (identical=0%, minor
change=0.52%). Use the region list to localize even when the global % is inflated. Also: the
Figma→baseline→capture→diff pipeline is proven on a real frame (aspect 0.28%<1%, normalize
engaged); OCR text track was unavailable (enable for typography last-mile).
Home: `rumor-ui-pixel-diff` + `docs/CALIBRATION-guestlist.md`.

### 2026-06-24 — RUM-7067 retro: review bug-classes, contract probing, merge + sim gotchas
Symptom: shipping the collaborator guest-list/ticket feature, the operational lessons came from
PR-review bots and the sim, not the happy path — and none were in the plugin yet. Codex/Bugbot
caught four real bugs CI was green on; a clean `dev` merge red-failed typecheck; the sim wouldn't
tap where I aimed; an endpoint "404'd" that was actually wired.
Rule:
- **Four recurring review bug-classes** → `rumor-ui-standards-reviewer` (BLOCK/HIGH + symptom rows):
  destructive/bulk action with no confirmation (BLOCK); bulk status-transition sending a raw/
  display status instead of the normalized `currentStatus` (`SHORTLIST`→`APPLIED`); `keepPreviousData`
  without an `isPlaceholderData` pagination guard; a selection affordance rendered while its action
  is disabled (dead selection state).
- **Backend contract probing with curl** → new `rumor-api-contract` skill + `/api-verify` command:
  401 = route wired/auth-gated (pass), 404 = missing **or a method mismatch** (Nest 404s an
  unmatched verb — grep the service for PUT vs POST before concluding "missing"); match the body to
  the DTO.
- **`idb` coords are POINTS, not screenshot pixels** → `rumor-ui-verify-loop`, plus a shippable
  `/tmp/uidesc.py` describe-parser (`type | 'label' | cx cy`); re-describe after every tap.
- **A clean (no-conflict) merge can hide a semantic break** (dev refactored a prop away, orphaning a
  call site → red typecheck) → `rumor-ui-verify-loop` merge-discipline section: adopt upstream, keep
  net-new, run the full gate after *any* merge. Done-gate tightened to the literal 5 CI gates
  (added `test`, `--max-warnings 0`) in `rumor-mobile-standards` + `figma-to-screen`.
- **Lazy-require native modules** so a stale/absent binary degrades instead of redboxing at import
  → `rumor-ui-verify-loop` native gotchas (complements the rebuild recipe).
- **Figma gap ≠ UI defect**: populated mock vs unseeded data (e.g. `@handle • followers`) is a data/
  seed gap — prove the component with a unit test before restyling → `rumor-ui-pixel-diff`; same skill
  now documents fileKey recovery + `get_screenshot(fileKey,nodeId)`→curl-PNG as a first-class baseline.
Home: `rumor-ui-standards-reviewer`, `rumor-api-contract` (+`/api-verify`), `rumor-ui-verify-loop`,
`rumor-ui-pixel-diff`, `rumor-mobile-standards`, `figma-to-screen`; version bumped 0.4.0 → 0.5.0.

<!-- Append new lessons above this line. Newest first. -->
