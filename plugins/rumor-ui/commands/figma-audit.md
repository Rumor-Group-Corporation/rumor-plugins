---
description: Audit a built screen against its Figma frame and the Rumor mobile standards (spacing, tokens, a11y, state coverage).
argument-hint: "<screen/route> [figma-url]"
---

# /figma-audit — built screen vs Figma + standards

Audit **$ARGUMENTS**. Turn "the spacing looks off" into a concrete, measured checklist
instead of a vibe check. Use `rumor-ui-verify-loop` for capture and `rumor-mobile-standards`
for the rules.

## Steps

1. **Capture both sides.** Screenshot the running screen on the simulator (verify-loop).
   Pull the Figma frame via `get_screenshot` + exact values via `get_design_context`.
2. **Measure, don't eyeball.** Compare:
   - **Spacing & layout** — padding, gaps, row pitch. Compute rendered pitch from
     `idb ui describe-all` frames when a gap is in question. Watch for virtualized-list
     `gap` silently not applying (needs `ItemSeparatorComponent`).
   - **Tokens** — every color/font/radius/spacing resolves to a named `tailwind.config.js`
     token. Flag any arbitrary `[..]` value or inline static `style`.
   - **Typography** — family/size/weight/line-height match the registered fonts.
3. **Accessibility** — every interactive element has a stable a11y label (also what the
   behavior tests query by).
4. **State coverage** — empty, permission-denied, loading, error, and populated all render
   per the Figma states. Exercise the permission gate with `simctl privacy reset/grant`.
5. **Standards scan** — run the `rumor-ui-standards-reviewer` agent over the changed files
   for placement/styling/TS violations.

## Output

A findings list, most-severe first: `file:line — what's wrong — the exact fix (token name,
primitive, or measurement)`. Distinguish **must-fix** (off-spec, standards violation) from
**nice-to-have**. If it matches the frame and passes standards, say so plainly.
