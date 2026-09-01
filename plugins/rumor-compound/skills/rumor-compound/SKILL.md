---
name: rumor-compound
description: "The Rumor compound-engineering loop and its shared context (repos, laws, Linear wiring, worktrees, review stack). Load when starting or routing any rce-* stage, when the user says 'compound engineering', asks how the Rumor loop works, or invokes /rce with no stage. Holds the laws and references every other rce-* skill reads."
---

# Rumor Compound Engineering — the loop

**The year is 2026.** Compound engineering means structuring work so each unit
makes the next one easier: you capture what you learn as you go, in the repo, so
the toolset gets smarter every run. This plugin is that loop for the Rumor stack,
wired to **Linear** (not GitHub Issues) and aware of **every main Rumor repo**.

## The pipeline

```
  /rce-ideate  ── grounded ideas from the repo + open Linear issues
       │
  /rce-plan    ── a durable plan in docs/plans/, anchored to a Linear issue
       │
  /rce-work    ── build it in an isolated sibling worktree, path-limited commits
       │
  /rce-review  ── Rumor's real reviewers (opus-reviewer, thermos, rams, /code-review)
       │
  /rce-ship    ── commit (named files), push, PR linked to the Linear issue
       │
  /rce-babysit ── watch CI + answer EVERY bot finding, drive to merge-ready
       │
  /rce-compound ─ write the learning to docs/solutions/ so the next agent reuses it
```

`/rce-lfg` runs the whole pipeline hands-off for one Linear issue.
`/rce-setup` health-checks a repo and writes its config.

Each stage hands a durable artifact to the next. You do not need to run them in
order or all of them — each works alone. But the compounding only happens if you
close the loop: **`rce-compound` is what makes tomorrow cheaper.**

## Shared context — load what the stage needs

The stage skills are lean kernels. The Rumor knowledge lives in this skill's
`references/`, and each stage loads only the files it needs. Resolve these paths
**from this `rumor-compound` skill's directory** (the stage skills reach them as
`../rumor-compound/references/<file>`):

- **`references/laws.md`** — the 10 non-negotiable Rumor laws. **Every stage loads
  this.** It outranks the task.
- **`references/repos.md`** — repo detection, package-manager detection, deriving
  the verify command. Load in any stage that runs or ships code.
- **`references/linear.md`** — branch⇄issue anchor, read-free / write-additive
  rules, PR linking. Load in any stage that touches an issue.
- **`references/worktree.md`** — sibling `<repo>-worktrees/<slug>` isolation. Load
  before any branch move or edit.
- **`references/review-stack.md`** — which reviewers exist and how to route.
- **`references/config.md`** — optional `.compound-engineering/config.yaml`.

If a `references/*.md` this skill names cannot be read, **stop** before the action
it governs and report the missing reference — do not reconstruct a law or a
convention from memory.

## The one rule that makes it "the Rumor way"

Before any stage acts, it has read **`references/laws.md`** and knows which repo it
is in (**`references/repos.md`**). A stage that skips those two is running generic
compound engineering, not Rumor's — and will violate a worktree, merge, or deploy
law that generic engineering has no reason to know.

## When invoked directly

If the user runs `/rce` or asks about the loop with no stage in mind, show the
pipeline above, name the seven stages plus `lfg`/`setup`, and ask which one — or
offer `/rce-lfg <Linear issue>` to run the whole thing. Do not start building.
