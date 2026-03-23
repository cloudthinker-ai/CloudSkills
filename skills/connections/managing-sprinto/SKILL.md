---
name: managing-sprinto
description: |
  Use when working with Sprinto — sprinto compliance automation platform for SOC
  2, ISO 27001, HIPAA, GDPR, and PCI DSS. Covers automated check monitoring,
  entity management, policy tracking, training compliance, and audit readiness.
  Use when reviewing compliance check results, tracking entity compliance
  status, managing security policies, monitoring employee training, or preparing
  for compliance audits.
connection_type: sprinto
preload: false
---

# Sprinto Management Skill

Manage and analyze Sprinto compliance checks, entities, policies, and audit readiness.

## API Conventions

### Authentication
All API calls use `Authorization: Bearer $SPRINTO_API_TOKEN` -- injected automatically. Never hardcode tokens.

### Base URL
`https://api.sprinto.com/v1`

### Core Helper Function

```bash
#!/bin/bash

sprinto_api() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"

    if [ -n "$data" ]; then
        curl -s -X "$method" \
            -H "Authorization: Bearer $SPRINTO_API_TOKEN" \
            -H "Content-Type: application/json" \
            "https://api.sprinto.com/v1${endpoint}" \
            -d "$data"
    else
        curl -s -X "$method" \
            -H "Authorization: Bearer $SPRINTO_API_TOKEN" \
            -H "Content-Type: application/json" \
            "https://api.sprinto.com/v1${endpoint}"
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
sprinto_api GET "/frameworks" \
    | jq -r '.data[] | "\(.id)\t\(.name)\t\(.readinessScore // "N/A")%"' | column -t | head -10

echo ""
echo "=== Checks Summary ==="
sprinto_api GET "/checks?limit=1" \
    | jq '"Total checks: \(.meta.total // "N/A")"' -r

echo ""
echo "=== Integrations ==="
sprinto_api GET "/integrations" \
    | jq -r '.data[] | "\(.name)\t\(.status)\t\(.lastSync[0:16] // "Never")"' | column -t | head -10
```

## Analysis Phase

### Check Monitoring

```bash
#!/bin/bash
echo "=== Checks by Status ==="
CHECKS=$(sprinto_api GET "/checks?limit=200")
echo "$CHECKS" | jq '{
    total: (.data | length),
    passing: ([.data[] | select(.status == "passing")] | length),
    failing: ([.data[] | select(.status == "failing")] | length),
    warning: ([.data[] | select(.status == "warning")] | length),
    not_applicable: ([.data[] | select(.status == "not_applicable")] | length)
}'

echo ""
echo "=== Failing Checks ==="
echo "$CHECKS" | jq -r '.data[] | select(.status == "failing") | "\(.status)\t\(.name[0:50])\t\(.category[0:15])"' \
    | column -t | head -20

echo ""
echo "=== Checks by Category ==="
echo "$CHECKS" | jq -r '[.data[].category] | group_by(.) | map({category: .[0], count: length}) | sort_by(.count) | reverse | .[:10][] | "\(.count)\t\(.category)"' | column -t
```

### Entity Compliance

```bash
#!/bin/bash
echo "=== Entity Overview ==="
sprinto_api GET "/entities?limit=200" \
    | jq '{
        total: (.data | length),
        compliant: ([.data[] | select(.complianceStatus == "compliant")] | length),
        non_compliant: ([.data[] | select(.complianceStatus == "non_compliant")] | length)
    }'

echo ""
echo "=== Non-Compliant Entities ==="
sprinto_api GET "/entities?limit=50&complianceStatus=non_compliant" \
    | jq -r '.data[] | "\(.type)\t\(.name[0:30])\t\(.complianceStatus)\tissues:\(.issueCount // 0)"' \
    | column -t | head -15

echo ""
echo "=== Entities by Type ==="
sprinto_api GET "/entities?limit=500" \
    | jq -r '[.data[].type] | group_by(.) | map({type: .[0], count: length}) | sort_by(.count) | reverse | .[] | "\(.count)\t\(.type)"' | column -t
```

### Policy & Training

```bash
#!/bin/bash
echo "=== Policy Status ==="
sprinto_api GET "/policies?limit=100" \
    | jq -r '.data[] | "\(.status)\t\(.name[0:40])\tacknowledged:\(.acknowledgedCount // 0)/\(.totalCount // 0)"' \
    | sort | column -t | head -15

echo ""
echo "=== Training Compliance ==="
sprinto_api GET "/training?limit=100" \
    | jq '{
        total_employees: (.data | length),
        completed: ([.data[] | select(.trainingStatus == "completed")] | length),
        pending: ([.data[] | select(.trainingStatus == "pending")] | length),
        overdue: ([.data[] | select(.trainingStatus == "overdue")] | length)
    }'

echo ""
echo "=== Overdue Training ==="
sprinto_api GET "/training?limit=50&trainingStatus=overdue" \
    | jq -r '.data[] | "\(.employeeName)\t\(.email[0:30])\t\(.trainingName[0:25])\tdue:\(.dueDate[0:10])"' \
    | column -t | head -10
```

### Audit Readiness

```bash
#!/bin/bash
echo "=== Readiness Score ==="
sprinto_api GET "/frameworks" \
    | jq -r '.data[] | "\(.name[0:25])\treadiness:\(.readinessScore // 0)%\tchecks:\(.totalChecks // "N/A")\tfailing:\(.failingChecks // "N/A")"' | column -t

echo ""
echo "=== Audit Timeline ==="
sprinto_api GET "/audits" \
    | jq -r '.data[] | "\(.status)\t\(.frameworkName[0:20])\tstart:\(.startDate[0:10] // "TBD")\tend:\(.endDate[0:10] // "TBD")"' | column -t | head -10
```

## Output Format

Present results as a structured report:
```
Managing Sprinto Report
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

- **Automated checks**: Most checks run automatically via integrations -- verify integration sync status
- **Entity types**: Entities include people, devices, cloud accounts, repos -- filter by type
- **Pagination**: Use `limit` and `offset` -- check `meta.total`
- **Rate limits**: Check response headers for rate limiting
- **Readiness score**: Score is calculated from passing/total checks -- may lag behind real-time changes
