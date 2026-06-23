---
description: Turn a Figma frame into a shipped, standards-compliant, tested UI screen in rumor-mobile-expo.
argument-hint: "<figma-url> [target route or feature name]"
---

# /figma-screen — Figma frame -> shipped screen

Run the full Rumor design-to-code pipeline for: **$ARGUMENTS**

Load and follow the `figma-to-screen` skill as the master workflow. It sequences the
`rumor-mobile-standards`, `rumor-behavior-testing`, and `rumor-ui-verify-loop` skills —
pull each in as its phase needs it.

## Do this in order

1. **Loop setup** — confirm you're on a clean branch off `dev`, the simulator + Metro are
   up, and the Figma Dev Mode MCP is reachable. Open (or confirm) a draft PR.
2. **Extract** — use the `figma-design-extractor` agent on the URL. Get exact tokens,
   spacing, typography, the node tree, and every interaction/empty/error state. Produce the
   extraction brief.
3. **Map** — before any JSX, produce the mapping table: each Figma node -> an existing
   `src/components/ui/` primitive + named `tailwind.config.js` tokens. Flag any node with no
   mapping as an explicit decision (extend a primitive / add a token).
4. **Compose** — build the thin route + feature components to `rumor-mobile-standards`.
   Honor the standards hook's feedback as a blocking signal.
5. **Test** — behavior tests per `rumor-behavior-testing`, covering the full state matrix.
6. **Verify** — run the `rumor-ui-verify-loop`; then run `/figma-audit` to check the build
   against the frame (spacing, tokens, a11y, states).
7. **Self-review & ship** — `/code-review` then `/simplify`; fix at the right altitude;
   push; drive CI green; triage + resolve bot threads with a regression test per fix.
8. **Retro** — if anything surprised you, run `/ui-retro` to fold it back into the plugin.

Stop and ask the user only when a design decision is genuinely ambiguous (a node with no
primitive and no obvious token, or a missing interaction spec). Otherwise proceed.
