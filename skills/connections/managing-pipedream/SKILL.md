---
name: managing-pipedream
description: |
  Use when working with Pipedream — pipedream serverless workflow management
  covering workflow inventory, event source monitoring, connected account
  health, execution history, and credit usage tracking. Use when auditing
  workflow configurations, investigating event processing failures, monitoring
  invocation quotas, or reviewing connected service integrations.
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

## Output Format

Present results as a structured report:
```
Managing Pipedream Report
═════════════════════════
Resources discovered: [count]

Resource       Status    Key Metric    Issues
──────────────────────────────────────────────
[name]         [ok/warn] [value]       [findings]

Summary: [total] resources | [ok] healthy | [warn] warnings | [crit] critical
Action Items: [list of prioritized findings]
```

Target ≤50 lines of output. Use tables for multi-resource comparisons.

## Anti-Hallucination Rules

1. **NEVER assume resource names** — always discover via CLI/API in Phase 1 before referencing in Phase 2.
2. **NEVER fabricate metric names or dimensions** — verify against the service documentation or `--help` output.
3. **NEVER mix CLI commands between service versions** — confirm which version/API you are targeting.
4. **ALWAYS use the discovery → verify → analyze chain** — every resource referenced must have been discovered first.
5. **ALWAYS handle empty results gracefully** — an empty response is valid data, not an error to retry.

## Counter-Rationalizations

| Shortcut | Counter | Why |
|----------|---------|-----|
| "I'll skip discovery and check known resources" | Always run Phase 1 discovery first | Resource names change, new resources appear — assumed names cause errors |
| "The user only asked for a quick check" | Follow the full discovery → analysis flow | Quick checks miss critical issues; structured analysis catches silent failures |
| "Default configuration is probably fine" | Audit configuration explicitly | Defaults often leave logging, security, and optimization features disabled |
| "Metrics aren't needed for this" | Always check relevant metrics when available | API/CLI responses show current state; metrics reveal trends and intermittent issues |
| "I don't have access to that" | Try the command and report the actual error | Assumed permission failures prevent useful investigation; actual errors are informative |

## Common Pitfalls

- **Credit limits**: Free/paid tiers have daily invocation and credit caps
- **Event source backpressure**: Sources can queue events faster than workflows process them
- **Connected accounts**: OAuth accounts expire -- check account status when steps fail
- **Cold starts**: Infrequently triggered workflows may have cold start latency
- **Step exports**: Data passed between steps via exports -- missing exports cause downstream failures
- **Concurrency**: Workflow executions run concurrently by default -- add concurrency controls for shared resources
