# rumor-db

Lets your agent query the Rumor database (prod or UAT) **read-only**, over Tailscale,
with one script. The agent loads the `rumor-db` skill by itself when you ask for real
data ("how many guests confirmed for X", "look up this user", "check the DB").

## Install

```
/plugin marketplace add Rumor-Group-Corporation/rumor-plugins
/plugin install rumor-db@rumor
```

## One-time setup on your Mac

You need all five. `doctor` checks them in order and tells you which one is missing.

1. **Tailscale** — signed in to the therumor.com tailnet, in `group:eng`
   (ask arthurobo if the connector is "not visible").
2. **Tailscale routes and DNS on:**
   ```
   tailscale set --accept-routes --accept-dns=true
   ```
3. **AWS CLI** signed in to account `371876947910`. If you use profiles, export
   `AWS_PROFILE` in your shell profile so the agent's shell gets it too.
4. **Secret access:** your AWS user needs `secretsmanager:GetSecretValue` on
   `prod-rumor-dispatch-neon-readonly` and `uat-rumor-dispatch-neon-readonly`.
   `ReadOnlyAccess` alone does NOT include this. Ask an AWS admin.
5. **psql:** `brew install libpq && brew link --force libpq`

Then ask your agent to "run rumor-db doctor", or run it yourself:

```
~/.claude/plugins/cache/rumor/rumor-db/*/skills/rumor-db/scripts/rumor-db.sh doctor
```

**Optional, stops permission prompts:** add this to `permissions.allow` in
`~/.claude/settings.json`:

```json
"Bash(*/rumor-db/scripts/rumor-db.sh *)"
```

## What the script guarantees

- Login is `agent_bot` only (rumor-infra `AGENTS.md`). `analyst`, `neondb_owner` and
  anything else are refused. The password never touches disk, argv or output.
- One statement per call, first word SELECT / WITH / EXPLAIN / SHOW / TABLE / VALUES,
  inside `BEGIN READ ONLY` with a 60s timeout (max 2min). Prod lands on the read-only compute.
- It never changes your Tailscale settings.

Results contain real customer PII. Do not paste them into Slack, Linear or PRs.
