---
name: managing-secureframe
description: |
  Secureframe compliance automation platform for SOC 2, ISO 27001, HIPAA, PCI DSS, and GDPR compliance. Covers control monitoring, test automation, personnel management, vendor tracking, and evidence collection. Use when reviewing compliance controls, tracking test results, managing personnel onboarding compliance, or preparing for security audits with Secureframe.
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

## Common Pitfalls

- **Pagination**: Use `per_page` and `page` parameters -- check `meta.total_count`
- **Rate limits**: Check response headers for rate limit status
- **Framework scoping**: Controls belong to specific frameworks -- filter by framework ID
- **Test automation**: Tests run on schedules tied to integrations -- check integration health first
- **Evidence linking**: Evidence is linked to controls -- query via control ID for specific evidence
