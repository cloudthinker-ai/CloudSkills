---
name: managing-sysaid
description: |
  SysAid ITSM platform management covering ticket management, asset discovery and inventory, self-service portal administration, and reporting. Use when creating and routing helpdesk tickets, reviewing discovered IT assets and their configurations, managing the self-service portal catalog, or generating operational reports on ticket volume and resolution times.
connection_type: sysaid
preload: false
---

# SysAid ITSM Management Skill

Manage and analyze SysAid tickets, assets, self-service portal, and reports.

## API Conventions

### Authentication
All API calls use session-based auth or API token — injected automatically.

### Base URL
`https://{{account}}.sysaidit.com/api/v1`

### Core Helper Function

```bash
#!/bin/bash

sysaid_api() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"

    if [ -n "$data" ]; then
        curl -s -X "$method" \
            -H "Authorization: Bearer $SYSAID_TOKEN" \
            -H "Content-Type: application/json" \
            "${SYSAID_URL}/api/v1${endpoint}" \
            -d "$data"
    else
        curl -s -X "$method" \
            -H "Authorization: Bearer $SYSAID_TOKEN" \
            -H "Content-Type: application/json" \
            "${SYSAID_URL}/api/v1${endpoint}"
    fi
}
```

## Common Operations

### Ticket Management

```bash
#!/bin/bash
echo "=== Open Service Records ==="
sysaid_api GET "/sr?type=incident&archive=0&fields=id,title,priority,status,assignedTo,insertTime&limit=25&sort=priority&dir=asc" \
    | jq -r '.[] | "\(.id)\tP\(.priority)\t\(.status)\t\(.title[0:60])"' \
    | column -t

echo ""
echo "=== Unassigned Tickets ==="
sysaid_api GET "/sr?type=incident&archive=0&assignedTo=&limit=15" \
    | jq -r '.[] | "\(.id)\tP\(.priority)\t\(.insertTime[0:16])\t\(.title[0:50])"' \
    | column -t

echo ""
echo "=== Overdue Tickets ==="
sysaid_api GET "/sr?type=incident&archive=0&overdue=true&limit=15" \
    | jq -r '.[] | "\(.id)\tP\(.priority)\t\(.dueDate)\t\(.title[0:50])"' \
    | column -t
```

### Asset Discovery & Inventory

```bash
#!/bin/bash
echo "=== Asset Summary by Type ==="
sysaid_api GET "/asset?limit=200&fields=id,name,assetType,status" \
    | jq -r '[.[].assetType] | group_by(.) | map({type: .[0], count: length}) | sort_by(.count) | reverse | .[] | "\(.type): \(.count)"'

echo ""
echo "=== Recently Discovered Assets ==="
sysaid_api GET "/asset?sort=lastScanDate&dir=desc&limit=15&fields=id,name,assetType,lastScanDate,ipAddress" \
    | jq -r '.[] | "\(.id)\t\(.name)\t\(.assetType)\t\(.ipAddress // "-")\t\(.lastScanDate[0:10])"' \
    | column -t
```

### Self-Service Portal

```bash
#!/bin/bash
echo "=== Service Catalog Items ==="
sysaid_api GET "/catalog?limit=25" \
    | jq -r '.[] | "\(.id)\t\(.name)\t\(.category // "-")"' \
    | column -t

echo ""
echo "=== Most Used Catalog Items ==="
sysaid_api GET "/catalog?sort=usageCount&dir=desc&limit=10" \
    | jq -r '.[] | "\(.usageCount) uses\t\(.name)"' \
    | column -t
```

## Common Pitfalls

- **Service Record types**: Use `type=incident`, `type=request`, `type=problem`, `type=change` for filtering
- **Archive flag**: Set `archive=0` to exclude archived records from queries
- **Session management**: Session tokens may expire — handle 401 with re-authentication
- **Rate limits**: Vary by deployment — check with your SysAid admin
- **Pagination**: Use `limit` and `offset` parameters — default limit may be 100
- **Custom fields**: Custom list values use numeric IDs — check field configuration for mappings
- **Date format**: Dates are typically in milliseconds since epoch — convert for display
