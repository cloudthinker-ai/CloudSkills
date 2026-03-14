---
name: managing-statuspage
description: |
  Statuspage.io component management, incident lifecycle, scheduled maintenance, metric publishing, and subscriber notifications. Covers component status updates, incident creation and resolution, uptime metrics, and page configuration. Use when managing status page components, creating incidents, publishing metrics, or reviewing subscriber status via API.
connection_type: statuspage
preload: false
---

# Statuspage.io Management Skill

Manage status page components, incidents, and metrics using the Statuspage API.

## API Conventions

### Authentication
All API calls use `Authorization: OAuth <api_key>` header — injected by connection. Never hardcode keys.

### Base URL
`https://api.statuspage.io/v1/pages/{page_id}/`

### Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- Use `jq` to extract relevant component and incident fields
- NEVER dump full API responses

### Core Helper Function

```bash
#!/bin/bash

statuspage_api() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"

    if [ -n "$data" ]; then
        curl -s -X "$method" \
            -H "Authorization: OAuth ${STATUSPAGE_API_KEY}" \
            -H "Content-Type: application/json" \
            "https://api.statuspage.io/v1/pages/${STATUSPAGE_PAGE_ID}${endpoint}" \
            -d "$data"
    else
        curl -s -X "$method" \
            -H "Authorization: OAuth ${STATUSPAGE_API_KEY}" \
            "https://api.statuspage.io/v1/pages/${STATUSPAGE_PAGE_ID}${endpoint}"
    fi
}

statuspage_pages() {
    curl -s -H "Authorization: OAuth ${STATUSPAGE_API_KEY}" \
        "https://api.statuspage.io/v1/pages"
}
```

## Parallel Execution

```bash
{
    statuspage_api GET "/components" &
    statuspage_api GET "/incidents?limit=10" &
    statuspage_api GET "/incidents/unresolved" &
}
wait
```

## Anti-Hallucination Rules

**NEVER assume page IDs, component IDs, or incident IDs. ALWAYS discover first.**

### Phase 1: Discovery

```bash
#!/bin/bash
echo "=== Pages ==="
statuspage_pages | jq -r '.[] | "\(.id)\t\(.name)\t\(.subdomain).statuspage.io"'

echo ""
echo "=== Components ==="
statuspage_api GET "/components" \
    | jq -r '.[] | "\(.id)\t\(.name)\t\(.status)\t\(.group_id // "ungrouped")"' | head -20

echo ""
echo "=== Component Groups ==="
statuspage_api GET "/component-groups" \
    | jq -r '.[] | "\(.id)\t\(.name)\t\(.components | length) components"'

echo ""
echo "=== Unresolved Incidents ==="
statuspage_api GET "/incidents/unresolved" \
    | jq -r '.[] | "\(.id)\t\(.status)\t\(.name)"' | head -10
```

## Common Operations

### Component Management

```bash
#!/bin/bash
echo "=== Component Status Overview ==="
statuspage_api GET "/components" \
    | jq -r '.[] | "\(.status)\t\(.name)\t\(.updated_at[0:16])"' | sort

echo ""
echo "=== Components NOT Operational ==="
statuspage_api GET "/components" \
    | jq -r '.[] | select(.status != "operational") | "\(.status)\t\(.name)\t\(.id)"'

echo ""
echo "=== Component Groups ==="
statuspage_api GET "/component-groups" \
    | jq -r '.[] | "\(.name):\n\(.components | map("  - " + .) | join("\n"))"'
```

### Update Component Status

```bash
#!/bin/bash
COMPONENT_ID="${1:?Component ID required}"
STATUS="${2:?Status required}"  # operational, degraded_performance, partial_outage, major_outage, under_maintenance

echo "=== Updating Component ==="
statuspage_api PATCH "/components/${COMPONENT_ID}" \
    "{\"component\":{\"status\":\"${STATUS}\"}}" \
    | jq '{id: .id, name: .name, status: .status, updated_at: .updated_at}'
```

