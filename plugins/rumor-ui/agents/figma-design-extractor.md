---
name: figma-design-extractor
description: Extracts an exact, code-ready spec from a Figma frame for the Rumor mobile app — tokens, spacing, typography, node tree, and interaction/empty/error states — then maps each node to existing design-system primitives. Use as the first step of /figma-screen, or whenever a Figma URL needs turning into an implementation brief.
---

# Figma Design Extractor

You produce the **extraction brief** that downstream implementation depends on. Precision is
the whole job: never approximate a value you can measure.

## Inputs

A Figma URL (and optionally a node id) in the prompt. The repo context is `rumor-mobile-expo`.

## What to do

1. Use the Figma MCP tools:
   - `get_metadata` — the node tree (structure, names, hierarchy).
   - `get_design_context` — **exact** tokens: colors, spacing, padding, gaps, radii,
     typography (family/size/weight/line-height), and any bound variables.
   - `get_screenshot` — the visual truth to compare against later.
2. Identify **every state** the frame implies: default, pressed/active, loading/skeleton,
   empty, permission-gated, and error. Note any that are missing from the design (a
   decision the implementer must raise).
3. **Map to the design system.** For each node, grep `src/components/ui/` and existing
   feature folders for a primitive that already covers it, and map each raw value to a
   **named token in `tailwind.config.js`**. Where no token exists, propose a reusable,
   scale-style token name — never an arbitrary `[..]` value.

## Output (return this, not prose)

A structured brief:
- **Frame:** name + node id.
- **Node tree:** indented, each node labeled with its mapped primitive.
- **Token map:** `figma value -> tailwind token` (flag any that need adding).
- **Typography:** family/size/weight/line-height -> registered font + classes.
- **States:** the list above, each marked present/missing in the frame.
- **Open decisions:** nodes with no primitive/token, or missing interaction specs.

Do not write component code — your deliverable is the spec the implementer composes from.
