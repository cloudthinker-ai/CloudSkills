---
name: managing-pipedream
description: |
  Pipedream serverless workflow management covering workflow inventory, event source monitoring, connected account health, execution history, and credit usage tracking. Use when auditing workflow configurations, investigating event processing failures, monitoring invocation quotas, or reviewing connected service integrations.
connection_type: pipedream
preload: false
---

# Pipedream Management Skill

Manage and monitor Pipedream serverless workflows, event sources, and connected accounts.

## MANDATORY: Discovery-First Pattern

**Always list workflows and sources before querying specific resources.**

### Phase 1: Discovery

```bash
#!/bin/bash

PIPEDREAM_API="https://api.pipedream.com/v1"

pd_api() {
    curl -s -H "Authorization: Bearer $PIPEDREAM_API_KEY" \
         -H "Content-Type: application/json" \
         "${PIPEDREAM_API}/${1}"
}

echo "=== Pipedream Account ==="
pd_api "users/me" | jq '{email: .data.email, org: .data.org, tier: .data.pricing_tier}'

echo ""
echo "=== Workflows ==="
pd_api "users/me/workflows?limit=50" | jq -r '
    .data[] |
    "\(.id)\t\(.name // "Untitled")\t\(.active)\t\(.trigger.type // "manual")"
' | column -t | head -30

echo ""
echo "=== Event Sources ==="
pd_api "users/me/sources?limit=30" | jq -r '
    .data[] |
    "\(.id)\t\(.name)\t\(.active)\t\(.component_id)"
' | column -t | head -20
```

### Phase 2: Analysis

```bash
#!/bin/bash

echo "=== Workflow Errors (recent) ==="
pd_api "users/me/workflows" | jq -r '.data[].id' | head -15 | while read wid; do
    pd_api "workflows/${wid}/event_summaries?limit=5&status=error" | jq -r --arg wid "$wid" '
        .data[]? |
        "\($wid)\t\(.ts)\tERROR\t\(.error // "unknown")"
    '
done | column -t | head -20

echo ""
echo "=== Credit Usage ==="
pd_api "users/me" | jq '{
    credits_used: .data.orgs[0].daily_credits_used,
    credits_limit: .data.orgs[0].daily_credits_quota,
    invocations_today: .data.orgs[0].daily_invocations
}'

echo ""
echo "=== Inactive Workflows ==="
pd_api "users/me/workflows?limit=50" | jq -r '
    .data[] |
    select(.active == false) |
    "\(.id)\t\(.name // "Untitled")\tINACTIVE"
' | column -t
```

## Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- Use limit parameter on API calls to control result size
- Never dump full workflow code -- extract step names and trigger types

## Common Pitfalls

- **Credit limits**: Free/paid tiers have daily invocation and credit caps
- **Event source backpressure**: Sources can queue events faster than workflows process them
- **Connected accounts**: OAuth accounts expire -- check account status when steps fail
- **Cold starts**: Infrequently triggered workflows may have cold start latency
- **Step exports**: Data passed between steps via exports -- missing exports cause downstream failures
- **Concurrency**: Workflow executions run concurrently by default -- add concurrency controls for shared resources
