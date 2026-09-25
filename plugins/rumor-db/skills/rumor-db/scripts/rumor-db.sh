#!/usr/bin/env bash
# rumor-db.sh — read-only access to Rumor's Neon databases over the tailnet.
#
#   rumor-db.sh [--env prod|uat] [--csv] doctor          first-run setup check (no password)
#   rumor-db.sh [--env prod|uat] [--csv] status          who am I + data freshness
#   rumor-db.sh [--env prod|uat] [--csv] query "<SQL>"   one read-only statement
#   rumor-db.sh [--env prod|uat] [--csv] tables [text]   list tables, optional name filter
#   rumor-db.sh [--env prod|uat] [--csv] columns <table> columns of one table
#   rumor-db.sh [--env prod|uat] [--csv] event <slug>    therumor.com/p/<slug> -> event row
#   rumor-db.sh [--env prod|uat] preflight | probe       tailnet checks only (no password)
#
# Path: this Mac -> tailnet -> app connector rumor-prod-db-tunnel -> prod NAT
# (54.175.237.37, on both Neon IP-Allow lists) -> Neon. No SSH, no local port,
# no loopback: psql dials the real Neon hostname, so TLS SNI is correct and no
# PGOPTIONS=endpoint= is needed. Runbook: rumor-backend-services
# docs/DATABASE-TUNNEL.md.
#
# Rules this script enforces rather than trusts:
#   * The login is agent_bot (rumor-infra AGENTS.md: every agent Neon connection
#     uses agent_bot), from <env>-rumor-dispatch-neon-readonly. RUMOR_DB_LOGIN=
#     agent_adhoc selects the dedicated agent login once its secret exists. Any
#     other login is refused. There is no fallback to analyst or neondb_owner.
#   * The password lives only in this process's environment. Never on disk,
#     never on argv, never printed.
#   * It never changes Tailscale settings. It tells you what is wrong instead.
#   * Every query runs inside BEGIN READ ONLY with SET LOCAL timeouts, on the
#     DIRECT host (never -pooler), per AGENTS.md.
set -euo pipefail

ENV="prod"
FORMAT="aligned"
while [ $# -gt 0 ]; do
  case "$1" in
    --env) ENV="${2:-}"; shift 2 ;;
    --csv) FORMAT="csv"; shift ;;
    *) break ;;
  esac
done
case "$ENV" in prod|uat) ;; *) echo "ERROR: --env must be prod or uat" >&2; exit 2 ;; esac

CMD="${1:-}"; shift || true
REGION="us-east-1"
ACCOUNT="371876947910"
CONNECTOR="rumor-prod-db-tunnel"

# Whitelist of logins, each bound to its own secret. Nothing else is accepted.
LOGIN="${RUMOR_DB_LOGIN:-agent_bot}"
case "$LOGIN" in
  agent_bot)   SECRET_ID="${ENV}-rumor-dispatch-neon-readonly" ;;
  agent_adhoc) SECRET_ID="${ENV}-rumor-agent-readonly" ;;
  *) echo "ERROR: RUMOR_DB_LOGIN must be agent_bot or agent_adhoc (got '$LOGIN'). No other login is allowed." >&2; exit 2 ;;
esac

# The timeout goes into SQL, so it must match a strict shape. agent_bot's role
# default is 15s; SET LOCAL raises it for this one transaction only.
STMT_TIMEOUT="${RUMOR_DB_TIMEOUT:-60s}"
case "$STMT_TIMEOUT" in
  [1-9]s|[1-9][0-9]s|1[01][0-9]s|120s|1min|2min) ;;
  *) echo "ERROR: RUMOR_DB_TIMEOUT must be 1s..120s, 1min or 2min (got '$STMT_TIMEOUT')." >&2; exit 2 ;;
esac

# Anycast prefixes the old *.neon.tech connector domain list taught the connector.
# If they are still advertised, --accept-routes sends Vercel/Cloudflare/CloudFront
# traffic through prod. See rumor-infra db-tunnel/README.md.
ANYCAST_RE='^(64\.239\.|104\.16\.|104\.18\.|13\.35\.|18\.165\.)'

