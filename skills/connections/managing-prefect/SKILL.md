---
name: managing-prefect
description: |
  Use when working with Prefect — prefect workflow orchestration platform
  management. Covers flow run monitoring, deployment management, work pool
  status, automation rules, block configuration, and agent health. Use when
  checking flow run status, investigating failures, managing deployments, or
  auditing Prefect infrastructure.
connection_type: prefect
preload: false
---

# Prefect Management Skill

Manage and monitor Prefect flows, deployments, and orchestration infrastructure via the Prefect API.

## MANDATORY: Discovery-First Pattern

**Always list deployments and work pools before querying specific flow runs.**

### Phase 1: Discovery

```bash
#!/bin/bash

prefect_api() {
    local method="${1:-GET}"
    local endpoint="$2"
    local data="${3:-}"

    if [ -n "$data" ]; then
        curl -s -X "$method" \
            -H "Authorization: Bearer ${PREFECT_API_KEY}" \
            -H "Content-Type: application/json" \
            "${PREFECT_API_URL}/api/${endpoint}" \
            -d "$data"
    else
        curl -s -X "$method" \
            -H "Authorization: Bearer ${PREFECT_API_KEY}" \
            "${PREFECT_API_URL}/api/${endpoint}"
    fi
}

echo "=== Work Pools ==="
prefect_api POST "work_pools/filter" '{}' | jq -r '
    .[] | "\(.name)\t\(.type)\t\(.status // "unknown")\t\(.concurrency_limit // "unlimited")"
' | column -t

echo ""
echo "=== Deployments ==="
prefect_api POST "deployments/filter" '{"limit": 30}' | jq -r '
    .[] | "\(.name)\t\(.flow_name // "?")\t\(if .is_schedule_active then "ACTIVE" else "PAUSED" end)\t\(.work_pool_name // "default")"
' | column -t | head -30

echo ""
echo "=== Recent Flow Runs ==="
prefect_api POST "flow_runs/filter" '{"sort": "START_TIME_DESC", "limit": 15}' | jq -r '
    .[] | "\(.id[0:8])\t\(.name)\t\(.state_type)\t\(.start_time[0:16] // "pending")"
' | column -t
```

## Core Helper Functions

```bash
#!/bin/bash

prefect_api() {
    local method="${1:-GET}"
    local endpoint="$2"
    local data="${3:-}"

    if [ -n "$data" ]; then
        curl -s -X "$method" \
            -H "Authorization: Bearer ${PREFECT_API_KEY}" \
            -H "Content-Type: application/json" \
            "${PREFECT_API_URL}/api/${endpoint}" \
            -d "$data"
    else
        curl -s -X "$method" \
            -H "Authorization: Bearer ${PREFECT_API_KEY}" \
            "${PREFECT_API_URL}/api/${endpoint}"
    fi
}
```

## Output Rules
- **TOKEN EFFICIENCY**: Target ≤50 lines per output
- Prefect 2.x API uses POST with filter bodies for listing — not GET with query params
- Use `sort` and `limit` in filter bodies to control output size

## Common Operations

### Flow Run Dashboard

```bash
#!/bin/bash
echo "=== Flow Run Summary (last 24h) ==="
SINCE=$(date -u -d '24 hours ago' +%Y-%m-%dT%H:%M:%SZ)
prefect_api POST "flow_runs/filter" "{\"flow_runs\": {\"start_time\": {\"after_\": \"${SINCE}\"}}, \"limit\": 200}" | jq '
    group_by(.state_type) | map({state: .[0].state_type, count: length}) |
    sort_by(-.count) | .[] | "\(.state): \(.count)"
' -r

echo ""
echo "=== Failed Flow Runs ==="
prefect_api POST "flow_runs/filter" "{\"flow_runs\": {\"state\": {\"type\": {\"any_\": [\"FAILED\"]}}}, \"sort\": \"START_TIME_DESC\", \"limit\": 10}" | jq -r '
    .[] | "\(.id[0:8])\t\(.name)\t\(.state_name)\t\(.start_time[0:16])\t\(.total_task_run_count) tasks"
' | column -t

echo ""
echo "=== Late / Pending Runs ==="
prefect_api POST "flow_runs/filter" "{\"flow_runs\": {\"state\": {\"type\": {\"any_\": [\"PENDING\", \"SCHEDULED\"]}}}, \"limit\": 10}" | jq -r '
    .[] | "\(.id[0:8])\t\(.name)\t\(.state_name)\t\(.expected_start_time[0:16] // "?")"
' | column -t
```

### Deployment Management

