---
name: rce-setup
description: "Health-check the Rumor compound loop in the current repo and write/refresh its optional .compound-engineering/config.yaml. Run once per repo, or to confirm where artifacts land, which verify command is used, and whether Linear is reachable."
disable-model-invocation: true
---

# rce-setup — health check and repo config

A lightweight check. It does **not** bulk-install anything; it reports what is
present and offers to write the one optional config file.

## Load first

`../rumor-compound/references/repos.md`, `config.md`, `linear.md`, `laws.md`.

## Phase 1 — Diagnose

Run the bundled health script from **this skill's directory** (the Bash CWD is the
user's repo, not the skill dir, so a bare `scripts/` path will not resolve):

```bash
SKILL_DIR="<absolute path of the directory containing this SKILL.md>"
bash "$SKILL_DIR/scripts/check-health"
```

If the script is missing, run its checks inline. The report covers:

- **Repo:** name, remote (must be `Rumor-Group-Corporation/<name>`), current branch,
  and the Linear id parsed from the branch.
- **Package manager** (from the lockfile) and the **derived verify command** (from
  `package.json` scripts) — the exact command `rce-work` will run.
- **Worktree convention:** the sibling `<repo>-worktrees/` dir and how many
  worktrees are live.
- **docs_root:** the resolved artifact root and which config layer set it. An
  invalid `docs_root` is flagged — artifacts will not be written until it is fixed.
- **Linear MCP:** reachable this session or not (degrade-and-disclose if not).
- **Reviewers:** which of opus-reviewer / thermos / rams / `/code-review` are
  available.

Display the report. Missing optional reviewers are capabilities, not failures.

## Phase 2 — Offer to write config

If the repo has no `.compound-engineering/config.yaml`, offer to create one from
`../../templates/config.example.yaml` (relative to the plugin root). Every write to
a user-owned file is offered, not forced (LAW 1). Also offer to add
`.compound-engineering/config.local.yaml` to `.gitignore` if that pattern is used.
Refresh `config.example.yaml` if it is stale.

## Phase 3 — Summary

```text
✅ Rumor compound-engineering — ready

Repo:      <name>  (<remote>)  branch <branch>  →  Linear <ISSUE-ID or none>
Verify:    <derived verify command>
Artifacts: <docs_root>/{plans,solutions,ideation}
Linear:    <reachable | not connected this session>
Reviewers: <available list>

Run  /rce-lfg <ISSUE-ID>  to run the whole loop, or /rce-plan to start.
```
