---
name: rumor-db
description: Query the Rumor production or UAT database (Neon Postgres) read-only over Tailscale. Use whenever you need real Rumor data — "check the DB", "how many guests/RSVPs/users", "look up this event / user / guest", resolve therumor.com/p/<slug>, verify a bug against real rows, check data freshness, or "can I reach the database". This is the ONLY approved agent path to the Rumor database; use it instead of the Neon MCP, the old jump host, rumor-readonly-db, or a hand-built psql command.
---

# rumor-db — read-only Rumor database over Tailscale

One script does everything. It sits next to this file:

```bash
DB="${CLAUDE_PLUGIN_ROOT:-/nonexistent}/skills/rumor-db/scripts/rumor-db.sh"
[ -x "$DB" ] || DB=$(find ~/.claude/plugins/cache ~/.claude/skills/rumor-db/ \
                        -path '*rumor-db/scripts/rumor-db.sh' 2>/dev/null | sort | tail -1)
echo "$DB"   # empty? use scripts/rumor-db.sh inside this skill's base directory
```

Start with `status`. Run `doctor` only on a new machine or when `status` fails.

Default env is `prod`. Global flags go BEFORE the command: `--env uat`, `--csv`.
Results go to stdout. The `preflight ok: ...` line and all errors go to stderr,
so `"$DB" --csv query "..." > out.csv` gives a clean CSV.

```bash
"$DB" doctor                        # first run on a machine: checks everything, no password
"$DB" status                        # who am I, read-only?, how fresh is the data
"$DB" tables guest                  # tables whose name contains "guest", with approx rows
"$DB" columns guest                 # columns of one table — run this BEFORE writing SQL
"$DB" event my-party-slug           # event row for therumor.com/p/my-party-slug
"$DB" query "SELECT count(*) FROM guest WHERE deleted_at IS NULL"
"$DB" --csv query "SELECT status, count(*) FROM guest GROUP BY 1"
"$DB" --env uat status
```

## Do this, every time

1. Run the script. Do not build your own psql command, conninfo, SSH tunnel or
   `PGOPTIONS`. The script already does routing, IPv4 pinning, TLS and timeouts.
2. Do not guess column names. Run `columns <table>` first.
3. One statement per `query`. Allowed first words: SELECT, WITH, EXPLAIN, SHOW,
   TABLE, VALUES. No `;` inside the SQL. No backslash anywhere (write
   `right(col,3)='_id'`, not `LIKE '%\_id'`). Add a `LIMIT` yourself.
4. Long query? `RUMOR_DB_TIMEOUT=2min "$DB" query "..."` (default 60s, max 2min).

## Never do these

- Never use the Neon MCP (`mcp__Neon__*`). It connects as the owner role, with write access.
- Never use the jump host `44.202.90.183`, `rumor-readonly-db`, or `rumor-team-jumphost.pem`. They are gone.
- Never use the `analyst` or `neondb_owner` login, and never read a secret yourself.
  The script reads it into its own process only.
- Never change Tailscale settings (`tailscale set ...`). Tell the user the command instead.
- Never paste emails, phone numbers or names from results into Slack, Linear, PRs or files
  unless the user asks. The data is real customer PII.

If the script fails, read the error, find it in the table below, and do what the
table says. If the table says STOP, stop and tell the user. Do not try another path.

## Errors

