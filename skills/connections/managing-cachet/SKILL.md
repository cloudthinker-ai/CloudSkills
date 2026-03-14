---
name: managing-cachet
description: |
  Cachet open-source status page management, component tracking, incident reporting, and metric visualization. Covers component group management, incident lifecycle, scheduled maintenance, metric points, and subscriber management. Use when managing self-hosted status pages, creating incidents, tracking component health, or reviewing uptime metrics in Cachet.
connection_type: cachet
preload: false
---

# Cachet Management Skill

Manage and analyze components, incidents, metrics, and subscribers in Cachet.

## API Conventions

### Authentication
All API calls use the `X-Cachet-Token: $CACHET_API_KEY` header. Never hardcode tokens.

### Base URL
`$CACHET_URL/api/v1` (self-hosted, set via environment variable)

### Core Helper Function

```bash
#!/bin/bash

cachet_api() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"

    if [ -n "$data" ]; then
        curl -s -X "$method" \
            -H "X-Cachet-Token: $CACHET_API_KEY" \
            -H "Content-Type: application/json" \
            "${CACHET_URL}/api/v1${endpoint}" \
            -d "$data"
    else
        curl -s -X "$method" \
            -H "X-Cachet-Token: $CACHET_API_KEY" \
            -H "Content-Type: application/json" \
            "${CACHET_URL}/api/v1${endpoint}"
    fi
}
```

## Output Rules
- **TOKEN EFFICIENCY**: Extract only needed fields with `jq`
- Target <=50 lines per script output
- Never dump full API responses

## Discovery Phase

### List Components

```bash
#!/bin/bash
echo "=== Components ==="
cachet_api GET "/components?per_page=25" \
    | jq -r '.data[] | "\(.status_name)\t\(.name)\t\(.group.name // "ungrouped")"' | column -t

echo ""
echo "=== Component Groups ==="
cachet_api GET "/components/groups" \
    | jq -r '.data[] | "\(.name)\t\(.enabled_components | length) components"' | column -t
```

### Active Incidents

```bash
#!/bin/bash
echo "=== Active Incidents ==="
cachet_api GET "/incidents?sort=id&order=desc&per_page=20" \
    | jq -r '.data[] | select(.status < 4) | "\(.created_at[0:16])\t\(.human_status)\t\(.name[0:60])"' \
    | column -t

echo ""
echo "=== Scheduled Maintenance ==="
cachet_api GET "/schedules" \
    | jq -r '.data[] | "\(.scheduled_at[0:16])\t\(.status_name)\t\(.name[0:50])"' | column -t
```

## Analysis Phase

### Component Health Overview

```bash
#!/bin/bash
echo "=== Component Status Summary ==="
cachet_api GET "/components?per_page=100" \
    | jq -r '.data[] | .status_name' | sort | uniq -c | sort -rn

echo ""
echo "=== Components Not Operational ==="
cachet_api GET "/components?per_page=100" \
    | jq -r '.data[] | select(.status != 1) | "\(.status_name)\t\(.name)\t\(.updated_at[0:16])"' | column -t

echo ""
echo "=== Metrics ==="
cachet_api GET "/metrics" \
    | jq -r '.data[] | "\(.name)\t\(.default_value)\t\(.calc_type_name)"' | column -t
```

### Incident Detail

```bash
#!/bin/bash
INCIDENT_ID="${1:?Incident ID required}"

echo "=== Incident Details ==="
cachet_api GET "/incidents/${INCIDENT_ID}" \
    | jq '.data | {id, name, human_status, message: .message[0:200], created_at, updated_at}'

echo ""
echo "=== Incident Updates ==="
cachet_api GET "/incidents/${INCIDENT_ID}/updates" \
    | jq -r '.data[] | "\(.created_at[0:16])\t\(.human_status)\t\(.message[0:80])"' | column -t
```

## Output Format
- Use tab-separated columns with `column -t`
- Limit lists to 15-25 items
- Show summaries before details

## Common Pitfalls
- **Self-hosted**: Base URL varies per installation -- always use `$CACHET_URL` env variable
- **Component status codes**: 1=Operational, 2=Performance Issues, 3=Partial Outage, 4=Major Outage
- **Incident status codes**: 1=Investigating, 2=Identified, 3=Watching, 4=Fixed
- **Pagination**: Use `per_page` and `page` parameters, check `meta.pagination` for total pages
- **Metrics**: Metric points are time-series data -- use `/metrics/{id}/points` for values
