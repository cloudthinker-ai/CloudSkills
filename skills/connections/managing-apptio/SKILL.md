---
name: managing-apptio
description: |
  Apptio and Cloudability IT financial management and cloud cost optimization. Covers IT cost allocation, cloud cost analysis, benchmarking, budget forecasting, showback/chargeback reports, and technology business management. Use when managing IT financial planning, benchmarking cloud spend, or creating chargeback models.
connection_type: apptio
preload: false
---

# Apptio / Cloudability Management Skill

Manage IT financial planning and cloud cost optimization with Apptio and Cloudability.

## MANDATORY: Discovery-First Pattern

**Always list connected accounts and cost models before querying financial data.**

### Phase 1: Discovery

```bash
#!/bin/bash

apptio_api() {
    local method="${1:-GET}"
    local endpoint="$2"
    local data="${3:-}"
    if [ -n "$data" ]; then
        curl -s -X "$method" -H "Authorization: Bearer $APPTIO_API_TOKEN" \
            -H "Content-Type: application/json" \
            "https://api.apptio.com/v1/${endpoint}" -d "$data"
    else
        curl -s -X "$method" -H "Authorization: Bearer $APPTIO_API_TOKEN" \
            "https://api.apptio.com/v1/${endpoint}"
    fi
}

cloudability_api() {
    local endpoint="$1"
    curl -s -H "Authorization: Bearer $CLOUDABILITY_API_TOKEN" \
        "https://api.cloudability.com/v3/${endpoint}"
}

echo "=== Connected Cloud Accounts ==="
cloudability_api "vendors/accounts" | jq -r '
    .result[] | "\(.vendorAccountId)\t\(.vendorAccountName)\t\(.vendor)\t\(.status)"
' | column -t | head -20

echo ""
echo "=== Cost Models ==="
apptio_api GET "cost-models" | jq -r '
    .items[] | "\(.id)\t\(.name)\t\(.status)\tPeriod: \(.period)"
' | column -t

echo ""
echo "=== Business Units ==="
apptio_api GET "business-units" | jq -r '
    .items[] | "\(.id)\t\(.name)\tOwner: \(.owner // "unassigned")"
' | column -t | head -15
```

## Core Helper Functions

```bash
#!/bin/bash

apptio_api() {
    local method="${1:-GET}"
    local endpoint="$2"
    local data="${3:-}"
    if [ -n "$data" ]; then
        curl -s -X "$method" -H "Authorization: Bearer $APPTIO_API_TOKEN" \
            -H "Content-Type: application/json" \
            "https://api.apptio.com/v1/${endpoint}" -d "$data"
    else
        curl -s -X "$method" -H "Authorization: Bearer $APPTIO_API_TOKEN" \
            "https://api.apptio.com/v1/${endpoint}"
    fi
}

cloudability_api() {
    local endpoint="$1"
    curl -s -H "Authorization: Bearer $CLOUDABILITY_API_TOKEN" \
        "https://api.cloudability.com/v3/${endpoint}"
}
```

## Output Rules
- **TOKEN EFFICIENCY**: Target ≤50 lines per output
- Use jq to extract financial summaries and cost allocation data
- Round costs to 2 decimal places

## Common Operations

### IT Cost Allocation

```bash
#!/bin/bash
PERIOD="${1:-current}"

echo "=== IT Cost Allocation by Business Unit ==="
apptio_api GET "cost-allocation?period=${PERIOD}&groupBy=businessUnit" | jq -r '
    .items[] | "\(.businessUnit)\t$\(.totalCost | . * 100 | round / 100)\tDirect: $\(.directCost | . * 100 | round / 100)\tShared: $\(.sharedCost | . * 100 | round / 100)"
' | sort -t'$' -k2 -rn | column -t | head -15

echo ""
echo "=== Cost by IT Tower ==="
apptio_api GET "cost-allocation?period=${PERIOD}&groupBy=itTower" | jq -r '
    .items[] | "\(.itTower)\t$\(.totalCost | . * 100 | round / 100)\t\(.percentOfTotal | . * 100 | round / 100)%"
' | sort -t'$' -k2 -rn | column -t | head -15
```

### Cloud Cost Analysis (Cloudability)

