---
name: managing-cloudhealth
description: |
  CloudHealth by VMware multi-cloud cost management and governance. Covers cost reporting, rightsizing recommendations, governance policies, budget tracking, reserved instance management, and compliance auditing. Use when analyzing cloud spend across providers, enforcing tagging policies, or tracking budgets.
connection_type: cloudhealth
preload: false
---

# CloudHealth Management Skill

Manage multi-cloud cost reporting, governance, and optimization with CloudHealth.

## MANDATORY: Discovery-First Pattern

**Always list accounts and perspectives before querying cost data.**

### Phase 1: Discovery

```bash
#!/bin/bash

cht_api() {
    local endpoint="$1"
    curl -s -H "Content-Type: application/json" \
        "https://chapi.cloudhealthtech.com/v1/${endpoint}?api_key=${CLOUDHEALTH_API_KEY}"
}

echo "=== CloudHealth Accounts ==="
cht_api "aws_accounts" | jq -r '
    .aws_accounts[] | "\(.id)\t\(.name)\t\(.status)\t\(.owner_id)"
' | column -t | head -20

echo ""
echo "=== Perspectives ==="
cht_api "perspective_schemas" | jq -r '.[] | "\(.id)\t\(.name)"' | column -t | head -15

echo ""
echo "=== Current Month Spend ==="
cht_api "olap_reports/cost/history" | jq -r '
    .dimensions[0].items[] | "\(.label)\t$\(.total | . * 100 | round / 100)"
' | sort -t'$' -k2 -rn | head -10
```

## Core Helper Functions

```bash
#!/bin/bash

cht_api() {
    local endpoint="$1"
    local params="${2:-}"
    curl -s -H "Content-Type: application/json" \
        "https://chapi.cloudhealthtech.com/v1/${endpoint}?api_key=${CLOUDHEALTH_API_KEY}${params:+&$params}"
}

cht_report() {
    local report_type="$1"
    local params="${2:-}"
    cht_api "olap_reports/${report_type}" "$params"
}
```

## Output Rules
- **TOKEN EFFICIENCY**: Target ≤50 lines per output
- Use jq to extract cost summaries from OLAP report responses
- Round dollar amounts to 2 decimal places

## Common Operations

### Cost Reporting by Account

```bash
#!/bin/bash
MONTHS="${1:-3}"

echo "=== Monthly Cost Trend (last $MONTHS months) ==="
cht_api "olap_reports/cost/history" "interval=monthly&past=${MONTHS}" | jq -r '
    .dimensions[0].items[] |
    "\(.label)\t$\(.values | map(. // 0) | map(. * 100 | round / 100) | join("\t$"))"
' | column -t | head -20

echo ""
echo "=== Cost by Service ==="
cht_api "olap_reports/cost/history" "interval=monthly&past=1&dimensions[]=AWS-Service-Category" | jq -r '
    .dimensions[0].items[] |
    "\(.label)\t$\(.total | . * 100 | round / 100)"
' | sort -t'$' -k2 -rn | column -t | head -15
```

### Rightsizing Recommendations

```bash
#!/bin/bash
echo "=== EC2 Rightsizing Recommendations ==="
cht_api "olap_reports/usage/ec2_instance" | jq -r '
    .dimensions[0].items[] |
    select(.recommendation != null) |
    "\(.label)\tCurrent: \(.instance_type)\tRecommended: \(.recommendation.instance_type)\tSavings: $\(.recommendation.savings | . * 100 | round / 100)/mo"
' | sort -t'$' -k4 -rn | head -20

echo ""
echo "=== RDS Rightsizing ==="
cht_api "olap_reports/usage/rds" | jq -r '
    .dimensions[0].items[] |
    select(.recommendation != null) |
    "\(.label)\tCurrent: \(.instance_type)\tRecommended: \(.recommendation.instance_type)\tSavings: $\(.recommendation.savings | . * 100 | round / 100)/mo"
' | sort -t'$' -k4 -rn | head -10
```

### Governance Policy Status

```bash
#!/bin/bash
echo "=== Active Policies ==="
cht_api "policies" | jq -r '
    .policies[] | "\(.id)\t\(.name)\t\(.status)\tViolations: \(.violation_count // 0)"
' | column -t | head -20

echo ""
echo "=== Policy Violations ==="
cht_api "policies" | jq -r '
    .policies[] | select(.violation_count > 0) |
    "\(.name)\t\(.violation_count) violations\tSeverity: \(.severity)"
' | sort -t':' -k2 -rn | column -t | head -15
```

### Budget Tracking

```bash
#!/bin/bash
echo "=== Budget Summary ==="
cht_api "olap_reports/cost/budget" | jq -r '
    .dimensions[0].items[] |
    "\(.label)\tBudget: $\(.budget | . * 100 | round / 100)\tActual: $\(.actual | . * 100 | round / 100)\tVariance: \(.variance_percent | . * 100 | round / 100)%"
' | column -t | head -15

echo ""
echo "=== Over-Budget Items ==="
cht_api "olap_reports/cost/budget" | jq -r '
    .dimensions[0].items[] |
    select(.variance_percent > 0) |
    "\(.label)\tOver by: $\(.variance | . * 100 | round / 100)\t(\(.variance_percent | . * 100 | round / 100)%)"
' | sort -t'$' -k2 -rn | column -t | head -10
```

### Reserved Instance Analysis

```bash
#!/bin/bash
echo "=== RI Utilization ==="
cht_api "olap_reports/cost/ri_utilization" | jq -r '
    .dimensions[0].items[] |
    "\(.label)\tUtilization: \(.utilization_percent | . * 100 | round / 100)%\tCoverage: \(.coverage_percent | . * 100 | round / 100)%"
' | column -t | head -15

echo ""
echo "=== RI Recommendations ==="
cht_api "olap_reports/cost/ri_recommendations" | jq -r '
    .dimensions[0].items[] |
    "\(.label)\t\(.instance_type)\tSavings: $\(.estimated_savings | . * 100 | round / 100)/yr\tBreak-even: \(.break_even_months) months"
' | sort -t'$' -k3 -rn | column -t | head -10
```

## Safety Rules
- **Read-only queries**: CloudHealth API is primarily for reporting -- policy changes need UI confirmation
- **API rate limits**: CloudHealth enforces rate limits -- space out bulk queries
- **Data freshness**: Cost data can lag by 24-48 hours from cloud provider billing
- **Multi-account**: Always verify account context when reviewing costs

## Common Pitfalls
- **Perspective confusion**: Different perspectives show different cost aggregations -- verify which perspective is active
- **Untagged resources**: Resources without tags appear under "unallocated" -- this skews cost attribution
- **Blended vs unblended**: Blended rates average across RI and on-demand -- use unblended for true cost
- **API pagination**: Large result sets require pagination -- check for next_page tokens
- **Time zones**: Cost reports use UTC -- account for timezone differences in daily reports
- **Amortized costs**: RI upfront payments can be amortized or shown as one-time -- check report settings
