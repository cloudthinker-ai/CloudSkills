---
name: managing-plivo
description: |
  Plivo cloud communications platform management for voice calls, SMS messaging, phone number management, and usage analytics. Use when analyzing message delivery rates, monitoring call quality, reviewing Plivo account usage and billing, or managing phone number inventory.
connection_type: plivo
preload: false
---

# Plivo Management Skill

Manage and analyze Plivo voice, messaging, and phone number resources.

## API Conventions

### Authentication
All API calls use HTTP Basic Auth with Auth ID and Auth Token, injected automatically.

### Base URL
`https://api.plivo.com/v1/Account/$PLIVO_AUTH_ID`

### Core Helper Function

```bash
#!/bin/bash

plivo_api() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"

    if [ -n "$data" ]; then
        curl -s -X "$method" \
            -u "$PLIVO_AUTH_ID:$PLIVO_AUTH_TOKEN" \
            -H "Content-Type: application/json" \
            "https://api.plivo.com/v1/Account/${PLIVO_AUTH_ID}${endpoint}/" \
            -d "$data"
    else
        curl -s -X "$method" \
            -u "$PLIVO_AUTH_ID:$PLIVO_AUTH_TOKEN" \
            "https://api.plivo.com/v1/Account/${PLIVO_AUTH_ID}${endpoint}/"
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
echo "=== Account Details ==="
plivo_api GET "" | jq '{auth_id: .auth_id, name: .name, cash_credits: .cash_credits, state: .state}'

echo ""
echo "=== Phone Numbers ==="
plivo_api GET "/Number?limit=50" \
    | jq -r '.objects[] | "\(.number)\t\(.region)\t\(.type)\t\(.sms_enabled)\t\(.voice_enabled)"' \
    | column -t | head -20

echo ""
echo "=== Applications ==="
plivo_api GET "/Application?limit=20" \
    | jq -r '.objects[] | "\(.app_id[0:12])\t\(.app_name)\t\(.default_endpoint_app)"' \
    | column -t | head -15
```

## Phase 2: Analysis

### Messaging Health

```bash
#!/bin/bash
echo "=== Recent Messages ==="
plivo_api GET "/Message?limit=50&offset=0" \
    | jq -r '.objects[] | "\(.message_time[0:16])\t\(.message_direction)\t\(.message_state)\t\(.to_number)"' \
    | head -20

echo ""
echo "=== Message Status Breakdown ==="
plivo_api GET "/Message?limit=200" \
    | jq -r '.objects[] | .message_state' | sort | uniq -c | sort -rn

echo ""
echo "=== Failed Messages ==="
plivo_api GET "/Message?limit=100" \
    | jq -r '.objects[] | select(.message_state == "failed") | "\(.message_time[0:16])\t\(.error_code)\t\(.to_number)"' \
    | head -10
```

### Call & Usage Analytics

```bash
#!/bin/bash
echo "=== Recent Calls ==="
plivo_api GET "/Call?limit=50" \
    | jq -r '.objects[] | "\(.initiation_time[0:16])\t\(.call_direction)\t\(.call_duration)s\t\(.end_time[0:16])"' \
    | head -20

echo ""
echo "=== Pricing / Usage ==="
plivo_api GET "/Pricing" | jq '{country: .country, phone_code: .phone_code}' | head -10
```

## Output Format

```
=== Account: <name> ===
Balance: $<cash_credits>  State: <active|suspended>

--- Phone Numbers: <count> ---
<number>  <region>  SMS:<y/n>  Voice:<y/n>

--- Messaging Health ---
Delivered: <n>  Failed: <n>  Queued: <n>

--- Call Summary ---
Total: <n>  Avg Duration: <n>s
```

## Common Pitfalls
- **Trailing slash**: Plivo API requires trailing `/` on all endpoints
- **Pagination**: Use `limit` and `offset` params; check `meta.total_count` for total
- **Rate limits**: 20 requests/second for most endpoints
- **Number format**: Use E.164 format with country code (e.g., 14155551234)