log()  { printf '%s\n' "$*" >&2; }
die()  { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
need() { command -v "$1" >/dev/null || die "$1 not found. $2"; }

aws_ok() {
  need aws "Install the AWS CLI (brew install awscli) and sign in to account $ACCOUNT."
  local acct
  acct=$(aws sts get-caller-identity --query Account --output text 2>/dev/null) \
    || die "the AWS CLI has no working credentials. Sign in to account $ACCOUNT (set AWS_PROFILE if you use profiles)."
  [ "$acct" = "$ACCOUNT" ] || die "the AWS CLI is signed in to account $acct, not $ACCOUNT. Set AWS_PROFILE to your Rumor profile."
}

# ── secret: host/db/user without the password, password only into PGPASSWORD ──
load_secret() {
  aws_ok
  local raw
  raw=$(aws secretsmanager get-secret-value --region "$REGION" --secret-id "$SECRET_ID" \
        --query SecretString --output text 2>&1) || {
    case "$raw" in
      *ResourceNotFound*)
        die "secret $SECRET_ID does not exist, so login $LOGIN is not provisioned in $ENV.
  STOP. Do not try analyst, neondb_owner, the Neon MCP or any other path. Tell the user." ;;
      *AccessDenied*)
        die "your AWS user may not read $SECRET_ID. Ask an AWS admin for secretsmanager:GetSecretValue on it.
  STOP. Do not try another login." ;;
      *) die "could not read $SECRET_ID: $raw" ;;
    esac; }
  # Parse in python, print only non-secret fields.
  local fields
  fields=$(printf '%s' "$raw" | python3 -c '
import json,sys
d=json.load(sys.stdin)
for k in ("POSTGRES_HOST","POSTGRES_DATABASE","POSTGRES_USERNAME"):
    v=d.get(k,"")
    if not v or any(c.isspace() for c in v): sys.exit("bad or missing "+k)
    print(v)') || die "secret $SECRET_ID has an unexpected shape"
  DB_HOST=$(sed -n 1p <<<"$fields"); DB_NAME=$(sed -n 2p <<<"$fields"); DB_USER=$(sed -n 3p <<<"$fields")
  [ "$DB_USER" = "$LOGIN" ] || die "secret user is '$DB_USER', expected '$LOGIN'. Refusing."
  DB_HOST="${DB_HOST/-pooler./.}"   # direct endpoint only; the pooler shares sessions
  case "$DB_HOST" in *[!A-Za-z0-9.-]*) die "secret host is not a bare hostname" ;; esac
  case "$DB_NAME" in *[!A-Za-z0-9_]*) die "secret database is not a bare name" ;; esac
  PGPASSWORD=$(printf '%s' "$raw" | python3 -c 'import json,sys;print(json.load(sys.stdin)["POSTGRES_PASSWORD"])')
  export PGPASSWORD
}

# The secret is the source of truth, but preflight/probe/doctor must work
# without a password, so they use the known compute hosts.
default_host() {
  case "$ENV" in
    prod) echo "ep-cold-moon-av2pkufg.c-11.us-east-1.aws.neon.tech" ;;   # read-only compute
    uat)  echo "ep-little-truth-avovdzfn.c-11.us-east-1.aws.neon.tech" ;; # no read-only compute on uat
  esac
}

