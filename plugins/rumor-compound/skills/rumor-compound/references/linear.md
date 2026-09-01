# Linear — the issue tracker (replaces GitHub Issues everywhere)

Rumor tracks work in **Linear**, not GitHub Issues. Wherever the upstream compound
loop reaches for a GitHub issue — grounding ideation, the plan's source of record,
recording review residuals, closing the loop — this plugin reaches for a Linear
issue instead. This file owns that wiring. Every `rce-*` skill that touches an
issue loads it.

## Reaching Linear

Use the workspace's **Linear MCP tools**, matched by capability, not by a fixed
server name (the server id differs per session). The tool suffixes you need:

| Need | Tool suffix |
|------|-------------|
| Find issues | `list_issues` (filters: `team`, `assignee`, `state`, `query`, `project`, `label`, `cycle`) |
| Read one issue | `get_issue` (accepts an identifier like `DEM-519` or a UUID) |
| Create / update an issue | `save_issue` |
| Read comments | `list_comments` |
| Post a comment | `save_comment` |
| Statuses for a team | `list_issue_statuses` |
| Teams / projects / users | `list_teams`, `list_projects`, `list_users`, `get_user` |
| Attach a link (PR) | `create_attachment` |

If these are **deferred** (not yet loaded), load them with the host's tool-search
primitive using the query `linear` before calling them. If **no** Linear MCP is
connected this session, say so and fall back: read the issue from what the user
pasted, and record residuals in the PR body instead of a Linear comment. Never
block the loop on Linear being unreachable — degrade and disclose.

## Branch ⇄ issue — the anchor

Rumor branches are named `chris/<key>-<num>-<slug>`, e.g.
`chris/dem-519-chat-delegated-channel`. The Linear identifier is the `<key>-<num>`
part, **uppercased**:

```bash
BRANCH="$(git -C "$REPO_ROOT" rev-parse --abbrev-ref HEAD)"
ISSUE_ID="$(printf '%s' "$BRANCH" | grep -oiE '[a-z]+-[0-9]+' | head -1 | tr a-z A-Z)"
# dem-519 -> DEM-519 ; plat-432 -> PLAT-432 ; rum-8325 -> RUM-8325
```

Team keys in the workspace: **RUM** (Rumor), **DEM** (Pod 2 / Demand),
**PLAT** (Platform), plus Services, Pod 1 (Supply), Design. Do not hardcode the
map — `get_issue "$ISSUE_ID"` resolves the team itself.

**Resolving the active issue**, in order:
1. An issue id in the skill's argument (`DEM-519`, or a `linear.app/...` URL).
2. The id parsed from the current branch (above).
3. Ask the user which issue, or offer to create one (LAW 9: creation is
   autonomous, but naming a *new* record when one may already exist deserves a
   quick "or is this DEM-###?" so you do not create a duplicate).

## Read is free; write is additive-autonomous (LAW 9)

- **Reading** issues, comments, projects, and statuses for grounding and context
  is always fine and needs no confirmation.
- **Writing** is autonomous only when additive and forward: create an issue, post
  a comment, attach the PR link, add a label, move status **forward**
  (Todo → In Progress → In Review → Done via `list_issue_statuses` then
  `save_issue`).
- **Ask first** (LAW 1) before deleting/archiving anything, moving status
  **backward** or to Canceled, reassigning away from the owner, or bulk-editing.

When you post to Linear, keep it a durable record a human will act on — link the
PR, name the residual, state the decision. Do not narrate plugin plumbing there.

## PR ⇄ Linear linking

Put the issue id in the branch name (already the convention) and in the PR title
or body; Linear auto-links a PR whose branch or title contains `DEM-519`. Also
`create_attachment` the PR URL onto the issue so the link is bidirectional, and
let status automation (or an explicit forward `save_issue`) move the issue to
In Review on PR open and Done on merge.
