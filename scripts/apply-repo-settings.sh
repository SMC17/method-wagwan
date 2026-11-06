#!/usr/bin/env bash
# Apply repository settings, the main-branch ruleset, and security features.
# Run once with a maintainer's own gh login: scripts/apply-repo-settings.sh [owner/repo]
# Every step reports its own result, so a setting the account plan does not allow
# is printed and skipped rather than stopping the script. Tracked in issue #8.
set -uo pipefail

repo="${1:-SMC17/method-wagwan}"
ok()   { printf '  ok    %s\n' "$1"; }
skip() { printf '  SKIP  %s (%s)\n' "$1" "$2"; }
run()  { local label="$1"; shift; local out; if out="$("$@" 2>&1)"; then ok "$label"; else skip "$label" "$(tr '\n' ' ' <<<"$out" | cut -c1-160)"; fi; }

echo "Repository settings for $repo"
run "merge, branch, and feature settings" gh api -X PATCH "repos/$repo" \
  -f description="Walk-forward replay engine for code: models propose, deterministic programs decide. Built in Zig, with verified language forks." \
  -f homepage="https://claude.ai/artifact/WhdbtrnFdx9eQwud6X2yR6" \
  -F has_issues=true -F has_discussions=true -F has_wiki=false -F has_projects=true \
  -F allow_squash_merge=true -F allow_merge_commit=false -F allow_rebase_merge=false \
  -F delete_branch_on_merge=true -F allow_auto_merge=true -F allow_update_branch=true \
  -F web_commit_signoff_required=false \
  -f squash_merge_commit_title=PR_TITLE -f squash_merge_commit_message=PR_BODY

run "topics" gh api -X PUT "repos/$repo/topics" \
  -f 'names[]=zig' -f 'names[]=compiler' -f 'names[]=backtesting' -f 'names[]=llm' \
  -f 'names[]=git' -f 'names[]=fuzzing' -f 'names[]=reproducibility' -f 'names[]=software-engineering'

echo "Security"
run "Dependabot alerts"             gh api -X PUT "repos/$repo/vulnerability-alerts"
run "Dependabot security updates"   gh api -X PUT "repos/$repo/automated-security-fixes"
run "private vulnerability reporting" gh api -X PUT "repos/$repo/private-vulnerability-reporting"
run "secret scanning and push protection" gh api -X PATCH "repos/$repo" --input - <<'JSON'
{"security_and_analysis": {
  "secret_scanning": {"status": "enabled"},
  "secret_scanning_push_protection": {"status": "enabled"}
}}
JSON

echo "Ruleset for the default branch"
existing="$(gh api "repos/$repo/rulesets" --jq '.[] | select(.name=="main protection") | .id' 2>/dev/null || true)"
ruleset="$(cat <<'JSON'
{
  "name": "main protection",
  "target": "branch",
  "enforcement": "active",
  "conditions": { "ref_name": { "include": ["~DEFAULT_BRANCH"], "exclude": [] } },
  "bypass_actors": [
    { "actor_id": 5, "actor_type": "RepositoryRole", "bypass_mode": "pull_request" }
  ],
  "rules": [
    { "type": "deletion" },
    { "type": "non_fast_forward" },
    { "type": "required_linear_history" },
    { "type": "pull_request", "parameters": {
        "required_approving_review_count": 0,
        "dismiss_stale_reviews_on_push": true,
        "require_code_owner_review": false,
        "require_last_push_approval": false,
        "required_review_thread_resolution": true
    } },
    { "type": "required_status_checks", "parameters": {
        "strict_required_status_checks_policy": true,
        "required_status_checks": [
          { "context": "Markdown lint" },
          { "context": "Link check" },
          { "context": "Workflow lint" },
          { "context": "PR title" }
        ]
    } }
  ]
}
JSON
)"
if [ -n "$existing" ]; then
  run "update ruleset $existing" gh api -X PUT "repos/$repo/rulesets/$existing" --input - <<<"$ruleset"
else
  run "create ruleset" gh api -X POST "repos/$repo/rulesets" --input - <<<"$ruleset"
fi

echo "Done. Post any SKIP lines as a comment on issue #8."
