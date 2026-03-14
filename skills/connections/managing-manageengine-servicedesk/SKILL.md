---
name: managing-manageengine-servicedesk
description: |
  ManageEngine ServiceDesk Plus management covering incident handling, IT asset tracking, CMDB configuration, and reporting. Use when creating and managing incidents with SLA tracking, cataloging hardware and software assets, building CMDB relationships between configuration items, or generating operational performance reports.
connection_type: manageengine-servicedesk
preload: false
---

# ManageEngine ServiceDesk Plus Management Skill

Manage and analyze ManageEngine ServiceDesk Plus incidents, assets, and CMDB.

## API Conventions

### Authentication
All API calls use technician API key — injected as query parameter or header.

### Base URL
`https://{{server}}/api/v3`

### Core Helper Function

```bash
#!/bin/bash

me_api() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"

    if [ -n "$data" ]; then
        curl -s -X "$method" \
            -H "authtoken: $MANAGEENGINE_API_KEY" \
            -H "Content-Type: application/json" \
            "${MANAGEENGINE_URL}/api/v3${endpoint}" \
            -d "$data"
    else
        curl -s -X "$method" \
            -H "authtoken: $MANAGEENGINE_API_KEY" \
            -H "Content-Type: application/json" \
            "${MANAGEENGINE_URL}/api/v3${endpoint}"
    fi
}
```

## Common Operations

### Incident Management

```bash
#!/bin/bash
echo "=== Open Requests ==="
me_api GET "/requests?list_info={\"row_count\":25,\"sort_field\":\"priority\",\"sort_order\":\"asc\",\"search_criteria\":{\"field\":\"status.name\",\"condition\":\"is not\",\"value\":\"Closed\"}}" \
    | jq -r '.requests[] | "\(.id)\t\(.priority.name)\t\(.status.name)\t\(.subject[0:60])"' \
    | column -t

echo ""
echo "=== Overdue Requests ==="
me_api GET "/requests?list_info={\"row_count\":15,\"search_criteria\":{\"field\":\"is_overdue\",\"condition\":\"is\",\"value\":true}}" \
    | jq -r '.requests[] | "\(.id)\t\(.priority.name)\t\(.due_by_time)\t\(.subject[0:50])"' \
    | column -t
```

### Asset Management

```bash
#!/bin/bash
echo "=== Asset Summary ==="
me_api GET "/assets?list_info={\"row_count\":100}" \
    | jq -r '[.assets[].product_type.name] | group_by(.) | map({type: .[0], count: length}) | sort_by(.count) | reverse | .[] | "\(.type): \(.count)"'

echo ""
echo "=== Assets by State ==="
me_api GET "/assets?list_info={\"row_count\":100}" \
    | jq -r '[.assets[].asset_state] | group_by(.) | map({state: .[0], count: length}) | sort_by(.count) | reverse | .[] | "\(.state): \(.count)"'
```

### CMDB Operations

```bash
#!/bin/bash
echo "=== CI Types ==="
me_api GET "/cmdb/ci_types" \
    | jq -r '.ci_types[] | "\(.id)\t\(.name)\t\(.ci_count // 0) CIs"' \
    | column -t

echo ""
echo "=== Configuration Items ==="
CI_TYPE_ID="${1:?CI Type ID required}"
me_api GET "/cmdb/ci_types/${CI_TYPE_ID}/cis?list_info={\"row_count\":25}" \
    | jq -r '.cis[] | "\(.id)\t\(.name)\t\(.ci_state // "-")"' \
    | column -t
```

## Common Pitfalls

- **list_info parameter**: Filtering and pagination use JSON-encoded `list_info` query parameter
- **Search criteria**: Nested JSON structure with `field`, `condition`, `value` — multiple criteria use `logical_operator`
- **Auth header**: Uses `authtoken` header (not `Authorization`) — format varies between cloud and on-premise
- **Rate limits**: Cloud edition enforces rate limits — check documentation for current limits
- **API versions**: v3 is current — v1 endpoints still work but may lack features
- **Date format**: Epoch milliseconds in responses — provide human-readable dates in search criteria
- **Pagination**: Use `row_count` and `start_index` in `list_info` JSON parameter
