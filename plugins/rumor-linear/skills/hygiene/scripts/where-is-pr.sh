#!/usr/bin/env bash
# where-is-pr.sh — where is this PR's code actually live?
#
# Usage: where-is-pr.sh <github-pr-url> [<github-pr-url> ...]
#
# Prints one JSON object per PR:
#   {"pr":"grapevine#451","state":"MERGED","merged_at":"…","merge_sha":"…",
#    "surfaces":["web"],"uat":"yes|no|n/a|unknown","prod":"yes|no|n/a|unknown",
#    "evidence":"…","caveats":["…"],
#    "open":{"draft":false,"review":"APPROVED|CHANGES_REQUESTED|REVIEW_REQUIRED|NONE",
#            "checks_failing":0,"opened_at":"…"}}   (open is null unless state=OPEN)
#
# "yes" means the PR's merge commit is an ancestor of the commit currently
# deployed to that environment. "unknown" means there is no trustworthy signal —
# the caller must NOT move a ticket on "unknown". Deploy heads are fetched once
# per run and cached, so passing many PRs in one call is cheap.
#
# Requires: gh (authenticated with access to Rumor-Group-Corporation), jq.
# Speed: ~4s per PR serially; many PRs run 8 in parallel (WHERE_IS_PR_PARALLEL).
set -uo pipefail

ORG="Rumor-Group-Corporation"
CACHE="$(mktemp -d)"
trap 'rm -rf "$CACHE"' EXIT

die() { echo "{\"error\":$(jq -Rn --arg m "$1" '$m')}"; exit 1; }
command -v gh >/dev/null || die "gh CLI not installed"
command -v jq >/dev/null || die "jq not installed"

# --- deploy heads (cached per run) ------------------------------------------

# Latest SUCCESSFUL GitHub deployment sha for an environment name.
deploy_sha() { # repo env
  local key; key="$CACHE/dep_$(printf '%s_%s' "$1" "$2" | tr -c 'a-zA-Z0-9' '_')"
  if [[ ! -f "$key" ]]; then
    local sha=""
    while read -r id dsha; do
      [[ -z "$id" ]] && continue
      state="$(gh api "repos/$ORG/$1/deployments/$id/statuses?per_page=1" --jq '.[0].state' 2>/dev/null)"
      if [[ "$state" == "success" ]]; then sha="$dsha"; break; fi
    done < <(gh api -X GET "repos/$ORG/$1/deployments" -f environment="$2" -f per_page=10 \
               --jq '.[]|"\(.id) \(.sha)"' 2>/dev/null)
    echo "$sha" > "$key"
  fi
  cat "$key"
}

# Backend UAT: the delivered-main tag (moved only after all changed services are live on ECS).
backend_uat_sha() {
  local key="$CACHE/be_uat"
  [[ -f "$key" ]] || gh api "repos/$ORG/rumor-backend-services/git/ref/tags/delivered-main" \
    --jq '.object.sha' 2>/dev/null > "$key"
  cat "$key"
}

# Backend prod: newest release/prod-* GitHub Release by PUBLISHED date, resolved to its commit.
# (Tag dates lie for lightweight tags; never sort by them.)
backend_prod_sha() {
  local key="$CACHE/be_prod"
  if [[ ! -f "$key" ]]; then
    local tag
    tag="$(gh api "repos/$ORG/rumor-backend-services/releases?per_page=20" \
      --jq '[.[]|select(.tag_name|startswith("release/prod-"))|select(.draft|not)]|sort_by(.published_at)|last|.tag_name' 2>/dev/null)"
    if [[ -n "$tag" && "$tag" != "null" ]]; then
      gh api "repos/$ORG/rumor-backend-services/commits/$tag" --jq '.sha' 2>/dev/null > "$key"
      echo "$tag" > "$CACHE/be_prod_tag"
    else
      : > "$key"
    fi
  fi
  cat "$key"
}

# Mobile prod (JS lane): head_sha of the newest successful production-ota.yml run.
mobile_ota_sha() {
  local key="$CACHE/mobile_ota"
  [[ -f "$key" ]] || gh api "repos/$ORG/rumor-mobile-expo/actions/workflows/production-ota.yml/runs?status=success&per_page=1" \
    --jq '.workflow_runs[0].head_sha // ""' 2>/dev/null > "$key"
  cat "$key"
}

