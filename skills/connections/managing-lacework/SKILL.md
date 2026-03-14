---
name: managing-lacework
description: |
  Lacework cloud security platform for threat detection, compliance assessment, vulnerability management, and cloud workload protection. Covers alert investigation, compliance report analysis, container security, host vulnerability scanning, and anomaly detection. Use when investigating cloud security alerts, reviewing compliance posture, analyzing vulnerabilities in cloud workloads, or managing Lacework agent deployments.
connection_type: lacework
preload: false
---

# Lacework Management Skill

Manage and analyze Lacework alerts, compliance reports, vulnerabilities, and cloud security posture.

## API Conventions

### Authentication
All API calls use `Authorization: Bearer $LACEWORK_ACCESS_TOKEN` -- injected automatically. Never hardcode tokens.

### Base URL
`https://$LACEWORK_ACCOUNT.lacework.net/api/v2`

### Core Helper Function

```bash
#!/bin/bash

lw_api() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"
    local base="https://${LACEWORK_ACCOUNT}.lacework.net/api/v2"

    if [ -n "$data" ]; then
        curl -s -X "$method" \
            -H "Authorization: Bearer $LACEWORK_ACCESS_TOKEN" \
            -H "Content-Type: application/json" \
            "${base}${endpoint}" \
            -d "$data"
    else
        curl -s -X "$method" \
            -H "Authorization: Bearer $LACEWORK_ACCESS_TOKEN" \
            -H "Content-Type: application/json" \
            "${base}${endpoint}"
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
echo "=== Active Alerts ==="
lw_api GET "/Alerts?timeFilter=Last7Days" \
    | jq '{total: (.data | length), critical: ([.data[] | select(.severity == "Critical")] | length), high: ([.data[] | select(.severity == "High")] | length)}'

echo ""
echo "=== Cloud Accounts ==="
lw_api GET "/CloudAccounts" \
    | jq -r '.data[] | "\(.type)\t\(.name)\t\(.enabled)"' | column -t | head -10

echo ""
echo "=== Agent Status ==="
lw_api GET "/AgentInfo" \
    | jq '{total_agents: (.data | length)}' 2>/dev/null || echo "Agent info unavailable"
```

## Analysis Phase

### Alert Investigation

```bash
#!/bin/bash
echo "=== Critical/High Alerts (last 7 days) ==="
lw_api GET "/Alerts?timeFilter=Last7Days" \
    | jq -r '.data[] | select(.severity == "Critical" or .severity == "High") | "\(.startTime[0:16])\t\(.severity)\t\(.alertType)\t\(.alertName[0:50])"' \
    | sort -r | column -t | head -20

echo ""
echo "=== Alerts by Type ==="
lw_api GET "/Alerts?timeFilter=Last7Days" \
    | jq -r '[.data[].alertType] | group_by(.) | map({type: .[0], count: length}) | sort_by(.count) | reverse | .[:10][] | "\(.count)\t\(.type)"' | column -t
```

### Compliance Summary

```bash
#!/bin/bash
echo "=== Compliance Reports ==="
lw_api GET "/Reports?primaryQueryId=LW_AWS_CIS_14&type=COMPLIANCE" \
    | jq -r '.data[0] | {reportType: .reportType, summary: {passed: .summary.numPass, failed: .summary.numFail, suppressed: .summary.numSuppressed}}' 2>/dev/null

echo ""
echo "=== Failed Compliance Checks ==="
lw_api GET "/Reports?primaryQueryId=LW_AWS_CIS_14&type=COMPLIANCE" \
    | jq -r '.data[0].recommendations[] | select(.status == "NonCompliant") | "\(.recId)\t\(.title[0:60])\t\(.resourceCount) resources"' \
    | head -15 | column -t
```

### Host Vulnerabilities

```bash
#!/bin/bash
echo "=== Host Vulnerability Summary ==="
lw_api POST "/Vulnerabilities/Hosts/search" '{"timeFilter":{"startTime":"'"$(date -u -v-7d +%Y-%m-%dT%H:%M:%SZ)"'","endTime":"'"$(date -u +%Y-%m-%dT%H:%M:%SZ)"'"},"filters":[{"field":"severity","expression":"in","values":["Critical","High"]}]}' \
    | jq '{total: (.data | length), critical: ([.data[] | select(.severity == "Critical")] | length), high: ([.data[] | select(.severity == "High")] | length)}' 2>/dev/null

echo ""
echo "=== Top Vulnerable Hosts ==="
lw_api POST "/Vulnerabilities/Hosts/search" '{"timeFilter":{"startTime":"'"$(date -u -v-7d +%Y-%m-%dT%H:%M:%SZ)"'","endTime":"'"$(date -u +%Y-%m-%dT%H:%M:%SZ)"'"}}' \
    | jq -r '[.data[] | {host: .machineTags.Hostname, severity: .severity}] | group_by(.host) | map({host: .[0].host, count: length}) | sort_by(.count) | reverse | .[:10][] | "\(.count)\t\(.host)"' \
    | column -t 2>/dev/null
```

## Common Pitfalls

- **Token expiration**: Access tokens expire after 1 hour -- refresh via `/access/tokens`
- **Time filters**: Use predefined filters (`Last7Days`, `Last24Hours`) or ISO 8601 format
- **Account-specific URL**: Each Lacework account has a unique subdomain
- **Rate limits**: 480 requests/hour per API key
- **Pagination**: Large datasets use `nextPage` token -- check response for pagination info
