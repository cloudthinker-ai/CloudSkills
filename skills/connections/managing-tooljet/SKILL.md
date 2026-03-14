---
name: managing-tooljet
description: |
  ToolJet low-code platform management covering application inventory, datasource health, workspace organization, user management, and environment configuration. Use when reviewing internal tool setups, investigating data query failures, monitoring application versions, or auditing workspace access controls.
connection_type: tooljet
preload: false
---

# ToolJet Management Skill

Manage and monitor ToolJet applications, datasources, workspaces, and user access.

## MANDATORY: Discovery-First Pattern

**Always list workspaces and applications before querying specific resources.**

### Phase 1: Discovery

```bash
#!/bin/bash

TOOLJET_API="${TOOLJET_URL}/api"

tooljet_api() {
    curl -s -H "Authorization: Bearer $TOOLJET_API_TOKEN" \
         -H "Content-Type: application/json" \
         "${TOOLJET_API}/${1}"
}

echo "=== ToolJet Organization ==="
tooljet_api "organizations" | jq -r '
    .[] |
    "\(.id)\t\(.name)\t\(.status)"
' | column -t

echo ""
echo "=== Applications ==="
tooljet_api "apps" | jq -r '
    .apps[] |
    "\(.id)\t\(.name)\t\(.is_public)\t\(.created_at[:10])"
' | column -t | head -30

echo ""
echo "=== Data Sources ==="
tooljet_api "data_sources" | jq -r '
    .data_sources[] |
    "\(.id)\t\(.name)\t\(.kind)\t\(.created_at[:10])"
' | column -t | head -20
```

### Phase 2: Analysis

```bash
#!/bin/bash

echo "=== Application Versions ==="
tooljet_api "apps" | jq -r '.apps[].id' | head -10 | while read aid; do
    tooljet_api "apps/${aid}/versions" | jq -r --arg aid "$aid" '
        .versions[]? |
        "\($aid)\t\(.id)\t\(.name)\t\(.created_at[:10])"
    '
done | column -t | head -20

echo ""
echo "=== Users & Permissions ==="
tooljet_api "users" | jq -r '
    .users[] |
    "\(.email)\t\(.role)\t\(.status)\t\(.created_at[:10])"
' | column -t | head -20

echo ""
echo "=== Data Source Health ==="
tooljet_api "data_sources" | jq '{
    total: (.data_sources | length),
    by_type: (.data_sources | group_by(.kind) | map({type: .[0].kind, count: length}))
}'

echo ""
echo "=== Public Apps (security review) ==="
tooljet_api "apps" | jq -r '
    .apps[] |
    select(.is_public == true) |
    "\(.id)\t\(.name)\tPUBLIC"
' | column -t
```

## Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- Filter apps by workspace or public/private status
- Never dump full application definitions -- extract component and query names

## Common Pitfalls

- **Version management**: App versions must be explicitly released -- draft versions are not live
- **Data source credentials**: Credentials are encrypted -- test connectivity after changes
- **Public apps**: Public apps are accessible without login -- audit regularly for data exposure
- **Query timeouts**: Long-running data queries timeout -- check query performance
- **Environment variables**: Server-side env vars differ from workspace variables
- **Multi-workspace**: Users can belong to multiple workspaces with different roles
