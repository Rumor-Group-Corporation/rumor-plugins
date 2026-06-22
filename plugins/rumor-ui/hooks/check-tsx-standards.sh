#!/usr/bin/env bash
#
# rumor-ui standards guard (PostToolUse).
#
# Fast regex pre-check of just-edited TS/TSX files in the Rumor mobile (NativeWind) app
# against the hard, unambiguous rules in the rumor-mobile-standards skill. It is a SIGNAL,
# not the source of truth (yarn lint/typecheck is) — it catches the common violations the
# instant they're written so they're fixed at the source instead of in review.
#
# Exit 2 feeds stderr back to the model as a blocking signal. Any other failure exits 0 so
# the hook never gets in the way of unrelated work.

set -u

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

# Must be a TS/TSX source file (not a declaration file).
case "$file" in
  *.d.ts) exit 0 ;;
  *.tsx|*.ts) ;;
  *) exit 0 ;;
esac

# Resolve to an absolute path so relative tool paths work too.
case "$file" in
  /*) abs="$file" ;;
  *)  abs="$PWD/$file" ;;
esac

# Detect the NativeWind mobile app by walking UP for a tailwind.config that uses nativewind.
# This replaces a brittle hardcoded folder name (`rumor-mobile-expo/`): relative paths and
# renamed clones still resolve, and non-NativeWind code (the backend) is correctly skipped.
dir="$(dirname "$abs")"
is_mobile=false
while [ -n "$dir" ] && [ "$dir" != "/" ]; do
  for cfg in "$dir/tailwind.config.js" "$dir/tailwind.config.ts" "$dir/tailwind.config.cjs"; do
    if [ -f "$cfg" ] && grep -q nativewind "$cfg" 2>/dev/null; then is_mobile=true; break 2; fi
  done
  dir="$(dirname "$dir")"
done
[ "$is_mobile" = true ] || exit 0

is_test=false
case "$file" in
  *.test.ts|*.test.tsx|*/jest.setup.*|*/__mocks__/*) is_test=true ;;
esac

violations=""
add() { violations="${violations}\n  - $1"; }
# Return up to 3 matching lines. NOTE: callers must test the captured output ([ -n "$out" ]),
# never the exit status — `grep | head` can exit non-zero via SIGPIPE when there are >3
# matches, which would otherwise silently drop the violation on the worst-offending files.
hits() { grep -nE "$1" "$file" 2>/dev/null | head -3; }
indent() { printf '%s' "$1" | sed 's/^/      /'; }

# --- Hard rules (always enforced) ---

out="$(hits '@ts-(ignore|nocheck)')"
[ -n "$out" ] && add "TypeScript suppression (@ts-ignore/@ts-nocheck) is banned. Use @ts-expect-error with a reason only if unavoidable:\n$(indent "$out")"

# Explicit `any` in a type position: after : < , | & or `as`, followed by a non-identifier
# char or end-of-line. Catches `let v: any`, `Record<string, any>`, `x as any`, `<any>`,
# `any[]`; ignores `anything`, `company`, object keys like `{ any: 1 }`.
out="$(hits '(:|<|,|\||&|[[:space:]]as)[[:space:]]*any([^[:alnum:]_]|$)')"
[ -n "$out" ] && add "Explicit 'any' is banned. Use a precise type or 'unknown' with narrowing:\n$(indent "$out")"

# --- UI styling rules (skip for test/mock files, which legitimately stub things) ---
if [ "$is_test" = false ]; then
  out="$(hits 'StyleSheet\.create')"
  [ -n "$out" ] && add "StyleSheet.create is banned for UI styling — use NativeWind className:\n$(indent "$out")"

  out="$(hits "from[[:space:]]+[\"'\`]twrnc")"
  [ -n "$out" ] && add "twrnc was intentionally removed — use NativeWind className:\n$(indent "$out")"

  # Arbitrary Tailwind values with units/hex inside brackets (e.g. w-[12px], bg-[#fff]).
  out="$(hits '\[[0-9.]+(px|rem|em|vh|vw)\]|\[#[0-9a-fA-F]{3,8}\]')"
  [ -n "$out" ] && add "Arbitrary Tailwind value — use the scale or add a reusable token in tailwind.config.js:\n$(indent "$out")"

  # Closed-vocabulary backstop: a quoted hex color literal or rgb()/rgba() in source. Requiring
  # a quote before the hex avoids false positives on JS private fields (this.#bad) and hashtag
  # substrings — RN color literals are always strings. Full per-class validation is the
  # generator's job; this catches the high-precision escape a regex can own.
  color_pat="[\"'\`]#[0-9a-fA-F]{3,8}|rgba?\\("
  out="$(hits "$color_pat")"
  [ -n "$out" ] && add "Hardcoded color literal — never inline hex/rgb; use a token (tailwind.config.js / token-map.json), per rumor-strict-design-system:\n$(indent "$out")"
fi

if [ -n "$violations" ]; then
  printf 'rumor-ui standards check flagged %s:%b\n\nFix these at the source (see the rumor-mobile-standards skill). These are hard repo rules; do not suppress them.\n' "$file" "$violations" >&2
  exit 2
fi

exit 0
