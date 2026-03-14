---
name: managing-zapier
description: |
  Zapier workflow automation management covering Zap inventory, task usage tracking, connection health, error monitoring, and folder organization. Use when auditing Zap configurations, investigating failed tasks, monitoring usage quotas, or reviewing connected app integrations.
connection_type: zapier
preload: false
---

# Zapier Management Skill

Manage and monitor Zapier workflow automations, task usage, and connected applications.

## MANDATORY: Discovery-First Pattern

**Always list Zaps and connections before querying specific resources.**

### Phase 1: Discovery

```bash
#!/bin/bash

ZAPIER_API="https://api.zapier.com/v1"

zapier_api() {
    curl -s -H "Authorization: Bearer $ZAPIER_API_KEY" \
         -H "Content-Type: application/json" \
         "${ZAPIER_API}/${1}"
}

echo "=== Zapier Account Overview ==="
zapier_api "profile" | jq '{email: .email, plan: .plan, role: .role}'

echo ""
echo "=== Zaps Summary ==="
zapier_api "zaps" | jq -r '
    .results[] |
    "\(.id)\t\(.title // "Untitled")\t\(.status)\t\(.steps | length) steps"
' | column -t | head -30

echo ""
echo "=== Connected Apps ==="
zapier_api "apps" | jq -r '.results[] | "\(.title)\t\(.status)"' | column -t | head -20
```

### Phase 2: Analysis

```bash
#!/bin/bash

echo "=== Zap Error Summary ==="
zapier_api "zaps" | jq -r '
    .results[] |
    select(.status == "off" or .last_run_status == "error") |
    "\(.id)\t\(.title)\t\(.status)\t\(.last_run_status // "unknown")"
' | column -t

echo ""
echo "=== Task Usage ==="
zapier_api "profile" | jq '{
    tasks_used: .usage.tasks_used,
    tasks_limit: .usage.tasks_limit,
    usage_pct: ((.usage.tasks_used / .usage.tasks_limit) * 100 | floor)
}'

echo ""
echo "=== Zaps by Status ==="
zapier_api "zaps" | jq '{
    total: (.results | length),
    on: [.results[] | select(.status == "on")] | length,
    off: [.results[] | select(.status == "off")] | length,
    draft: [.results[] | select(.status == "draft")] | length
}'
```

## Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- Filter Zaps by status or folder to reduce noise
- Never dump full Zap step configurations -- extract key fields

## Common Pitfalls

- **Task limits**: Zapier plans have monthly task caps -- monitor usage to avoid workflow pauses
- **Connection auth**: App connections expire -- check connection health when Zaps fail
- **Multi-step Zaps**: Each step in a multi-step Zap consumes a task -- high-step Zaps consume quotas quickly
- **Error holds**: Zaps auto-disable after repeated errors -- check held Zaps regularly
- **Webhook triggers**: Webhook-triggered Zaps can be invoked externally -- audit for security
