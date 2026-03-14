---
name: managing-gitea
description: |
  Gitea self-hosted Git platform management covering repository inventory, organization structure, user administration, webhook monitoring, issue and pull request tracking, and CI/CD integration status. Use when auditing repository configurations, investigating access issues, monitoring instance health, or reviewing organization settings.
connection_type: gitea
preload: false
---

# Gitea Management Skill

Manage and monitor Gitea repositories, organizations, users, and webhooks.

## MANDATORY: Discovery-First Pattern

**Always list organizations and repositories before querying specific resources.**

### Phase 1: Discovery

```bash
#!/bin/bash

GITEA_API="${GITEA_URL}/api/v1"

gitea_api() {
    curl -s -H "Authorization: token $GITEA_TOKEN" \
         -H "Content-Type: application/json" \
         "${GITEA_API}/${1}"
}

echo "=== Gitea Version ==="
gitea_api "version" | jq '.version'

echo ""
echo "=== Organizations ==="
gitea_api "orgs?limit=20" | jq -r '
    .[] |
    "\(.username)\t\(.full_name // "")\t\(.visibility)"
' | column -t

echo ""
echo "=== Repositories ==="
gitea_api "repos/search?limit=30&sort=updated&order=desc" | jq -r '
    .data[] |
    "\(.full_name)\t\(.default_branch)\t\(.private)\t\(.updated_at[:10])\t\(.archived)"
' | column -t | head -30

echo ""
echo "=== Users ==="
gitea_api "admin/users?limit=30" 2>/dev/null | jq -r '
    .[]? |
    "\(.login)\t\(.email)\t\(.is_admin)\t\(.active)\t\(.last_login[:10])"
' | column -t | head -20
```

### Phase 2: Analysis

```bash
#!/bin/bash

echo "=== Repository Health ==="
gitea_api "repos/search?limit=20&sort=updated&order=desc" | jq -r '.data[].full_name' | while read repo; do
    BRANCHES=$(gitea_api "repos/${repo}/branches?limit=1" | jq '. | length')
    ISSUES=$(gitea_api "repos/${repo}" | jq '.open_issues_count')
    echo -e "${repo}\tissues=${ISSUES}\tbranches=${BRANCHES}"
done | column -t | head -15

echo ""
echo "=== Webhooks ==="
gitea_api "repos/search?limit=10&sort=updated&order=desc" | jq -r '.data[].full_name' | while read repo; do
    gitea_api "repos/${repo}/hooks" | jq -r --arg repo "$repo" '
        .[]? |
        "\($repo)\t\(.type)\t\(.active)\t\(.config.url[:40])"
    '
done | column -t | head -15

echo ""
echo "=== Branch Protection ==="
gitea_api "repos/search?limit=10&sort=updated&order=desc" | jq -r '.data[].full_name' | while read repo; do
    gitea_api "repos/${repo}/branch_protections" | jq -r --arg repo "$repo" '
        .[]? |
        "\($repo)\t\(.branch_name)\treview=\(.required_approvals)\tpush_whitelist=\(.enable_push_whitelist)"
    '
done | column -t | head -15

echo ""
echo "=== Open Pull Requests ==="
gitea_api "repos/search?limit=10&sort=updated&order=desc" | jq -r '.data[].full_name' | while read repo; do
    gitea_api "repos/${repo}/pulls?state=open&limit=5" | jq -r --arg repo "$repo" '
        .[]? |
        "\($repo)\t#\(.number)\t\(.title[:35])\t\(.user.login)"
    '
done | column -t | head -15
```

## Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- Use limit and sort parameters
- Never dump full repository contents or diff data -- extract metadata

## Common Pitfalls

- **Admin API**: Some endpoints require admin tokens -- user tokens return 403
- **Mirror repos**: Mirrored repositories sync on schedule -- check mirror status for stale data
- **Actions**: Gitea Actions (CI/CD) is opt-in -- verify it is enabled in app.ini
- **LFS storage**: Large File Storage consumes server disk -- monitor LFS object sizes
- **OAuth2 providers**: External auth providers need periodic configuration review
- **Webhook secrets**: Webhooks without secrets accept forged payloads -- always set a secret