# Files that never ship to users: CI, docs, agent notes, dev tooling, tests.
NONSHIP_RE='(^\.github/|^docs/|\.md$|^AGENTS|^CLAUDE|^tools/|^\.husky/|/e2e/|^e2e/|\.spec\.tsx?$|\.test\.tsx?$|/__tests__/|^test/|playwright|^\.maestro/|^maestro/)'
nonship_only() { [[ -n "$1" ]] && ! grep -qvE "$NONSHIP_RE" <<<"$1"; }

# Is commit $2 contained in deploy head $3? Prints yes/no/unknown.
contains() { # repo merge_sha deploy_sha
  [[ -z "$3" ]] && { echo unknown; return; }
  [[ "$2" == "$3" ]] && { echo yes; return; }
  local st
  st="$(gh api "repos/$ORG/$1/compare/$2...$3" --jq '.status' 2>/dev/null)"
  case "$st" in
    ahead|identical) echo yes ;;
    behind|diverged) echo no ;;
    *) echo unknown ;;
  esac
}

# --- per PR --------------------------------------------------------------------

check_pr() {
  local url="$1" repo num
  if [[ "$url" =~ github\.com/$ORG/([^/]+)/pull/([0-9]+) ]]; then
    repo="${BASH_REMATCH[1]}"; num="${BASH_REMATCH[2]}"
  else
    jq -nc --arg u "$url" '{pr:$u, error:"not a Rumor-Group-Corporation PR url"}'; return
  fi

  local pr
  pr="$(gh api "repos/$ORG/$repo/pulls/$num" \
        --jq '{state, merged:(.merged_at!=null), merged_at, merge_sha:.merge_commit_sha, title, base:.base.ref, head:.head.ref, author:.user.login, updated_at}' 2>/dev/null)"
  [[ -z "$pr" ]] && { jq -nc --arg p "$repo#$num" '{pr:$p, error:"cannot read PR (access? deleted?)"}'; return; }

  local merged state merge_sha base title
  merged="$(jq -r .merged <<<"$pr")"; merge_sha="$(jq -r .merge_sha <<<"$pr")"
  base="$(jq -r .base <<<"$pr")"; title="$(jq -r .title <<<"$pr")"
  if [[ "$merged" == "true" ]]; then state=MERGED
  elif [[ "$(jq -r .state <<<"$pr")" == "open" ]]; then state=OPEN
  else state=CLOSED; fi

  local uat=n/a prod=n/a evidence="" surfaces="[]"
  local -a caveats=()

  local open_info='null'
  if [[ "$state" == "OPEN" ]]; then
    open_info="$(gh pr view "$num" -R "$ORG/$repo" --json isDraft,reviewDecision,statusCheckRollup,createdAt \
      --jq '{draft:.isDraft, review:(if (.reviewDecision // "") == "" then "NONE" else .reviewDecision end), opened_at:.createdAt,
             checks_failing:([.statusCheckRollup[]? | select((.conclusion // .state) as $c | ["FAILURE","ERROR","TIMED_OUT","CANCELLED"] | index($c))] | length)}' 2>/dev/null)"
    [[ -z "$open_info" ]] && open_info='null'
  fi

  if [[ "$state" != "MERGED" ]]; then
    evidence="PR is $state"
    [[ "$repo" == web-2.0 && "$state" == OPEN ]] && \
      caveats+=("open PR in FROZEN web-2.0: it will never merge — not a required PR; ask whether to close it (and whether a grapevine port exists)")
  elif [[ "$base" != "main" && "$base" != "master" ]] && \
       [[ ! "$(gh api "repos/$ORG/$repo/compare/$merge_sha...main" --jq .status 2>/dev/null)" =~ ^(ahead|identical)$ ]]; then
    uat=unknown; prod=unknown
    evidence="merged into '$base', and that commit is not on main"
    caveats+=("merged into a side branch ('$base') that never reached main: check the PR it was stacked on, or whether '$base' was merged")
  else
    [[ "$base" != "main" && "$base" != "master" ]] && \
      caveats+=("merged into '$base', which later reached main — read against main's deploys")
    local files
    files="$(gh api "repos/$ORG/$repo/pulls/$num/files?per_page=100" --paginate --jq '.[].filename' 2>/dev/null)"
    local nonship=0; nonship_only "$files" && nonship=1
    case "$repo" in
      rumor-backend-services)
        surfaces='["backend"]'
        local u p
        u="$(backend_uat_sha)"; p="$(backend_prod_sha)"
        uat="$(contains "$repo" "$merge_sha" "$u")"
        prod="$(contains "$repo" "$merge_sha" "$p")"
        evidence="UAT=delivered-main@${u:0:7}; prod=$(cat "$CACHE/be_prod_tag" 2>/dev/null)@${p:0:7}"
        if [[ $nonship == 1 ]]; then
          surfaces='["none"]'; uat=n/a; prod=n/a
          caveats+=("docs/CI/test-only change: Deliver skips it, nothing deploys — not a required PR")
        fi
        if grep -q '^apps/lambda/' <<<"$files"; then
          caveats+=("touches apps/lambda: lambdas are NOT shipped by the prod promote — prod=yes covers ECS services only; confirm the lambda was deployed to prod by hand")
          [[ "$prod" == "yes" ]] && prod=unknown
        fi
        if grep -q 'migrations/' <<<"$files"; then
          caveats+=("adds a migration: prod schema moves only with a Deliver promote")
        fi
        ;;
      grapevine)
        local web=0 studio=0 agent=0 shared=0
        grep -q '^apps/web/' <<<"$files" && web=1
        grep -q '^apps/studio/' <<<"$files" && studio=1
        grep -q '^apps/host-agent' <<<"$files" && agent=1
        grep -qE '^(packages/|package\.json|pnpm-lock|turbo\.json)' <<<"$files" && shared=1
        # e2e / test-only changes inside an app don't ship anything
        if [[ $nonship == 1 ]]; then
          web=0; studio=0; agent=0; shared=0
        fi
        [[ $shared == 1 && $web == 0 && $studio == 0 ]] && { web=1; studio=1; }
        local -a sf=() us=() ps=()
        if [[ $web == 1 ]]; then
          sf+=(web)
          us+=("$(contains "$repo" "$merge_sha" "$(deploy_sha grapevine 'uat – rumor-web')")")
          ps+=("$(contains "$repo" "$merge_sha" "$(deploy_sha grapevine 'Production – rumor-web')")")
        fi
        if [[ $studio == 1 ]]; then
          sf+=(studio)
          us+=("$(contains "$repo" "$merge_sha" "$(deploy_sha grapevine 'uat – rumor-studio')")")
          ps+=("$(contains "$repo" "$merge_sha" "$(deploy_sha grapevine 'Production – rumor-studio')")")
        fi
        if [[ ${#sf[@]} -eq 0 ]]; then
          surfaces='["none"]'; uat=n/a; prod=n/a
          evidence="no apps/web or apps/studio files — nothing deploys"
          [[ $agent == 1 ]] && caveats+=("host-agent only: no prod deploy oracle — confirm by hand")
        else
          surfaces="$(printf '%s\n' "${sf[@]}" | jq -R . | jq -sc .)"
          # a ticket is live only when EVERY surface it touched is live
          worst() { local r=yes; for v in "$@"; do
              [[ "$v" == no ]] && { echo no; return; }
              [[ "$v" == unknown ]] && r=unknown; done; echo "$r"; }
          uat="$(worst "${us[@]}")"; prod="$(worst "${ps[@]}")"
          evidence="GitHub deployments (Vercel) per app: ${sf[*]}"
          caveats+=("web prod promotes are CLI redeploys and GitHub can miss one; if prod=no but the change is visibly live on therumor.com, trust 'vercel inspect therumor.com --scope therumor'")
        fi
        ;;
      rumor-mobile-expo)
        surfaces='["mobile"]'
        uat=yes   # staging OTA publishes on every push to main
        if [[ $nonship == 1 ]]; then
          surfaces='["none"]'; uat=n/a; prod=n/a
          evidence="CI/docs/test-only: ships nothing to devices"
        elif grep -qE '^(ios/|android/|plugins/|patches/|app\.config\.(ts|js)$|app\.json$|eas\.json$|package\.json$|package-lock\.json$|yarn\.lock$)' <<<"$files"; then
          prod=unknown
          evidence="NATIVE change: only live when the App Store build containing it is READY_FOR_SALE"
          caveats+=("native lane: confirm the App Store version (App Store Connect) before moving to In Production")
        else
          local o; o="$(mobile_ota_sha)"
          prod="$(contains "$repo" "$merge_sha" "$o")"
          evidence="JS-only: UAT=staging OTA on merge; prod=production-ota@${o:0:7}"
        fi
        ;;
      rumor-web-next)
        surfaces='["admin-legacy"]'
        [[ $nonship == 1 ]] && surfaces='["none"]'
        uat="$(contains "$repo" "$merge_sha" "$(deploy_sha rumor-web-next uat)")"
        prod="$(contains "$repo" "$merge_sha" "$(deploy_sha rumor-web-next Production)")"
        evidence="GitHub deployments uat / Production"
        ;;
      web-2.0)
        # grapevine imported web-2.0's history, so a web-2.0 merge commit that is an
        # ancestor of grapevine's web deploy IS live on therumor.com. Check that
        # first; fall back to web-2.0's own (frozen) deployments.
        surfaces='["web"]'
        local gu gp
        gu="$(contains grapevine "$merge_sha" "$(deploy_sha grapevine 'uat – rumor-web')")"
        gp="$(contains grapevine "$merge_sha" "$(deploy_sha grapevine 'Production – rumor-web')")"
        if [[ "$gp" == yes || "$gu" == yes ]]; then
          uat="$gu"; prod="$gp"
          [[ "$prod" == yes ]] && uat=yes
          evidence="web-2.0 commit carried into grapevine history; read against grapevine web deploys"
        else
          # web-2.0's own deployments describe the OLD therumor.com; never report them as live
          uat=unknown; prod=no
          evidence="web-2.0 is FROZEN (grapevine is the web source since 2026-09-24) and this commit is not in grapevine's deployed history"
          caveats+=("web-2.0 frozen and not carried into grapevine: it may never ship unless ported")
        fi
        ;;
      rumor-infra)
        # Terraform: merging does not apply it. Someone runs the apply per env.
        surfaces='["infra"]'; uat=unknown; prod=unknown
        evidence="terraform: merged ≠ applied"
        caveats+=("confirm 'terraform apply' ran in UAT and prod for this change")
        ;;
      *)
        # No deploy oracle. Merged to main counts for In UAT (the same rule Linear's
        # own GitHub automation applies on merge); never for production.
        surfaces='["unknown"]'; uat=yes; prod=unknown
        evidence="no deploy oracle for $repo — merged to main counts as In UAT only"
        caveats+=("no deploy signal for this repo: confirm with the owner before moving past In UAT")
        ;;
    esac
    if [[ "$surfaces" == '["none"]' ]]; then uat=n/a; prod=n/a; evidence="CI/docs/tooling/test-only — ships nothing"; fi
  fi

  jq -nc --arg pr "$repo#$num" --arg url "$url" --arg state "$state" --argjson meta "$pr" \
     --argjson surfaces "$surfaces" --arg uat "$uat" --arg prod "$prod" --arg evidence "$evidence" \
     --arg title "$title" --argjson open "$open_info" \
     --argjson caveats "$(printf '%s\n' "${caveats[@]+"${caveats[@]}"}" | jq -R . | jq -sc 'map(select(length>0))')" \
     '{pr:$pr, url:$url, title:$title, state:$state, author:$meta.author, merged_at:$meta.merged_at,
       merge_sha:$meta.merge_sha, base:$meta.base, surfaces:$surfaces, uat:$uat, prod:$prod,
       evidence:$evidence, caveats:$caveats, open:$open}'
}

[[ $# -eq 0 ]] && die "usage: where-is-pr.sh <pr-url> [<pr-url> ...]"

# One PR: run inline. Many: warm every deploy head once (so parallel workers only
# read the cache), then check PRs 8 at a time. Output order follows input order.
if [[ $# -eq 1 ]]; then check_pr "$1"; exit 0; fi

backend_uat_sha >/dev/null; backend_prod_sha >/dev/null; mobile_ota_sha >/dev/null
for env in 'uat – rumor-web' 'Production – rumor-web' 'uat – rumor-studio' 'Production – rumor-studio'; do
  deploy_sha grapevine "$env" >/dev/null
done
deploy_sha rumor-web-next uat >/dev/null; deploy_sha rumor-web-next Production >/dev/null
deploy_sha web-2.0 uat >/dev/null; deploy_sha web-2.0 'Production – rumor-web' >/dev/null

PAR="${WHERE_IS_PR_PARALLEL:-8}"
i=0
for u in "$@"; do
  i=$((i+1))
  check_pr "$u" > "$CACHE/out_$(printf '%05d' "$i")" &
  (( i % PAR == 0 )) && wait
done
wait
cat "$CACHE"/out_*
