---
name: managing-vonage
description: |
  Vonage (formerly Nexmo) communications platform management covering SMS, voice, video, and messaging APIs. Use when analyzing message delivery, monitoring voice call quality, reviewing account balance, or managing Vonage applications and phone numbers.
connection_type: vonage
preload: false
---

# Vonage Management Skill

Manage and analyze Vonage communications resources including SMS, voice, and video APIs.

## API Conventions

### Authentication
API calls use API Key and Secret as query parameters or Basic Auth, injected automatically.

### Base URL
`https://api.nexmo.com` (REST) and `https://api.nexmo.com/v2` (v2 endpoints)

### Core Helper Function

```bash
#!/bin/bash

vonage_api() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"

    if [ -n "$data" ]; then
        curl -s -X "$method" \
            -H "Authorization: Basic $(echo -n "$VONAGE_API_KEY:$VONAGE_API_SECRET" | base64)" \
            -H "Content-Type: application/json" \
            "https://api.nexmo.com${endpoint}" \
            -d "$data"
    else
        curl -s -X "$method" \
            -H "Authorization: Basic $(echo -n "$VONAGE_API_KEY:$VONAGE_API_SECRET" | base64)" \
            "https://api.nexmo.com${endpoint}"
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
echo "=== Account Balance ==="
vonage_api GET "/account/get-balance?api_key=$VONAGE_API_KEY&api_secret=$VONAGE_API_SECRET" \
    | jq '{balance: .value, auto_reload: .autoReload}'

echo ""
echo "=== Owned Numbers ==="
vonage_api GET "/account/numbers?api_key=$VONAGE_API_KEY&api_secret=$VONAGE_API_SECRET&size=50" \
    | jq -r '.numbers[] | "\(.msisdn)\t\(.country)\t\(.type)\t\(.features | join(","))"' \
    | column -t | head -20

echo ""
echo "=== Applications ==="
vonage_api GET "/v2/applications?page_size=50" \
    | jq -r '._embedded.applications[] | "\(.id[0:12])\t\(.name)\t\(.capabilities | keys | join(","))"' \
    | column -t | head -15
```

## Phase 2: Analysis

### Message Delivery Analysis

```bash
#!/bin/bash
echo "=== SMS Search (last 24h) ==="
DATE=$(date -u -d '1 day ago' +%Y-%m-%d)
vonage_api GET "/search/messages?api_key=$VONAGE_API_KEY&api_secret=$VONAGE_API_SECRET&date=$DATE&limit=100" \
    | jq -r '.items[] | "\(.date_received)\t\(.type)\t\(.status)\t\(.to)\t\(.error_code // "ok")"' \
    | head -20

echo ""
echo "=== Delivery Status Breakdown ==="
vonage_api GET "/search/messages?api_key=$VONAGE_API_KEY&api_secret=$VONAGE_API_SECRET&date=$DATE&limit=200" \
    | jq -r '.items[] | .status' | sort | uniq -c | sort -rn
```

### Account Health

```bash
#!/bin/bash
echo "=== Account Configuration ==="
vonage_api GET "/account/settings?api_key=$VONAGE_API_KEY&api_secret=$VONAGE_API_SECRET" \
    | jq '{max_outbound_request: .max_outbound_request, max_inbound_request: .max_inbound_request}'

echo ""
echo "=== Number Inventory Summary ==="
vonage_api GET "/account/numbers?api_key=$VONAGE_API_KEY&api_secret=$VONAGE_API_SECRET&size=100" \
    | jq '{
        total: (.numbers | length),
        by_country: (.numbers | group_by(.country) | map({(.[0].country): length}) | add),
        by_type: (.numbers | group_by(.type) | map({(.[0].type): length}) | add)
    }'
```

## Output Format

```
=== Account Balance: $<amount> ===
Auto-Reload: <enabled|disabled>

--- Numbers ---
Total: <n>  By Country: US:<n>, GB:<n>
By Type: mobile:<n>, landline:<n>

--- Message Delivery (24h) ---
Delivered: <n>  Failed: <n>  Pending: <n>
Top Errors: <code>: <count>
```

## Common Pitfalls
- **Auth methods vary**: Some endpoints use query params, others use Basic Auth or JWT
- **Rate limits**: SMS is 30 requests/second, voice is 5 requests/second
- **Number format**: Always use E.164 format (no +, just digits like 14155551234)
- **Pagination**: Use `page` and `page_size` parameters; check `total_pages` in response
