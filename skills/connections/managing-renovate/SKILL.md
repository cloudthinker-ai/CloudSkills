---
name: managing-renovate
description: |
  Renovate dependency update bot management covering configuration analysis, update PR tracking, dependency dashboard monitoring, package rule auditing, merge confidence review, and schedule optimization. Use when auditing Renovate configurations, investigating stale dependency PRs, reviewing auto-merge policies, or optimizing update grouping strategies.
connection_type: github
preload: false
---

# Renovate Management Skill

Analyze and monitor Renovate dependency update configurations, PRs, and dashboard status.

## MANDATORY: Discovery-First Pattern

**Always locate Renovate configuration and check the dependency dashboard before analyzing PRs.**

### Phase 1: Discovery

```bash
#!/bin/bash

GH_API="https://api.github.com"

gh_api() {
    curl -s -H "Authorization: Bearer $GITHUB_TOKEN" \
         -H "Accept: application/vnd.github+json" \
         "${GH_API}/${1}"
}

echo "=== Locate Renovate Config ==="
gh_api "orgs/${GITHUB_ORG}/repos?per_page=20&sort=updated" | jq -r '.[].full_name' | while read repo; do
    for cfg in "renovate.json" "renovate.json5" ".renovaterc" ".renovaterc.json" ".github/renovate.json" ".github/renovate.json5"; do
        if gh_api "repos/${repo}/contents/${cfg}" 2>/dev/null | jq -e '.name' >/dev/null 2>&1; then
            echo -e "${repo}\t${cfg}\tFOUND"
            break
        fi
    done
done | column -t | head -20

echo ""
echo "=== Dependency Dashboard Issues ==="
gh_api "orgs/${GITHUB_ORG}/repos?per_page=10&sort=updated" | jq -r '.[].full_name' | while read repo; do
    gh_api "repos/${repo}/issues?labels=dependencies&state=open&per_page=1&creator=renovate[bot]" | jq -r --arg repo "$repo" '
        .[]? |
        "\($repo)\t#\(.number)\t\(.title[:50])\t\(.updated_at[:10])"
    '
done | column -t | head -15

echo ""
echo "=== Open Renovate PRs ==="
gh_api "orgs/${GITHUB_ORG}/repos?per_page=10&sort=updated" | jq -r '.[].full_name' | while read repo; do
    gh_api "repos/${repo}/pulls?state=open&per_page=10" | jq -r --arg repo "$repo" '
        .[] | select(.user.login == "renovate[bot]") |
        "\($repo)\t#\(.number)\t\(.title[:50])\t\(.created_at[:10])"
    '
done | column -t | head -20
```

### Phase 2: Analysis

```bash
#!/bin/bash

REPO="${1:-${GITHUB_ORG}/${GITHUB_REPO}}"

echo "=== Renovate Config Analysis ==="
for cfg in "renovate.json" "renovate.json5" ".renovaterc" ".renovaterc.json" ".github/renovate.json"; do
    CONTENT=$(gh_api "repos/${REPO}/contents/${cfg}" 2>/dev/null)
    if echo "$CONTENT" | jq -e '.name' >/dev/null 2>&1; then
        echo "$CONTENT" | jq -r '.content' | base64 -d 2>/dev/null | jq '{
            extends: .extends,
            schedule: .schedule,
            automerge: .automerge,
            packageRules_count: (.packageRules | length // 0),
            labels: .labels,
            prConcurrentLimit: .prConcurrentLimit,
            rangeStrategy: .rangeStrategy
        }' 2>/dev/null
        break
    fi
done

echo ""
echo "=== Stale Renovate PRs (>14 days) ==="
gh_api "repos/${REPO}/pulls?state=open&per_page=30" | jq -r '
    .[] |
    select(.user.login == "renovate[bot]") |
    select((.created_at[:10] | strptime("%Y-%m-%d") | mktime) < (now - 1209600)) |
    "#\(.number)\t\(.title[:50])\t\(.created_at[:10])\tSTALE"
' | column -t

echo ""
echo "=== Recently Merged Renovate PRs ==="
gh_api "repos/${REPO}/pulls?state=closed&per_page=20&sort=updated&direction=desc" | jq -r '
    .[] |
    select(.user.login == "renovate[bot]" and .merged_at != null) |
    "#\(.number)\t\(.title[:50])\t\(.merged_at[:10])"
' | head -10

echo ""
echo "=== PR Status Summary ==="
OPEN=$(gh_api "repos/${REPO}/pulls?state=open&per_page=100" | jq '[.[] | select(.user.login == "renovate[bot]")] | length')
echo "Open Renovate PRs: ${OPEN}"
```

## Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- Summarize package rules rather than dumping full config
- Focus on stale PRs and configuration issues

## Common Pitfalls

- **Config precedence**: Repository config extends presets -- check full resolved config via Renovate logs
- **Schedule mismatch**: Renovate schedule uses cron-like syntax -- verify timezone settings
- **Automerge requirements**: Automerge requires passing CI and branch protection rules
- **PR limits**: prConcurrentLimit controls open PR count -- low limits delay updates
- **Grouping**: Poorly configured grouping creates large PRs that are hard to review
- **Major updates**: Major version updates are not auto-created by default -- check packageRules
- **Rebasing**: Renovate rebases PRs on schedule -- force-pushed branches confuse some CI setups
- **Lock file maintenance**: Lock file PRs can conflict with other dependency PRs
