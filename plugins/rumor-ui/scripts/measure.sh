#!/usr/bin/env bash
#
# rumor-ui MEASURE step — capture the current sim screen and diff it against a baseline
# (typically a Figma frame export). The numeric backbone of the convergence loop.
#
# Wraps Argent's CLI (`argent run …`), handles the cold-start capture race, and emits ONE
# compact JSON line to stdout that the loop parses:
#   {"mismatch_pct": <float|null>, "status": "...", "current": "...",
#    "diffPath": "...", "contextDiffPath": "..."}
#
# Usage:
#   measure.sh --udid <udid> --outdir <dir> \
#              [--baseline <figma-frame.png>] [--bundle <id> --launch] [--route <url>] \
#              [--current <path>]
#
# Exit 0 on success (JSON on stdout); non-zero with {"error":...} on failure.
#
# IMPORTANT: Argent CLI stdout is redirected to a FILE, never captured via $(...). Command
# substitution intermittently lost the CLI's stdout even when the tool succeeded (the diff
# images were written but the JSON came back empty). Reading the result from a file is
# reliable. See docs/SPIKE-argent.md.

set -uo pipefail
ARGENT_OUT="${TMPDIR:-/tmp}/rumor-ui-argent.out"
ARGENT_ERR="${TMPDIR:-/tmp}/rumor-ui-argent.err"
ARGENT() { npx -y @swmansion/argent@latest "$@" >"$ARGENT_OUT" 2>"$ARGENT_ERR"; }

UDID=""; OUTDIR="/tmp/rumor-ui-measure"; BASELINE=""; BUNDLE=""; ROUTE=""; LAUNCH=0; CURRENT=""
while [ $# -gt 0 ]; do
  case "$1" in
    --udid) UDID="$2"; shift 2;;
    --outdir) OUTDIR="$2"; shift 2;;
    --baseline) BASELINE="$2"; shift 2;;
    --bundle) BUNDLE="$2"; shift 2;;
    --route) ROUTE="$2"; shift 2;;
    --launch) LAUNCH=1; shift;;
    --current) CURRENT="$2"; shift 2;;
    *) echo "{\"error\":\"unknown_arg\",\"arg\":\"$1\"}"; exit 2;;
  esac
done
[ -n "$UDID" ] || { echo '{"error":"missing_udid"}'; exit 2; }
mkdir -p "$OUTDIR"
[ -n "$CURRENT" ] || CURRENT="$OUTDIR/current.png"

# A warm, persistent tool-server should already be running (the loop's preflight starts it:
#   nohup npx -y @swmansion/argent@latest server start --detach >/tmp/argent-server.log 2>&1 &
# `argent run` auto-starts one too. NOTE: `server start` is foreground by default — never
# call it inline here.

# Optional: bring the app to a deterministic state before capture. Settle after each
# navigation so the capture reflects the new screen, not the previous one (deep links and
# launches animate/transition asynchronously). Override with NAV_SETTLE_SECS.
NAV_SETTLE_SECS="${NAV_SETTLE_SECS:-3}"
if [ "$LAUNCH" = 1 ] && [ -n "$BUNDLE" ]; then
  ARGENT run launch-app --udid "$UDID" --bundleId "$BUNDLE"
  sleep "$NAV_SETTLE_SECS"
fi
if [ -n "$ROUTE" ]; then
  ARGENT run open-url --udid "$UDID" --url "$ROUTE"
  sleep "$NAV_SETTLE_SECS"
fi

# Capture with cold-start retry (Argent's first capture on a fresh tool-server can fail with
# "no image to export"; subsequent ones succeed — see docs/SPIKE-argent.md).
rm -f "$CURRENT"
cap_ok=0
for _ in 1 2 3 4; do
  ARGENT run screenshot --udid "$UDID" --downscaler lanczos3 --out "$CURRENT" --json
  if [ -s "$CURRENT" ]; then cap_ok=1; break; fi
  sleep 1
done
[ "$cap_ok" = 1 ] || { echo '{"error":"capture_failed"}'; exit 1; }

# No baseline → report the capture only (useful for /ui-verify or recording a flow).
if [ -z "$BASELINE" ]; then
  printf '{"mismatch_pct":null,"status":"captured","current":"%s"}\n' "$CURRENT"
  exit 0
fi
[ -s "$BASELINE" ] || { echo '{"error":"baseline_missing"}'; exit 1; }

# Settle, then diff with retry. Result is read from the file ARGENT() wrote, not $(...).
sleep 2
DIFF_OUT="$OUTDIR/diff-result.json"
: > "$DIFF_OUT"
diff_ok=0
for _ in 1 2 3 4; do
  ARGENT run screenshot-diff --udid "$UDID" --baselinePath "$BASELINE" \
    --currentPath "$CURRENT" --outputDir "$OUTDIR" --json
  cp -f "$ARGENT_OUT" "$DIFF_OUT" 2>/dev/null || true
  if grep -q '"summary"' "$DIFF_OUT" 2>/dev/null; then diff_ok=1; break; fi
  sleep 2
done

# Explicit failure: no attempt produced a parseable diff. Emit an error and a non-zero exit
# so callers never mistake a failed MEASURE for a valid (e.g. mismatch_pct=null) measurement.
if [ "$diff_ok" != 1 ]; then
  ERRTAIL="$(tail -c 300 "$ARGENT_ERR" 2>/dev/null | tr '\n' ' ')"
  printf '{"error":"diff_failed","stderr":"%s"}\n' "$(printf '%s' "$ERRTAIL" | sed 's/"/\\"/g')"
  exit 1
fi

python3 - "$CURRENT" "$DIFF_OUT" <<'PY'
import sys, json, re
cur, diff_out = sys.argv[1], sys.argv[2]
try:
    d = json.loads(open(diff_out).read())
    s = d.get("summary", "")
except Exception as e:
    print(json.dumps({"error": "diff_parse_failed", "detail": str(e)[:200]})); sys.exit(1)
if not s:
    print(json.dumps({"error": "diff_no_summary"})); sys.exit(1)
m  = re.search(r'pixel_mismatch:\s*([\d.]+)%', s)
st = re.search(r'status:\s*(\w+)', s)
if not m:
    print(json.dumps({"error": "diff_no_mismatch", "detail": s[:200]})); sys.exit(1)
print(json.dumps({
    "mismatch_pct": float(m.group(1)),
    "status": st.group(1) if st else None,
    "current": cur,
    "diffPath": d.get("diffPath"),
    "contextDiffPath": d.get("contextDiffPath"),
}))
PY
