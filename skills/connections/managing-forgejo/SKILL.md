---
name: managing-forgejo
description: |
  Forgejo self-hosted Git forge management covering repository inventory, organization structure, user administration, webhook monitoring, Actions runner status, and federation configuration. Use when auditing repository settings, investigating CI/CD issues, monitoring instance health, or reviewing access controls on Forgejo instances.
connection_type: forgejo
preload: false
---

# Forgejo Management Skill

Manage and monitor Forgejo repositories, organizations, users, Actions runners, and webhooks.

## MANDATORY: Discovery-First Pattern

**Always list organizations and repositories before querying specific resources.**

### Phase 1: Discovery

```bash
#!/bin/bash

FORGEJO_API="${FORGEJO_URL}/api/v1"

forgejo_api() {
    curl -s -H "Authorization: token $FORGEJO_TOKEN" \
         -H "Content-Type: application/json" \
         "${FORGEJO_API}/${1}"
}

echo "=== Forgejo Version ==="
forgejo_api "version" | jq '.version'

echo ""
echo "=== Organizations ==="
forgejo_api "orgs?limit=20" | jq -r '
    .[] |
    "\(.username)\t\(.full_name // "")\t\(.visibility)"
' | column -t

echo ""
echo "=== Repositories ==="
forgejo_api "repos/search?limit=30&sort=updated&order=desc" | jq -r '
    .data[] |
    "\(.full_name)\t\(.default_branch)\t\(.private)\t\(.updated_at[:10])\t\(.fork)"
' | column -t | head -30

echo ""
echo "=== Users ==="
forgejo_api "admin/users?limit=30" 2>/dev/null | jq -r '
    .[]? |
    "\(.login)\t\(.email)\t\(.is_admin)\t\(.active)\t\(.last_login[:10])"
' | column -t | head -20
```

### Phase 2: Analysis

```bash
#!/bin/bash

echo "=== Actions Runners ==="
forgejo_api "admin/runners" 2>/dev/null | jq -r '
    .[]? |
    "\(.id)\t\(.name)\t\(.status)\t\(.labels | join(","))"
' | column -t | head -15

echo ""
echo "=== Branch Protection ==="
forgejo_api "repos/search?limit=10&sort=updated&order=desc" | jq -r '.data[].full_name' | while read repo; do
    forgejo_api "repos/${repo}/branch_protections" | jq -r --arg repo "$repo" '
        .[]? |
        "\($repo)\t\(.branch_name)\tapprovals=\(.required_approvals)\tpush=\(.enable_push_whitelist)"
    '
done | column -t | head -15

echo ""
echo "=== Webhooks ==="
forgejo_api "repos/search?limit=10&sort=updated&order=desc" | jq -r '.data[].full_name' | while read repo; do
    forgejo_api "repos/${repo}/hooks" | jq -r --arg repo "$repo" '
        .[]? |
        "\($repo)\t\(.type)\t\(.active)\t\(.config.url[:40])"
    '
done | column -t | head -15

echo ""
echo "=== Open Issues & PRs ==="
forgejo_api "repos/search?limit=10&sort=updated&order=desc" | jq -r '.data[] |
    "\(.full_name)\tissues=\(.open_issues_count)\tprs=\(.open_pr_counter)"
' | column -t | head -15

echo ""
echo "=== Federation Status ==="
forgejo_api "nodeinfo" 2>/dev/null | jq '{
    software: .software,
    total_users: .usage.users.total,
    active_users: .usage.users.activeMonth,
    local_posts: .usage.localPosts
}' 2>/dev/null || echo "Federation not enabled"
```

## Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- Use limit and sort parameters
- Never dump full repository contents -- extract metadata and status

## Common Pitfalls

- **Gitea compatibility**: Forgejo API is Gitea-compatible but may diverge -- check version-specific docs
- **Actions runners**: Forgejo Actions requires registered runners -- check runner availability
- **Federation**: ActivityPub federation is experimental -- not all instances enable it
- **Admin endpoints**: Admin API requires admin-level tokens
- **Mirror sync**: Mirrored repositories sync on intervals -- check sync timestamps
- **Storage backends**: Forgejo supports multiple storage backends -- check config for S3/minio
- **Package registry**: Built-in package registry shares storage with repository data
