# rumor — Claude Code plugin marketplace

A personal [Claude Code](https://code.claude.com/docs/en/plugins) plugin marketplace for the Rumor stack.

## Install

```
/plugin marketplace add Rumor-Group-Corporation/rumor-plugins
/plugin install rumor-harness@rumor
/rumor-harness:setup
```

## Plugins

| Plugin | Description |
|--------|-------------|
| **rumor-harness** | **Everyone should install this.** Rumor's shared Claude Code harness: Jev (TypeSafe) compaction keeps long sessions small without a lossy summary, large-file reads go to exact line ranges, and numbers-only team metrics keep it improving. Install, then run `/rumor-harness:setup`. Source: [rumor-jev-router](https://github.com/Rumor-Group-Corporation/rumor-jev-router). |
| **thermos** | Thermo-nuclear branch review — deep correctness/security audits and harsh code-quality rubrics, run by parallel subagents. Vendored from [cursor/plugins](https://github.com/cursor/plugins/tree/main/thermos) (MIT) and repackaged in Claude Code plugin format. |
| **ralph-wiggum** | Autonomous agent loop — runs Claude Code repeatedly until all PRD items are done, fresh context each iteration, memory persisted via git/`progress.txt`/`prd.json`. Based on Geoffrey Huntley's Ralph pattern. |

### ralph-wiggum commands

- `/ralph-wiggum:prd` — generate a structured `prd.json` from an idea or Linear issue
- `/ralph-wiggum:ralph` — start the autonomous loop against a `prd.json`
- `/ralph-wiggum:ralph-status` — check progress of a running loop

### thermos skills

- `/thermos:thermo-nuclear-review` — comprehensive security + correctness audit of a branch's changes
- `/thermos:thermo-nuclear-code-quality-review` — extremely strict maintainability / abstraction-quality review
- `/thermos:thermos` — runs both reviews in parallel via subagents, then synthesizes findings

## Adding more plugins

Drop a plugin under `plugins/<name>/` (with `.claude-plugin/plugin.json`) and add an entry to
`.claude-plugin/marketplace.json`, then push. Users refresh with `/plugin marketplace update rumor`.
