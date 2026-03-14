---
name: managing-nocodb
description: |
  NocoDB spreadsheet-database platform management covering base inventory, table structure analysis, view configurations, webhook monitoring, shared view auditing, and API token management. Use when reviewing database schemas, investigating data sync issues, monitoring webhook deliveries, or auditing shared access links.
connection_type: nocodb
preload: false
---

# NocoDB Management Skill

Manage and monitor NocoDB bases, tables, views, webhooks, and shared access.

## MANDATORY: Discovery-First Pattern

**Always list bases and tables before querying specific records or configurations.**

### Phase 1: Discovery

```bash
#!/bin/bash

NOCODB_API="${NOCODB_URL}/api/v1"

nocodb_api() {
    curl -s -H "xc-auth: $NOCODB_API_TOKEN" \
         -H "Content-Type: application/json" \
         "${NOCODB_API}/${1}"
}

echo "=== Bases ==="
nocodb_api "db/meta/projects" | jq -r '
    .list[] |
    "\(.id)\t\(.title)\t\(.type // "database")\t\(.sources | length) sources"
' | column -t

echo ""
echo "=== Tables (first base) ==="
BASE_ID=$(nocodb_api "db/meta/projects" | jq -r '.list[0].id')
nocodb_api "db/meta/projects/${BASE_ID}/tables" | jq -r '
    .list[] |
    "\(.id)\t\(.title)\t\(.columns | length) cols\t\(.meta.rowCount // "?")"
' | column -t | head -20

echo ""
echo "=== Shared Views ==="
nocodb_api "db/meta/projects/${BASE_ID}/tables" | jq -r '.list[].id' | while read tid; do
    nocodb_api "db/meta/tables/${tid}/shared-views" 2>/dev/null | jq -r --arg tid "$tid" '
        .list[]? |
        "\($tid)\t\(.id)\t\(.type)\t\(.password != null)"
    '
done | column -t | head -15
```

### Phase 2: Analysis

```bash
#!/bin/bash

BASE_ID=$(nocodb_api "db/meta/projects" | jq -r '.list[0].id')

echo "=== Table Schema Summary ==="
nocodb_api "db/meta/projects/${BASE_ID}/tables" | jq -r '
    .list[] |
    "\(.title)\t\(.columns | length) cols\tLinks: \([.columns[] | select(.uidt == "LinkToAnotherRecord")] | length)"
' | column -t | head -20

echo ""
echo "=== Webhooks ==="
nocodb_api "db/meta/projects/${BASE_ID}/tables" | jq -r '.list[].id' | while read tid; do
    nocodb_api "db/meta/tables/${tid}/hooks" 2>/dev/null | jq -r --arg tid "$tid" '
        .list[]? |
        "\($tid)\t\(.title)\t\(.event)\t\(.active)"
    '
done | column -t | head -15

echo ""
echo "=== External Sources ==="
nocodb_api "db/meta/projects/${BASE_ID}" | jq -r '
    .sources[]? |
    "\(.id)\t\(.type)\t\(.config.host // "embedded")\t\(.enabled)"
' | column -t

echo ""
echo "=== API Tokens ==="
nocodb_api "db/meta/projects/${BASE_ID}/api-tokens" 2>/dev/null | jq -r '
    .list[]? |
    "\(.id)\t\(.description)\t\(.created_at[:10])"
' | column -t
```

## Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- Filter tables by base
- Never dump full record data -- extract schema and metadata only

## Common Pitfalls

- **Shared views**: Shared view links grant public access -- audit and revoke unused links
- **External DB sync**: External database sources may drift from NocoDB schema cache
- **Webhook failures**: Failed webhook deliveries are not retried by default
- **Link columns**: LinkToAnotherRecord columns create implicit junction tables
- **Row limits**: Free tier or self-hosted may have practical row limits based on resources
- **API token scope**: API tokens have full access -- use per-base tokens where possible
