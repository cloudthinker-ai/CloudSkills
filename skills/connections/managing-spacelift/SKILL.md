---
name: managing-spacelift
description: |
  Spacelift IaC management platform. Covers stack management, run history, policy evaluation, drift detection, module registry, and worker pool monitoring. Use when managing Spacelift stacks, investigating run failures, reviewing policies, or auditing infrastructure deployments.
connection_type: spacelift
preload: false
---

# Spacelift Management Skill

Manage and inspect Spacelift stacks, runs, policies, and infrastructure deployments.

## MANDATORY: Discovery-First Pattern

**Always list stacks and check account status before triggering runs.**

### Phase 1: Discovery

```bash
#!/bin/bash

echo "=== Spacelift Account Info ==="
spacectl profile current 2>/dev/null

echo ""
echo "=== Stacks Summary ==="
spacectl stack list --output json 2>/dev/null | jq '
    {
        total: length,
        by_state: (group_by(.state) | map({state: .[0].state, count: length})),
        by_vendor: (group_by(.vendor) | map({vendor: .[0].vendor, count: length}))
    }
' || spacectl stack list 2>/dev/null | head -20

echo ""
echo "=== Worker Pools ==="
spacectl worker-pool list 2>/dev/null | head -10
```

## Core Helper Functions

```bash
#!/bin/bash

# Spacelift CLI wrapper
sp_cmd() {
    spacectl "$@" 2>/dev/null
}

# Spacelift GraphQL API
sp_api() {
    local query="$1"
    curl -s -H "Authorization: Bearer $SPACELIFT_API_TOKEN" \
        -H "Content-Type: application/json" \
        -d "{\"query\": \"$query\"}" \
        "https://${SPACELIFT_API_ENDPOINT}/graphql"
}
```

## Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- Use `--output json` with jq for structured output
- Use GraphQL API for complex queries
- Never dump full run logs -- extract summaries and errors

## Common Operations

### Stack Management

```bash
#!/bin/bash
STACK="${1:-}"

if [ -n "$STACK" ]; then
    echo "=== Stack Details: $STACK ==="
    spacectl stack show --id "$STACK" --output json 2>/dev/null | jq '{
        name: .name,
        state: .state,
        branch: .branch,
        repository: .repository,
        vendor: .vendor,
        space: .space,
        worker_pool: .worker_pool,
        autodeploy: .autodeploy,
        labels: .labels
    }'
else
    echo "=== All Stacks ==="
    spacectl stack list --output json 2>/dev/null | jq -r '
        .[] | "\(.id)\t\(.state)\t\(.vendor)\t\(.branch)"
    ' | column -t | head -30
fi
```

### Run History and Inspection

```bash
#!/bin/bash
STACK="${1:?Stack ID required}"

echo "=== Recent Runs ==="
spacectl stack runs --id "$STACK" --output json 2>/dev/null | jq '
    .[0:10][] | {
        id: .id,
        type: .type,
        state: .state,
        created_at: .created_at,
        triggered_by: .triggered_by,
        changes: .changes
    }
'

echo ""
echo "=== Last Failed Run ==="
spacectl stack runs --id "$STACK" --output json 2>/dev/null | jq '
    [.[] | select(.state == "FAILED")] | first // "No failures"
'
```

### Policy Evaluation

```bash
#!/bin/bash
echo "=== Policies ==="
spacectl policy list --output json 2>/dev/null | jq -r '
    .[] | "\(.id)\t\(.type)\t\(.name)\t\(.space)"
' | column -t | head -20

echo ""
echo "=== Policy Types ==="
spacectl policy list --output json 2>/dev/null | jq '
    group_by(.type) | map({type: .[0].type, count: length})
'

echo ""
STACK="${1:-}"
if [ -n "$STACK" ]; then
    echo "=== Policies Attached to $STACK ==="
    spacectl stack show --id "$STACK" --output json 2>/dev/null | jq '.policies'
fi
```

### Drift Detection

```bash
#!/bin/bash
echo "=== Stacks with Drift ==="
spacectl stack list --output json 2>/dev/null | jq -r '
    .[] | select(.state == "DRIFTED") |
    "\(.id)\t\(.name)\t\(.state)\t\(.drifted_at // "unknown")"
' | column -t

echo ""
echo "=== Drift Schedule ==="
spacectl stack list --output json 2>/dev/null | jq -r '
    .[] | select(.drift_detection_schedule != null) |
    "\(.id)\t\(.drift_detection_schedule)"
' | column -t | head -15
```

### Trigger Run

```bash
#!/bin/bash
STACK="${1:?Stack ID required}"
DRY_RUN="${2:-true}"

if [ "$DRY_RUN" = "true" ]; then
    echo "=== Current Stack State ==="
    spacectl stack show --id "$STACK" --output json 2>/dev/null | jq '{state: .state, branch: .branch, autodeploy: .autodeploy}'
    echo ""
    echo "To trigger a run, confirm with dry_run=false"
else
    echo "=== Triggering Run for $STACK ==="
    spacectl stack run trigger --id "$STACK" --tail 2>&1 | tail -20
fi
```

## Safety Rules

- **NEVER trigger runs on production stacks without review** -- check stack autodeploy settings
- **Review policy evaluations** before confirming applies
- **Worker pool capacity** -- check worker availability before triggering multiple runs
- **Administrative stacks** manage other stacks -- changes cascade
- **Use approval policies** for production stack applies

## Common Pitfalls

- **API token scope**: Tokens are scoped to spaces -- ensure token has access to target stack's space
- **Autodeploy chains**: Stacks with autodeploy trigger automatically on dependency changes -- can cascade
- **Context attachments**: Missing contexts cause variable/secret resolution failures at runtime
- **Worker pool drain**: Private worker pools can become overwhelmed -- check queue depth
- **Policy sampling**: Plan policies evaluate on proposed changes -- they cannot see runtime values
- **Stack dependencies**: Deleting a stack that others depend on breaks the dependency chain
- **Drift detection timing**: Drift runs consume worker capacity -- schedule during low-traffic periods
- **Space inheritance**: Policies attached to parent spaces inherit to child spaces -- check effective policies
