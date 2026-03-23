---
name: managing-sentinel
description: |
  Use when working with Sentinel — microsoft Sentinel SIEM incident management,
  threat hunting, analytics rules, and security operations. Covers incident
  triage, KQL-based threat hunting, alert rule configuration, connector health,
  and workbook analytics. Use when investigating security incidents, reviewing
  detection rules, analyzing threat patterns, or managing Sentinel workspace
  health.
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

## Output Format

Present results as a structured report:
```
Managing Sentinel Report
════════════════════════
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

- **API versioning**: Always include `api-version` query parameter -- features vary by version
- **KQL queries**: Log Analytics queries go through a different endpoint (`/api/query`)
- **ARM path length**: Full resource path is required for every call -- use helper function
- **Pagination**: Large result sets use `nextLink` for pagination
- **RBAC**: Requires Microsoft Sentinel Reader role minimum -- Contributor for write operations
