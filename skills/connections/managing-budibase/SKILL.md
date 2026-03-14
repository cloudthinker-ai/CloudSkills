---
name: managing-budibase
description: |
  Budibase low-code platform management covering application inventory, table and datasource health, screen layout analysis, automation monitoring, and user role auditing. Use when reviewing internal app configurations, investigating data connectivity issues, monitoring automation runs, or auditing user access controls.
connection_type: budibase
preload: false
---

# Budibase Management Skill

Manage and monitor Budibase applications, datasources, automations, and user access.

## MANDATORY: Discovery-First Pattern

**Always list applications and datasources before querying specific resources.**

### Phase 1: Discovery

```bash
#!/bin/bash

BUDIBASE_API="${BUDIBASE_URL}/api/public/v1"

bb_api() {
    curl -s -H "x-budibase-api-key: $BUDIBASE_API_KEY" \
         -H "Content-Type: application/json" \
         "${BUDIBASE_API}/${1}" ${2:+-X POST -d "$2"}
}

echo "=== Applications ==="
bb_api "applications/search" '{"limit": 50}' | jq -r '
    .data[] |
    "\(.appId)\t\(.name)\t\(.status)\t\(.version)"
' | column -t | head -30

echo ""
echo "=== Tables ==="
bb_api "tables/search" '{}' | jq -r '
    .data[] |
    "\(.name)\t\(.type)\t\(.sourceId // "internal")\t\(.schema | keys | length) cols"
' | column -t | head -20

echo ""
echo "=== Users ==="
bb_api "users/search" '{"limit": 30}' | jq -r '
    .data[] |
    "\(.email)\t\(.role // "none")\t\(.status)"
' | column -t | head -20
```

### Phase 2: Analysis

```bash
#!/bin/bash

echo "=== Application Health ==="
bb_api "applications/search" '{"limit": 50}' | jq '{
    total: (.data | length),
    published: [.data[] | select(.status == "published")] | length,
    development: [.data[] | select(.status == "development")] | length
}'

echo ""
echo "=== Automations ==="
bb_api "applications/search" '{"limit": 20}' | jq -r '.data[].appId' | while read aid; do
    bb_api "automations/search" "{\"appId\": \"${aid}\"}" | jq -r --arg aid "$aid" '
        .data[]? |
        "\($aid)\t\(.name)\t\(.type)\t\(.enabled // false)"
    '
done | column -t | head -20

echo ""
echo "=== External Datasources ==="
bb_api "tables/search" '{}' | jq -r '
    .data[] |
    select(.sourceId != null and .sourceId != "bb_internal") |
    "\(.name)\t\(.sourceType // "unknown")\t\(.sourceId)"
' | column -t

echo ""
echo "=== Role Distribution ==="
bb_api "users/search" '{"limit": 100}' | jq '
    .data | group_by(.role) | map({role: .[0].role, count: length})
'
```

## Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- Filter apps by status (published vs development)
- Never dump full table schemas or automation definitions -- extract names and types

## Common Pitfalls

- **Publish required**: Changes in dev mode are not live until explicitly published
- **Internal DB limits**: Internal Budibase DB has row and storage limits per plan
- **Automation triggers**: Row-based triggers fire on every change -- can cause cascading automations
- **External datasources**: Connection failures to external DBs break dependent screens
- **User roles**: Role hierarchy (admin/power/basic) controls both UI and API access
- **Backups**: Self-hosted instances require manual backup of CouchDB data
