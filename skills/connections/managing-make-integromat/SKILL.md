---
name: managing-make-integromat
description: |
  Make (formerly Integromat) scenario management covering scenario inventory, execution history, connection health, webhook monitoring, and data store analysis. Use when auditing automation scenarios, investigating execution failures, monitoring operation quotas, or reviewing integration configurations.
connection_type: make
preload: false
---

# Make (Integromat) Management Skill

Manage and monitor Make automation scenarios, executions, and connected services.

## MANDATORY: Discovery-First Pattern

**Always list scenarios and connections before querying specific resources.**

### Phase 1: Discovery

```bash
#!/bin/bash

MAKE_API="https://us1.make.com/api/v2"

make_api() {
    curl -s -H "Authorization: Token $MAKE_API_TOKEN" \
         -H "Content-Type: application/json" \
         "${MAKE_API}/${1}"
}

echo "=== Make Organization ==="
make_api "organizations" | jq -r '.organizations[] | "\(.id)\t\(.name)\t\(.zone)"' | column -t

echo ""
echo "=== Scenarios Summary ==="
make_api "scenarios?pg[limit]=50" | jq -r '
    .scenarios[] |
    "\(.id)\t\(.name)\t\(.isEnabled // false)\t\(.scheduling.type // "manual")"
' | column -t | head -30

echo ""
echo "=== Connections ==="
make_api "connections" | jq -r '
    .connections[] |
    "\(.id)\t\(.name)\t\(.accountType)\t\(.metadata.status // "unknown")"
' | column -t | head -20
```

### Phase 2: Analysis

```bash
#!/bin/bash

echo "=== Failed Executions (recent) ==="
make_api "scenarios" | jq -r '.scenarios[].id' | while read sid; do
    make_api "scenarios/${sid}/executions?pg[limit]=5" | jq -r --arg sid "$sid" '
        .executions[]? |
        select(.status == "failed") |
        "\($sid)\t\(.id)\t\(.status)\t\(.finished)"
    '
done | column -t | head -20

echo ""
echo "=== Operations Usage ==="
make_api "organizations" | jq -r '
    .organizations[] |
    "Org: \(.name) | Ops used: \(.operations.used // 0) / \(.operations.limit // "unlimited")"
'

echo ""
echo "=== Disabled Scenarios ==="
make_api "scenarios" | jq -r '
    .scenarios[] |
    select(.isEnabled == false) |
    "\(.id)\t\(.name)\tDISABLED\tLast: \(.lastExec // "never")"
' | column -t
```

## Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- Use pagination parameters to limit results
- Never dump full scenario blueprints -- extract key module names

## Common Pitfalls

- **Operation limits**: Make bills by operations -- monitor usage across all scenarios
- **Incomplete executions**: Stuck executions consume slots -- check and cancel stale runs
- **Connection expiry**: OAuth connections expire -- renew before scenarios fail
- **Webhook queue**: Webhooks queue data when scenarios are off -- data loss risk if queue overflows
- **Error handlers**: Scenarios without error handler routes silently fail -- always add error paths
- **Data stores**: Data store row limits depend on plan -- monitor capacity
