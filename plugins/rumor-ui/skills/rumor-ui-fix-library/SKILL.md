---
name: rumor-ui-fix-library
description: The compounding fix library for Figma->code in rumor-mobile-expo — a searchable store of solved UI deltas so each build starts closer to pixel-perfect. Use during the convergence loop's DIAGNOSE step (search before inventing a fix), when recording a solved visual delta, or maintaining the token glossary. This is what makes the plugin get better every run.
---

# Rumor UI Fix Library (the compounding loop)

The plugin gets better over time only if solved problems are written down and **searched
before re-solving**. Modeled on compound-engineering's `ce-compound`: every fixed Figma↔code
delta becomes a reusable entry, so a recurring mismatch resolves in seconds next time instead
of another full diagnose/fix iteration.

Two stores, both in the `rumor-mobile-expo` repo (not the plugin):

## 1. `docs/solutions/ui-bugs/` — solved deltas
One markdown file per solved symptom. Format (see `templates/fix-entry.example.md`):
```markdown
---
component: MutualsHero
token: gap-3
problem_type: spacing        # spacing | color | typography | layout | state | perf
symptom: "row gap rendered ~2px instead of 12px in a virtualized list"
date: 2026-06-22
---
**Symptom:** <what the diff/region showed — include the measured numbers>
**What didn't work:** <dead ends, so nobody retries them>
**Fix:** <the change that worked, with the exact token/prop>
**Root cause:** <why it happened>
**Prevention:** <the rule that stops it recurring; promote to a skill/hook if general>
```

## 2. `CONCEPTS.md` — the token glossary
Design-system vocabulary ↔ Figma variables, so every run speaks one language and never
re-derives mappings. (See `templates/CONCEPTS.example.md`.) Maps e.g. Figma `Color/Primary` ↔
`bg-primary` ↔ `#1f1f1f`, `Spacing/M` ↔ `gap-3`, the two font families, etc. This is the
human-readable companion to `token-map.json`.

## Search-FIRST protocol (the rule that makes it compound)

During the convergence loop's **DIAGNOSE** step, before proposing any new fix:
1. Classify the changed region: `spacing | color | typography | layout | state | perf`.
2. **Search `docs/solutions/ui-bugs/`** by `problem_type` + component + keywords (grep the
   frontmatter + symptom lines). If a matching entry exists, apply its **Fix** directly and
   skip the dead ends in **What didn't work**.
3. Only if nothing matches, diagnose from scratch — and then **write a new entry** for it.

The mobile repo's `CLAUDE.md` should carry a one-line routing rule: *"Before fixing a
Figma↔code visual delta, search `docs/solutions/ui-bugs/` and `CONCEPTS.md` first."* That
routing line is what turns one-off fixes into a compounding asset.

## Writing a good entry

- **Key by symptom, not by fix** — you search by what you observe (the diff region), not by
  the solution you don't know yet.
- **Include the measured numbers** (mismatch %, region coords, px values) — they make the
  match unambiguous next time.
- **Record dead ends** in "What didn't work" — saving a future run from repeating them is half
  the value.
- **Promote general rules upward:** if a fix reflects a rule that applies broadly, also add it
  to `rumor-mobile-standards` (or the hook if regex-catchable) and `LESSONS.md` — the library
  is for specific deltas, the skills are for general rules.

Fed by `/ui-retro` after a screen ships; consumed by [[rumor-ui-convergence-loop]] DIAGNOSE.
