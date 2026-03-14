---
name: managing-prefect-deep
description: |
  Prefect deep workflow orchestration management covering flow inventory, flow run monitoring, deployment health, work pool status, block configuration, automation rules, and agent/worker health checks. Use when investigating flow run failures, analyzing task concurrency, monitoring infrastructure health, or auditing Prefect configurations.
connection_type: prefect
preload: false
---

# Prefect Deep Management Skill

Manage and monitor Prefect flow orchestration, deployments, work pools, and infrastructure.

## MANDATORY: Discovery-First Pattern

**Always list flows and work pools before querying specific flow runs.**

### Phase 1: Discovery

```bash
#!/bin/bash

PREFECT_API="${PREFECT_API_URL:-https://api.prefect.cloud/api}"

prefect_api() {
    curl -s -H "Authorization: Bearer $PREFECT_API_KEY" \
         -H "Content-Type: application/json" \
         "${PREFECT_API}/accounts/${PREFECT_ACCOUNT_ID}/workspaces/${PREFECT_WORKSPACE_ID}/${1}" \
         ${2:+-d "$2"}
}

echo "=== Prefect Workspace ==="
prefect_api "" | jq '{workspace: .name, handle: .handle}'

echo ""
echo "=== Flows ==="
prefect_api "flows/filter" '{"limit": 30}' | jq -r '
    .[] |
    "\(.id)\t\(.name)\t\(.created)"
' | column -t | head -30

echo ""
echo "=== Work Pools ==="
prefect_api "work_pools/filter" '{}' | jq -r '
    .[] |
    "\(.name)\t\(.type)\t\(.status // "unknown")\t\(.is_paused)"
' | column -t

echo ""
echo "=== Deployments ==="
prefect_api "deployments/filter" '{"limit": 30}' | jq -r '
    .[] |
    "\(.name)\t\(.flow_id)\t\(.is_schedule_active)\t\(.work_pool_name // "default")"
' | column -t | head -20
```

### Phase 2: Analysis

```bash
#!/bin/bash

echo "=== Failed Flow Runs (last 24h) ==="
YESTERDAY=$(date -u -d '24 hours ago' +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -v-24H +%Y-%m-%dT%H:%M:%SZ)
prefect_api "flow_runs/filter" "{\"flow_runs\":{\"state\":{\"type\":{\"any_\":[\"FAILED\",\"CRASHED\"]}},\"start_time\":{\"after_\":\"${YESTERDAY}\"}},\"limit\":20}" | jq -r '
    .[] |
    "\(.name)\t\(.state_type)\t\(.total_task_run_count) tasks\t\(.start_time)"
' | column -t | head -20

echo ""
echo "=== Work Pool Health ==="
prefect_api "work_pools/filter" '{}' | jq -r '
    .[] |
    "\(.name)\t\(.type)\tpaused=\(.is_paused)\tlast_polled=\(.last_polled // "never")"
' | column -t

echo ""
echo "=== Late Flow Runs ==="
prefect_api "flow_runs/filter" '{"flow_runs":{"state":{"type":{"any_":["LATE"]}}}, "limit":10}' | jq -r '
    .[] |
    "\(.name)\t\(.state_type)\t\(.expected_start_time)\tDeployment: \(.deployment_id)"
' | column -t

echo ""
echo "=== Blocks ==="
prefect_api "block_documents/filter" '{"limit": 20}' | jq -r '
    .[] |
    "\(.name)\t\(.block_type.slug)\t\(.is_anonymous)"
' | column -t | head -15
```

## Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- Use state type filters to focus on problem runs
- Never dump full flow run logs -- extract state messages and error summaries

## Common Pitfalls

- **Work pool polling**: Workers must actively poll work pools -- stale last_polled indicates dead workers
- **Late runs**: LATE state means scheduled run was not picked up -- check worker availability
- **Concurrency limits**: Global and tag-based concurrency limits can cause runs to queue
- **Block secrets**: Block documents may contain credentials -- never dump full block data
- **Infrastructure mismatches**: Deployment infrastructure type must match work pool type
- **Result persistence**: Without result persistence configured, task results are lost on failure
- **Subflows**: Parent flow failures can orphan child flow runs -- check nested runs
- **Automations**: Automation rules can pause deployments or cancel runs -- review active automations