```bash
#!/bin/bash
echo "=== Active Deployments ==="
prefect_api POST "deployments/filter" '{"deployments": {"is_schedule_active": {"eq_": true}}, "limit": 20}' | jq -r '
    .[] | "\(.id[0:8])\t\(.name)\t\(.flow_name)\t\(.schedule.cron // .schedule.interval // "custom")\t\(.work_pool_name // "default")"
' | column -t

echo ""
echo "=== Paused Deployments ==="
prefect_api POST "deployments/filter" '{"deployments": {"is_schedule_active": {"eq_": false}}, "limit": 20}' | jq -r '
    .[] | "\(.id[0:8])\t\(.name)\t\(.flow_name)"
' | column -t

echo ""
echo "=== Deployment Run History ==="
DEPLOYMENT_ID="${1:-}"
if [ -n "$DEPLOYMENT_ID" ]; then
    prefect_api POST "flow_runs/filter" "{\"deployments\": {\"id\": {\"any_\": [\"${DEPLOYMENT_ID}\"]}}, \"sort\": \"START_TIME_DESC\", \"limit\": 10}" | jq -r '
        .[] | "\(.id[0:8])\t\(.state_type)\t\(.start_time[0:16])\t\(.total_task_run_count) tasks"
    ' | column -t
fi
```

### Work Pool and Worker Status

```bash
#!/bin/bash
echo "=== Work Pool Details ==="
prefect_api POST "work_pools/filter" '{}' | jq -r '
    .[] | "\(.name)\t\(.type)\t\(.is_paused)\tconcurrency=\(.concurrency_limit // "unlimited")"
' | column -t

echo ""
echo "=== Work Queues ==="
prefect_api POST "work_pools/filter" '{}' | jq -r '.[].name' | while read pool; do
    prefect_api POST "work_pools/${pool}/queues/filter" '{}' | jq -r --arg pool "$pool" '
        .[]? | "\($pool)\t\(.name)\t\(.is_paused)\tpriority=\(.priority)\tconcurrency=\(.concurrency_limit // "unlimited")"
    '
done | column -t

echo ""
echo "=== Workers (last seen) ==="
prefect_api POST "work_pools/filter" '{}' | jq -r '.[].name' | while read pool; do
    prefect_api GET "work_pools/${pool}/workers/filter" 2>/dev/null | jq -r --arg pool "$pool" '
        .[]? | "\($pool)\t\(.name)\t\(.last_heartbeat_time[0:16] // "never")\t\(.status // "unknown")"
    ' 2>/dev/null
done | column -t
```

### Automation Rules

```bash
#!/bin/bash
echo "=== Automations ==="
prefect_api POST "automations/filter" '{}' | jq -r '
    .[] | "\(.id[0:8])\t\(.name)\t\(if .enabled then "ENABLED" else "DISABLED" end)\t\(.trigger.type // "unknown")"
' | column -t | head -20

echo ""
echo "=== Automation Actions ==="
prefect_api POST "automations/filter" '{}' | jq -r '
    .[] | "\(.name)\ttrigger=\(.trigger.type // "?")\taction=\(.actions[0].type // "?")"
' | column -t | head -15
```

### Flow and Task Run Details

```bash
#!/bin/bash
FLOW_RUN_ID="${1:?Flow Run ID required}"

echo "=== Flow Run Details ==="
prefect_api GET "flow_runs/${FLOW_RUN_ID}" | jq '{
    id: .id,
    name: .name,
    state: .state_type,
    state_name: .state_name,
    start_time: .start_time,
    end_time: .end_time,
    total_task_runs: .total_task_run_count,
    deployment_id: .deployment_id
}'

echo ""
echo "=== Task Runs ==="
prefect_api POST "task_runs/filter" "{\"flow_runs\": {\"id\": {\"any_\": [\"${FLOW_RUN_ID}\"]}}, \"sort\": \"START_TIME_ASC\"}" | jq -r '
    .[] | "\(.name)\t\(.state_type)\t\(.start_time[0:16] // "?")\t\(.total_run_time // 0 | floor)s"
' | column -t | head -20
```

## Output Format

Present results as a structured report:
```
Managing Prefect Report
═══════════════════════
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

- **Prefect 1 vs 2**: APIs are completely different — Prefect 2 uses filter-based POST endpoints, Prefect 1 uses GraphQL
- **State types**: `COMPLETED`, `FAILED`, `CANCELLED`, `PENDING`, `RUNNING`, `SCHEDULED`, `CRASHED` — `CRASHED` means infrastructure failure
- **Work pools vs agents**: Prefect 2.x uses work pools; agents are deprecated — check which model is in use
- **Filter syntax**: Prefect filters use `any_`, `eq_`, `before_`, `after_` operators — not standard comparison
- **Concurrency limits**: Work pool and queue concurrency limits are independent — both apply
- **Schedule active flag**: `is_schedule_active: false` pauses the schedule but allows manual triggers
- **Task run state**: Task runs can succeed while the parent flow run fails (e.g., if the flow has post-task logic)
- **Block references**: Deployments reference blocks (storage, infrastructure) — missing blocks cause deployment failures
- **Cloud vs Server**: Prefect Cloud requires API key auth; self-hosted Prefect Server may not require auth
