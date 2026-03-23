---
name: managing-prisma-cloud
description: |
  Use when working with Prisma Cloud — palo Alto Prisma Cloud security platform
  for cloud security posture management, workload protection, and compliance
  monitoring. Covers alert management, policy configuration, asset inventory,
  vulnerability findings, compliance frameworks, and runtime protection. Use
  when investigating cloud security alerts, reviewing compliance status,
  analyzing vulnerabilities, or managing Prisma Cloud policies and integrations.
connection_type: prisma-cloud
preload: false
---

# Prisma Cloud Management Skill

Manage and analyze Prisma Cloud alerts, policies, compliance, and cloud security posture.

## API Conventions

### Authentication
All API calls use `x-redlock-auth: $PRISMA_TOKEN` -- injected automatically via login API. Never hardcode tokens.

### Base URL
`https://api.$PRISMA_STACK.prismacloud.io`

### Core Helper Function

```bash
#!/bin/bash

prisma_api() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"
    local base="https://api.${PRISMA_STACK}.prismacloud.io"

    if [ -n "$data" ]; then
        curl -s -X "$method" \
            -H "x-redlock-auth: $PRISMA_TOKEN" \
            -H "Content-Type: application/json" \
            "${base}${endpoint}" \
            -d "$data"
    else
        curl -s -X "$method" \
            -H "x-redlock-auth: $PRISMA_TOKEN" \
            -H "Content-Type: application/json" \
            "${base}${endpoint}"
    fi
}
```

## Output Rules
- **TOKEN EFFICIENCY**: Extract only needed fields with `jq`
- Target <=50 lines per script output
- Always filter by relevant time range to avoid huge response sets
- Never dump full API responses

## Discovery Phase

```bash
#!/bin/bash
echo "=== Alert Summary ==="
prisma_api GET "/v2/alert?timeType=relative&timeAmount=7&timeUnit=day&detailed=false" \
    | jq '{total: length, critical: ([.[] | select(.policy.severity == "critical")] | length), high: ([.[] | select(.policy.severity == "high")] | length)}'

echo ""
echo "=== Cloud Accounts ==="
prisma_api GET "/cloud" \
    | jq -r '.[] | "\(.cloudType)\t\(.name)\t\(.enabled)\t\(.lastModifiedTs | todate[0:10])"' | column -t | head -10

echo ""
echo "=== Policy Summary ==="
prisma_api GET "/v2/policy?policy.enabled=true" \
    | jq '{enabled_policies: length}' 2>/dev/null
```

## Analysis Phase

### Alert Investigation

```bash
#!/bin/bash
echo "=== Open Alerts (Critical/High) ==="
prisma_api POST "/v2/alert" '{"timeRange":{"type":"relative","value":{"amount":7,"unit":"day"}},"filters":[{"name":"alert.status","value":"open","operator":"="},{"name":"policy.severity","value":"critical,high","operator":"="}],"limit":20}' \
    | jq -r '.items[]? | "\(.alertTime[0:16])\t\(.policy.severity)\t\(.status)\t\(.policy.name[0:50])"' \
    | column -t | head -20

echo ""
echo "=== Alerts by Policy Type ==="
prisma_api POST "/v2/alert" '{"timeRange":{"type":"relative","value":{"amount":7,"unit":"day"}},"filters":[{"name":"alert.status","value":"open","operator":"="}]}' \
    | jq -r '[.items[]?.policy.policyType] | group_by(.) | map({type: .[0], count: length}) | sort_by(.count) | reverse | .[] | "\(.count)\t\(.type)"' | column -t
```

### Compliance Dashboard

```bash
#!/bin/bash
echo "=== Compliance Summary ==="
prisma_api GET "/compliance/posture" \
    | jq -r '.complianceDetails[] | "\(.name[0:30])\tpassed:\(.passedResources)\tfailed:\(.failedResources)\tscore:\(.highSeverityFailedResources)"' \
    | column -t | head -15

echo ""
echo "=== Top Failed Compliance Standards ==="
prisma_api GET "/compliance/posture?timeType=relative&timeAmount=1&timeUnit=month" \
    | jq -r '.complianceDetails | sort_by(.failedResources) | reverse | .[:10][] | "\(.failedResources)\t\(.name[0:40])"' | column -t
```

### Asset Inventory

```bash
#!/bin/bash
echo "=== Asset Inventory by Cloud ==="
prisma_api GET "/v2/inventory?timeType=relative&timeAmount=1&timeUnit=day" \
    | jq -r '.groupedAggregates[]? | "\(.cloudTypeName)\ttotal:\(.totalResources)\tfailed:\(.failedResources)\tpassed:\(.passedResources)"' | column -t

echo ""
echo "=== Highest Risk Resources ==="
prisma_api POST "/resource/scan_info" '{"timeRange":{"type":"relative","value":{"amount":1,"unit":"day"}},"filters":[{"name":"resource.severity","value":"critical","operator":"="}],"limit":10}' \
    | jq -r '.resources[]? | "\(.severity)\t\(.cloudType)\t\(.resourceType[0:25])\t\(.name[0:30])"' | column -t
```

## Output Format

Present results as a structured report:
```
Managing Prisma Cloud Report
════════════════════════════
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

- **Token expiration**: Tokens expire after 10 minutes -- refresh via `/login` endpoint
- **Stack-specific URL**: API URL varies by stack (app, app2, app3, api.eu, api.gov, etc.)
- **v1 vs v2 API**: Prefer v2 endpoints -- they support pagination and better filtering
- **Time filters**: Use `timeType=relative` with `timeAmount` and `timeUnit` for relative ranges
- **Rate limits**: 30 requests/minute for most endpoints -- implement backoff
- **RQL queries**: Resource Query Language for custom asset searches via `/search/config`