```bash
#!/bin/bash
echo "=== Cloud Cost Summary (last 30 days) ==="
cloudability_api "reporting/cost/run?start_date=$(date -u -d '30 days ago' +%Y-%m-%d)&end_date=$(date -u +%Y-%m-%d)&dimensions[]=vendor&metrics[]=unblended_cost" | jq -r '
    .result[] | "\(.vendor)\t$\(.unblended_cost | . * 100 | round / 100)"
' | sort -t'$' -k2 -rn | column -t

echo ""
echo "=== Cost by Service (Top 15) ==="
cloudability_api "reporting/cost/run?start_date=$(date -u -d '30 days ago' +%Y-%m-%d)&end_date=$(date -u +%Y-%m-%d)&dimensions[]=service_name&metrics[]=unblended_cost&sort[]=unblended_cost&order=desc&limit=15" | jq -r '
    .result[] | "\(.service_name)\t$\(.unblended_cost | . * 100 | round / 100)"
' | column -t
```

### Benchmarking

```bash
#!/bin/bash
echo "=== Cost Benchmarking ==="
apptio_api GET "benchmarking/summary" | jq '{
    itSpendPerRevenue: .itSpendPerRevenue,
    cloudSpendPerEmployee: .cloudSpendPerEmployee,
    industryMedian: .industryMedian,
    percentile: .percentile,
    peerComparison: .peerComparison
}'

echo ""
echo "=== Benchmark by IT Tower ==="
apptio_api GET "benchmarking/by-tower" | jq -r '
    .items[] | "\(.tower)\tYour Cost: $\(.yourCost | . * 100 | round / 100)\tMedian: $\(.industryMedian | . * 100 | round / 100)\tPercentile: \(.percentile)th"
' | column -t | head -10
```

### Budget Forecasting

```bash
#!/bin/bash
echo "=== Budget vs Actual ==="
apptio_api GET "budgets/current" | jq -r '
    .items[] | "\(.category)\tBudget: $\(.budgetAmount | . * 100 | round / 100)\tActual: $\(.actualAmount | . * 100 | round / 100)\tVariance: \(.variancePercent | . * 100 | round / 100)%"
' | column -t | head -15

echo ""
echo "=== Forecast (next quarter) ==="
apptio_api GET "forecasts/next-quarter" | jq '{
    forecastTotal: .forecastTotal,
    budgetTotal: .budgetTotal,
    variance: .variance,
    trend: .trend,
    confidenceLevel: .confidenceLevel
}'
```

### Showback / Chargeback Reports

```bash
#!/bin/bash
BU="${1:-}"

echo "=== Chargeback Report ==="
ENDPOINT="chargeback/report?period=current"
[ -n "$BU" ] && ENDPOINT="${ENDPOINT}&businessUnit=${BU}"
apptio_api GET "$ENDPOINT" | jq -r '
    .items[] | "\(.businessUnit)\t\(.service)\t$\(.chargedAmount | . * 100 | round / 100)\tModel: \(.allocationModel)"
' | sort -t'$' -k3 -rn | column -t | head -20

echo ""
echo "=== Allocation Models ==="
apptio_api GET "allocation-models" | jq -r '
    .items[] | "\(.name)\tType: \(.type)\tBasis: \(.allocationBasis)"
' | column -t | head -10
```

## Safety Rules
- **Financial data sensitivity**: Cost allocation data may be confidential -- restrict access appropriately
- **Read-only queries**: API operations are observational -- cost model changes require UI
- **Budget approvals**: Never modify budgets or forecasts without finance team approval
- **Chargeback accuracy**: Validate allocation models before publishing chargeback reports

## Common Pitfalls
- **Data lag**: Cloud billing data can lag 24-72 hours from actual usage
- **Allocation models**: Incorrect shared cost allocation models skew business unit charges
- **Amortization**: RI/SP amortization settings affect how upfront payments appear in reports
- **Multi-currency**: Global organizations need proper exchange rate configuration
- **Tag coverage**: Low tag coverage makes cost allocation inaccurate -- target 90%+ tagging
- **API versioning**: Apptio and Cloudability have separate APIs -- use correct endpoints for each
