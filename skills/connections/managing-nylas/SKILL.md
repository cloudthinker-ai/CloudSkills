---
name: managing-nylas
description: |
  Nylas calendar and email API platform management covering calendars, events, messages, contacts, and scheduling pages. Use when monitoring calendar sync health, analyzing email delivery, reviewing scheduling page performance, managing connected accounts, or troubleshooting Nylas API issues.
connection_type: nylas
preload: false
---

# Nylas Management Skill

Manage and analyze Nylas calendar, email, and scheduling resources.

## API Conventions

### Authentication
All API calls use Bearer API key with grant ID, injected automatically.

### Base URL
`https://api.us.nylas.com/v3`

### Core Helper Function

```bash
#!/bin/bash

nylas_api() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"

    if [ -n "$data" ]; then
        curl -s -X "$method" \
            -H "Authorization: Bearer $NYLAS_API_KEY" \
            -H "Content-Type: application/json" \
            "https://api.us.nylas.com/v3${endpoint}" \
            -d "$data"
    else
        curl -s -X "$method" \
            -H "Authorization: Bearer $NYLAS_API_KEY" \
            "https://api.us.nylas.com/v3${endpoint}"
    fi
}
```

## Output Rules
- Target ≤50 lines per script output
- Use `jq` to extract only needed fields
- Never dump full API responses

## Phase 1: Discovery

```bash
#!/bin/bash
echo "=== Grants (Connected Accounts) ==="
nylas_api GET "/grants?limit=20" \
    | jq -r '.data[] | "\(.id[0:16])\t\(.email)\t\(.provider)\t\(.grant_status)\t\(.created_at | strftime("%Y-%m-%d"))"' \
    | column -t | head -15

echo ""
echo "=== Calendars ==="
GRANT_ID=$(nylas_api GET "/grants?limit=1" | jq -r '.data[0].id')
nylas_api GET "/grants/$GRANT_ID/calendars?limit=20" \
    | jq -r '.data[] | "\(.id[0:16])\t\(.name[0:30])\t\(.is_primary)\t\(.read_only)"' \
    | column -t | head -15

echo ""
echo "=== Upcoming Events ==="
nylas_api GET "/grants/$GRANT_ID/events?limit=20&start=$(date +%s)&calendar_id=primary" \
    | jq -r '.data[] | "\(.when.start_time | strftime("%Y-%m-%d %H:%M"))\t\(.title[0:30])\t\(.status)\t\(.participants | length) attendees"' \
    | head -15
```

## Phase 2: Analysis

### Calendar Health

```bash
#!/bin/bash
GRANT_ID=$(nylas_api GET "/grants?limit=1" | jq -r '.data[0].id')

echo "=== Event Summary (next 7 days) ==="
START=$(date +%s)
END=$(date -d '7 days' +%s)
nylas_api GET "/grants/$GRANT_ID/events?limit=100&start=$START&end=$END&calendar_id=primary" \
    | jq '{
        total_events: (.data | length),
        by_status: (.data | group_by(.status) | map({(.[0].status): length}) | add),
        avg_duration_min: (.data | map((.when.end_time - .when.start_time) / 60) | if length > 0 then add / length | floor else 0 end)
    }'

echo ""
echo "=== Events Per Day ==="
nylas_api GET "/grants/$GRANT_ID/events?limit=100&start=$START&end=$END&calendar_id=primary" \
    | jq -r '.data[] | .when.start_time | strftime("%Y-%m-%d")' | sort | uniq -c | sort -k2

echo ""
echo "=== Cancelled/Declined Events ==="
nylas_api GET "/grants/$GRANT_ID/events?limit=20&start=$START&end=$END&calendar_id=primary" \
    | jq -r '.data[] | select(.status == "cancelled") | "\(.when.start_time | strftime("%Y-%m-%d %H:%M"))\t\(.title[0:30])"' \
    | head -10
```

### Account Sync Health

```bash
#!/bin/bash
echo "=== Grant Status Summary ==="
nylas_api GET "/grants?limit=50" \
    | jq -r '.data[] | .grant_status' | sort | uniq -c | sort -rn

echo ""
echo "=== Grants with Issues ==="
nylas_api GET "/grants?limit=50" \
    | jq -r '.data[] | select(.grant_status != "valid") | "\(.id[0:16])\t\(.email)\t\(.grant_status)\t\(.provider)"' \
    | head -10

echo ""
echo "=== Scheduling Pages ==="
nylas_api GET "/scheduling/configurations?limit=10" \
    | jq -r '.data[] | "\(.id[0:16])\t\(.name[0:30])\t\(.event_booking.duration_minutes)min"' \
    | head -10
```

## Output Format

```
=== Nylas Account ===
Connected Grants: <n>  Healthy: <n>  Invalid: <n>

--- Calendar (7d) ---
Events: <n>  Avg Duration: <n>min
By Status: confirmed: <n>, cancelled: <n>

--- Scheduling Pages ---
Total: <n>
```

## Common Pitfalls
- **Grant-scoped**: Most endpoints require a grant ID in the URL path
- **Timestamps**: Use Unix epoch seconds for event time filters
- **v3 API**: Nylas v3 is significantly different from v2; use v3 endpoints
- **Rate limits**: 5 requests/second per grant; 60 requests/second per application
- **Provider differences**: Google, Microsoft, and IMAP have different capabilities