# ── preflight: every tailnet condition from the runbook, checked in order ──────
# Sets HOSTADDR to one IPv4 address that routes through the tailnet. psql gets
# host=<real name> (TLS SNI) plus hostaddr=<that v4>, so a Mac with global IPv6
# cannot leak out over native v6 and be refused by the allow list.
preflight() {
  local host="$1" ts json
  need tailscale "Install Tailscale and join the therumor.com tailnet."
  need dig "dig ships with macOS; check your PATH."
  json=$(tailscale status --json 2>/dev/null) || die "tailscale is not running. Open the Tailscale app and sign in."

  CONNECTOR_JSON="$json" python3 - "$CONNECTOR" "$ANYCAST_RE" <<'PY' || exit 1
import json,os,re,sys
d=json.loads(os.environ["CONNECTOR_JSON"]); name,anycast=sys.argv[1],sys.argv[2]
def fail(m): print("ERROR: "+m,file=sys.stderr); sys.exit(1)
if d.get("BackendState")!="Running": fail("tailscale state is %s, not Running. Sign in to the tailnet."%d.get("BackendState"))
peers=[p for p in d.get("Peer",{}).values() if p.get("HostName")==name]
if not peers: fail("connector %s is not visible. You must be in group:eng on the therumor.com tailnet."%name)
p=peers[0]
if not p.get("Online"): fail("connector %s is offline. Tell the infra owner (arthurobo)."%name)
bad=[r for r in (p.get("PrimaryRoutes") or []) if re.match(anycast,r)]
if bad: print("WARNING: the connector still advertises %d Vercel/Cloudflare/CloudFront anycast routes (%s ...).\n"
              "         With --accept-routes on, that traffic goes through prod. Clear them: rumor-infra db-tunnel/README.md."%(len(bad),bad[0]),file=sys.stderr)
PY

  tailscale dns status 2>/dev/null | grep -qE 'neon\.tech' \
    || die "no neon.tech split-DNS route. Is --accept-dns off? The user runs: tailscale set --accept-dns=true"

  ts=$(tailscale debug prefs 2>/dev/null | python3 -c 'import json,sys;print(json.load(sys.stdin).get("RouteAll"))' 2>/dev/null || echo unknown)
  if [ "$ts" != "True" ]; then
    die "--accept-routes is off, so Neon traffic leaves en0 and Neon refuses your IP.
  The user turns it on (this script never changes it):  tailscale set --accept-routes"
  fi

  # dig through the tailnet resolver is also what makes the connector learn the
  # route, so a cold start fixes itself on the second pass.
  local ip ifc try
  HOSTADDR=""
  for try in 1 2; do
    for ip in $(dig +short A "$host" | grep -E '^[0-9]+(\.[0-9]+){3}$'); do
      ifc=$(route -n get "$ip" 2>/dev/null | awk '/interface:/{print $2}')
      case "$ifc" in utun*) HOSTADDR="$ip"; break 2 ;; esac
    done
    if [ "$try" = 1 ]; then sleep 3; fi
  done
  [ -n "$HOSTADDR" ] || die "no A record for $host routes through the tailnet (last: ${ip:-none} via ${ifc:-none}).
  The connector may not have learned the route yet. Wait a minute and retry."
  log "preflight ok: $host via $HOSTADDR ($ifc)"
}

# No credential at all. "no password supplied" = routing, TLS, SNI and the
# IP-Allow list all passed. "IP address ... not allowed" = the packet left
# your own interface.
probe() {
  need psql "brew install libpq, then add its bin to PATH."
  local h out; h=$(default_host); preflight "$h"
  out=$(PGPASSWORD='' psql -w --no-psqlrc "host=$h hostaddr=$HOSTADDR port=5432 dbname=neondb user=probe_nobody sslmode=require connect_timeout=15" -c 'select 1' 2>&1 || true)
  case "$out" in
    *"no password supplied"*) log "probe ok: Neon reached through the tailnet; refused only for the missing password." ;;
    *"not allowed to connect"*) die "Neon refused the source IP, so traffic did not go through the connector: $out" ;;
    *) die "unexpected: $out" ;;
  esac
}

conninfo() { echo "host=$DB_HOST hostaddr=$HOSTADDR port=5432 dbname=$DB_NAME user=$DB_USER sslmode=require connect_timeout=15 application_name=rumor-db-skill"; }

# Run SQL on stdin inside one read-only transaction. ON_ERROR_STOP ends the
# session on any error, which rolls the transaction back.
run_ro() {
  need psql "brew install libpq, then add its bin to PATH."
  local fmt=()
  [ "$FORMAT" = csv ] && fmt=(--csv)
  { printf 'BEGIN READ ONLY;\n'
    printf "SET LOCAL statement_timeout = '%s';\n" "$STMT_TIMEOUT"
    printf "SET LOCAL idle_in_transaction_session_timeout = '30s';\n"
    printf "SET LOCAL lock_timeout = '2s';\n"
    cat
    printf '\nCOMMIT;\n'
  } | psql --no-psqlrc -X -q -v ON_ERROR_STOP=1 -P pager=off ${fmt[@]+"${fmt[@]}"} "$@" "$(conninfo)"
}

