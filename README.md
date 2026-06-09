# rumor — Claude Code plugin marketplace

A personal [Claude Code](https://code.claude.com/docs/en/plugins) plugin marketplace for the Rumor stack.

## Install

```
/plugin marketplace add Rumor-Group-Corporation/rumor-plugins
/plugin install thermos@rumor
```

## Plugins

| Plugin | Description |
|--------|-------------|
| **thermos** | Thermo-nuclear branch review — deep correctness/security audits and harsh code-quality rubrics, run by parallel subagents. Vendored from [cursor/plugins](https://github.com/cursor/plugins/tree/main/thermos) (MIT) and repackaged in Claude Code plugin format. |

### thermos skills

- `/thermos:thermo-nuclear-review` — comprehensive security + correctness audit of a branch's changes
- `/thermos:thermo-nuclear-code-quality-review` — extremely strict maintainability / abstraction-quality review
- `/thermos:thermos` — runs both reviews in parallel via subagents, then synthesizes findings

## Adding more plugins

Drop a plugin under `plugins/<name>/` (with `.claude-plugin/plugin.json`) and add an entry to
`.claude-plugin/marketplace.json`, then push. Users refresh with `/plugin marketplace update rumor`.
