---
name: managing-tugboat-logic
description: |
  Use when working with Tugboat Logic — tugboat Logic (now part of OneTrust)
  compliance automation for SOC 2, ISO 27001, and other security frameworks.
  Covers policy management, control monitoring, evidence collection, risk
  assessment, and audit preparation. Use when reviewing compliance status,
  managing security policies, tracking evidence collection, or preparing for
  compliance audits with Tugboat Logic.
connection_type: tugboat-logic
preload: false
---

# Tugboat Logic Management Skill

Manage and analyze Tugboat Logic compliance controls, policies, evidence, and audit readiness.

## API Conventions

### Authentication
All API calls use `Authorization: Bearer $TUGBOAT_API_TOKEN` -- injected automatically. Never hardcode tokens.

### Base URL
`https://api.tugboatlogic.com/v1`

### Core Helper Function

```bash
#!/bin/bash

tugboat_api() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"

    if [ -n "$data" ]; then
        curl -s -X "$method" \
            -H "Authorization: Bearer $TUGBOAT_API_TOKEN" \
            -H "Content-Type: application/json" \
            "https://api.tugboatlogic.com/v1${endpoint}" \
            -d "$data"
    else
        curl -s -X "$method" \
            -H "Authorization: Bearer $TUGBOAT_API_TOKEN" \
            -H "Content-Type: application/json" \
            "https://api.tugboatlogic.com/v1${endpoint}"
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
tugboat_api GET "/frameworks" \
    | jq -r '.data[] | "\(.id)\t\(.name)\t\(.status)"' | column -t | head -10

echo ""
echo "=== Controls Summary ==="
tugboat_api GET "/controls?limit=1" \
    | jq '"Total controls: \(.total // .meta.total // "N/A")"' -r

echo ""
echo "=== Policies ==="
tugboat_api GET "/policies?limit=100" \
    | jq '{total_policies: (.data | length), published: ([.data[] | select(.status == "published")] | length)}'
```

## Analysis Phase

### Control Monitoring

```bash
#!/bin/bash
echo "=== Controls by Status ==="
CONTROLS=$(tugboat_api GET "/controls?limit=200")
echo "$CONTROLS" | jq '{
    total: (.data | length),
    implemented: ([.data[] | select(.status == "implemented")] | length),
    not_implemented: ([.data[] | select(.status == "not_implemented")] | length),
    partial: ([.data[] | select(.status == "partially_implemented")] | length)
}'

echo ""
echo "=== Not Implemented Controls ==="
echo "$CONTROLS" | jq -r '.data[] | select(.status == "not_implemented") | "\(.status)\t\(.name[0:50])\t\(.framework[0:15])"' \
    | column -t | head -15

echo ""
echo "=== Control Coverage by Framework ==="
echo "$CONTROLS" | jq -r '[.data[] | {framework: .framework, status: .status}] | group_by(.framework) | map({framework: .[0].framework, total: length, implemented: ([.[] | select(.status == "implemented")] | length)}) | .[] | "\(.framework[0:20])\t\(.implemented)/\(.total)"' | column -t
```

### Policy Management

```bash
#!/bin/bash
echo "=== Policy Status ==="
tugboat_api GET "/policies?limit=100" \
    | jq -r '.data[] | "\(.status)\t\(.name[0:40])\tlastUpdated:\(.updatedAt[0:10] // "N/A")"' \
    | sort | column -t | head -20

echo ""
echo "=== Policies Needing Review ==="
tugboat_api GET "/policies?limit=100" \
    | jq -r '.data[] | select(.reviewRequired == true or .status == "draft") | "\(.name[0:40])\t\(.status)\t\(.owner // "No owner")"' \
    | column -t | head -10
```

### Evidence Collection

```bash
#!/bin/bash
echo "=== Evidence Status ==="
tugboat_api GET "/evidence?limit=200" \
    | jq '{
        total: (.data | length),
        collected: ([.data[] | select(.status == "collected")] | length),
        pending: ([.data[] | select(.status == "pending")] | length),
        expired: ([.data[] | select(.status == "expired")] | length)
    }'

echo ""
echo "=== Pending Evidence ==="
tugboat_api GET "/evidence?limit=50&status=pending" \
    | jq -r '.data[] | "\(.controlName[0:30])\t\(.name[0:35])\t\(.dueDate[0:10] // "No due date")"' \
    | column -t | head -15
```

### Risk Assessment

```bash
#!/bin/bash
echo "=== Risk Register ==="
tugboat_api GET "/risks?limit=50" \
    | jq -r '.data[] | "\(.riskLevel)\t\(.name[0:40])\t\(.status)\towner:\(.owner[0:20] // "Unassigned")"' \
    | sort | column -t | head -15

echo ""
echo "=== Risks by Level ==="
tugboat_api GET "/risks?limit=200" \
    | jq -r '[.data[].riskLevel] | group_by(.) | map({level: .[0], count: length}) | sort_by(.count) | reverse | .[] | "\(.level): \(.count)"'
```

## Output Format

Present results as a structured report:
```
Managing Tugboat Logic Report
═════════════════════════════
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

- **OneTrust migration**: Tugboat Logic was acquired by OneTrust -- API may transition to OneTrust endpoints
- **Pagination**: Use `limit` and `offset` parameters -- check response for total count
- **Rate limits**: Check response headers for rate limiting information
- **Policy versioning**: Policies have versions -- ensure you are querying the latest version
- **Framework mapping**: Controls map to multiple frameworks -- filter by framework ID when needed