connect() { load_secret; preflight "$DB_HOST"; }

# Whitelist the statement shape. Anything else is refused, never guessed at.
check_sql() {
  local sql="$1" body first
  body=$(printf '%s' "$sql" | sed -e 's/[[:space:]]*;[[:space:]]*$//')
  case "$body" in *";"*) die "one statement only (found ';' inside the SQL)." ;; esac
  case "$body" in *"\\"*) die "psql backslash commands are not allowed." ;; esac
  first=$(printf '%s' "$body" | tr '[:upper:]' '[:lower:]' | sed -e 's/^[[:space:](]*//' | awk '{print $1; exit}')
  case "$first" in
    select|with|explain|show|table|values) ;;
    *) die "only SELECT / WITH / EXPLAIN / SHOW / TABLE / VALUES are allowed (got '${first:-nothing}')." ;;
  esac
  SQL_BODY="$body"
}

bare_name() { case "$1" in ""|*[!A-Za-z0-9_]*) die "$2 must be letters, digits or _ (got '$1')" ;; esac; }

case "$CMD" in
  preflight) preflight "$(default_host)" ;;
  probe)     probe ;;

  doctor)
    # Everything a new teammate needs, checked in order, with no password read.
    log "== $ENV, login $LOGIN, secret $SECRET_ID"
    need python3 "Install Xcode command line tools: xcode-select --install"
    need psql "brew install libpq && brew link --force libpq"
    aws_ok; log "aws ok: account $ACCOUNT"
    aws secretsmanager describe-secret --region "$REGION" --secret-id "$SECRET_ID" --query Name --output text >/dev/null 2>&1 \
      || die "cannot see secret $SECRET_ID (missing, or your AWS user lacks access). Tell the user."
    log "secret ok: $SECRET_ID exists"
    probe
    log "doctor ok. Next: rumor-db.sh --env $ENV status" ;;

  status)
    connect
    run_ro -A -F ' | ' <<'SQL'
SELECT current_user AS user_name,
       pg_is_in_recovery() AS read_only_compute,
       current_setting('transaction_read_only') AS tx_read_only,
       now() AS db_now,
       (SELECT max(created_at) FROM "user") AS newest_user,
       now() - (SELECT max(created_at) FROM "user") AS newest_user_age;
SQL
    ;;

  query)
    [ $# -ge 1 ] || die 'usage: rumor-db.sh query "SELECT ..."'
    check_sql "$1"
    connect
    printf '%s;\n' "$SQL_BODY" | run_ro ;;

  tables)
    filter="${1:-}"
    [ -z "$filter" ] || bare_name "$filter" "filter"
    connect
    run_ro -v filter="%${filter}%" <<'SQL'
SELECT c.relname AS table_name,
       c.reltuples::bigint AS approx_rows
  FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
 WHERE n.nspname = 'public' AND c.relkind IN ('r','p','v','m')
   AND c.relname ILIKE :'filter'
 ORDER BY 1;
SQL
    ;;

  columns)
    table="${1:-}"; bare_name "$table" "table"
    connect
    run_ro -v t="$table" <<'SQL'
SELECT column_name, data_type, is_nullable, column_default
  FROM information_schema.columns
 WHERE table_schema = 'public' AND table_name = :'t'
 ORDER BY ordinal_position;
SQL
    ;;

  event)
    slug="${1:-}"
    case "$slug" in ""|*[!A-Za-z0-9_-]*) die "slug must be letters, digits, - or _" ;; esac
    connect
    run_ro -v slug="$slug" <<'SQL'
SELECT id, name, custom_url, start_date, created_at
  FROM event WHERE custom_url = :'slug';
SQL
    ;;

  *)
    sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//' >&2; exit 2 ;;
esac
