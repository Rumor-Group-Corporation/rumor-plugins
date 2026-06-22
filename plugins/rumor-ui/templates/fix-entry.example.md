---
component: MutualsHero
token: gap-3
problem_type: spacing
symptom: "row gap rendered ~2px instead of the 12px Figma spacing in a virtualized list"
date: 2026-06-22
---

**Symptom:** screenshot-diff flagged a thin tall changed region between every list row
(region h≈0.05, repeated). Measured rendered row pitch ~2px vs Figma's 12px gap.

**What didn't work:**
- Adding `gap-3` to the list container `className` — virtualized lists (FlashList/LegendList)
  don't apply container `gap` between recycled items.
- Wrapping each row in a `mb-3` View — created an uneven trailing margin after the last row.

**Fix:** use the list's `ItemSeparatorComponent` with a `h-3` (12px) spacer, and remove the
container `gap`. Pitch then matched Figma exactly.

**Root cause:** NativeWind `gap` maps to flex gap, which a virtualized list's recycler doesn't
honor between items — only `ItemSeparatorComponent` (or item padding) spaces recycled rows.

**Prevention:** for spacing *between* virtualized list items, always use
`ItemSeparatorComponent`, never container `gap`. (General enough to live in
`rumor-mobile-standards` lists section too.)
