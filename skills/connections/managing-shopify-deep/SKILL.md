---
name: managing-shopify-deep
description: |
  Use when working with Shopify Deep — advanced Shopify store management
  including products, inventory, orders, customers, analytics, fulfillment,
  shipping, themes, apps, and webhooks. Covers sales performance, inventory
  health, fulfillment rates, abandoned cart analysis, and app ecosystem
  monitoring.
connection_type: shopify-deep
preload: false
---

# Shopify Deep Management Skill

Advanced monitoring and management of Shopify store operations.

## MANDATORY: Discovery-First Pattern

**Always discover shop info and resource counts before querying detailed data.**

### Phase 1: Discovery

```bash
#!/bin/bash
SHOP_API="https://${SHOPIFY_STORE}.myshopify.com/admin/api/2024-10"
AUTH="X-Shopify-Access-Token: ${SHOPIFY_ACCESS_TOKEN}"

echo "=== Shop Info ==="
curl -s -H "$AUTH" "$SHOP_API/shop.json" | \
  jq -r '.shop | "Name: \(.name)\nDomain: \(.domain)\nPlan: \(.plan_display_name)\nCurrency: \(.currency)\nTimezone: \(.timezone)\nCreated: \(.created_at)"'

echo ""
echo "=== Resource Counts ==="
for resource in products orders customers; do
  count=$(curl -s -H "$AUTH" "$SHOP_API/$resource/count.json" | jq '.count')
  echo "$resource: $count"
done

echo ""
echo "=== Locations ==="
curl -s -H "$AUTH" "$SHOP_API/locations.json" | \
  jq -r '.locations[] | "\(.name) | ID: \(.id) | Active: \(.active) | Type: \(.localized_country_name)"'

echo ""
echo "=== Installed Apps ==="
curl -s -H "$AUTH" "$SHOP_API/installed_apps.json" 2>/dev/null | \
  jq -r '.installed_apps[]? | "\(.name) | ID: \(.id)"' || echo "Check apps via Partners Dashboard"

echo ""
echo "=== Webhooks ==="
curl -s -H "$AUTH" "$SHOP_API/webhooks.json" | \
  jq -r '.webhooks[] | "\(.topic) -> \(.address) | Format: \(.format)"'
```

**Phase 1 outputs:** Shop config, resource counts, locations, webhooks

### Phase 2: Analysis

```bash
#!/bin/bash
echo "=== Recent Orders (last 30 days) ==="
curl -s -H "$AUTH" "$SHOP_API/orders.json?created_at_min=$(date -v-30d +%Y-%m-%dT%H:%M:%S 2>/dev/null || date -d '30 days ago' +%Y-%m-%dT%H:%M:%S)&limit=250&status=any" | \
  jq -r '"Total Orders: \(.orders | length)\nRevenue: \([.orders[].total_price | tonumber] | add // 0)\nFulfilled: \([.orders[] | select(.fulfillment_status=="fulfilled")] | length)\nUnfulfilled: \([.orders[] | select(.fulfillment_status==null)] | length)\nRefunded: \([.orders[] | select(.financial_status=="refunded")] | length)"'

echo ""
echo "=== Inventory Warnings ==="
curl -s -H "$AUTH" "$SHOP_API/products.json?limit=50" | \
  jq -r '[.products[] | .variants[] | select(.inventory_quantity <= 5 and .inventory_management == "shopify")] | sort_by(.inventory_quantity) | .[:10] | .[] | "\(.title) (SKU: \(.sku)) | Stock: \(.inventory_quantity)"'

echo ""
echo "=== Abandoned Checkouts ==="
curl -s -H "$AUTH" "$SHOP_API/checkouts.json?limit=50" | \
  jq -r '"Abandoned Checkouts: \(.checkouts | length)\nAbandoned Value: \([.checkouts[].total_price | tonumber] | add // 0)"'

echo ""
echo "=== Top Products by Sales ==="
curl -s -H "$AUTH" "$SHOP_API/orders.json?limit=250&status=any&created_at_min=$(date -v-30d +%Y-%m-%dT%H:%M:%S 2>/dev/null || date -d '30 days ago' +%Y-%m-%dT%H:%M:%S)" | \
  jq -r '[.orders[].line_items[]] | group_by(.product_id) | map({title: .[0].title, qty: [.[].quantity] | add, revenue: [.[].price | tonumber * 100 | floor / 100] | add}) | sort_by(-.revenue) | .[:5] | .[] | "\(.title) | Qty: \(.qty) | Revenue: \(.revenue)"'
```

## Output Format

```
SHOPIFY DEEP STATUS
===================
Store: {name} ({plan})
Products: {count} | Orders: {count} | Customers: {count}
30-Day Revenue: {amount} {currency}
Fulfillment Rate: {percent}%
Low Stock Items: {count}
Abandoned Carts: {count} ({value})
Webhooks: {count} configured
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

- **API versioning**: Shopify uses date-based versioning (2024-10) — pin to a stable version
- **Rate limits**: 2 requests/second for REST — use GraphQL for bulk operations
- **Pagination**: Use cursor-based pagination (page_info) — not page numbers
- **Inventory tracking**: Only products with inventory_management="shopify" are tracked
