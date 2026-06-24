---
name: figma-to-screen
description: The end-to-end Rumor workflow for turning a Figma frame into a shipped UI screen in rumor-mobile-expo. Use whenever implementing a Figma design, building a new screen/component from a mock, translating design-to-code, or when a figma.com URL is given for the mobile app. Orchestrates design extraction, design-system mapping, standards-compliant composition, behavior tests, and simulator verification.
---

# Figma -> Screen (the Rumor pipeline)

This is the master workflow. It sequences the other rumor-ui skills. Read it, then
pull in the sub-skills as each phase needs them:
[[rumor-mobile-standards]] (how we write code), [[rumor-behavior-testing]] (the jest
harness), and [[rumor-ui-verify-loop]] (the simulator loop + native gotchas).

> Core mindset: **tighten the loop, then let it rip.** Every phase ends in an
> *objective* signal (typecheck, test, sim screenshot). Build the signal before the
> feature. **Verify, don't assert** — "tests pass" never means "it works"; look at the
> rendered pixels.

## Phase 0 — Set up the loop

1. **Clean branch off the integration branch** (`dev` for `rumor-mobile-expo`). Never
   branch off unrelated WIP — it's the #1 cause of "why is this file in my PR."
2. **Open a draft PR immediately** so CI + review bots run from commit one.
3. **Know the done-gate** — the five CI gates: `yarn lint` (`--max-warnings 0`)
   `&& yarn typecheck && yarn format:check && yarn test --ci && yarn build`. Run locally
   before every push, and again after any merge (a clean text-merge can still break typecheck).
4. Confirm the **Figma Dev Mode MCP** is reachable and the simulator + Metro are up
   (see [[rumor-ui-verify-loop]]).

## Phase 1 — Extract the design (measure, don't eyeball)

Use the `figma-design-extractor` agent (or the Figma MCP directly):
`get_design_context` for exact tokens/spacing/typography, `get_screenshot` for the
visual truth, `get_metadata` for the node tree. Capture the **real numbers** — never
approximate spacing or color from a screenshot.

Produce a short extraction brief: frame name, the component tree, the design tokens
used (mapped to `tailwind.config.js` names — see below), and any interaction states
(pressed, loading, empty, error).

## Phase 2 — Map to the design system BEFORE writing JSX

The single biggest quality lever: **reuse, don't reinvent.**

- Grep `src/components/ui/` for an existing primitive for each Figma node. Compose from
  primitives; do not fork them for one-off changes — extend via props/variants/`className`.
- Map every Figma token to a **named Tailwind token** in `tailwind.config.js`. If a value
  isn't tokenized yet, add a reusable, scale-style token — never an arbitrary `[12px]`.
- Check Code Connect / existing screens for the component mapping. If the platform already
  models the concept, match the established pattern.

Output a mapping table (Figma node -> our primitive + tokens) before any code. A node with
no mapping is a decision: extend a primitive or add a token — make it explicitly.

## Phase 3 — Compose, to standard

Follow [[rumor-mobile-standards]] exactly. The shape:
- **Thin route** under `src/app/` (params, query/mutation wiring, navigation only).
- **Feature components** under `src/components/<feature>/` (the JSX).
- **Helpers/domain logic** in `src/lib/<feature>/`; **API** in a services layer behind
  `src/hooks/api/` TanStack Query hooks; **client state** in a focused Zustand store. Before
  wiring a hook to a new endpoint, probe the contract (path + method + body) per
  [[rumor-api-contract]] / `/api-verify` — a wrong verb 404s exactly like a missing route.
- NativeWind `className` only. `FC<Props>`. No `any`, no non-null `!`, no `@ts-ignore`.

The standards hook (PostToolUse) will flag violations as you write — treat its output as a
blocking signal and fix at the source, don't suppress.

## Phase 4 — Behavior tests

Write tests in the Testing Library philosophy — see [[rumor-behavior-testing]] for the
full harness and every jest/RNTL gotcha we've already paid for. Cover the empty /
permission / loading / error matrix, not just the happy path. Assert observable behavior
(labeled controls, visible text, fired callbacks) — never `useState` or internal `testID`s.

## Phase 5 — Verify on the simulator (pixel-tight)

Run the loop in [[rumor-ui-verify-loop]]: deep-link to the screen, screenshot, and compare
against the Figma frame from Phase 1. Use `/figma-audit` to make this a checklist
(spacing, tokens, a11y labels, state coverage) instead of a vibe check. Drive interactions
with `idb` and re-screenshot. If behavior doesn't match code, suspect the runtime, not your
change (native gotchas section).

## Phase 6 — Self-review, then push

Before humans/bots: run `/thermos`, `/code-review`, `/simplify` (fan-out adversarial
review with different lenses). Fix at the right altitude — address the mechanism, not a
band-aid. Then push; let Bugbot/Codex + CI run; triage real vs stale; reply + resolve
threads; add a regression test for every real fix.

## Phase 7 — Capture what you learned

If anything surprised you — a new gotcha, a missing token, a primitive that needed
extending — run `/ui-retro` to fold it into the right skill or `LESSONS.md`. The plugin is
only as good as the learnings you feed back into it.

## Anti-patterns (hard no)

- Eyeballing spacing/color instead of pulling exact Figma values.
- Reinventing a primitive that already exists in `src/components/ui/`.
- Arbitrary `[..]` Tailwind values, inline `style` for static layout, `StyleSheet.create`.
- Testing implementation details.
- Claiming done on something only a device can prove (SMS, real backend) — flag it for QA.
- Letting unrelated changes ride along. One branch, one concern.
