#!/usr/bin/env bash
#
# rumor-ui standards guard (PostToolUse).
#
# Fast regex pre-check of just-edited TS/TSX files in the Rumor mobile app against the
# hard, unambiguous rules in the rumor-mobile-standards skill. It is a SIGNAL, not the
# source of truth (yarn lint/typecheck is) — it catches the common violations the instant
# they're written so they're fixed at the source instead of in review.
#
# Exit 2 feeds stderr back to the model as a blocking signal. Any other failure exits 0 so
# the hook never gets in the way of unrelated work.

set -uo pipefail

input="$(cat 2>/dev/null)" || exit 0

# Extract the edited file path from the tool input (jq if present, else python3, else bail).
file=""
if command -v jq >/dev/null 2>&1; then
  file="$(printf '%s' "$input" | jq -r '.tool_input.file_path // .tool_input.path // empty' 2>/dev/null)"
elif command -v python3 >/dev/null 2>&1; then
  file="$(printf '%s' "$input" | python3 -c 'import sys,json;
try:
    d=json.load(sys.stdin); ti=d.get("tool_input",{}); print(ti.get("file_path") or ti.get("path") or "")
except Exception:
    print("")' 2>/dev/null)"
fi

[ -n "$file" ] || exit 0
[ -f "$file" ] || exit 0

# Only police UI source in the mobile app. Skip anything else (backend, configs, docs).
case "$file" in
  *.tsx|*.ts) ;;
  *) exit 0 ;;
esac
case "$file" in
  *rumor-mobile-expo/*) ;;
  *) exit 0 ;;
esac
# Don't flag declaration files.
case "$file" in
  *.d.ts) exit 0 ;;
esac

is_test=false
case "$file" in
  *.test.ts|*.test.tsx|*/jest.setup.*|*/__mocks__/*) is_test=true ;;
esac

violations=""
add() { violations="${violations}\n  - $1"; }
hits() { grep -nE "$1" "$file" 2>/dev/null | head -3; }

# --- Hard rules (always enforced) ---

if out="$(hits '@ts-(ignore|nocheck)')"; then
  [ -n "$out" ] && add "TypeScript suppression (@ts-ignore/@ts-nocheck) is banned. Use @ts-expect-error with a reason only if unavoidable:\n$(printf '%s' "$out" | sed 's/^/      /')"
fi

if out="$(hits '(:[[:space:]]*any([[:space:]]|;|,|\)|>|\[)|as[[:space:]]+any|<any>|Array<any>)')"; then
  [ -n "$out" ] && add "Explicit 'any' is banned. Use a precise type or 'unknown' with narrowing:\n$(printf '%s' "$out" | sed 's/^/      /')"
fi

# --- UI styling rules (skip for test/mock files, which legitimately stub things) ---
if [ "$is_test" = false ]; then
  if out="$(hits 'StyleSheet\.create')"; then
    [ -n "$out" ] && add "StyleSheet.create is banned for UI styling — use NativeWind className:\n$(printf '%s' "$out" | sed 's/^/      /')"
  fi
  if out="$(hits \"from[[:space:]]+['\\\"]twrnc['\\\"]\")"; then
    [ -n "$out" ] && add "twrnc was intentionally removed — use NativeWind className:\n$(printf '%s' "$out" | sed 's/^/      /')"
  fi
  # Arbitrary Tailwind values with units/hex inside brackets (e.g. w-[12px], bg-[#fff]).
  if out="$(hits '\[[0-9.]+(px|rem|em|vh|vw)\]|\[#[0-9a-fA-F]{3,8}\]')"; then
    [ -n "$out" ] && add "Arbitrary Tailwind value — use the scale or add a reusable token in tailwind.config.js:\n$(printf '%s' "$out" | sed 's/^/      /')"
  fi
fi

if [ -n "$violations" ]; then
  printf 'rumor-ui standards check flagged %s:%b\n\nFix these at the source (see the rumor-mobile-standards skill). These are hard repo rules; do not suppress them.\n' "$file" "$violations" >&2
  exit 2
fi

exit 0
