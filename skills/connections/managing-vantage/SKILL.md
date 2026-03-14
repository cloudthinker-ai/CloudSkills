---
name: managing-vantage
description: |
  Vantage cloud cost management and observability platform. Covers cost reports across providers, anomaly detection, budget alerts, resource-level cost tracking, and provider integrations. Use when analyzing multi-cloud costs, setting up budget alerts, or investigating cost anomalies.
connection_type: vantage
preload: false
---

# Vantage Management Skill

Manage multi-cloud cost visibility and optimization with Vantage.

## MANDATORY: Discovery-First Pattern

**Always list workspaces and connected providers before querying costs.**

### Phase 1: Discovery

```bash
#!/bin/bash

vantage_api() {
    local method="${1:-GET}"
    local endpoint="$2"
    local data="${3:-}"
    if [ -n "$data" ]; then
        curl -s -X "$method" -H "Authorization: Bearer $VANTAGE_API_TOKEN" \
            -H "Content-Type: application/json" \
            "https://api.vantage.sh/v2/${endpoint}" -d "$data"
    else
        curl -s -X "$method" -H "Authorization: Bearer $VANTAGE_API_TOKEN" \
            "https://api.vantage.sh/v2/${endpoint}"
    fi
}

echo "=== Connected Providers ==="
vantage_api GET "integrations" | jq -r '
    .integrations[] | "\(.id)\t\(.provider)\t\(.status)\t\(.account_id // "N/A")"
' | column -t

echo ""
echo "=== Workspaces ==="
vantage_api GET "workspaces" | jq -r '
    .workspaces[] | "\(.token)\t\(.name)"
' | column -t

echo ""
echo "=== Cost Reports ==="
vantage_api GET "cost_reports" | jq -r '
    .cost_reports[] | "\(.token)\t\(.title)\t\(.groupings)\t\(.date_interval)"
' | column -t | head -15
```

## Core Helper Functions

```bash
#!/bin/bash

vantage_api() {
    local method="${1:-GET}"
    local endpoint="$2"
    local data="${3:-}"
    if [ -n "$data" ]; then
        curl -s -X "$method" -H "Authorization: Bearer $VANTAGE_API_TOKEN" \
            -H "Content-Type: application/json" \
            "https://api.vantage.sh/v2/${endpoint}" -d "$data"
    else
        curl -s -X "$method" -H "Authorization: Bearer $VANTAGE_API_TOKEN" \
            "https://api.vantage.sh/v2/${endpoint}"
    fi
}
```

## Output Rules
- **TOKEN EFFICIENCY**: Target ≤50 lines per output
- Filter API responses with jq to extract cost summaries
- Round costs to 2 decimal places

## Common Operations

### Cost Report Analysis

```bash
#!/bin/bash
REPORT_TOKEN="${1:?Cost report token required}"

echo "=== Cost Report Details ==="
vantage_api GET "cost_reports/${REPORT_TOKEN}" | jq '{
    title: .cost_report.title,
    groupings: .cost_report.groupings,
    dateInterval: .cost_report.date_interval,
    filter: .cost_report.filter
}'

echo ""
echo "=== Cost Data ==="
vantage_api GET "cost_reports/${REPORT_TOKEN}/costs" | jq -r '
    .costs[] | "\(.date)\t$\(.amount | . * 100 | round / 100)\t\(.grouping // "total")"
' | column -t | head -25
```

### Anomaly Detection

```bash
#!/bin/bash
echo "=== Cost Anomalies ==="
vantage_api GET "anomalies" | jq -r '
    .anomalies[] |
    "\(.detected_at[0:10])\t\(.provider)\t\(.service)\tExpected: $\(.expected_amount | . * 100 | round / 100)\tActual: $\(.actual_amount | . * 100 | round / 100)\tDeviation: \(.deviation_percent | . * 100 | round / 100)%"
' | sort -r | column -t | head -15

echo ""
echo "=== Active Anomaly Alerts ==="
vantage_api GET "anomaly_alerts" | jq -r '
    .anomaly_alerts[] | "\(.token)\t\(.threshold_percent)% threshold\tNotify: \(.notification_channels | join(","))"
' | column -t
```

### Budget Management

```bash
#!/bin/bash
echo "=== Budget Summary ==="
vantage_api GET "budgets" | jq -r '
    .budgets[] |
    "\(.name)\tBudget: $\(.amount | . * 100 | round / 100)\tSpent: $\(.current_spend | . * 100 | round / 100)\tRemaining: $\((.amount - .current_spend) | . * 100 | round / 100)\tPeriod: \(.period)"
' | column -t | head -15

echo ""
echo "=== Over-Budget Alerts ==="
vantage_api GET "budgets" | jq -r '
    .budgets[] |
    select(.current_spend > .amount) |
    "\(.name)\tOver by: $\((.current_spend - .amount) | . * 100 | round / 100)\t(\((.current_spend / .amount * 100) | round)% of budget)"
' | column -t
```

### Provider Cost Breakdown

```bash
#!/bin/bash
echo "=== Cost by Provider ==="
vantage_api GET "costs?start_date=$(date -u -d '30 days ago' +%Y-%m-%d)&end_date=$(date -u +%Y-%m-%d)&groupings=provider" | jq -r '
    .costs[] | "\(.grouping)\t$\(.amount | . * 100 | round / 100)"
' | sort -t'$' -k2 -rn | column -t

echo ""
echo "=== Cost by Service (Top 20) ==="
vantage_api GET "costs?start_date=$(date -u -d '30 days ago' +%Y-%m-%d)&end_date=$(date -u +%Y-%m-%d)&groupings=service" | jq -r '
    .costs[] | "\(.grouping)\t$\(.amount | . * 100 | round / 100)"
' | sort -t'$' -k2 -rn | column -t | head -20
```

### Resource-Level Cost Tracking

```bash
#!/bin/bash
SERVICE="${1:?Service name required}"

echo "=== Resource Costs for $SERVICE ==="
vantage_api GET "costs?start_date=$(date -u -d '7 days ago' +%Y-%m-%d)&end_date=$(date -u +%Y-%m-%d)&groupings=resource&filter=service:${SERVICE}" | jq -r '
    .costs[] | "\(.grouping)\t$\(.amount | . * 100 | round / 100)"
' | sort -t'$' -k2 -rn | column -t | head -20

echo ""
echo "=== Daily Trend for $SERVICE ==="
vantage_api GET "costs?start_date=$(date -u -d '7 days ago' +%Y-%m-%d)&end_date=$(date -u +%Y-%m-%d)&groupings=date&filter=service:${SERVICE}" | jq -r '
    .costs[] | "\(.grouping)\t$\(.amount | . * 100 | round / 100)"
' | column -t
```

## Safety Rules
- **Read-only platform**: Vantage does not modify infrastructure -- all operations are observational
- **Token security**: API tokens grant read access to cost data -- treat as sensitive
- **Budget alerts**: Configure notification channels before relying on budget alerts
- **Data retention**: Verify data retention period before querying historical cost data

## Common Pitfalls
- **Integration delay**: New provider integrations take 24-48 hours to populate cost data
- **Cost allocation tags**: Resources without tags appear as unattributed -- ensure tagging compliance
- **Currency**: All costs are in USD by default -- convert for non-USD reporting
- **API pagination**: Large datasets require cursor-based pagination -- check for `links.next`
- **Report filters**: Saved reports may have filters that exclude certain services or accounts
- **Anomaly sensitivity**: Low thresholds generate noise; high thresholds miss real anomalies -- tune carefully
