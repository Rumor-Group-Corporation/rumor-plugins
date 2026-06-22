# rumor-ui

**Figma -> code, the Rumor way.** Turns a Figma frame into a standards-compliant, tested,
verified UI screen in `rumor-mobile-expo` — and gets better every time you use it.

This plugin compresses everything we learned shipping Rumor Mutuals (the
[zero-to-hero playbook](https://github.com/Rumor-Group-Corporation)) into something the
agent loads, enforces, and improves automatically.

## What's in it

| Piece | Name | Does |
|---|---|---|
| **Command** | `/figma-screen <url>` | The full pipeline: extract -> map -> compose -> test -> verify -> ship. |
| **Command** | `/figma-audit <screen>` | Measure a built screen against its Figma frame + standards. |
| **Command** | `/ui-verify` | Simulator loop: deep-link, screenshot, report what actually rendered. |
| **Command** | `/ui-retro` | Fold a new learning back into the plugin. |
| **Skill** | `figma-to-screen` | The master workflow that sequences the others. |
| **Skill** | `rumor-mobile-standards` | How we write code (AGENTS.md distilled + rationale). |
| **Skill** | `rumor-behavior-testing` | The RNTL/jest harness + every gotcha we've already paid for. |
| **Skill** | `rumor-ui-verify-loop` | The pixel-tight sim loop + native/runtime gotchas. |
| **Agent** | `figma-design-extractor` | Turns a frame into an exact, code-ready brief. |
| **Agent** | `rumor-ui-standards-reviewer` | Judgment-call standards review the hook can't do. |
| **Hook** | `check-tsx-standards.sh` | Auto-flags hard standards violations the instant they're written. |
| **Ledger** | `LESSONS.md` | The consistently-improve log; reviewed like code. |

## Install

It's published in the `rumor` marketplace (this repo). Add the marketplace, then install:

```
/plugin marketplace add Rumor-Group-Corporation/rumor-plugins
/plugin install rumor-ui@rumor
```

Pair with the **Figma Dev Mode MCP** (desktop app) and **XcodeBuild MCP** for the full loop.

## The design philosophy

1. **Tighten the loop, then let it rip** — every phase ends in an objective signal.
2. **Verify, don't assert** — look at the rendered pixels, not the diff.
3. **Reuse, don't reinvent** — compose from `src/components/ui/` primitives and tokens.
4. **Standards are executed, not remembered** — the hook enforces; the skills explain.
5. **It compounds** — `/ui-retro` makes every shipped screen improve the next one.

## Contributing a lesson

Run `/ui-retro` after a screen ships, or edit the relevant skill / `LESSONS.md` directly,
bump the patch version in `.claude-plugin/plugin.json`, and open a PR. The plugin is code.
