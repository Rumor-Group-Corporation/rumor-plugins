# vercel

Connects Claude Code to **Vercel's official MCP server** (`https://mcp.vercel.com`) so agents can
manage projects and deployments, inspect deployment status, and read build/runtime logs without
leaving the editor.

## Install

```
/plugin marketplace update rumor
/plugin install vercel@rumor
```

## Authenticate

The server uses OAuth. After install, open the MCP panel and sign in to the Vercel account/team you
want:

```
/mcp
```

Pick the scope (e.g. `bc-rumor-design` or `therumor`) when prompted.

## What you get

Tools to list/inspect projects and deployments, check deployment state, and pull build & runtime
logs — handy for shipping and debugging the Rumor web apps and the design-system microsite.

> Remote HTTP MCP, OAuth per user — nothing secret is committed. Each teammate authenticates their
> own Vercel access on install.
