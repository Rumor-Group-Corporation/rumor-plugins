---
name: rumor-strict-design-system
description: The strict, closed-vocabulary design system for Figma->code in rumor-mobile-expo. Use when generating UI from Figma, mapping Figma variables/tokens to code, deciding whether a color/spacing/font value is on-system, or setting up the design-system artifacts. Enforces that generated code can ONLY emit tokens that exist - never an invented hex or arbitrary value.
---

# Rumor Strict Design System

The whole point: **the generator cannot invent values.** "Use the design system" is a wish;
"can only emit tokens that exist in `token-map.json`" is a rule. This skill defines the
closed vocabulary and how it's enforced. Generate/refresh the artifacts with `/figma-ds-sync`.

## The closed vocabulary — three artifacts (+ rules)

These live in `rumor-mobile-expo`, generated from `tailwind.config.js` + `src/components/ui`
+ the Figma file. See `templates/token-map.example.json` and `templates/DESIGN.example.md`
in this plugin for the real, grounded format.

### 1. `token-map.json` — the keystone
Maps every Figma variable to its `tailwind.config.js` key and the NativeWind class(es) it
emits:
```jsonc
{
  "color/primary":   { "tw": "primary",     "class": "bg-primary / text-primary / border-primary" },
  "color/rumor-lime":{ "tw": "rumor-lime",  "class": "bg-rumor-lime / text-rumor-lime" },
  "space/4":         { "tw": "4",           "class": "p-4 / gap-4 / m-4" },
  "radius/2.5xl":    { "tw": "2.5xl",       "class": "rounded-2.5xl" },
  "font/dia-medium": { "tw": "dia-medium",  "class": "font-dia-medium" }
}
```

**The rule:** during generation, resolve every Figma value (`get_variable_defs` for the
node) through this map. **An unmapped value is a HARD FAILURE** — stop and surface it:

> "Figma uses `#3A7BD5` (color/brand-blue) — no matching token. Add a token to
> `tailwind.config.js` + `token-map.json`, or pick the nearest existing token. Not emitting
> a raw hex."

Never emit a raw hex / px / rgb(). Never invent a `[12px]` arbitrary value.

### 2. `DESIGN.md` — the brand layer (human-readable)
The Google-Stitch / designmd 6-section format, tokens stated as **NativeWind classes**:
Visual Theme & Atmosphere · Color System · Typography · Components & Patterns ·
Spacing & Layout · Motion & Interaction · + Rationale + Accessibility. This is the
"what good looks like" reference both the generator and reviewers read.

### 3. `code-connect.json` — component mapping
`get_code_connect_map` output: Figma component id -> `src/components/ui` import + prop/variant
mapping. Component instances resolve to a real import, never a re-implemented primitive.

### CLAUDE rules block (enforcement prose, `IMPORTANT:`-prefixed)
- `IMPORTANT: tokens live in tailwind.config.js — never hardcode hex/px/font names; emit only classes resolvable through token-map.json.`
- `IMPORTANT: primitives live in src/components/ui — reuse them (see code-connect.json); never recreate one.`
- RN output only: `View/Text/Pressable/Image`, NativeWind `className`, no web CSS.
- **Required Flow (do not skip):** parse URL -> `get_design_context` -> (`get_metadata`
  fallback for truncation) -> `get_variable_defs` -> resolve via `token-map.json` ->
  `get_code_connect_map` -> `get_screenshot` -> download assets -> generate -> validate.
- **Conflict rule:** when a project token conflicts with the Figma spec, **prefer the token
  and nudge spacing/size minimally** to preserve the visual. Fidelity to the *system* beats
  fidelity to an off-system pixel.

## How it's enforced (two layers)

1. **At generation time (strict gate):** the Required Flow resolves every value through
   `token-map.json`; unmapped -> stop. This is where strictness primarily lives, because the
   generator has the parsed Figma value + the map in hand.
2. **At edit time (hook backstop):** `hooks/check-tsx-standards.sh` blocks the cheap escapes
   a regex can catch with high precision — **raw hex / rgb() color literals** and **arbitrary
   `[..]` Tailwind values** in `.ts(x)` source. (Full per-class validation stays in the
   generator, not the hook, to avoid false positives on the hundreds of legitimate built-in
   utilities like `flex`, `items-center`.)

## Working with the system

- **Adding a token is a deliberate act**, not a side effect. If Figma genuinely needs a new
  value: add it to `tailwind.config.js`, add the mapping to `token-map.json`, note it in
  `DESIGN.md`, and *then* use it. The friction is the feature — it keeps the palette small.
- **Prefer semantic tokens** (`primary`, `muted`, `destructive`) over raw named grays where a
  semantic one fits; reserve the named scale for genuinely one-off needs.
- **Fonts:** the two families are ABCDiatype (`font-dia*`) and RomieTrial (`font-romie*`).
  Map Figma text styles to these; never introduce a third family without a product decision.

See [[rumor-mobile-standards]] for the broader coding rules and [[figma-to-screen]] for where
this fits in the pipeline.
