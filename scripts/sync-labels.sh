#!/usr/bin/env bash
# Sync repository labels to .github/labels.json.
# Creates missing labels, updates changed ones, and deletes labels not in the file.
# Usage: scripts/sync-labels.sh [owner/repo]
set -euo pipefail

repo="${1:-${GITHUB_REPOSITORY:-SMC17/method-wagwan}}"
file="$(dirname "$0")/../.github/labels.json"

existing="$(gh api --paginate "repos/$repo/labels" --jq '.[].name')"

jq -c '.[]' "$file" | while read -r label; do
  name="$(jq -r .name <<<"$label")"
  color="$(jq -r .color <<<"$label")"
  desc="$(jq -r .description <<<"$label")"
  enc="$(jq -rn --arg s "$name" '$s|@uri')"
  if grep -Fxq "$name" <<<"$existing"; then
    gh api -X PATCH "repos/$repo/labels/$enc" -f color="$color" -f description="$desc" >/dev/null
    echo "updated  $name"
  else
    gh api -X POST "repos/$repo/labels" -f name="$name" -f color="$color" -f description="$desc" >/dev/null
    echo "created  $name"
  fi
done

wanted="$(jq -r '.[].name' "$file")"
while read -r name; do
  [ -z "$name" ] && continue
  if ! grep -Fxq "$name" <<<"$wanted"; then
    enc="$(jq -rn --arg s "$name" '$s|@uri')"
    gh api -X DELETE "repos/$repo/labels/$enc" >/dev/null
    echo "deleted  $name"
  fi
done <<<"$existing"