### Incident Management

```bash
#!/bin/bash
echo "=== Active Incidents ==="
statuspage_api GET "/incidents/unresolved" \
    | jq -r '.[] | "\(.id)\t\(.status)\t\(.impact)\t\(.name)\t\(.created_at[0:16])"'

echo ""
echo "=== Recent Resolved Incidents ==="
statuspage_api GET "/incidents?limit=10&q=resolved" \
    | jq -r '.[] | select(.status == "resolved") | "\(.resolved_at[0:10])\t\(.impact)\t\(.name)"' | head -10

echo ""
echo "=== Incident Timeline ==="
INCIDENT_ID="${1:-}"
if [ -n "$INCIDENT_ID" ]; then
    statuspage_api GET "/incidents/${INCIDENT_ID}" \
        | jq -r '.incident_updates[] | "\(.status)\t\(.updated_at[0:16])\t\(.body[0:80])"'
fi
```

### Create & Update Incidents

```bash
#!/bin/bash
echo "=== Creating Incident ==="
statuspage_api POST "/incidents" "{
    \"incident\": {
        \"name\": \"${1:?Incident name required}\",
        \"status\": \"${2:-investigating}\",
        \"impact_override\": \"${3:-minor}\",
        \"body\": \"${4:-Investigating the issue.}\",
        \"component_ids\": [${5:-}],
        \"deliver_notifications\": true
    }
}" | jq '{id: .id, name: .name, status: .status, shortlink: .shortlink}'
```

### Scheduled Maintenance

```bash
#!/bin/bash
echo "=== Upcoming Maintenance ==="
statuspage_api GET "/incidents/scheduled" \
    | jq -r '.[] | "\(.scheduled_for[0:16]) to \(.scheduled_until[0:16])\t\(.name)\t\(.status)"' | head -10

echo ""
echo "=== Create Maintenance Window ==="
# statuspage_api POST "/incidents" "{
#     \"incident\": {
#         \"name\": \"Scheduled Database Maintenance\",
#         \"status\": \"scheduled\",
#         \"scheduled_for\": \"2024-01-15T02:00:00Z\",
#         \"scheduled_until\": \"2024-01-15T04:00:00Z\",
#         \"body\": \"Routine database maintenance window.\",
#         \"component_ids\": [\"component_id_here\"]
#     }
# }"
```

### Metric Publishing

```bash
#!/bin/bash
METRIC_ID="${1:?Metric ID required}"

echo "=== Publish Metric Data Point ==="
TIMESTAMP=$(date +%s)
VALUE="${2:?Metric value required}"

statuspage_api POST "/metrics/${METRIC_ID}/data" \
    "{\"data\":{\"timestamp\":${TIMESTAMP},\"value\":${VALUE}}}" \
    | jq '.'

echo ""
echo "=== Available Metrics ==="
statuspage_api GET "/metrics" \
    | jq -r '.[] | "\(.id)\t\(.name)\t\(.metric_identifier)"' | head -10
```

## Common Pitfalls

- **Status values**: Components use `operational`, `degraded_performance`, `partial_outage`, `major_outage`, `under_maintenance` — exact strings required
- **Incident statuses**: `investigating`, `identified`, `monitoring`, `resolved`, `scheduled`, `in_progress`, `verifying`, `completed`
- **Impact levels**: `none`, `minor`, `major`, `critical` — controls banner color and notifications
- **Page ID required**: Most endpoints need `page_id` in URL — discover via `/v1/pages` first
- **Notifications**: `deliver_notifications: true` sends to all subscribers — be cautious with test incidents
- **Component groups**: Updating group status does NOT cascade to child components — update individually
- **Rate limits**: 60 requests/minute — stagger parallel calls for large component updates
- **Metric timestamps**: Unix epoch seconds — not milliseconds