| Error text | Cause | What to do |
|---|---|---|
| `tailscale is not running` / `state is ... not Running` | Tailscale off or signed out | User opens Tailscale and signs in. |
| `connector ... is not visible` | User not in `group:eng` | STOP. Ask the tailnet admin (arthurobo). |
| `connector ... is offline` | Connector down | STOP. Tell arthurobo. |
| `--accept-routes is off` | Mac does not use tailnet routes | User runs `tailscale set --accept-routes`. |
| `no neon.tech split-DNS route` | `--accept-dns` off | User runs `tailscale set --accept-dns=true`. |
| `no A record ... routes through the tailnet` | Route not learned yet | Wait 60s, retry once. |
| `Neon refused the source IP` | Traffic left the tailnet | Run `doctor`; report its output. |
| `AWS CLI has no working credentials` / `signed in to account X` | AWS not signed in, or wrong profile | User signs in; set `AWS_PROFILE` to their Rumor profile. |
| `may not read ...` / `cannot see secret` | AWS user lacks access to the secret | STOP. User asks an AWS admin for `secretsmanager:GetSecretValue` on `<env>-rumor-dispatch-neon-readonly`. |
| `secret ... does not exist` | Login not provisioned | STOP. Tell the user. |
| `canceling statement due to statement timeout` | Query too slow | Add filters / LIMIT, or `RUMOR_DB_TIMEOUT=2min`. |
| `cannot execute ... in a read-only transaction` | You wrote a write | Working as designed. This skill is read-only. |
| Permission prompt or classifier denial on the script | Harness permission | STOP. Ask the user to allow it (rule below). Do not work around it. |

Allow rule for `~/.claude/settings.json` → `permissions.allow` (user adds it once):
`"Bash(*/rumor-db/scripts/rumor-db.sh *)"`

## Schema facts (verified 2026-09-25 on prod)

These are the traps that give a wrong number with no error. Read them before you
answer a counting question.

- Tables are singular: `event`, `guest`, `"user"` (always quote `user`), `user_role`,
  `guest_ticket_type`.
- **Soft delete everywhere.** `event`, `guest`, `"user"`, `user_role`,
  `guest_ticket_type` all have `deleted_at`. Add `deleted_at IS NULL` for EVERY
  table in the query. The app (TypeORM) adds it; raw SQL does not.
- **Check-in is NOT `guest.check_in`.** That column is deprecated and almost
  always NULL. The real value is `guest_ticket_type.check_in` (boolean, NOT NULL,
  default false), joined on `guest_ticket_type.guest_id = guest.id`. Count
  checked-in guests as `count(DISTINCT g.id) FILTER (WHERE gtt.check_in)`.
  `last_checked_in_at` is almost never set; do not use it. One guest can have
  several `guest_ticket_type` rows, so always count `DISTINCT g.id`, never `count(*)`.
  `false` means "no-show" OR "the host never ran check-in". An event with 0
  check-ins probably did not use the door tool. Say so; do not report a 0% show rate.
- `therumor.com/p/<slug>` = `event.custom_url`. It can be NULL; then identify the
  event by `event.id`. Event host = `event.owner_id`.
- `guest` joins: `guest.event_id` → `event.id`, `guest.user_id` → `"user".id`.
- `guest.status` is an enum (shows as `USER-DEFINED` in `columns`); compare with a
  string literal. Values: CONFIRMED, INVITED, APPLIED, DECLINED, DRAFT, NO_STATUS.
- Plus-ones are ordinary `guest` rows with `guest_of_id` / `lead_guest_id` set.
  A plain count includes them. Say in your answer whether you included them.
- Time types differ: `event.start_date` / `end_date` are `timestamptz`;
  `created_at`, `updated_at`, `deleted_at` are `timestamp` (UTC, no zone).
- `"user"` contact: `email`, `phone_number`. Roles: `user_role.user_id`, `role_id`, `status`.
- `tables <text>` is a case-insensitive substring match on table name. `columns`
  takes a bare table name (schema `public` only). `EXPLAIN ANALYZE` is allowed;
  it runs the query inside the read-only transaction.

## How it works (for debugging only)

Mac → tailnet → app connector `rumor-prod-db-tunnel` → prod NAT `54.175.237.37`
(on both Neon IP-Allow lists) → Neon direct host. psql dials the real hostname
with `hostaddr=<tailnet-routed IPv4>` so IPv6 cannot bypass the connector. Login
is `agent_bot` from AWS secret `<env>-rumor-dispatch-neon-readonly` (rumor-infra
AGENTS.md: agents use `agent_bot`). Each call runs in `BEGIN READ ONLY` with
`SET LOCAL` timeouts. On prod it lands on the physically read-only compute; UAT
has no read-only compute, so there only the role and the transaction block writes.
`RUMOR_DB_LOGIN=agent_adhoc` switches to the dedicated agent login when its
secret `<env>-rumor-agent-readonly` exists. No other login is accepted.
