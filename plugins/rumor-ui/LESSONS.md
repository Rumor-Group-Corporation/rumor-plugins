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

<!-- Append new lessons above this line. Newest first. -->
