---
name: managing-thoropass
description: |
  Thoropass (formerly Laika) compliance automation and audit management platform for SOC 2, ISO 27001, HIPAA, and PCI DSS. Covers control monitoring, evidence management, audit workflows, policy tracking, and readiness assessment. Use when reviewing compliance control status, managing evidence collection, tracking audit progress, monitoring policy compliance, or assessing audit readiness.
connection_type: thoropass
preload: false
---

# Thoropass Management Skill

Manage and analyze Thoropass compliance controls, evidence, audits, and readiness posture.

## API Conventions

### Authentication
All API calls use `Authorization: Bearer $THOROPASS_API_TOKEN` -- injected automatically. Never hardcode tokens.

### Base URL
`https://api.thoropass.com/v1`

### Core Helper Function

```bash
#!/bin/bash

thoropass_api() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"

    if [ -n "$data" ]; then
        curl -s -X "$method" \
            -H "Authorization: Bearer $THOROPASS_API_TOKEN" \
            -H "Content-Type: application/json" \
            "https://api.thoropass.com/v1${endpoint}" \
            -d "$data"
    else
        curl -s -X "$method" \
            -H "Authorization: Bearer $THOROPASS_API_TOKEN" \
            -H "Content-Type: application/json" \
            "https://api.thoropass.com/v1${endpoint}"
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
echo "=== Frameworks ==="
thoropass_api GET "/frameworks" \
    | jq -r '.data[] | "\(.id)\t\(.name)\t\(.status)"' | column -t | head -10

echo ""
echo "=== Controls Summary ==="
thoropass_api GET "/controls?limit=1" \
    | jq '"Total controls: \(.meta.total // "N/A")"' -r

echo ""
echo "=== Active Audits ==="
thoropass_api GET "/audits" \
    | jq -r '.data[] | "\(.id)\t\(.frameworkName)\t\(.status)\t\(.auditPeriod // "N/A")"' | column -t | head -5
```

## Analysis Phase

### Control Status

```bash
#!/bin/bash
echo "=== Controls by Status ==="
CONTROLS=$(thoropass_api GET "/controls?limit=200")
echo "$CONTROLS" | jq '{
    total: (.data | length),
    implemented: ([.data[] | select(.status == "implemented")] | length),
    not_implemented: ([.data[] | select(.status == "not_implemented")] | length),
    in_progress: ([.data[] | select(.status == "in_progress")] | length),
    not_applicable: ([.data[] | select(.status == "not_applicable")] | length)
}'

echo ""
echo "=== Controls Not Implemented ==="
echo "$CONTROLS" | jq -r '.data[] | select(.status == "not_implemented") | "\(.status)\t\(.name[0:45])\t\(.framework[0:15])\towner:\(.owner[0:20] // "Unassigned")"' \
    | column -t | head -15

echo ""
echo "=== Implementation Progress by Framework ==="
echo "$CONTROLS" | jq -r '[.data[] | {fw: .framework, s: .status}] | group_by(.fw) | map({fw: .[0].fw[0:20], total: length, done: ([.[] | select(.s == "implemented")] | length)}) | .[] | "\(.fw)\t\(.done)/\(.total)\t\((.done * 100 / .total | floor))%"' | column -t
```

### Evidence Management

```bash
#!/bin/bash
echo "=== Evidence Collection ==="
thoropass_api GET "/evidence?limit=200" \
    | jq '{
        total: (.data | length),
        collected: ([.data[] | select(.status == "collected")] | length),
        pending: ([.data[] | select(.status == "pending")] | length),
        rejected: ([.data[] | select(.status == "rejected")] | length)
    }'

echo ""
echo "=== Pending Evidence ==="
thoropass_api GET "/evidence?limit=50&status=pending" \
    | jq -r '.data[] | "\(.controlName[0:30])\t\(.name[0:35])\towner:\(.assignee[0:20] // "Unassigned")"' \
    | column -t | head -15

echo ""
echo "=== Rejected Evidence ==="
thoropass_api GET "/evidence?limit=20&status=rejected" \
    | jq -r '.data[] | "\(.controlName[0:30])\t\(.name[0:30])\treason:\(.rejectionReason[0:30] // "N/A")"' | column -t
```

### Audit Progress

```bash
#!/bin/bash
echo "=== Audit Status ==="
thoropass_api GET "/audits" \
    | jq -r '.data[] | "\(.frameworkName)\t\(.status)\tprogress:\(.completionPercentage // 0)%\tauditor:\(.auditorName // "TBD")"' | column -t

echo ""
echo "=== Audit Findings ==="
AUDIT_ID=$(thoropass_api GET "/audits" | jq -r '.data[0].id // empty')
if [ -n "$AUDIT_ID" ]; then
    thoropass_api GET "/audits/${AUDIT_ID}/findings?limit=20" \
        | jq -r '.data[] | "\(.severity)\t\(.status)\t\(.description[0:50])"' | column -t | head -15
fi

echo ""
echo "=== Audit Requests ==="
if [ -n "$AUDIT_ID" ]; then
    thoropass_api GET "/audits/${AUDIT_ID}/requests?limit=20&status=open" \
        | jq -r '.data[] | "\(.status)\t\(.description[0:50])\tdue:\(.dueDate[0:10] // "N/A")"' | column -t | head -10
fi
```

### Policy Tracking

```bash
#!/bin/bash
echo "=== Policy Status ==="
thoropass_api GET "/policies?limit=100" \
    | jq -r '.data[] | "\(.status)\t\(.name[0:40])\tversion:\(.version // "N/A")\tlastUpdated:\(.updatedAt[0:10] // "N/A")"' \
    | sort | column -t | head -15

echo ""
echo "=== Policies Pending Review ==="
thoropass_api GET "/policies?limit=50&status=pending_review" \
    | jq -r '.data[] | "\(.name[0:40])\towner:\(.owner[0:20] // "Unassigned")\tdue:\(.reviewDueDate[0:10] // "N/A")"' | column -t
```

## Common Pitfalls

- **Audit-centric workflow**: Thoropass combines compliance automation with audit management
- **Evidence review**: Evidence goes through auditor review -- check for rejected items
- **Pagination**: Use `limit` and `offset` -- check `meta.total`
- **Rate limits**: Check response headers for rate limiting
- **Audit period scoping**: Evidence and controls may be scoped to specific audit periods
- **Auditor requests**: During audits, auditors create requests that need attention
