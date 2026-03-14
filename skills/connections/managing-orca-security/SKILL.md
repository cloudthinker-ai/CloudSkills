---
name: managing-orca-security
description: |
  Orca Security cloud-native application protection platform for agentless vulnerability scanning, compliance monitoring, and threat detection across cloud environments. Covers alert management, asset inventory, vulnerability prioritization, compliance frameworks, and attack path analysis. Use when investigating cloud security alerts, reviewing asset vulnerabilities, analyzing compliance posture, or managing Orca Security configurations.
connection_type: orca-security
preload: false
---

# Orca Security Management Skill

Manage and analyze Orca Security alerts, assets, vulnerabilities, and compliance posture.

## API Conventions

### Authentication
All API calls use `Authorization: Token $ORCA_API_TOKEN` -- injected automatically. Never hardcode tokens.

### Base URL
`https://app.orcasecurity.io/api`

### Core Helper Function

```bash
#!/bin/bash

orca_api() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"

    if [ -n "$data" ]; then
        curl -s -X "$method" \
            -H "Authorization: Token $ORCA_API_TOKEN" \
            -H "Content-Type: application/json" \
            "https://app.orcasecurity.io/api${endpoint}" \
            -d "$data"
    else
        curl -s -X "$method" \
            -H "Authorization: Token $ORCA_API_TOKEN" \
            -H "Content-Type: application/json" \
            "https://app.orcasecurity.io/api${endpoint}"
    fi
}
```

## Output Rules
- **TOKEN EFFICIENCY**: Extract only needed fields with `jq`
- Target <=50 lines per script output
- Always filter by relevant time range to avoid huge response sets
- Never dump full API responses

## Discovery Phase

```bash
#!/bin/bash
echo "=== Alert Summary ==="
orca_api GET "/alerts/query/summary" \
    | jq '{total: .total_alerts, critical: .critical, high: .high, medium: .medium, low: .low}'

echo ""
echo "=== Cloud Accounts ==="
orca_api GET "/cloud_accounts" \
    | jq -r '.data[] | "\(.cloud_provider)\t\(.account_name)\t\(.status)"' | column -t | head -10

echo ""
echo "=== Asset Count ==="
orca_api GET "/assets?limit=1" \
    | jq '"Total assets: \(.total_items)"' -r
```

## Analysis Phase

### Alert Investigation

```bash
#!/bin/bash
echo "=== Critical/High Alerts ==="
orca_api POST "/alerts/query" '{"filters":{"severity":["hazardous","critical","high"]},"limit":20,"order_by":"score","order":"desc"}' \
    | jq -r '.data[] | "\(.create_time[0:16])\t\(.severity)\t\(.alert_type)\t\(.description[0:50])"' \
    | column -t | head -20

echo ""
echo "=== Alerts by Category ==="
orca_api POST "/alerts/query" '{"filters":{},"group_by":"category","limit":100}' \
    | jq -r '.data[] | "\(.count)\t\(.category)"' | sort -rn | head -10 | column -t
```

### Asset Vulnerabilities

```bash
#!/bin/bash
echo "=== Most Vulnerable Assets ==="
orca_api POST "/assets/query" '{"filters":{"has_vulnerabilities":true},"order_by":"risk_score","order":"desc","limit":15}' \
    | jq -r '.data[] | "\(.risk_score)\t\(.asset_type)\t\(.asset_name[0:30])\t\(.cloud_provider)\tcrit:\(.vulnerability_summary.critical // 0)"' \
    | column -t

echo ""
echo "=== Vulnerability Summary by Severity ==="
orca_api GET "/vulnerabilities/summary" \
    | jq '{critical: .critical, high: .high, medium: .medium, low: .low, total: .total}'
```

### Compliance Overview

```bash
#!/bin/bash
echo "=== Compliance Frameworks ==="
orca_api GET "/compliance/frameworks" \
    | jq -r '.data[] | "\(.name[0:30])\tpassed:\(.passed_checks)\tfailed:\(.failed_checks)\tscore:\(.compliance_score)%"' \
    | column -t | head -15

echo ""
echo "=== Failed Compliance Checks (Critical) ==="
orca_api POST "/compliance/query" '{"filters":{"status":"failed","severity":"critical"},"limit":15}' \
    | jq -r '.data[] | "\(.severity)\t\(.framework[0:15])\t\(.title[0:50])\t\(.affected_assets) assets"' \
    | column -t | head -15
```

## Common Pitfalls

- **Agentless model**: Orca uses SideScanning -- no agent deployment required but needs cloud account access
- **Score vs severity**: Risk scores are numeric (0-100), severity is categorical
- **Pagination**: Use `limit` and `offset` parameters -- default limit is typically 20
- **Rate limits**: API rate limits apply -- check `X-RateLimit-Remaining` header
- **Multi-cloud**: Assets span AWS, Azure, GCP -- filter by `cloud_provider` when needed
