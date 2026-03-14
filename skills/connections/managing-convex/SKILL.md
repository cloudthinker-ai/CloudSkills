---
name: managing-convex
description: |
  Convex backend platform management covering project inventory, table schemas, function deployments, scheduled job status, index configuration, environment variable auditing, and usage metrics. Use for comprehensive Convex project health and resource optimization.
connection_type: convex
preload: false
---

# Convex Management

Analyze Convex projects, tables, functions, scheduled jobs, and deployment health.

## Phase 1: Discovery

```bash
#!/bin/bash
TOKEN="${CONVEX_DEPLOY_KEY}"
DEPLOY_URL="${CONVEX_URL}"
AUTH=(-H "Authorization: Convex ${TOKEN}" -H "Content-Type: application/json")

echo "=== Deployment Info ==="
curl -s "${DEPLOY_URL}/api/get_deployment_info" "${AUTH[@]}" \
  | jq -r '"Project: \(.projectSlug)\tTeam: \(.teamSlug)\tStatus: \(.deploymentState)"' \
  | column -t

echo ""
echo "=== Tables ==="
curl -s "${DEPLOY_URL}/api/list_tables" "${AUTH[@]}" \
  | jq -r '.[] | "\(.name)\t\(.documentCount // "N/A") docs\t\(.sizeBytes // "N/A") bytes"' \
  | column -t | head -20

echo ""
echo "=== Functions ==="
curl -s "${DEPLOY_URL}/api/list_functions" "${AUTH[@]}" \
  | jq -r '.[] | "\(.name)\t\(.type)\t\(.visibility)"' \
  | column -t | head -30

echo ""
echo "=== Indexes ==="
curl -s "${DEPLOY_URL}/api/list_indexes" "${AUTH[@]}" \
  | jq -r '.[] | "\(.table)\t\(.name)\t\(.fields | join(","))\t\(.status)"' \
  | column -t | head -20
```

## Phase 2: Analysis

```bash
#!/bin/bash
TOKEN="${CONVEX_DEPLOY_KEY}"
DEPLOY_URL="${CONVEX_URL}"
AUTH=(-H "Authorization: Convex ${TOKEN}" -H "Content-Type: application/json")

echo "=== Scheduled Jobs ==="
curl -s "${DEPLOY_URL}/api/list_scheduled_jobs" "${AUTH[@]}" \
  | jq -r '.[] | "\(.name)\t\(.state)\t\(.scheduledTime)\t\(.completedTime // \"pending\")"' \
  | column -t | head -20

echo ""
echo "=== Cron Jobs ==="
curl -s "${DEPLOY_URL}/api/list_cron_jobs" "${AUTH[@]}" \
  | jq -r '.[] | "\(.name)\t\(.schedule)\t\(.lastRun // \"never\")\t\(.nextRun)"' \
  | column -t | head -10

echo ""
echo "=== Environment Variables (names only) ==="
curl -s "${DEPLOY_URL}/api/list_environment_variables" "${AUTH[@]}" \
  | jq -r '.[].name' | while read -r name; do echo "  ${name}"; done

echo ""
echo "=== Usage Metrics ==="
curl -s "${DEPLOY_URL}/api/usage" "${AUTH[@]}" \
  | jq '{function_calls: .functionCalls, database_bandwidth: .databaseBandwidth, storage_bandwidth: .storageBandwidth, action_compute: .actionCompute}' 2>/dev/null

echo ""
echo "=== Recent Deployments ==="
curl -s "${DEPLOY_URL}/api/list_deployments" "${AUTH[@]}" \
  | jq -r '.[:5][] | "\(.id[0:8])\t\(.status)\t\(.startTime)\t\(.endTime // \"in-progress\")"' \
  | column -t | head -10
```

## Output Format

```
CONVEX ANALYSIS
=================
Table            Documents    Size       Indexes   Functions
──────────────────────────────────────────────────────────────
users            5,240        12MB       3         8 (query/mutation)
messages         124,500      89MB       5         12 (query/mutation/action)
sessions         2,100        3MB        2         4 (query/mutation)

Functions: 24 total (10 queries, 8 mutations, 6 actions)
Cron Jobs: 3 active | Scheduled: 2 pending
Env Vars: 8 configured | Deployments: 5 recent (all successful)
```

## Safety Rules

- **Read-only**: Only use list/get API endpoints
- **Never run mutations**, delete tables, or modify indexes without confirmation
- **Environment variables**: Never output values, only names
- **Deploy keys**: Never expose deploy key values in output
