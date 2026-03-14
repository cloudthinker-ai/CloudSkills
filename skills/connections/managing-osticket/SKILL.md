---
name: managing-osticket
description: |
  osTicket open-source helpdesk management covering ticket creation and routing, canned response templates, SLA plan configuration, and department-based ticket assignment. Use when managing support tickets in osTicket, configuring automated responses for common issues, setting up SLA plans with grace periods, or organizing helpdesk departments and agent assignments.
connection_type: osticket
preload: false
---

# osTicket Helpdesk Management Skill

Manage and analyze osTicket tickets, canned responses, and SLA plans.

## API Conventions

### Authentication
All API calls use API key — injected via `X-API-Key` header.

### Base URL
`https://{{server}}/api`

### Core Helper Function

```bash
#!/bin/bash

ost_api() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"

    if [ -n "$data" ]; then
        curl -s -X "$method" \
            -H "X-API-Key: $OSTICKET_API_KEY" \
            -H "Content-Type: application/json" \
            "${OSTICKET_URL}/api${endpoint}" \
            -d "$data"
    else
        curl -s -X "$method" \
            -H "X-API-Key: $OSTICKET_API_KEY" \
            -H "Content-Type: application/json" \
            "${OSTICKET_URL}/api${endpoint}"
    fi
}
```

## Common Operations

### Ticket Management

```bash
#!/bin/bash
echo "=== Open Tickets ==="
ost_api GET "/tickets.json?status=open&limit=25&order=priority&dir=asc" \
    | jq -r '.[] | "\(.ticket_number)\t\(.priority)\t\(.status)\t\(.subject[0:60])"' \
    | column -t

echo ""
echo "=== Overdue Tickets ==="
ost_api GET "/tickets.json?status=open&overdue=true&limit=15" \
    | jq -r '.[] | "\(.ticket_number)\t\(.priority)\t\(.due_date)\t\(.subject[0:50])"' \
    | column -t

echo ""
echo "=== Tickets by Department ==="
ost_api GET "/tickets.json?status=open&limit=200" \
    | jq -r '[.[].department] | group_by(.) | map({dept: .[0], count: length}) | sort_by(.count) | reverse | .[] | "\(.dept): \(.count)"'
```

### Create Ticket

```bash
#!/bin/bash
echo "=== Creating New Ticket ==="
ost_api POST "/tickets.json" "{
    \"name\": \"${1:?Requester name required}\",
    \"email\": \"${2:?Requester email required}\",
    \"subject\": \"${3:?Subject required}\",
    \"message\": \"${4:?Message required}\",
    \"topicId\": ${5:-1},
    \"priorityId\": ${6:-2}
}" | jq '.'
```

### Canned Responses

```bash
#!/bin/bash
echo "=== Available Canned Responses ==="
ost_api GET "/canned.json" \
    | jq -r '.[] | "\(.id)\t\(.title[0:60])\t\(.department // "All")"' \
    | column -t
```

## Common Pitfalls

- **API key scope**: osTicket has separate API keys for ticket creation vs. management — ensure correct key
- **Limited API**: osTicket's native API is limited — some operations may require direct database queries or plugins
- **JSON content type**: Always send `Content-Type: application/json` — XML is also supported but JSON is preferred
- **Ticket number vs ID**: Ticket numbers are display-friendly (e.g., `123456`), IDs are internal integers
- **SLA configuration**: SLA plans are configured in admin panel — API access may be limited
- **Custom fields**: Custom form fields are accessible but vary by help topic
- **Authentication**: API key must be associated with an active staff account
