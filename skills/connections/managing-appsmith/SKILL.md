---
name: managing-appsmith
description: |
  Appsmith low-code platform management covering application inventory, workspace organization, datasource health, page and widget analysis, and user access auditing. Use when reviewing internal tool configurations, investigating datasource connectivity, monitoring application deployments, or auditing workspace permissions.
connection_type: appsmith
preload: false
---

# Appsmith Management Skill

Manage and monitor Appsmith applications, workspaces, datasources, and deployments.

## MANDATORY: Discovery-First Pattern

**Always list workspaces and applications before querying specific resources.**

### Phase 1: Discovery

```bash
#!/bin/bash

APPSMITH_API="${APPSMITH_URL}/api/v1"

appsmith_api() {
    curl -s -H "Authorization: Bearer $APPSMITH_API_KEY" \
         -H "Content-Type: application/json" \
         "${APPSMITH_API}/${1}"
}

echo "=== Workspaces ==="
appsmith_api "workspaces" | jq -r '
    .data[] |
    "\(.id)\t\(.name)\t\(.userPermissions | length) perms"
' | column -t

echo ""
echo "=== Applications ==="
appsmith_api "applications" | jq -r '
    .data[] |
    "\(.id)\t\(.name)\t\(.workspaceId)\t\(.isPublic // false)"
' | column -t | head -30

echo ""
echo "=== Datasources ==="
appsmith_api "datasources" | jq -r '
    .data[] |
    "\(.id)\t\(.name)\t\(.pluginName)\t\(.isValid)"
' | column -t | head -20
```

### Phase 2: Analysis

```bash
#!/bin/bash

echo "=== Invalid Datasources ==="
appsmith_api "datasources" | jq -r '
    .data[] |
    select(.isValid == false) |
    "\(.id)\t\(.name)\t\(.pluginName)\tINVALID\t\(.invalids | join("; "))"
' | column -t

echo ""
echo "=== Application Pages ==="
appsmith_api "applications" | jq -r '.data[].id' | head -10 | while read aid; do
    appsmith_api "pages?applicationId=${aid}" | jq -r --arg aid "$aid" '
        .data[]? |
        "\($aid)\t\(.id)\t\(.name)\t\(.isDefault)"
    '
done | column -t | head -20

echo ""
echo "=== App Summary ==="
appsmith_api "applications" | jq '{
    total_apps: (.data | length),
    public_apps: [.data[] | select(.isPublic == true)] | length,
    private_apps: [.data[] | select(.isPublic != true)] | length
}'
```

## Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- Filter applications by workspace
- Never dump full page/widget DSL -- extract page names and widget counts

## Common Pitfalls

- **Datasource validity**: Invalid datasources prevent queries from running -- fix credentials or connection strings
- **Git sync**: Applications with Git sync can have merge conflicts -- check sync status
- **Environment configs**: Datasource configs differ between environments -- verify the correct env
- **Widget bindings**: Broken JS bindings in widgets cause runtime errors -- not visible via API
- **Deploy vs edit**: Published app differs from edit mode -- ensure latest changes are deployed
