---
name: managing-ifttt
description: |
  IFTTT automation platform management covering applet inventory, service connection health, activity log monitoring, and usage tracking. Use when auditing applet configurations, investigating trigger or action failures, monitoring service connectivity, or reviewing automation activity history.
connection_type: ifttt
preload: false
---

# IFTTT Management Skill

Manage and monitor IFTTT applets, service connections, and automation activity.

## MANDATORY: Discovery-First Pattern

**Always list applets and services before querying specific resources.**

### Phase 1: Discovery

```bash
#!/bin/bash

IFTTT_API="https://connect.ifttt.com/v2"

ifttt_api() {
    curl -s -H "Authorization: Bearer $IFTTT_SERVICE_KEY" \
         -H "Content-Type: application/json" \
         "${IFTTT_API}/${1}"
}

echo "=== IFTTT Service Info ==="
ifttt_api "me" | jq '{user_id: .data.id, email: .data.email, tier: .data.tier}'

echo ""
echo "=== Active Applets ==="
ifttt_api "applets?limit=50" | jq -r '
    .data[] |
    "\(.id)\t\(.name)\t\(.status)\t\(.trigger_service // "unknown")"
' | column -t | head -30

echo ""
echo "=== Connected Services ==="
ifttt_api "connections" | jq -r '
    .data[] |
    "\(.service_id)\t\(.service_name)\t\(.status)\t\(.connected_at // "unknown")"
' | column -t | head -20
```

### Phase 2: Analysis

```bash
#!/bin/bash

echo "=== Recent Activity Log ==="
ifttt_api "activity?limit=20" | jq -r '
    .data[] |
    "\(.timestamp)\t\(.applet_name)\t\(.status)\t\(.message // "")"
' | column -t | head -20

echo ""
echo "=== Failed Applets ==="
ifttt_api "applets?status=failed" | jq -r '
    .data[] |
    "\(.id)\t\(.name)\t\(.error_count // 0) errors\t\(.last_error // "none")"
' | column -t

echo ""
echo "=== Applet Summary ==="
ifttt_api "applets?limit=100" | jq '{
    total: (.data | length),
    active: [.data[] | select(.status == "active")] | length,
    paused: [.data[] | select(.status == "paused")] | length,
    errored: [.data[] | select(.status == "error")] | length
}'
```

## Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- Filter applets by status to focus on problem areas
- Never dump full applet configurations -- extract trigger and action service names

## Common Pitfalls

- **Service disconnects**: Services require re-authentication when tokens expire
- **Polling triggers**: IFTTT polls some triggers at intervals -- not real-time for all services
- **Rate limits**: Free tier limits applet count and execution frequency
- **Filter codes**: Applets with filter code (JavaScript) can silently skip executions
- **Multi-action**: Pro+ applets with multiple actions -- one failing action does not stop others
- **Webhook security**: Webhook triggers expose URLs that anyone can call -- rotate if compromised
