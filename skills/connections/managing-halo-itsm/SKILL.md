---
name: managing-halo-itsm
description: |
  HaloITSM platform management covering ticket lifecycle, SLA policy configuration, knowledge base article management, and asset tracking. Use when creating and managing support tickets with custom workflows, monitoring SLA compliance and breach risks, publishing and organizing knowledge base articles for self-service, or tracking IT hardware and software assets through their lifecycle.
connection_type: halo-itsm
preload: false
---

# HaloITSM Management Skill

Manage and analyze HaloITSM tickets, SLAs, knowledge base, and assets.

## API Conventions

### Authentication
All API calls use OAuth2 client credentials — token injected automatically.

### Base URL
`https://{{tenant}}.haloitsm.com/api`

### Core Helper Function

```bash
#!/bin/bash

halo_api() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"

    if [ -n "$data" ]; then
        curl -s -X "$method" \
            -H "Authorization: Bearer $HALO_TOKEN" \
            -H "Content-Type: application/json" \
            "${HALO_URL}/api${endpoint}" \
            -d "$data"
    else
        curl -s -X "$method" \
            -H "Authorization: Bearer $HALO_TOKEN" \
            -H "Content-Type: application/json" \
            "${HALO_URL}/api${endpoint}"
    fi
}
```

## Common Operations

### Ticket Management

```bash
#!/bin/bash
echo "=== Open Tickets ==="
halo_api GET "/tickets?open_only=true&order=priority&count=25" \
    | jq -r '.tickets[] | "\(.id)\tP\(.priority_id)\t\(.status_name)\t\(.summary[0:60])"' \
    | column -t

echo ""
echo "=== Unassigned Tickets ==="
halo_api GET "/tickets?open_only=true&unassigned=true&count=15" \
    | jq -r '.tickets[] | "\(.id)\tP\(.priority_id)\t\(.dateoccurred[0:16])\t\(.summary[0:50])"' \
    | column -t

echo ""
echo "=== Tickets by Category ==="
halo_api GET "/tickets?open_only=true&count=200" \
    | jq -r '[.tickets[].category_1] | group_by(.) | map({cat: .[0], count: length}) | sort_by(.count) | reverse | .[:10] | .[] | "\(.cat // "Uncategorized"): \(.count)"'
```

### SLA Monitoring

```bash
#!/bin/bash
echo "=== SLA Policies ==="
halo_api GET "/sla" \
    | jq -r '.[] | "\(.id)\t\(.name)\tResponse: \(.response_time // "-")\tResolution: \(.fix_time // "-")"' \
    | column -t

echo ""
echo "=== Tickets at SLA Risk ==="
halo_api GET "/tickets?open_only=true&sla_status=warning&count=15" \
    | jq -r '.tickets[] | "\(.id)\t\(.sla_name // "-")\t\(.sla_response_status // "-")\t\(.summary[0:50])"' \
    | column -t
```

### Knowledge Base

```bash
#!/bin/bash
echo "=== Published KB Articles ==="
halo_api GET "/knowledgebase?count=20&order=usecount_desc" \
    | jq -r '.articles[] | "\(.id)\t\(.usecount // 0) views\t\(.name[0:60])"' \
    | column -t

echo ""
echo "=== Draft Articles ==="
halo_api GET "/knowledgebase?published=false&count=15" \
    | jq -r '.articles[] | "\(.id)\t\(.dateoccurred[0:10])\t\(.name[0:60])"' \
    | column -t
```

### Asset Tracking

```bash
#!/bin/bash
echo "=== Assets by Type ==="
halo_api GET "/asset?count=200" \
    | jq -r '[.assets[].assettype_name] | group_by(.) | map({type: .[0], count: length}) | sort_by(.count) | reverse | .[] | "\(.type): \(.count)"'

echo ""
echo "=== Recently Updated Assets ==="
halo_api GET "/asset?order=lastupdated_desc&count=15" \
    | jq -r '.assets[] | "\(.id)\t\(.inventory_number // "-")\t\(.assettype_name)\t\(.device_name)"' \
    | column -t
```

## Common Pitfalls

- **OAuth2 flow**: Uses client credentials grant — token expires, handle refresh
- **Pagination**: Use `count` and `page_no` parameters — check `record_count` in response for total
- **Filtering**: Query parameters vary by endpoint — check endpoint-specific documentation
- **SLA statuses**: Filter by `sla_status` values: `ok`, `warning`, `breached`
- **Custom fields**: Accessed via `customfields` array in ticket responses — reference by field name
- **Date format**: ISO 8601 format in UTC
- **Ticket types**: Different endpoints may be needed for incidents, requests, problems, changes
