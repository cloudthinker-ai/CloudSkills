---
name: managing-sentinel
description: |
  Microsoft Sentinel SIEM incident management, threat hunting, analytics rules, and security operations. Covers incident triage, KQL-based threat hunting, alert rule configuration, connector health, and workbook analytics. Use when investigating security incidents, reviewing detection rules, analyzing threat patterns, or managing Sentinel workspace health.
connection_type: sentinel
preload: false
---

# Microsoft Sentinel Management Skill

Manage and analyze Microsoft Sentinel incidents, analytics rules, threat hunting, and data connectors.

## API Conventions

### Authentication
All API calls use `Authorization: Bearer $SENTINEL_ACCESS_TOKEN` -- injected automatically via Azure AD. Never hardcode tokens.

### Base URL
`https://management.azure.com/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.OperationalInsights/workspaces/$WORKSPACE_NAME/providers/Microsoft.SecurityInsights`

### Core Helper Function

```bash
#!/bin/bash

sentinel_api() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"
    local base="https://management.azure.com/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.OperationalInsights/workspaces/$WORKSPACE_NAME/providers/Microsoft.SecurityInsights"

    if [ -n "$data" ]; then
        curl -s -X "$method" \
            -H "Authorization: Bearer $SENTINEL_ACCESS_TOKEN" \
            -H "Content-Type: application/json" \
            "${base}${endpoint}?api-version=2023-11-01" \
            -d "$data"
    else
        curl -s -X "$method" \
            -H "Authorization: Bearer $SENTINEL_ACCESS_TOKEN" \
            -H "Content-Type: application/json" \
            "${base}${endpoint}?api-version=2023-11-01"
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
echo "=== Active Incidents ==="
sentinel_api GET "/incidents" \
    | jq '[.value[] | select(.properties.status != "Closed")] | length | "Open incidents: \(.)"' -r

echo ""
echo "=== Data Connectors ==="
sentinel_api GET "/dataConnectors" \
    | jq '[.value[]] | length | "Connected sources: \(.)"' -r

echo ""
echo "=== Analytics Rules ==="
sentinel_api GET "/alertRules" \
    | jq '{total: (.value | length), enabled: ([.value[] | select(.properties.enabled == true)] | length)}' -r
```

## Analysis Phase

### Incident Overview

```bash
#!/bin/bash
echo "=== High Severity Open Incidents ==="
sentinel_api GET "/incidents" \
    | jq -r '[.value[] | select(.properties.status != "Closed" and (.properties.severity == "High" or .properties.severity == "Critical"))] | sort_by(.properties.createdTimeUtc) | reverse | .[:15][] | "\(.properties.createdTimeUtc[0:16])\t\(.properties.severity)\t\(.properties.status)\t\(.properties.title[0:60])"' \
    | column -t

echo ""
echo "=== Incidents by Severity ==="
sentinel_api GET "/incidents" \
    | jq -r '[.value[] | select(.properties.status != "Closed")] | group_by(.properties.severity) | map({severity: .[0].properties.severity, count: length}) | .[] | "\(.severity): \(.count)"'

echo ""
echo "=== Incidents by Owner ==="
sentinel_api GET "/incidents" \
    | jq -r '[.value[] | select(.properties.status != "Closed")] | group_by(.properties.owner.assignedTo // "Unassigned") | map({owner: .[0].properties.owner.assignedTo // "Unassigned", count: length}) | sort_by(.count) | reverse | .[] | "\(.owner): \(.count)"' | head -10
```

### Analytics Rules Health

```bash
#!/bin/bash
echo "=== Enabled Rules by Type ==="
sentinel_api GET "/alertRules" \
    | jq -r '[.value[] | select(.properties.enabled == true)] | group_by(.kind) | map({kind: .[0].kind, count: length}) | .[] | "\(.kind): \(.count)"'

echo ""
echo "=== Recently Triggered Rules (last 7 days) ==="
sentinel_api GET "/incidents" \
    | jq -r '[.value[] | select(.properties.createdTimeUtc > "'"$(date -u -v-7d +%Y-%m-%dT%H:%M:%SZ)"'")] | group_by(.properties.title) | map({rule: .[0].properties.title[0:50], count: length}) | sort_by(.count) | reverse | .[:10][] | "\(.count)\t\(.rule)"' \
    | column -t
```

### Data Connector Health

```bash
#!/bin/bash
echo "=== Connected Data Sources ==="
sentinel_api GET "/dataConnectors" \
    | jq -r '.value[] | "\(.kind)\t\(.name[0:40])"' | column -t

echo ""
echo "=== Connector Status ==="
sentinel_api GET "/dataConnectorCheckRequirementsStatus" 2>/dev/null \
    | jq -r '.value[]? | "\(.connectorId)\t\(.status)"' | column -t | head -15
```

## Common Pitfalls

- **API versioning**: Always include `api-version` query parameter -- features vary by version
- **KQL queries**: Log Analytics queries go through a different endpoint (`/api/query`)
- **ARM path length**: Full resource path is required for every call -- use helper function
- **Pagination**: Large result sets use `nextLink` for pagination
- **RBAC**: Requires Microsoft Sentinel Reader role minimum -- Contributor for write operations
