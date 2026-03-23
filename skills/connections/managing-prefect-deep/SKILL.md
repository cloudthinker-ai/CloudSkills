---
name: managing-prefect-deep
description: |
  Use when working with Prefect Deep — prefect deep workflow orchestration
  management covering flow inventory, flow run monitoring, deployment health,
  work pool status, block configuration, automation rules, and agent/worker
  health checks. Use when investigating flow run failures, analyzing task
  concurrency, monitoring infrastructure health, or auditing Prefect
  configurations.
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

## Output Format

Present results as a structured report:
```
Managing Prefect Deep Report
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

- **Work pool polling**: Workers must actively poll work pools -- stale last_polled indicates dead workers
- **Late runs**: LATE state means scheduled run was not picked up -- check worker availability
- **Concurrency limits**: Global and tag-based concurrency limits can cause runs to queue
- **Block secrets**: Block documents may contain credentials -- never dump full block data
- **Infrastructure mismatches**: Deployment infrastructure type must match work pool type
- **Result persistence**: Without result persistence configured, task results are lost on failure
- **Subflows**: Parent flow failures can orphan child flow runs -- check nested runs
- **Automations**: Automation rules can pause deployments or cancel runs -- review active automations
