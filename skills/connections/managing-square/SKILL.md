---
name: managing-square
description: |
  Use when working with Square — square payment and commerce platform management
  including locations, catalog, orders, payments, subscriptions, invoices, team
  members, and devices. Covers payment volume metrics, location performance,
  catalog health, and device connectivity status.
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

## Anti-Hallucination Rules

1. **NEVER assume resource names** — always discover via CLI/API in Phase 1 before referencing in Phase 2.
2. **NEVER fabricate metric names or dimensions** — verify against the service documentation or `--help` output.
3. **NEVER mix CLI commands between service versions** — confirm which version/API you are targeting.
4. **ALWAYS use the discovery → verify → analyze chain** — every resource referenced must have been discovered first.
5. **ALWAYS handle empty results gracefully** — an empty response is valid data, not an error to retry.

## Counter-Rationalizations

| Shortcut | Counter | Why |
|----------|---------|-----|
| "I'll skip discovery and check known resources" | Always run Phase 1 discovery first | Resource names change, new resources appear — assumed names cause errors |
| "The user only asked for a quick check" | Follow the full discovery → analysis flow | Quick checks miss critical issues; structured analysis catches silent failures |
| "Default configuration is probably fine" | Audit configuration explicitly | Defaults often leave logging, security, and optimization features disabled |
| "Metrics aren't needed for this" | Always check relevant metrics when available | API/CLI responses show current state; metrics reveal trends and intermittent issues |
| "I don't have access to that" | Try the command and report the actual error | Assumed permission failures prevent useful investigation; actual errors are informative |

## Common Pitfalls

- **Sandbox vs Production**: Use connect.squareupsandbox.com for testing
- **Location scoping**: Most queries are location-scoped — specify location_id
- **Amount in cents**: All amounts are in smallest currency unit (cents)
- **OAuth scopes**: Each API requires specific scopes — check permissions on failure
