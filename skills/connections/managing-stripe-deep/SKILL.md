---
name: managing-stripe-deep
description: |
  Use when working with Stripe Deep — advanced Stripe payment platform
  management including payment intents, subscriptions, invoices, disputes,
  payouts, Connect accounts, radar fraud rules, and billing portal. Covers
  revenue analytics, dispute rate monitoring, payout scheduling, and webhook
  health.
connection_type: stripe-deep
preload: false
---

# Stripe Deep Management Skill

Advanced monitoring and management of Stripe payment infrastructure.

## MANDATORY: Discovery-First Pattern

**Always discover account capabilities and active products before querying transactions.**

### Phase 1: Discovery

```bash
#!/bin/bash
STRIPE_API="https://api.stripe.com/v1"
AUTH="-u ${STRIPE_SECRET_KEY}:"

echo "=== Account Info ==="
curl -s $AUTH "$STRIPE_API/account" | \
  jq -r '"Name: \(.settings.dashboard.display_name)\nCountry: \(.country)\nPayouts Enabled: \(.payouts_enabled)\nCharges Enabled: \(.charges_enabled)\nCapabilities: \(.capabilities | to_entries | map(select(.value=="active")) | map(.key) | join(", "))"'

echo ""
echo "=== Active Products ==="
curl -s $AUTH "$STRIPE_API/products?active=true&limit=10" | \
  jq -r '.data[] | "\(.name) | ID: \(.id) | Created: \(.created | todate)"'

echo ""
echo "=== Webhook Endpoints ==="
curl -s $AUTH "$STRIPE_API/webhook_endpoints?limit=10" | \
  jq -r '.data[] | "\(.url) | Status: \(.status) | Events: \(.enabled_events | length)"'

echo ""
echo "=== Connected Accounts (if Connect) ==="
curl -s $AUTH "$STRIPE_API/accounts?limit=5" | \
  jq -r '.data[] | "\(.id) | Type: \(.type) | Payouts: \(.payouts_enabled)"' 2>/dev/null || echo "Connect not enabled"
```

**Phase 1 outputs:** Account capabilities, products, webhooks, connected accounts

### Phase 2: Analysis

```bash
#!/bin/bash
echo "=== Revenue (last 30 days) ==="
curl -s $AUTH "$STRIPE_API/charges?limit=100&created[gte]=$(date -v-30d +%s 2>/dev/null || date -d '30 days ago' +%s)" | \
  jq -r '[.data[] | select(.status=="succeeded")] | "Successful Charges: \(length)\nTotal Revenue: \([.[].amount] | add // 0 | . / 100) \(.[-1].currency // "usd" | ascii_upcase)"'

echo ""
echo "=== Subscription Metrics ==="
curl -s $AUTH "$STRIPE_API/subscriptions?limit=100&status=active" | \
  jq -r '"Active Subscriptions: \(.data | length)\nMRR (sample): \([.data[].items.data[0].price.unit_amount // 0] | add / 100)"'

echo ""
echo "=== Disputes ==="
curl -s $AUTH "$STRIPE_API/disputes?limit=20" | \
  jq -r '"Open Disputes: \([.data[] | select(.status | test("needs_response|under_review"))] | length)\nTotal: \(.data | length)"'
curl -s $AUTH "$STRIPE_API/disputes?limit=5" | \
  jq -r '.data[:5] | .[] | "\(.id) | Amount: \(.amount/100) | Status: \(.status) | Reason: \(.reason)"'

echo ""
echo "=== Failed Payments (last 7 days) ==="
curl -s $AUTH "$STRIPE_API/charges?limit=50&created[gte]=$(date -v-7d +%s 2>/dev/null || date -d '7 days ago' +%s)" | \
  jq -r '[.data[] | select(.status=="failed")] | "Failed Charges: \(length)\nFailure Codes: \([.[].failure_code] | group_by(.) | map({code: .[0], count: length}) | sort_by(-.count)[:5])"'

echo ""
echo "=== Payout Schedule ==="
curl -s $AUTH "$STRIPE_API/balance" | \
  jq -r '.available[] | "Available: \(.amount/100) \(.currency | ascii_upcase)"'
curl -s $AUTH "$STRIPE_API/payouts?limit=5" | \
  jq -r '.data[] | "\(.id) | Amount: \(.amount/100) | Status: \(.status) | Arrival: \(.arrival_date | todate)"'
```

## Output Format

```
STRIPE DEEP STATUS
==================
Account: {name} ({country})
Capabilities: {list}
30-Day Revenue: {amount} {currency}
Active Subscriptions: {count}
Disputes: {open} open / {total} total
Failed Payments (7d): {count}
Available Balance: {amount}
Webhook Endpoints: {count} ({healthy}/{total} healthy)
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

- **Test vs Live mode**: API key prefix determines mode (sk_test_ vs sk_live_) — never mix
- **Dispute rate**: Visa/MC threshold is 0.9% — monitor proactively
- **Pagination**: Default limit is 10 — always set limit for accurate counts
- **Webhook signatures**: Verify webhook signatures — missing verification is a security risk
- **Idempotency**: Always use idempotency keys for payment creation
