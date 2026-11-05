#!/usr/bin/env bash
# Create the GitHub Project board, its fields, and add every open issue with Priority and Phase set.
# Projects v2 needs GraphQL, so run this with a maintainer's own login that has the project scope:
#   gh auth refresh -s project
#   scripts/create-project.sh [owner] [repo]
# Tracked in issue #9. Views and the auto-add workflow are configured in the web UI afterward,
# as described in docs/github-workflow.md.
set -euo pipefail

owner="${1:-SMC17}"
repo="${2:-method-wagwan}"
title="method-wagwan"

num="$(gh project list --owner "$owner" --format json --jq ".projects[] | select(.title==\"$title\") | .number" | head -1)"
if [ -z "$num" ]; then
  num="$(gh project create --owner "$owner" --title "$title" --format json --jq .number)"
  echo "created project #$num"
else
  echo "using existing project #$num"
fi
gh project link "$num" --owner "$owner" --repo "$owner/$repo" >/dev/null 2>&1 || true
pid="$(gh project view "$num" --owner "$owner" --format json --jq .id)"

field() { # name, options csv
  if ! gh project field-list "$num" --owner "$owner" --format json --jq '.fields[].name' | grep -Fxq "$1"; then
    gh project field-create "$num" --owner "$owner" --name "$1" --data-type SINGLE_SELECT --single-select-options "$2" >/dev/null
    echo "created field $1"
  fi
}
field "Priority" "P0,P1,P2"
field "Phase" "M0,P1,P2,P3,P4,Down-range"
field "Area" "core,protocol,adapter-zig,adapter-cpp,oracle,primitives,trace,eval,fork,determinism,community,github"
field "Size" "XS,S,M,L,XL"
if ! gh project field-list "$num" --owner "$owner" --format json --jq '.fields[].name' | grep -Fxq "Target date"; then
  gh project field-create "$num" --owner "$owner" --name "Target date" --data-type DATE >/dev/null
fi

fields="$(gh project field-list "$num" --owner "$owner" --format json)"
fid()  { jq -r --arg f "$1" '.fields[] | select(.name==$f) | .id' <<<"$fields"; }
oid()  { jq -r --arg f "$1" --arg o "$2" '.fields[] | select(.name==$f) | .options[] | select(.name==$o) | .id' <<<"$fields"; }
set_opt() { # item, field, option
  local f o; f="$(fid "$2")"; o="$(oid "$2" "$3")"
  [ -n "$f" ] && [ -n "$o" ] && gh project item-edit --id "$1" --project-id "$pid" --field-id "$f" --single-select-option-id "$o" >/dev/null
}

phase_of() {
  case "$1" in
    "M0:"*) echo M0 ;; "Phase 1:"*) echo P1 ;; "Phase 2:"*) echo P2 ;;
    "Phase 3:"*) echo P3 ;; "Phase 4:"*) echo P4 ;; "Down-range"*) echo Down-range ;;
  esac
}

gh issue list --repo "$owner/$repo" --state open --limit 500 --json url,labels,milestone |
  jq -c '.[]' | while read -r it; do
    url="$(jq -r .url <<<"$it")"
    item="$(gh project item-add "$num" --owner "$owner" --url "$url" --format json --jq .id)"
    prio="$(jq -r '[.labels[].name | select(startswith("priority: "))][0] // empty | sub("priority: ";"")' <<<"$it")"
    [ -n "$prio" ] && set_opt "$item" Priority "$prio"
    phase="$(phase_of "$(jq -r '.milestone.title // ""' <<<"$it")")"
    [ -n "$phase" ] && set_opt "$item" Phase "$phase"
    echo "added $url"
  done

echo "Project #$num is ready. Configure views and the auto-add workflow as described in docs/github-workflow.md."
