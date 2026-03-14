---
name: managing-bitbucket-deep
description: |
  Bitbucket deep platform management covering repository inventory, Pipelines CI/CD monitoring, pull request analysis, branch permission auditing, deployment environment tracking, and workspace member management. Use when auditing repository configurations, investigating pipeline failures, reviewing branch restrictions, or managing workspace access.
connection_type: bitbucket
preload: false
---

# Bitbucket Deep Management Skill

Manage and monitor Bitbucket repositories, Pipelines, pull requests, and workspace settings at depth.

## MANDATORY: Discovery-First Pattern

**Always list workspaces and repositories before querying specific resources.**

### Phase 1: Discovery

```bash
#!/bin/bash

BB_API="https://api.bitbucket.org/2.0"

bb_api() {
    curl -s -u "${BITBUCKET_USERNAME}:${BITBUCKET_APP_PASSWORD}" \
         -H "Content-Type: application/json" \
         "${BB_API}/${1}"
}

echo "=== Workspace ==="
bb_api "workspaces/${BITBUCKET_WORKSPACE}" | jq '{
    name: .name, slug: .slug, type: .type
}'

echo ""
echo "=== Repositories ==="
bb_api "repositories/${BITBUCKET_WORKSPACE}?pagelen=30&sort=-updated_on" | jq -r '
    .values[] |
    "\(.slug)\t\(.mainbranch.name // "main")\t\(.is_private)\t\(.updated_on[:10])"
' | column -t | head -30

echo ""
echo "=== Workspace Members ==="
bb_api "workspaces/${BITBUCKET_WORKSPACE}/members?pagelen=30" | jq -r '
    .values[] |
    "\(.user.display_name)\t\(.user.nickname)\t\(.workspace_membership.role // "member")"
' | column -t | head -20
```

### Phase 2: Analysis

```bash
#!/bin/bash

echo "=== Failed Pipelines (recent) ==="
bb_api "repositories/${BITBUCKET_WORKSPACE}?pagelen=10&sort=-updated_on" | jq -r '.values[].slug' | while read repo; do
    bb_api "repositories/${BITBUCKET_WORKSPACE}/${repo}/pipelines/?pagelen=3&sort=-created_on&status=FAILED" | jq -r --arg repo "$repo" '
        .values[]? |
        "\($repo)\t\(.build_number)\t\(.state.result.name // .state.name)\t\(.created_on[:10])"
    '
done | column -t | head -20

echo ""
echo "=== Branch Restrictions ==="
bb_api "repositories/${BITBUCKET_WORKSPACE}?pagelen=10&sort=-updated_on" | jq -r '.values[].slug' | while read repo; do
    bb_api "repositories/${BITBUCKET_WORKSPACE}/${repo}/branch-restrictions?pagelen=10" | jq -r --arg repo "$repo" '
        .values[]? |
        "\($repo)\t\(.kind)\t\(.pattern)\t\(.value // 0)"
    '
done | column -t | head -15

echo ""
echo "=== Open Pull Requests ==="
bb_api "repositories/${BITBUCKET_WORKSPACE}?pagelen=10&sort=-updated_on" | jq -r '.values[].slug' | while read repo; do
    bb_api "repositories/${BITBUCKET_WORKSPACE}/${repo}/pullrequests?state=OPEN&pagelen=5" | jq -r --arg repo "$repo" '
        .values[]? |
        "\($repo)\t#\(.id)\t\(.title[:40])\t\(.author.display_name)\t\(.created_on[:10])"
    '
done | column -t | head -20

echo ""
echo "=== Deployment Environments ==="
bb_api "repositories/${BITBUCKET_WORKSPACE}?pagelen=5&sort=-updated_on" | jq -r '.values[].slug' | while read repo; do
    bb_api "repositories/${BITBUCKET_WORKSPACE}/${repo}/environments?pagelen=10" | jq -r --arg repo "$repo" '
        .values[]? |
        "\($repo)\t\(.name)\t\(.environment_type.name)\t\(.lock.type // "unlocked")"
    '
done | column -t | head -15
```

## Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- Use pagelen and sort parameters to control result size
- Never dump full pipeline logs or PR diffs -- extract status metadata

## Common Pitfalls

- **Build minutes**: Pipelines consume monthly build minutes based on plan
- **App passwords**: App passwords have scoped permissions -- verify required scopes
- **Branch restrictions**: Multiple restriction types (push, merge, delete) stack independently
- **Pipeline caching**: Cache key mismatches cause unnecessary rebuilds
- **Deployment locks**: Environment locks prevent concurrent deployments -- check lock status
- **Repository size**: Large repos with LFS hit size limits -- monitor repository size
- **Merge checks**: Required merge checks must pass before PR merge -- stale checks block merges
