---
name: managing-baserow
description: |
  Baserow open-source database platform management covering workspace organization, database and table inventory, field configuration analysis, view management, webhook monitoring, and user access auditing. Use when reviewing database structures, investigating API integration issues, monitoring webhook deliveries, or auditing workspace permissions.
connection_type: baserow
preload: false
---

# Baserow Management Skill

Manage and monitor Baserow workspaces, databases, tables, and integrations.

## MANDATORY: Discovery-First Pattern

**Always list workspaces and databases before querying specific tables.**

### Phase 1: Discovery

```bash
#!/bin/bash

BASEROW_API="${BASEROW_URL}/api"

baserow_api() {
    curl -s -H "Authorization: Token $BASEROW_API_TOKEN" \
         -H "Content-Type: application/json" \
         "${BASEROW_API}/${1}"
}

echo "=== Workspaces ==="
baserow_api "workspaces/" | jq -r '
    .[] |
    "\(.id)\t\(.name)\t\(.permissions)"
' | column -t

echo ""
echo "=== Databases ==="
baserow_api "applications/" | jq -r '
    .[] |
    select(.type == "database") |
    "\(.id)\t\(.name)\t\(.workspace.id)\t\(.tables | length) tables"
' | column -t | head -20

echo ""
echo "=== Tables (all databases) ==="
baserow_api "applications/" | jq -r '
    .[] | select(.type == "database") |
    .name as $db | .tables[]? |
    "\($db)\t\(.id)\t\(.name)\t\(.order)"
' | column -t | head -30
```

### Phase 2: Analysis

```bash
#!/bin/bash

echo "=== Table Fields Summary ==="
baserow_api "applications/" | jq -r '.[].tables[]?.id' | head -10 | while read tid; do
    baserow_api "database/fields/table/${tid}/" | jq -r --arg tid "$tid" '
        . as $fields | {
            table_id: $tid,
            field_count: ($fields | length),
            link_fields: [$fields[] | select(.type == "link_row")] | length,
            formula_fields: [$fields[] | select(.type == "formula")] | length
        }
    '
done | head -20

echo ""
echo "=== Views ==="
baserow_api "applications/" | jq -r '.[].tables[]?.id' | head -10 | while read tid; do
    baserow_api "database/views/table/${tid}/" | jq -r --arg tid "$tid" '
        .[]? |
        "\($tid)\t\(.id)\t\(.name)\t\(.type)\t\(.public)"
    '
done | column -t | head -20

echo ""
echo "=== Webhooks ==="
baserow_api "applications/" | jq -r '.[].tables[]?.id' | head -10 | while read tid; do
    baserow_api "database/webhooks/table/${tid}/" 2>/dev/null | jq -r --arg tid "$tid" '
        .[]? |
        "\($tid)\t\(.name)\t\(.active)\t\(.events | join(","))"
    '
done | column -t | head -15

echo ""
echo "=== Public Views (security review) ==="
baserow_api "applications/" | jq -r '.[].tables[]?.id' | head -10 | while read tid; do
    baserow_api "database/views/table/${tid}/" | jq -r --arg tid "$tid" '
        .[]? | select(.public == true) |
        "\($tid)\t\(.name)\tPUBLIC\t\(.public_view_has_password)"
    '
done | column -t
```

## Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- Filter by workspace or database
- Never dump full row data -- extract schema and view metadata

## Common Pitfalls

- **Public views**: Public views expose data without authentication -- audit regularly
- **Link row fields**: Link fields create bidirectional relationships -- deleting one side affects the other
- **Formula dependencies**: Formula fields depend on other fields -- field deletion can break formulas
- **Webhook retries**: Failed webhooks are retried with exponential backoff but eventually dropped
- **Row-level permissions**: Premium feature -- free tier has workspace-level permissions only
- **API rate limits**: Self-hosted has no default rate limiting -- configure reverse proxy limits
