---
description: Generate/refresh the strict design-system artifacts (token-map.json, DESIGN.md, code-connect.json, CLAUDE rules) from tailwind.config.js + src/components/ui + the Figma file.
argument-hint: "[figma-file-url] (optional — for variable + Code Connect extraction)"
---

# /figma-ds-sync — build the closed vocabulary

Generate or refresh the strict design-system artifacts for `rumor-mobile-expo` so all
Figma->code generation stays on-system. Follow the `rumor-strict-design-system` skill.
Input (optional): a Figma file URL for variable + Code Connect extraction — **$ARGUMENTS**

## Steps

1. **Scan the code side.**
   - Parse `tailwind.config.js` `theme.extend` -> every color/spacing/radius/fontFamily/
     fontSize/letterSpacing/lineHeight key and its value.
   - List `src/components/ui/*` primitives + their key props/variants.

2. **Scan the Figma side** (if a URL is given).
   - `get_variable_defs` -> the file's design variables (name -> value).
   - `get_code_connect_map` -> Figma component id -> code component links.

3. **Build `token-map.json`.** For each tailwind token, write
   `{ "<figma-var-or-category>/<name>": { "tw": "<key>", "class": "<emitted classes>" } }`.
   Match Figma variables to tailwind keys by value (hex/px) first, then by name. Report:
   - **Mapped** — Figma var <-> tailwind token (by value).
   - **Figma-only** — variables with no tailwind token (candidates to add to the config).
   - **Code-only** — tailwind tokens with no Figma variable (fine; still emittable).
   Use `templates/token-map.example.json` in this plugin as the format reference (it's built
   from the real config).

4. **Build `code-connect.json`** from the Code Connect map (Figma component -> ui import +
   prop mapping). Note unmapped Figma components — they fall back to the primitive-grep path.

5. **Write/refresh `DESIGN.md`** in the 6-section format (see `templates/DESIGN.example.md`),
   tokens stated as NativeWind classes. Keep it honest to the actual palette/fonts.

6. **Write the CLAUDE rules block** (the `IMPORTANT:`-prefixed enforcement prose from the
   skill) into the mobile repo's `CLAUDE.md` Figma section if not already present.

7. **Report a diff summary:** what changed since last sync, any Figma-only values that need a
   token decision, and any newly-unmapped components.

## Where artifacts go

`token-map.json`, `code-connect.json`, `DESIGN.md` live at the **`rumor-mobile-expo` repo
root** (they describe that app, not the plugin). Do not commit them to the plugin. This
command is the runtime generator; the plugin only ships the format + the rules.

Do not invent tokens. If Figma needs a value the config lacks, surface it as a decision in
step 3 — adding a token is a deliberate edit to `tailwind.config.js`, not an auto-action.
