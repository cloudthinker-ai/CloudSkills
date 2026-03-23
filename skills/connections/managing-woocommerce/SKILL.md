---
name: managing-woocommerce
description: |
  Use when working with Woocommerce — wooCommerce store management via REST API
  including products, orders, customers, coupons, shipping, taxes, reports, and
  system status. Covers sales analytics, inventory monitoring, order
  fulfillment, payment gateway health, and WordPress plugin compatibility.
connection_type: woocommerce
preload: false
---

# WooCommerce Management Skill

Monitor and manage WooCommerce stores via the REST API.

## MANDATORY: Discovery-First Pattern

**Always discover store system status and resources before querying orders or products.**

### Phase 1: Discovery

```bash
#!/bin/bash
WC_API="${WOOCOMMERCE_URL}/wp-json/wc/v3"
AUTH="-u ${WOOCOMMERCE_KEY}:${WOOCOMMERCE_SECRET}"

echo "=== System Status ==="
curl -s $AUTH "$WC_API/system_status" | \
  jq -r '"WC Version: \(.environment.version)\nWP Version: \(.environment.wp_version)\nPHP: \(.environment.php_version)\nDB: \(.environment.mysql_version)\nTheme: \(.theme.name) \(.theme.version)\nCurrency: \(.settings.currency)"'

echo ""
echo "=== Active Plugins ==="
curl -s $AUTH "$WC_API/system_status" | \
  jq -r '.active_plugins[] | "\(.plugin): \(.version)"' | head -15

echo ""
echo "=== Payment Gateways ==="
curl -s $AUTH "$WC_API/payment_gateways" | \
  jq -r '.[] | "\(.id) | Title: \(.title) | Enabled: \(.enabled)"'

echo ""
echo "=== Shipping Zones ==="
curl -s $AUTH "$WC_API/shipping/zones" | \
  jq -r '.[] | "\(.name) | ID: \(.id)"'

echo ""
echo "=== Resource Counts ==="
products=$(curl -s $AUTH "$WC_API/reports/products/totals" | jq '[.[].total] | add')
orders=$(curl -s $AUTH "$WC_API/reports/orders/totals" | jq '[.[].total] | add')
customers=$(curl -s $AUTH "$WC_API/reports/customers/totals" | jq '[.[].total] | add')
echo "Products: $products | Orders: $orders | Customers: $customers"
```

**Phase 1 outputs:** System status, plugins, gateways, resource counts

### Phase 2: Analysis

```bash
#!/bin/bash
echo "=== Sales Report (last 30 days) ==="
curl -s $AUTH "$WC_API/reports/sales?date_min=$(date -v-30d +%Y-%m-%d 2>/dev/null || date -d '30 days ago' +%Y-%m-%d)&date_max=$(date +%Y-%m-%d)" | \
  jq -r '.[] | "Total Sales: \(.total_sales)\nNet Sales: \(.net_sales)\nOrders: \(.total_orders)\nItems Sold: \(.total_items)\nAvg Order: \(.average_sales)\nRefunds: \(.total_refunds)"'

echo ""
echo "=== Order Status Distribution ==="
curl -s $AUTH "$WC_API/reports/orders/totals" | \
  jq -r '.[] | "\(.name): \(.total)"'

echo ""
echo "=== Low Stock Products ==="
curl -s $AUTH "$WC_API/products?stock_status=lowstock&per_page=10" | \
  jq -r '.[] | "\(.name) | SKU: \(.sku) | Stock: \(.stock_quantity) | Status: \(.stock_status)"'

echo ""
echo "=== Top Products (30 days) ==="
curl -s $AUTH "$WC_API/reports/top_sellers?period=month" | \
  jq -r '.[:5] | .[] | "ID: \(.product_id) | Name: \(.name // "N/A") | Qty: \(.quantity)"'

echo ""
echo "=== System Warnings ==="
curl -s $AUTH "$WC_API/system_status" | \
  jq -r '.pages[] | select(.page_on_front == false) | "Missing page: \(.page_name)"' 2>/dev/null
```

## Output Format

```
WOOCOMMERCE STATUS
==================
Store: {url} | WC {version} on WP {version}
Products: {count} | Orders: {count} | Customers: {count}
30-Day Sales: {amount} ({orders} orders)
Avg Order Value: {amount}
Low Stock Items: {count}
Payment Gateways: {enabled}/{total} enabled
Plugin Count: {count} active
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

- **Authentication**: WooCommerce uses OAuth 1.0a or basic auth over HTTPS — never use HTTP
- **Permalink structure**: REST API requires pretty permalinks enabled in WordPress
- **Rate limits**: Depends on hosting — shared hosting may throttle API requests
- **Plugin conflicts**: WooCommerce extensions can modify API behavior — check system status
