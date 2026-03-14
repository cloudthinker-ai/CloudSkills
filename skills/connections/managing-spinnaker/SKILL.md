---
name: managing-spinnaker
description: |
  Spinnaker continuous delivery and infrastructure management. Covers application deployment, pipeline management, infrastructure views, server group operations, load balancer configuration, and canary analysis. Use when checking deployment status, managing pipelines, investigating rollback scenarios, or auditing Spinnaker applications.
connection_type: spinnaker
preload: false
---

# Spinnaker Management Skill

Manage and monitor Spinnaker applications, pipelines, and infrastructure deployments.

## Core Helper Functions

```bash
#!/bin/bash

# Spinnaker Gate API helper
spin_api() {
    local method="${1:-GET}"
    local endpoint="$2"
    local data="${3:-}"

    if [ -n "$data" ]; then
        curl -s -X "$method" \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer ${SPINNAKER_TOKEN}" \
            "${SPINNAKER_GATE_URL}/${endpoint}" \
            -d "$data"
    else
        curl -s -X "$method" \
            -H "Authorization: Bearer ${SPINNAKER_TOKEN}" \
            "${SPINNAKER_GATE_URL}/${endpoint}"
    fi
}

# Spinnaker CLI wrapper
spin_cmd() {
    spin "$@" --gate-endpoint "${SPINNAKER_GATE_URL}" 2>/dev/null
}
```

## MANDATORY: Discovery-First Pattern

**Always list applications and pipelines before querying specific resources.**

### Phase 1: Discovery

```bash
#!/bin/bash

echo "=== Spinnaker Applications ==="
spin_api GET "applications" | jq -r '
    .[] | "\(.name)\t\(.email // "no-owner")\t\(.cloudProviders // "unknown")\taccounts=\(.accounts // "default")"
' | column -t | head -20

echo ""
echo "=== Application Summary ==="
APP_NAME="${1:-}"
if [ -n "$APP_NAME" ]; then
    spin_api GET "applications/${APP_NAME}" | jq '{
        name, email, cloudProviders,
        pipelines: (.attributes.pipelines // [] | length),
        accounts: .accounts
    }'
fi

echo ""
echo "=== Active Executions ==="
spin_api GET "executions?limit=15" 2>/dev/null || \
    spin_api GET "applications/${APP_NAME}/pipelines?limit=10&statuses=RUNNING" | jq -r '
    .[] | "\(.application)\t\(.name)\t\(.status)\t\(.startTime / 1000 | strftime("%Y-%m-%d %H:%M"))"
' | column -t
```

## Output Rules
- **TOKEN EFFICIENCY**: Target 50 lines per output
- Use `expand=false` to reduce payload size when listing
- Never dump full pipeline configs — extract key stages

## Common Operations

### Pipeline Management

```bash
#!/bin/bash
APP_NAME="${1:?Application name required}"

echo "=== Application Pipelines ==="
spin_api GET "applications/${APP_NAME}/pipelineConfigs" | jq -r '
    .[] | "\(.id[0:8])\t\(.name)\tstages=\(.stages | length)\ttriggers=\(.triggers | length)\tdisabled=\(.disabled // false)"
' | column -t

echo ""
echo "=== Recent Pipeline Executions ==="
spin_api GET "applications/${APP_NAME}/pipelines?limit=15" | jq -r '
    .[] |
    "\(.name)\t\(.status)\t\(.startTime / 1000 | strftime("%Y-%m-%d %H:%M"))\ttrigger=\(.trigger.type)"
' | column -t

echo ""
echo "=== Failed Executions ==="
spin_api GET "applications/${APP_NAME}/pipelines?limit=20&statuses=TERMINAL" | jq -r '
    .[] |
    "\(.name)\t\(.startTime / 1000 | strftime("%Y-%m-%d %H:%M"))\tfailedStage=\([.stages[] | select(.status == "TERMINAL")][0].name // "unknown")"
' | column -t
```

### Pipeline Execution Analysis

