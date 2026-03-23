---
name: managing-paddle
description: |
  Use when working with Paddle — paddle billing and payments platform management
  including products, prices, subscriptions, transactions, customers, discounts,
  and payouts. Covers MRR tracking, churn analysis, subscription health, revenue
  recognition, and tax compliance status.
connection_type: paddle
preload: false
---

# Paddle Management Skill

Monitor and manage Paddle billing, subscriptions, and revenue.

## MANDATORY: Discovery-First Pattern

**Always discover products and pricing before querying subscription or transaction data.**

### Phase 1: Discovery

```bash
#!/bin/bash
PADDLE_API="https://api.paddle.com"
AUTH="Authorization: Bearer ${PADDLE_API_KEY}"

echo "=== Products ==="
curl -s -H "$AUTH" "$PADDLE_API/products?status=active" | \
  jq -r '.data[] | "\(.name) | ID: \(.id) | Status: \(.status) | Tax: \(.tax_category)"'

echo ""
echo "=== Prices ==="
curl -s -H "$AUTH" "$PADDLE_API/prices?status=active" | \
  jq -r '.data[] | "\(.description // .id) | Product: \(.product_id) | Amount: \(.unit_price.amount) \(.unit_price.currency_code) | Billing: \(.billing_cycle.interval // "one-time")"'

echo ""
echo "=== Discounts ==="
curl -s -H "$AUTH" "$PADDLE_API/discounts?status=active" | \
  jq -r '.data[] | "\(.description) | Code: \(.code // "auto") | Amount: \(.amount) \(.type) | Usage: \(.usage_limit // "unlimited")"'

echo ""
echo "=== Notification Settings ==="
curl -s -H "$AUTH" "$PADDLE_API/notification-settings" | \
  jq -r '.data[] | "\(.description) | URL: \(.destination) | Active: \(.active) | Events: \(.subscribed_events | length)"'
```

**Phase 1 outputs:** Products, prices, discounts, notification endpoints

### Phase 2: Analysis

```bash
#!/bin/bash
echo "=== Subscription Summary ==="
for status in active past_due paused canceled trialing; do
  count=$(curl -s -H "$AUTH" "$PADDLE_API/subscriptions?status=$status" | jq '.meta.pagination.estimated_total // 0')
  echo "$status: $count"
done

echo ""
echo "=== Recent Transactions ==="
curl -s -H "$AUTH" "$PADDLE_API/transactions?status=completed&order_by=created_at[DESC]&per_page=10" | \
  jq -r '.data[] | "\(.id) | Amount: \(.details.totals.total) \(.currency_code) | Customer: \(.customer_id) | \(.created_at)"'

echo ""
echo "=== Revenue Summary (recent transactions) ==="
curl -s -H "$AUTH" "$PADDLE_API/transactions?status=completed&per_page=100" | \
  jq -r '"Completed Transactions: \(.data | length)\nTotal Revenue: \([.data[].details.totals.total | tonumber] | add // 0)\nCurrencies: \([.data[].currency_code] | unique | join(", "))"'

echo ""
echo "=== Payout History ==="
curl -s -H "$AUTH" "$PADDLE_API/payouts?per_page=5" | \
  jq -r '.data[] | "\(.id) | Amount: \(.amount) \(.currency_code) | Status: \(.status) | Paid: \(.paid_at // "pending")"' 2>/dev/null || echo "Check payouts in dashboard"
```

## Output Format

```
PADDLE STATUS
=============
Products: {count} active | Prices: {count}
Subscriptions: Active={count} Trial={count} Past Due={count}
Monthly Revenue (sample): {amount}
Churn (past_due + canceled): {count}
Discounts: {active} active
Notification Endpoints: {count}
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

- **Paddle Classic vs Billing**: API endpoints differ — v1 is Classic, v2 is Billing
- **Sandbox**: Use sandbox-api.paddle.com for testing — separate credentials
- **Tax handling**: Paddle is merchant of record — tax is included in amounts
- **Pagination**: Use `after` cursor pagination — not page numbers
