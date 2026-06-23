---
name: rumor-ui-convergence-loop
description: The self-correcting build-measure-fix loop that drives a Figma->code screen to pixel-perfect AND clean in rumor-mobile-expo. Use when running /figma-build, iterating a UI until it matches the design, or wiring the thermos/code-review/simplify residual gate. Defines the loop steps, the experiment log, and the multi-dimensional stopping criteria.
---

# Rumor UI Convergence Loop

The engine that makes Figma->code *flawless*: generate, then iterate against an objective
signal until the screen is **both** pixel-perfect **and** clean — never ship on looks alone.
Modeled on compound-engineering's `ce-optimize` (metric-gated, disk-checkpointed). Uses
[[rumor-strict-design-system]] for input, [[rumor-ui-pixel-diff]] to MEASURE, and
`/thermos` + `/code-review` + `/simplify` + `rumor-ui-standards-reviewer` as the gate.

## Inputs (easy in)
A Figma node URL. Optionally: the target feature/route name, and a calibrated TARGET
mismatch %. Everything else is discovered (sim udid via `argent run list-devices`, bundle
`com.alaboparallel.rumor-mobile-expo`, tokens via the DS layer).

## The loop

```
INIT
  reference  = Figma frame export (get_screenshot) → .rumor-ui/runs/<id>/figma.png
  spec       = get_design_context + get_variable_defs, resolved via token-map.json
  components = get_code_connect_map
  generate   = on-system NativeWind code (thin route + feature components, per standards)
  record nav = argent flow to the screen (deterministic capture state)
  CP-0: write baseline row to .rumor-ui/runs/<id>/log.yaml

LOOP (iteration N) — each fix in its own commit:
  1. MEASURE   scripts/measure.sh --baseline figma.png [--launch --route …]
                 → {mismatch_pct, status, regions(diffPath/contextDiffPath)}
               secondary gates: yarn typecheck/lint, token-map violations, a11y labels
  2. DIAGNOSE  cluster changed regions (layout / spacing / color / typography / missing state)
               SEARCH docs/solutions/ui-bugs/ FIRST → reuse a known fix if the symptom matches
               else rank fix hypotheses; use describe / debugger-inspect-element for exact
               on-device numbers when a pixel delta is ambiguous
  3. FIX       apply the highest-value fix; keep it on-system (DS layer enforces)
  4. RE-VERIFY re-run MEASURE; improved beyond noise_threshold → commit; else revert, keep best
  5. PERSIST   append the iteration row to log.yaml IMMEDIATELY; verify by read-back
               (conversation context is NOT durable storage); update `best`
  6. repeat until a stop condition (below) trips

CONVERGENCE CANDIDATE → RESIDUAL GATE
  run /simplify  (clean the code that accumulated during convergence)
  run /code-review + /thermos + rumor-ui-standards-reviewer
  done only if ALL gates clean; else feed findings back as fixes and re-enter the loop
```

## Stopping criteria — stop when ANY:
- **Target met (the goal):** `mismatch_pct ≤ TARGET` **AND** residual gate has zero unresolved
  actionable findings **AND** `/simplify` produced no further changes. This is "done."
- **Plateau:** no improvement beyond `noise_threshold` for `N` consecutive iterations
  (default N=2) — prevents thrashing on sub-pixel anti-aliasing.
- **Budget:** `max_iterations` (default 6) or `max_wall_clock` hit.
- **Empty backlog:** no untried fix hypotheses remain.
- **Manual stop / a blocking ambiguity** (unmapped token, missing interaction spec) → stop and
  ask, don't guess.

"Done" is multi-dimensional **on purpose**: a screen that looks perfect but has thermos-critical
findings, off-system classes, or messy code is *not done*.

## The experiment log (`.rumor-ui/runs/<id>/log.yaml`) — source of truth

Append-only; the run is resumable by scanning it. Never rely on chat memory.
```yaml
run: <id>
figma: <node-url>
target_pct: 2.0
baseline: { iter: 0, mismatch_pct: 28.4, note: "first generation" }
iterations:
  - { iter: 1, fix: "header bg primary→background token", mismatch_pct: 19.1, verdict: kept,    commit: a1b2c3 }
  - { iter: 2, fix: "row gap 8→gap-3 (12px)",            mismatch_pct: 6.7,  verdict: kept,    commit: d4e5f6 }
  - { iter: 3, fix: "title font-dia→font-romie-medium",  mismatch_pct: 2.0,  verdict: kept,    commit: 0789ab }
best: { iter: 3, mismatch_pct: 2.0 }
gate: { simplify: clean, code_review: clean, thermos: clean }
result: done
```

## Reporting (solid out)
On finish, report: final `mismatch_pct` vs TARGET, the iteration table (what each fix bought),
the residual-gate verdict, the final `contextDiffPath` (Read it to show the remaining delta),
and the commit range. If it stopped short of TARGET (plateau/budget), say so honestly with the
best achieved and what's left — don't imply pixel-perfect when it plateaued at 5%.

## Compounding
Every solved delta should leave a `docs/solutions/ui-bugs/` entry (symptom → fix) so DIAGNOSE
finds it next run. That's what turns each screen into a faster next screen — see `/ui-retro`.
