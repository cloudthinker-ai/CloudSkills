---
name: managing-env0-deep
description: |
  Advanced env0 environment management platform. Covers environment lifecycle tracking, template configuration analysis, cost monitoring integration, custom flow management, policy enforcement, variable inheritance, approval workflow inspection, and drift detection configuration. Use for deep env0 administration, cost governance, custom flow debugging, or multi-team environment management.
connection_type: env0
preload: false
---

# env0 Deep Management Skill

Advanced management of env0 environments, templates, custom flows, costs, and policies.

## MANDATORY: Discovery-First Pattern

**Always check organization and project context before modifying environments or policies.**

### Phase 1: Discovery

```bash
#!/bin/bash

ENV0_TOKEN="${ENV0_API_KEY:?ENV0_API_KEY required}"
ENV0_SECRET="${ENV0_API_SECRET:?ENV0_API_SECRET required}"
ENV0_API="https://api.env0.com"

env0_api() {
    curl -s -u "$ENV0_TOKEN:$ENV0_SECRET" "$ENV0_API/$1"
}

echo "=== Organizations ==="
env0_api "organizations" | jq -r '.[] | "\(.id)\t\(.name)"' | head -5

ORG_ID=$(env0_api "organizations" | jq -r '.[0].id')

echo ""
echo "=== Projects ==="
env0_api "projects?organizationId=$ORG_ID" | jq -r '.[] | "\(.name)\t\(.id)\t\(.description // "N/A")"' | head -15

echo ""
echo "=== Templates ==="
env0_api "blueprints?organizationId=$ORG_ID" | jq -r '.[] | "\(.name)\t\(.type)\t\(.repository)\t\(.isActive // true)"' | head -15

echo ""
echo "=== Active Environments ==="
env0_api "environments?organizationId=$ORG_ID&isActive=true" | jq -r '.[] | "\(.name)\t\(.status)\t\(.blueprintId)\t\(.updatedAt)"' | head -15
```

### Phase 2: Analysis

```bash
#!/bin/bash

ENV0_TOKEN="${ENV0_API_KEY:?ENV0_API_KEY required}"
ENV0_SECRET="${ENV0_API_SECRET:?ENV0_API_SECRET required}"
ENV0_API="https://api.env0.com"

env0_api() {
    curl -s -u "$ENV0_TOKEN:$ENV0_SECRET" "$ENV0_API/$1"
}

PROJECT_ID="${1:?Project ID required}"

echo "=== Project Environments ==="
env0_api "environments?projectId=$PROJECT_ID" | jq -r '.[] | "\(.name)\t\(.status)\t\(.latestDeploymentLog.status // "N/A")\t\(.updatedAt)"' | head -15

echo ""
echo "=== Deployment History ==="
env0_api "environments?projectId=$PROJECT_ID" | jq -r '.[] | .id' | head -5 | while read env_id; do
    ENV_NAME=$(env0_api "environments/$env_id" | jq -r '.name')
    echo "--- $ENV_NAME ---"
    env0_api "environments/$env_id/deployments?limit=3" | jq -r '.[] | "\(.type)\t\(.status)\t\(.startedAt)\t\(.planSummary // {})"' 2>/dev/null | head -5
done | head -25

echo ""
echo "=== Cost Tracking ==="
env0_api "costs?projectId=$PROJECT_ID" | jq '{totalMonthlyCost: .totalMonthlyCost, environments: [.environments[]? | {name: .name, cost: .monthlyCost}]}' 2>/dev/null | head -15

echo ""
echo "=== Custom Flows ==="
env0_api "custom-flows?organizationId=$(env0_api "projects/$PROJECT_ID" | jq -r '.organizationId')" | jq -r '.[]? | "\(.name)\t\(.type)\t\(.repository)"' 2>/dev/null | head -10

echo ""
echo "=== Policies ==="
env0_api "policies?projectId=$PROJECT_ID" | jq -r '.[]? | "\(.name)\t\(.type)\t\(.enabled)"' 2>/dev/null | head -10

echo ""
echo "=== Variable Sets ==="
env0_api "configuration?projectId=$PROJECT_ID&scope=PROJECT" | jq -r '.[] | "\(.name)\t\(.type)\t\(if .isSensitive then "***" else .value end)"' 2>/dev/null | head -15
```

## Output Format

```
ENV0 DEEP STATUS: <org>/<project>
Projects: <count> | Templates: <count> | Active Environments: <count>
Project: <name>
Environments: <count> (<active> active, <inactive> inactive)
Last Deployment: <status> at <timestamp>
Monthly Cost: $<amount>
Custom Flows: <count> | Policies: <count>
Variable Sets: <count> (<sensitive> sensitive)
Issues: <any failed deployments, cost overruns, policy violations, or stale environments>
```

## Safety Rules

- **NEVER destroy environments** without explicit user confirmation
- **NEVER modify sensitive variables** without confirming the value change
- **Always review deployment plans** before approving -- check plan summary for resource changes
- **Test custom flows** on non-production environments before applying organization-wide
- **Review policy enforcement** before enabling -- policies can block all deployments

## Common Pitfalls

- **TTL expiration**: Environments with TTL will auto-destroy -- verify TTL settings for important environments
- **Variable inheritance**: Organization > project > environment variable precedence -- check all levels
- **Custom flow failures**: Failed custom flow steps can block entire deployments -- check flow logs
- **Cost tracking lag**: Cost data may lag behind actual resource changes by up to 24 hours
- **Approval workflow blocking**: Required approvals can stall deployments indefinitely -- set timeout policies
- **Drift detection frequency**: Scheduled drift detection runs on a cadence -- manual runs available for immediate checks
- **Template versioning**: Pinned template versions prevent auto-updates -- review for security patches regularly
