---
name: managing-square
description: |
  Square payment and commerce platform management including locations, catalog, orders, payments, subscriptions, invoices, team members, and devices. Covers payment volume metrics, location performance, catalog health, and device connectivity status.
connection_type: square
preload: false
---

# Square Management Skill

Monitor and manage Square commerce and payment infrastructure.

## MANDATORY: Discovery-First Pattern

**Always discover locations and catalog before querying orders or payments.**

### Phase 1: Discovery

```bash
#!/bin/bash
SQ_API="https://connect.squareup.com/v2"
AUTH="Authorization: Bearer ${SQUARE_ACCESS_TOKEN}"

echo "=== Merchant Info ==="
curl -s -H "$AUTH" "$SQ_API/merchants/me" | \
  jq -r '.merchant | "Name: \(.business_name)\nCountry: \(.country)\nCurrency: \(.currency)\nStatus: \(.status)"'

echo ""
echo "=== Locations ==="
curl -s -H "$AUTH" "$SQ_API/locations" | \
  jq -r '.locations[] | "\(.name) | ID: \(.id) | Status: \(.status) | Type: \(.type) | Timezone: \(.timezone)"'

echo ""
echo "=== Catalog Summary ==="
curl -s -H "$AUTH" "$SQ_API/catalog/info" | \
  jq -r '.limits | to_entries[] | "\(.key): \(.value)"' 2>/dev/null
curl -s -H "$AUTH" -X POST "$SQ_API/catalog/search" \
  -H "Content-Type: application/json" \
  -d '{"object_types":["ITEM"],"limit":1}' | \
  jq -r '"Catalog items available: \(.objects | length) (sample)"'

echo ""
echo "=== Devices ==="
curl -s -H "$AUTH" "$SQ_API/devices" | \
  jq -r '.devices[] | "\(.name) | ID: \(.id) | Status: \(.status) | Code: \(.device_code.code // "N/A")"' 2>/dev/null || echo "No devices registered"
```

**Phase 1 outputs:** Merchant info, locations, catalog overview, devices

### Phase 2: Analysis

```bash
#!/bin/bash
echo "=== Recent Payments (last 7 days) ==="
curl -s -H "$AUTH" -X POST "$SQ_API/payments/search" \
  -H "Content-Type: application/json" \
  -d "{\"query\":{\"filter\":{\"date_time_filter\":{\"created_at\":{\"start_at\":\"$(date -v-7d +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -d '7 days ago' +%Y-%m-%dT%H:%M:%SZ)\"}}}},\"limit\":100}" | \
  jq -r '"Total Payments: \(.payments | length)\nTotal Amount: \([.payments[].amount_money.amount] | add // 0 | . / 100)\nCompleted: \([.payments[] | select(.status=="COMPLETED")] | length)\nFailed: \([.payments[] | select(.status=="FAILED")] | length)"'

echo ""
echo "=== Payment Methods Breakdown ==="
curl -s -H "$AUTH" -X POST "$SQ_API/payments/search" \
  -H "Content-Type: application/json" \
  -d "{\"query\":{\"filter\":{\"date_time_filter\":{\"created_at\":{\"start_at\":\"$(date -v-7d +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -d '7 days ago' +%Y-%m-%dT%H:%M:%SZ)\"}}}},\"limit\":100}" | \
  jq -r '[.payments[].source_type] | group_by(.) | map({type: .[0], count: length}) | sort_by(-.count) | .[] | "\(.type): \(.count)"'

echo ""
echo "=== Refunds Summary ==="
curl -s -H "$AUTH" "$SQ_API/refunds?begin_time=$(date -v-30d +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -d '30 days ago' +%Y-%m-%dT%H:%M:%SZ)&limit=50" | \
  jq -r '"Refunds (30d): \(.refunds | length)\nRefund Amount: \([.refunds[].amount_money.amount] | add // 0 | . / 100)"'

echo ""
echo "=== Active Subscriptions ==="
curl -s -H "$AUTH" -X POST "$SQ_API/subscriptions/search" \
  -H "Content-Type: application/json" \
  -d '{"query":{"filter":{"status":["ACTIVE"]}},"limit":100}' | \
  jq -r '"Active Subscriptions: \(.subscriptions | length // 0)"'
```

## Output Format

```
SQUARE STATUS
=============
Merchant: {name} ({country})
Locations: {active}/{total}
7-Day Payments: {count} ({amount} {currency})
Success Rate: {percent}%
Refund Rate: {percent}%
Active Subscriptions: {count}
Devices: {online}/{total} online
Issues: {list_of_warnings}
```

## Common Pitfalls

- **Sandbox vs Production**: Use connect.squareupsandbox.com for testing
- **Location scoping**: Most queries are location-scoped — specify location_id
- **Amount in cents**: All amounts are in smallest currency unit (cents)
- **OAuth scopes**: Each API requires specific scopes — check permissions on failure
