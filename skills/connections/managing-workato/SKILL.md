---
name: managing-workato
description: |
  Workato enterprise automation platform management covering recipe inventory, job execution history, connection health, lookup table monitoring, and workspace management. Use when auditing integration recipes, investigating job failures, monitoring transaction quotas, or reviewing connector configurations.
connection_type: workato
preload: false
---

# Workato Management Skill

Manage and monitor Workato automation recipes, connections, and job executions.

## MANDATORY: Discovery-First Pattern

**Always list recipes and connections before querying specific resources.**

### Phase 1: Discovery

```bash
#!/bin/bash

WORKATO_API="https://www.workato.com/api"

workato_api() {
    curl -s -H "Authorization: Bearer $WORKATO_API_TOKEN" \
         -H "Content-Type: application/json" \
         "${WORKATO_API}/${1}"
}

echo "=== Workato Workspace ==="
workato_api "users/me" | jq '{name: .name, email: .email, company: .company_name}'

echo ""
echo "=== Recipes Summary ==="
workato_api "recipes?per_page=50" | jq -r '
    .result[] |
    "\(.id)\t\(.name)\t\(.running)\t\(.trigger_application // "manual")"
' | column -t | head -30

echo ""
echo "=== Connections ==="
workato_api "connections" | jq -r '
    .result[] |
    "\(.id)\t\(.name)\t\(.provider)\t\(.authorized_at // "never")"
' | column -t | head -20
```

### Phase 2: Analysis

```bash
#!/bin/bash

echo "=== Failed Jobs (recent) ==="
workato_api "recipes" | jq -r '.result[].id' | head -20 | while read rid; do
    workato_api "recipes/${rid}/jobs?status=failed&per_page=5" | jq -r --arg rid "$rid" '
        .result[]? |
        "\($rid)\t\(.id)\t\(.status)\t\(.completed_at)\t\(.error // "")"
    '
done | column -t | head -20

echo ""
echo "=== Recipe Status Summary ==="
workato_api "recipes?per_page=100" | jq '{
    total: (.result | length),
    running: [.result[] | select(.running == true)] | length,
    stopped: [.result[] | select(.running == false)] | length
}'

echo ""
echo "=== Stale Connections ==="
workato_api "connections" | jq -r '
    .result[] |
    select(.authorized_at == null) |
    "\(.id)\t\(.name)\t\(.provider)\tUNAUTHORIZED"
' | column -t
```

## Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- Filter recipes by running status or folder
- Never dump full recipe definitions -- extract trigger and action app names

## Common Pitfalls

- **Transaction limits**: Workato bills by transactions -- monitor usage to avoid overages
- **Connection reauth**: Connections require periodic re-authorization via the UI
- **Recipe dependencies**: Recipes can call other recipes -- trace the full chain when debugging
- **Lookup tables**: Row limits depend on plan -- monitor table sizes
- **Error handling**: Recipes without error monitors lose failed job data after retention period
- **Environments**: Dev/test/prod environments have separate recipe copies -- check the right one
