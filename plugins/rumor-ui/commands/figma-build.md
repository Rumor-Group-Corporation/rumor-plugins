---
description: Build a Figma frame into a pixel-perfect, on-system, tested screen in rumor-mobile-expo — and self-correct in a loop until it matches the design AND passes review.
argument-hint: "<figma-url> [feature/route name] [--target <mismatch%>]"
---

# /figma-build — Figma frame → pixel-perfect screen (self-correcting)

The headline command. Generate, then **loop**: measure against the Figma frame, fix the
biggest delta, re-verify, repeat — until the screen is both pixel-perfect and clean.
Input: **$ARGUMENTS**

Drive this with [[rumor-ui-convergence-loop]] as the controller. It uses
[[rumor-strict-design-system]] (input), [[rumor-ui-pixel-diff]] (measure), and
`/thermos` + `/code-review` + `/simplify` (gate). Prereqs: Argent (`npx @swmansion/argent`),
Figma Dev Mode MCP, a booted sim, Metro + the Rumor dev client installed.

## Flow

1. **Preflight.** Confirm: clean branch off `dev`; sim booted (`argent run list-devices` →
   pick the booted udid); Metro up + dev client (`com.alaboparallel.rumor-mobile-expo`)
   installed; DS artifacts present (run `/figma-ds-sync` first if `token-map.json` is missing).
   Create the run dir `.rumor-ui/runs/<id>/`. **Warm the Argent tool-server once, detached**
   (it's foreground by default — never start it inline, and back-to-back cold calls race):
   ```bash
   nohup npx -y @swmansion/argent@latest server start --detach >/tmp/argent-server.log 2>&1 &
   ```

2. **Init.** Export the Figma frame (`get_screenshot` → `figma.png`); pull spec
   (`get_design_context` + `get_variable_defs`, resolved through `token-map.json` — an unmapped
   value stops the run); map components (`get_code_connect_map`); generate the on-system
   screen (thin route + feature components, per [[rumor-mobile-standards]]); record an Argent
   `flow` to the screen. Write the baseline row to `log.yaml`.

3. **Converge.** Run the loop: `measure` (scripts/measure.sh) → diagnose changed regions
   (search `docs/solutions/ui-bugs/` first) → apply the highest-value fix → re-measure →
   commit wins / revert losers → persist each iteration to `log.yaml`. Stop on
   target-OR-plateau-OR-budget (defaults: TARGET 2%, plateau 2, max 6 iterations).

4. **Residual gate.** On a convergence candidate: `/simplify`, then `/code-review` + `/thermos`
   + `rumor-ui-standards-reviewer`. Done **only** if visual ≤ TARGET AND gate clean AND
   simplify produced nothing. Otherwise feed findings back as fixes and re-enter the loop.

5. **Report.** Final `mismatch_pct` vs TARGET, the iteration table (what each fix bought), the
   gate verdict, the final `contextDiffPath` (Read it to show the remaining delta), and the
   commit range. If it plateaued short of TARGET, say so with the best achieved — never imply
   pixel-perfect when it isn't.

6. **Compound.** Write each solved delta to `docs/solutions/ui-bugs/` so the next build starts
   closer to perfect (`/ui-retro`).

## Guardrails
- **Stop and ask** on a blocking ambiguity: an unmapped token, a missing interaction/empty
  state, or a Figma component with no primitive. Don't invent — that's the strict system.
- Each fix is its own commit; the loop is resumable from `log.yaml` if interrupted.
- Calibrate TARGET per screen — anti-aliasing inflates raw %; lean on the OCR/font track and
  `describe`/`inspect-element` numeric tie-break for the last mile.
