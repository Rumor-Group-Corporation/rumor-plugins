---
name: rce-compound
description: "Capture a just-solved problem as a durable learning in the repo's docs/solutions/, so the next agent on this repo finds and reuses it. Use after finishing a non-trivial fix or feature -- this is the step that makes tomorrow's work cheaper. Rumor compound-engineering loop."
argument-hint: "[optional brief context] [mode:non-interactive for rce-lfg]"
---

# rce-compound — capture the learning (the compounding step)

**Outcome:** one solved problem written as a durable learning under
`<docs_root>/solutions/` in **this repo**, grounded against the current tree,
discoverable by the next agent. This is the step the whole loop exists for: without
it, every run starts from zero.

**One learning per run.** A session that solved several things gets several runs.

## Load first (required)

1. `../rumor-compound/references/laws.md`
2. `../rumor-compound/references/repos.md` — repo + `docs_root`.
3. `../rumor-compound/references/config.md`.

## Precondition (judge, do not ask)

Document a problem that is **solved, verified, and non-trivial** — a bug fix, a
convention discovered, a trap avoided, a workflow that worked. Judge this from the
session. If the session holds no such problem, write nothing and say why. (Learnings
land in the repo's `docs/solutions/`, per Chris's choice — this plugin does not
write to `~/.claude` auto-memory.)

## Phase 1 — Research

Gather the learning's substance from the session and re-ground it against the
current tree (the fix must still be there, the files must still exist). Check
`docs/solutions/` for an existing doc on the same problem — **update** it rather
than duplicating. Pull the Linear issue id (branch or arg) so the learning links
back to the work.

## Phase 2 — Write the learning

Write `<docs_root>/solutions/<short-slug>.md` (creation date lives **in the entry**,
not the filename). Frontmatter + body:

```markdown
---
title: <one line>
category: bug | convention | workflow | architecture
tags: [<repo>, <area>, ...]
problem_type: bug | knowledge
linear: DEM-519
date: 2026-08-31
---

## Problem
<what went wrong / what was unclear — concrete, with the symptom>

## Solution
<what fixed it, with the file:line or command that proves it>

## Why / how to apply next time
<the general rule the next agent should carry — this is the compounding part>

## Guidance layer
<if this contradicts a skill / runbook / CLAUDE.md that an agent reads while
acting, name that file — a learning that disagrees with acting-time guidance is
liable to be overridden, so flag it here rather than silently editing the guidance>
```

Ground every claim in the tree. A learning the next agent cannot verify is noise.

## Phase 3 — Record and report

Post a one-line pointer to the new learning as a comment on the Linear issue
(`save_comment`, autonomous per LAW 9), so the tracked work carries its own
knowledge trail. Then report: the learning path, the issue it links, and — if a
`docs/solutions/` doc contradicted current guidance — which guidance file to fix.

## mode:non-interactive (rce-lfg)

Ask nothing. Run the write-and-report pass and end on a terminal line the caller
parses: `Learning captured: <path>`, or `No learning captured: <reason>`.
