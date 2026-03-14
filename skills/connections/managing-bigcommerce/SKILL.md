---
name: managing-bigcommerce
description: |
  BigCommerce store management including products, orders, customers, channels, shipping, inventory, storefront themes, and webhooks. Covers sales analytics, order fulfillment rates, inventory health, and multi-channel performance comparison.
connection_type: bigcommerce
preload: false
---

# BigCommerce Management Skill

Monitor and manage BigCommerce store operations and performance.

## MANDATORY: Discovery-First Pattern

**Always discover store info and channels before querying orders or products.**

### Phase 1: Discovery

```bash
#!/bin/bash
BC_API="https://api.bigcommerce.com/stores/${BIGCOMMERCE_STORE_HASH}/v3"
BC_V2="https://api.bigcommerce.com/stores/${BIGCOMMERCE_STORE_HASH}/v2"
AUTH="X-Auth-Token: ${BIGCOMMERCE_ACCESS_TOKEN}"

echo "=== Store Info ==="
curl -s -H "$AUTH" "$BC_V2/store" | \
  jq -r '"Name: \(.name)\nDomain: \(.domain)\nPlan: \(.plan_name)\nCurrency: \(.currency)\nStatus: \(.status)"'

echo ""
echo "=== Channels ==="
curl -s -H "$AUTH" "$BC_API/channels" | \
  jq -r '.data[] | "\(.name) | ID: \(.id) | Type: \(.type) | Platform: \(.platform) | Status: \(.status)"'

echo ""
echo "=== Resource Summary ==="
products=$(curl -s -H "$AUTH" "$BC_API/catalog/products?limit=1" | jq '.meta.pagination.total')
orders=$(curl -s -H "$AUTH" "$BC_V2/orders/count" | jq '.count')
customers=$(curl -s -H "$AUTH" "$BC_API/customers?limit=1" | jq '.meta.pagination.total')
echo "Products: $products | Orders: $orders | Customers: $customers"

echo ""
echo "=== Webhooks ==="
curl -s -H "$AUTH" "$BC_API/hooks" | \
  jq -r '.data[] | "\(.scope) -> \(.destination) | Active: \(.is_active)"'
```

**Phase 1 outputs:** Store info, channels, resource counts, webhooks

### Phase 2: Analysis

```bash
#!/bin/bash
echo "=== Order Summary (last 30 days) ==="
curl -s -H "$AUTH" "$BC_V2/orders?min_date_created=$(date -v-30d +%Y-%m-%dT%H:%M:%S 2>/dev/null || date -d '30 days ago' +%Y-%m-%dT%H:%M:%S)+00:00&limit=250" | \
  jq -r '"Orders: \(length)\nRevenue: \([.[].total_inc_tax | tonumber] | add // 0)\nStatuses: \([.[].status] | group_by(.) | map({s:.[0],c:length}) | sort_by(-.c) | .[] | "\(.s): \(.c)") "' 2>/dev/null

echo ""
echo "=== Low Stock Products ==="
curl -s -H "$AUTH" "$BC_API/catalog/products?inventory_level:less=5&is_visible=true&limit=10" | \
  jq -r '.data[] | "\(.name) | SKU: \(.sku) | Stock: \(.inventory_level) | Tracking: \(.inventory_tracking)"'

echo ""
echo "=== Shipping Zones ==="
curl -s -H "$AUTH" "$BC_V2/shipping/zones" | \
  jq -r '.[] | "\(.name) | ID: \(.id) | Enabled: \(.enabled)"'

echo ""
echo "=== Abandoned Carts ==="
curl -s -H "$AUTH" "$BC_API/abandoned-carts?limit=50" | \
  jq -r '"Abandoned: \(.data | length)"' 2>/dev/null || echo "Check abandoned cart recovery settings"
```

## Output Format

```
BIGCOMMERCE STATUS
==================
Store: {name} ({plan})
Products: {count} | Orders: {count} | Customers: {count}
Channels: {count} ({types})
30-Day Revenue: {amount} {currency}
Low Stock: {count} products
Shipping Zones: {count}
Webhooks: {active}/{total}
Issues: {list_of_warnings}
```

## Common Pitfalls

- **V2 vs V3 API**: Some endpoints are V2 only (orders, store info) — check documentation
- **Rate limits**: 150 requests per 30-second window — monitor X-Rate-Limit headers
- **Multi-channel**: Products can be assigned to specific channels — filter accordingly
- **Pagination**: V3 uses page-based; V2 uses limit/page — different patterns
