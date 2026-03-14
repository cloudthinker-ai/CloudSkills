---
name: managing-hyperproof
description: |
  Hyperproof compliance operations platform for managing controls, evidence, risks, and audit workflows across multiple frameworks. Covers control testing, evidence automation, task management, risk register, and audit preparation. Use when reviewing control compliance, tracking evidence collection, managing compliance tasks, assessing organizational risk, or coordinating audit activities.
connection_type: hyperproof
preload: false
---

# Hyperproof Management Skill

Manage and analyze Hyperproof controls, evidence, tasks, risks, and audit workflows.

## API Conventions

### Authentication
All API calls use `Authorization: Bearer $HYPERPROOF_ACCESS_TOKEN` -- injected automatically. Never hardcode tokens.

### Base URL
`https://api.hyperproof.app/v1`

### Core Helper Function

```bash
#!/bin/bash

hp_api() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"

    if [ -n "$data" ]; then
        curl -s -X "$method" \
            -H "Authorization: Bearer $HYPERPROOF_ACCESS_TOKEN" \
            -H "Content-Type: application/json" \
            "https://api.hyperproof.app/v1${endpoint}" \
            -d "$data"
    else
        curl -s -X "$method" \
            -H "Authorization: Bearer $HYPERPROOF_ACCESS_TOKEN" \
            -H "Content-Type: application/json" \
            "https://api.hyperproof.app/v1${endpoint}"
    fi
}
```

## Output Rules
- **TOKEN EFFICIENCY**: Extract only needed fields with `jq`
- Target <=50 lines per script output
- Never dump full API responses

## Discovery Phase

```bash
#!/bin/bash
echo "=== Programs ==="
hp_api GET "/programs" \
    | jq -r '.[] | "\(.id)\t\(.name)\t\(.framework)"' | column -t | head -10

echo ""
echo "=== Controls Summary ==="
hp_api GET "/controls?pageSize=1" \
    | jq '"Total controls: \(.totalCount // (.data | length))"' -r

echo ""
echo "=== Task Summary ==="
hp_api GET "/tasks?pageSize=1&status=open" \
    | jq '"Open tasks: \(.totalCount // (.data | length))"' -r
```

## Analysis Phase

### Control Status

```bash
#!/bin/bash
PROGRAM_ID="${1:-}"

echo "=== Controls by Health ==="
ENDPOINT="/controls?pageSize=200"
[ -n "$PROGRAM_ID" ] && ENDPOINT="/programs/${PROGRAM_ID}/controls?pageSize=200"

CONTROLS=$(hp_api GET "$ENDPOINT")
echo "$CONTROLS" | jq '{
    total: (.data | length),
    healthy: ([.data[] | select(.healthStatus == "healthy")] | length),
    at_risk: ([.data[] | select(.healthStatus == "at_risk")] | length),
    unhealthy: ([.data[] | select(.healthStatus == "unhealthy")] | length),
    not_assessed: ([.data[] | select(.healthStatus == "not_assessed")] | length)
}'

echo ""
echo "=== Unhealthy Controls ==="
echo "$CONTROLS" | jq -r '.data[] | select(.healthStatus == "unhealthy" or .healthStatus == "at_risk") | "\(.healthStatus)\t\(.identifier)\t\(.name[0:45])\towner:\(.owner[0:20] // "Unassigned")"' \
    | column -t | head -15
```

### Evidence Management

```bash
#!/bin/bash
echo "=== Evidence Collection Status ==="
hp_api GET "/proofs?pageSize=200" \
    | jq '{
        total: (.data | length),
        current: ([.data[] | select(.status == "current")] | length),
        expiring_soon: ([.data[] | select(.status == "expiring_soon")] | length),
        expired: ([.data[] | select(.status == "expired")] | length),
        missing: ([.data[] | select(.status == "missing")] | length)
    }'

echo ""
echo "=== Expired/Missing Evidence ==="
hp_api GET "/proofs?pageSize=50&status=expired,missing" \
    | jq -r '.data[] | "\(.status)\t\(.name[0:35])\tcontrol:\(.controlIdentifier)\tdue:\(.dueDate[0:10] // "N/A")"' \
    | column -t | head -15
```

### Task Tracking

```bash
#!/bin/bash
echo "=== Open Tasks by Priority ==="
hp_api GET "/tasks?pageSize=100&status=open" \
    | jq -r '[.data[].priority] | group_by(.) | map({priority: .[0], count: length}) | sort_by(.count) | reverse | .[] | "\(.priority): \(.count)"'

echo ""
echo "=== Overdue Tasks ==="
hp_api GET "/tasks?pageSize=50&status=open&overdue=true" \
    | jq -r '.data[] | "\(.priority)\t\(.name[0:40])\tassignee:\(.assignee[0:20] // "Unassigned")\tdue:\(.dueDate[0:10])"' \
    | column -t | head -15
```

### Risk Register

```bash
#!/bin/bash
echo "=== Risk Summary ==="
hp_api GET "/risks?pageSize=100" \
    | jq '{
        total: (.data | length),
        by_level: ([.data[].riskLevel] | group_by(.) | map({level: .[0], count: length}))
    }'

echo ""
echo "=== High/Critical Risks ==="
hp_api GET "/risks?pageSize=50&riskLevel=high,critical" \
    | jq -r '.data[] | "\(.riskLevel)\t\(.name[0:40])\tstatus:\(.treatmentStatus)\towner:\(.owner[0:20] // "Unassigned")"' \
    | column -t | head -15
```

## Common Pitfalls

- **Program scoping**: Most queries can be scoped to a program -- include program ID for framework-specific views
- **Health vs status**: Controls have `healthStatus` (automated) and manual assessment status
- **Pagination**: Use `pageSize` and `page` -- check `totalCount` in response
- **Rate limits**: Check response headers for rate limiting
- **Proof vs evidence**: Hyperproof uses "proofs" terminology for evidence artifacts
- **OAuth2 tokens**: Access tokens expire -- refresh via OAuth2 token endpoint
