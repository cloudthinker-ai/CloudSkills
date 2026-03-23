---
name: managing-secureframe
description: |
  Use when working with Secureframe — secureframe compliance automation platform
  for SOC 2, ISO 27001, HIPAA, PCI DSS, and GDPR compliance. Covers control
  monitoring, test automation, personnel management, vendor tracking, and
  evidence collection. Use when reviewing compliance controls, tracking test
  results, managing personnel onboarding compliance, or preparing for security
  audits with Secureframe.
connection_type: secureframe
preload: false
---

# Secureframe Management Skill

Manage and analyze Secureframe compliance controls, tests, personnel, and audit readiness.

## API Conventions

### Authentication
All API calls use `Authorization: Bearer $SECUREFRAME_API_TOKEN` -- injected automatically. Never hardcode tokens.

### Base URL
`https://api.secureframe.com/v1`

### Core Helper Function

```bash
#!/bin/bash

sf_api() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"

    if [ -n "$data" ]; then
        curl -s -X "$method" \
            -H "Authorization: Bearer $SECUREFRAME_API_TOKEN" \
            -H "Content-Type: application/json" \
            "https://api.secureframe.com/v1${endpoint}" \
            -d "$data"
    else
        curl -s -X "$method" \
            -H "Authorization: Bearer $SECUREFRAME_API_TOKEN" \
            -H "Content-Type: application/json" \
            "https://api.secureframe.com/v1${endpoint}"
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
sf_api GET "/frameworks" \
    | jq -r '.data[] | "\(.id)\t\(.name)\t\(.status)"' | column -t | head -10

echo ""
echo "=== Controls Summary ==="
sf_api GET "/controls?per_page=1" \
    | jq '"Total controls: \(.meta.total_count // "N/A")"' -r

echo ""
echo "=== Integrations ==="
sf_api GET "/integrations" \
    | jq -r '.data[] | "\(.name)\t\(.status)\t\(.lastSync[0:16] // "Never")"' | column -t | head -10
```

## Analysis Phase

### Control Status

```bash
#!/bin/bash
echo "=== Controls by Status ==="
CONTROLS=$(sf_api GET "/controls?per_page=200")
echo "$CONTROLS" | jq '{
    total: (.data | length),
    passing: ([.data[] | select(.status == "passing")] | length),
    failing: ([.data[] | select(.status == "failing")] | length),
    not_applicable: ([.data[] | select(.status == "not_applicable")] | length)
}'

echo ""
echo "=== Failing Controls ==="
echo "$CONTROLS" | jq -r '.data[] | select(.status == "failing") | "\(.status)\t\(.name[0:50])\t\(.framework[0:15])"' \
    | column -t | head -20

echo ""
echo "=== Controls by Framework ==="
echo "$CONTROLS" | jq -r '[.data[].framework] | group_by(.) | map({framework: .[0], count: length}) | sort_by(.count) | reverse | .[] | "\(.count)\t\(.framework)"' | column -t
```

### Test Results

```bash
#!/bin/bash
echo "=== Test Overview ==="
sf_api GET "/tests?per_page=200" \
    | jq '{
        total: (.data | length),
        passing: ([.data[] | select(.result == "pass")] | length),
        failing: ([.data[] | select(.result == "fail")] | length),
        warning: ([.data[] | select(.result == "warning")] | length)
    }'

echo ""
echo "=== Failing Tests ==="
sf_api GET "/tests?per_page=50&result=fail" \
    | jq -r '.data[] | "\(.result)\t\(.name[0:45])\t\(.lastChecked[0:16] // "Never")\t\(.controlName[0:25])"' \
    | column -t | head -15
```

### Personnel Management

```bash
#!/bin/bash
echo "=== Personnel Compliance ==="
sf_api GET "/personnel?per_page=200" \
    | jq '{
        total: (.data | length),
        compliant: ([.data[] | select(.compliant == true)] | length),
        non_compliant: ([.data[] | select(.compliant == false)] | length)
    }'

echo ""
echo "=== Non-Compliant Personnel ==="
sf_api GET "/personnel?per_page=50&compliant=false" \
    | jq -r '.data[] | "\(.name)\t\(.email[0:30])\tincomplete:\(.incompleteRequirements | length) items"' \
    | column -t | head -15

echo ""
echo "=== Outstanding Requirements ==="
sf_api GET "/personnel?per_page=50&compliant=false" \
    | jq -r '.data[] | .incompleteRequirements[]? | "\(.type)\t\(.description[0:50])"' \
    | sort | uniq -c | sort -rn | head -10
```

### Vendor Risk

```bash
#!/bin/bash
echo "=== Vendor Overview ==="
sf_api GET "/vendors?per_page=100" \
    | jq '{
        total: (.data | length),
        reviewed: ([.data[] | select(.reviewStatus == "reviewed")] | length),
        pending: ([.data[] | select(.reviewStatus == "pending")] | length)
    }'

echo ""
echo "=== High Risk Vendors ==="
sf_api GET "/vendors?per_page=50&riskLevel=high" \
    | jq -r '.data[] | "\(.name[0:30])\t\(.riskLevel)\t\(.reviewStatus)\t\(.lastReview[0:10] // "Never")"' | column -t
```

## Output Format

Present results as a structured report:
```
Managing Secureframe Report
═══════════════════════════
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

- **Pagination**: Use `per_page` and `page` parameters -- check `meta.total_count`
- **Rate limits**: Check response headers for rate limit status
- **Framework scoping**: Controls belong to specific frameworks -- filter by framework ID
- **Test automation**: Tests run on schedules tied to integrations -- check integration health first
- **Evidence linking**: Evidence is linked to controls -- query via control ID for specific evidence
