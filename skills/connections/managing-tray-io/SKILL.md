---
name: managing-tray-io
description: |
  Tray.io integration platform management covering workflow inventory, execution monitoring, connector health, authentication management, and solution instance tracking. Use when auditing integration workflows, investigating execution failures, monitoring API usage, or reviewing connector configurations.
connection_type: tray-io
preload: false
---

# Tray.io Management Skill

Manage and monitor Tray.io integration workflows, connectors, and execution pipelines.

## MANDATORY: Discovery-First Pattern

**Always list workflows and connectors before querying specific resources.**

### Phase 1: Discovery

```bash
#!/bin/bash

TRAY_API="https://api.tray.io/core/v1"

tray_api() {
    curl -s -H "Authorization: Bearer $TRAY_API_TOKEN" \
         -H "Content-Type: application/json" \
         "${TRAY_API}/${1}"
}

echo "=== Tray.io Account ==="
tray_api "users/me" | jq '{name: .name, email: .email, role: .role}'

echo ""
echo "=== Workflows Summary ==="
tray_api "workflows" | jq -r '
    .data[] |
    "\(.id)\t\(.name)\t\(.enabled)\t\(.trigger_type // "manual")"
' | column -t | head -30

echo ""
echo "=== Authentications ==="
tray_api "authentications" | jq -r '
    .data[] |
    "\(.id)\t\(.name)\t\(.service)\t\(.status // "unknown")"
' | column -t | head -20
```

### Phase 2: Analysis

```bash
#!/bin/bash

echo "=== Failed Executions (recent) ==="
tray_api "workflows" | jq -r '.data[].id' | while read wid; do
    tray_api "workflows/${wid}/executions?limit=5" | jq -r --arg wid "$wid" '
        .data[]? |
        select(.status == "failed") |
        "\($wid)\t\(.id)\t\(.status)\t\(.finished_at)"
    '
done | column -t | head -20

echo ""
echo "=== Disabled Workflows ==="
tray_api "workflows" | jq -r '
    .data[] |
    select(.enabled == false) |
    "\(.id)\t\(.name)\tDISABLED"
' | column -t

echo ""
echo "=== Workflow Health Summary ==="
tray_api "workflows" | jq '{
    total: (.data | length),
    enabled: [.data[] | select(.enabled == true)] | length,
    disabled: [.data[] | select(.enabled == false)] | length
}'
```

## Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- Filter workflows by enabled/disabled status
- Never dump full workflow step definitions -- extract connector names and trigger types

## Common Pitfalls

- **Authentication expiry**: OAuth tokens expire and must be re-authenticated in the UI
- **Trigger types**: Manual vs scheduled vs webhook triggers behave differently for monitoring
- **Solution instances**: Embedded solutions create separate workflow instances per customer
- **Rate limits**: Connector-level rate limits can cause cascading failures across workflows
- **Step timeouts**: Long-running steps can timeout silently -- check execution durations
