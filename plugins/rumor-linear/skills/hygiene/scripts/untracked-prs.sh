#!/usr/bin/env bash
# untracked-prs.sh — PRs with no Linear ticket key in the title or branch.
#
# Usage: untracked-prs.sh [days=7] [author]
#
# Prints one JSON object per PR opened or merged in the last N days across the
# main Rumor repos whose title AND branch carry no `ABC-123` key. Dependabot,
# release and chore/ci PRs are listed with "routine":true so the caller can
# summarise them in one line instead of chasing anyone.
#
# A PR can still be linked by hand in Linear with no key anywhere — the caller
# must check the PR url against Linear attachments before calling it untracked.
set -uo pipefail

DAYS="${1:-7}"; AUTHOR="${2:-}"
ORG="Rumor-Group-Corporation"
REPOS=(grapevine rumor-backend-services rumor-mobile-expo rumor-web-next rumor-data-platform rumor-infra)
SINCE="$(date -u -v-"${DAYS}"d +%Y-%m-%d 2>/dev/null || date -u -d "-${DAYS} days" +%Y-%m-%d)"
# Real Linear team keys only — a loose [a-z]+-[0-9]+ matches utf-8, prod-8f4c, fix-2.
KEY_RE='(^|[^A-Za-z])(RUM|SERVE|SUP|DEM|PLAT|DX)-[0-9]+'

for r in "${REPOS[@]}"; do
  q="updated:>=$SINCE"
  [[ -n "$AUTHOR" ]] && q="$q author:$AUTHOR"
  gh pr list -R "$ORG/$r" --state all --search "$q" --limit 300 \
    --json number,title,url,author,state,headRefName,mergedAt \
    --jq '.[] | {number, title, url, author:.author.login, state, merged:(.mergedAt!=null), branch:.headRefName}' 2>/dev/null |
  while read -r row; do
    title="$(jq -r .title <<<"$row")"; branch="$(jq -r .branch <<<"$row")"
    shopt -s nocasematch
    if [[ "$title" =~ $KEY_RE || "$branch" =~ $KEY_RE ]]; then shopt -u nocasematch; continue; fi
    shopt -u nocasematch
    routine=false
    shopt -s nocasematch
    [[ "$title" =~ ^(chore|ci|build|deps|bump|release|revert|\[skip)|dependabot|renovate ]] && routine=true
    [[ "$(jq -r .author <<<"$row")" =~ bot ]] && routine=true
    shopt -u nocasematch
    jq -c --arg repo "$r" --argjson routine "$routine" '. + {repo:$repo, routine:$routine}' <<<"$row"
  done
done