```bash
#!/bin/bash
EXECUTION_ID="${1:?Execution ID required}"

echo "=== Execution Details ==="
spin_api GET "pipelines/${EXECUTION_ID}" | jq '{
    application, name, status,
    trigger_type: .trigger.type,
    start: (.startTime / 1000 | strftime("%Y-%m-%d %H:%M")),
    end: ((.endTime // 0) / 1000 | if . > 0 then strftime("%Y-%m-%d %H:%M") else "running" end),
    stages: [.stages[] | {name, status, type}]
}'

echo ""
echo "=== Failed Stages ==="
spin_api GET "pipelines/${EXECUTION_ID}" | jq -r '
    .stages[] | select(.status == "TERMINAL" or .status == "FAILED_CONTINUE") |
    "Stage: \(.name)\nType: \(.type)\nError: \(.context.exception.details.error // .context.failureMessage // "unknown")[0:100]\n---"
'
```

### Infrastructure View

```bash
#!/bin/bash
APP_NAME="${1:?Application name required}"

echo "=== Server Groups ==="
spin_api GET "applications/${APP_NAME}/serverGroups?expand=false" | jq -r '
    .[] |
    "\(.name)\t\(.region)\t\(.type)\tinstances=\(.instances | length)\tenabled=\(!.disabled)"
' | column -t | head -20

echo ""
echo "=== Load Balancers ==="
spin_api GET "applications/${APP_NAME}/loadBalancers" | jq -r '
    .[] | "\(.name)\t\(.type)\t\(.region // "global")\taccount=\(.account)"
' | column -t

echo ""
echo "=== Security Groups ==="
spin_api GET "applications/${APP_NAME}/firewalls" | jq -r '
    .[] | "\(.name)\t\(.type)\t\(.region // "global")\taccount=\(.accountName // .account)"
' | column -t | head -15
```

### Deployment Operations

```bash
#!/bin/bash
APP_NAME="${1:?Application name required}"
ACTION="${2:-status}"  # status, rollback-info

case "$ACTION" in
    "status")
        echo "=== Current Deployments ==="
        spin_api GET "applications/${APP_NAME}/serverGroups?expand=true" | jq -r '
            group_by(.cluster) | .[] |
            "Cluster: \(.[0].cluster)",
            (.[] | "  \(.name)\tinstances=\(.instances | length)\tstatus=\(if .disabled then "DISABLED" else "ENABLED" end)")
        '
        ;;
    "rollback-info")
        echo "=== Rollback Candidates ==="
        spin_api GET "applications/${APP_NAME}/serverGroups?expand=false" | jq -r '
            group_by(.cluster) | .[] | select(length > 1) |
            "Cluster: \(.[0].cluster)",
            (.[] | "  \(.name)\tenabled=\(!.disabled)\tinstances=\(.instances | length)")
        '
        ;;
esac
```

### Canary Analysis

```bash
#!/bin/bash
APP_NAME="${1:?Application name required}"

echo "=== Canary Configs ==="
spin_api GET "v2/canaries/canaryConfig" | jq -r '
    .[] | select(.applications[] == "'"$APP_NAME"'" or .applications == null) |
    "\(.id[0:8])\t\(.name)\tmetrics=\(.metrics | length)"
' | column -t

echo ""
echo "=== Recent Canary Runs ==="
spin_api GET "applications/${APP_NAME}/pipelines?limit=10" | jq -r '
    .[] | .stages[] | select(.type == "kayentaCanary") |
    "\(.name)\t\(.status)\tscore=\(.context.canaryScore // "pending")"
' | column -t
```

## Anti-Hallucination Rules
- NEVER guess application names — always list applications first
- NEVER fabricate execution IDs — query pipeline executions
- NEVER assume cloud provider or account — discover from application config
- Pipeline stage types vary by provider — check pipeline config before assuming

## Safety Rules
- NEVER trigger pipeline executions without explicit user confirmation
- NEVER disable server groups without user approval — causes outages
- NEVER scale down to zero without confirming intent
- NEVER modify pipeline configs without understanding all stages — stages may have side effects

## Common Pitfalls
- **Gate URL**: All API calls go through Gate (Spinnaker's API gateway) — ensure correct URL
- **Execution statuses**: `SUCCEEDED`, `TERMINAL` (failed), `RUNNING`, `PAUSED`, `CANCELED`, `NOT_STARTED`
- **Server group naming**: Follows `app-stack-detail-vNNN` convention — version numbers are auto-incremented
- **Manual judgment**: Pipelines may pause at manual judgment stages — check for `PAUSED` status
- **Bake vs Find**: Bake stage creates AMI/image; Find stage uses existing — different failure modes
- **Cloud provider differences**: AWS, GCP, K8s providers have different resource types and operations
- **Pipeline templates**: Inherited templates may override local config — check template source
