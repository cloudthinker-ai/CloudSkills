---
name: managing-statuspal
description: |
  StatusPal status page management, service monitoring, incident communication, and maintenance scheduling. Covers status page configuration, component health tracking, subscriber notifications, incident updates, and uptime metrics. Use when managing status pages, creating incident updates, scheduling maintenance windows, or reviewing uptime history in StatusPal.
connection_type: statuspal
preload: false
---

# StatusPal Management Skill

Manage and analyze status pages, incidents, and service components in StatusPal.

## API Conventions

### Authentication
All API calls use the `Authorization: Bearer $STATUSPAL_API_KEY` header. Never hardcode tokens.

### Base URL
`https://statuspal.io/api/v2`

### Core Helper Function

```bash
#!/bin/bash

statuspal_api() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"

    if [ -n "$data" ]; then
        curl -s -X "$method" \
            -H "Authorization: Bearer $STATUSPAL_API_KEY" \
            -H "Content-Type: application/json" \
            "https://statuspal.io/api/v2${endpoint}" \
            -d "$data"
    else
        curl -s -X "$method" \
            -H "Authorization: Bearer $STATUSPAL_API_KEY" \
            -H "Content-Type: application/json" \
            "https://statuspal.io/api/v2${endpoint}"
    fi
}
```

## Output Rules
- **TOKEN EFFICIENCY**: Extract only needed fields with `jq`
- Target <=50 lines per script output
- Never dump full API responses

## Discovery Phase

### List Status Pages and Services

```bash
#!/bin/bash
echo "=== Status Pages ==="
statuspal_api GET "/status_pages" \
    | jq -r '.status_pages[] | "\(.subdomain)\t\(.name)\t\(.current_status)"' | column -t

echo ""
echo "=== Services ==="
STATUS_PAGE_ID="${1:?Status page ID required}"
statuspal_api GET "/status_pages/${STATUS_PAGE_ID}/services" \
    | jq -r '.services[] | "\(.current_status)\t\(.name)\t\(.monitoring_type // "none")"' | column -t | head -20
```

### Active Incidents

```bash
#!/bin/bash
STATUS_PAGE_ID="${1:?Status page ID required}"

echo "=== Active Incidents ==="
statuspal_api GET "/status_pages/${STATUS_PAGE_ID}/incidents?state=open" \
    | jq -r '.incidents[] | "\(.starts_at[0:16])\t\(.type)\t\(.title[0:60])"' | column -t

echo ""
echo "=== Scheduled Maintenance ==="
statuspal_api GET "/status_pages/${STATUS_PAGE_ID}/maintenances?state=scheduled" \
    | jq -r '.maintenances[] | "\(.starts_at[0:16])\t\(.ends_at[0:16])\t\(.title[0:50])"' | column -t
```

## Analysis Phase

### Uptime Metrics

```bash
#!/bin/bash
STATUS_PAGE_ID="${1:?Status page ID required}"

echo "=== Service Uptime (30 days) ==="
statuspal_api GET "/status_pages/${STATUS_PAGE_ID}/services" \
    | jq -r '.services[] | "\(.name)\t\(.uptime_percentage // "N/A")%"' | column -t | head -20

echo ""
echo "=== Recent Incident History ==="
statuspal_api GET "/status_pages/${STATUS_PAGE_ID}/incidents?limit=15" \
    | jq -r '.incidents[] | "\(.starts_at[0:16])\t\(.state)\t\(.type)\t\(.title[0:50])"' | column -t
```

### Incident Detail

```bash
#!/bin/bash
STATUS_PAGE_ID="${1:?Status page ID required}"
INCIDENT_ID="${2:?Incident ID required}"

echo "=== Incident Details ==="
statuspal_api GET "/status_pages/${STATUS_PAGE_ID}/incidents/${INCIDENT_ID}" \
    | jq '.incident | {id, title, type, state, starts_at, ends_at, affected_services: [.services[].name]}'

echo ""
echo "=== Incident Updates ==="
statuspal_api GET "/status_pages/${STATUS_PAGE_ID}/incidents/${INCIDENT_ID}/updates" \
    | jq -r '.updates[] | "\(.created_at[0:16])\t\(.status)\t\(.description[0:80])"' | column -t
```

## Output Format
- Use tab-separated columns with `column -t`
- Limit lists to 15-25 items
- Show summaries before details

## Common Pitfalls
- **Status page scoped**: Most endpoints require `status_page_id` in the path
- **Incident types**: `major_outage`, `partial_outage`, `degraded_performance`, `maintenance`
- **Service states**: `operational`, `degraded`, `partial_outage`, `major_outage`, `maintenance`
- **Subscriber notifications**: Incident updates trigger subscriber notifications automatically
- **Pagination**: Use `limit` and `offset` parameters
