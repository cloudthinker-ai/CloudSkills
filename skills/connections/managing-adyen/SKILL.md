---
name: managing-adyen
description: |
  Adyen payment platform management including merchant accounts, payment methods, terminal configuration, risk management, settlement reports, and webhook notifications. Covers authorization rates, payment method performance, fraud scoring, and payout reconciliation.
connection_type: adyen
preload: false
---

# Adyen Management Skill

Monitor and manage Adyen payment processing infrastructure.

## MANDATORY: Discovery-First Pattern

**Always discover merchant accounts and payment methods before querying transaction data.**

### Phase 1: Discovery

```bash
#!/bin/bash
ADYEN_API="https://${ADYEN_ENVIRONMENT:-checkout-test}.adyen.com"
MGMT_API="https://management-${ADYEN_ENVIRONMENT:-test}.adyen.com/v3"
AUTH="X-API-Key: ${ADYEN_API_KEY}"

echo "=== Company Account ==="
curl -s -H "$AUTH" "$MGMT_API/companies/${ADYEN_COMPANY_ID}" | \
  jq -r '"Company: \(.name)\nStatus: \(.status)\nData Centers: \(.dataCenters | join(", "))"'

echo ""
echo "=== Merchant Accounts ==="
curl -s -H "$AUTH" "$MGMT_API/companies/${ADYEN_COMPANY_ID}/merchants" | \
  jq -r '.data[] | "\(.name) | ID: \(.id) | Status: \(.status) | Channels: \(.salesChannels)"'

echo ""
echo "=== Payment Methods ==="
curl -s -H "$AUTH" -H "Content-Type: application/json" \
  "$ADYEN_API/v71/paymentMethods" \
  -d "{\"merchantAccount\": \"${ADYEN_MERCHANT_ACCOUNT}\"}" | \
  jq -r '.paymentMethods[] | "\(.name) | Type: \(.type) | Brands: \(.brands // [] | join(","))"'

echo ""
echo "=== Webhooks ==="
curl -s -H "$AUTH" "$MGMT_API/merchants/${ADYEN_MERCHANT_ACCOUNT}/webhooks" | \
  jq -r '.data[] | "\(.type) | URL: \(.url) | Active: \(.active) | SSL: \(.sslVersion)"'
```

**Phase 1 outputs:** Company info, merchant accounts, payment methods, webhooks

### Phase 2: Analysis

```bash
#!/bin/bash
echo "=== Authorization Rate (via reporting) ==="
curl -s -H "$AUTH" -H "Content-Type: application/json" \
  "https://reporting-${ADYEN_ENVIRONMENT:-test}.adyen.com/v1/analytics/transactions" \
  -d "{
    \"merchantAccountCode\": \"${ADYEN_MERCHANT_ACCOUNT}\",
    \"timeRange\": {\"startDate\": \"$(date -v-7d +%Y-%m-%d 2>/dev/null || date -d '7 days ago' +%Y-%m-%d)\", \"endDate\": \"$(date +%Y-%m-%d)\"}
  }" | jq -r '"Authorized: \(.authorized)\nRefused: \(.refused)\nAuth Rate: \(.authorizationRate)%"' 2>/dev/null || echo "Reporting API requires separate access"

echo ""
echo "=== Terminal Status ==="
curl -s -H "$AUTH" "$MGMT_API/merchants/${ADYEN_MERCHANT_ACCOUNT}/terminals?pageSize=20" | \
  jq -r '.data[] | "\(.id) | Model: \(.model) | Status: \(.connectivity.status) | Firmware: \(.firmwareVersion)"' 2>/dev/null || echo "No terminals configured"

echo ""
echo "=== Risk Rules ==="
curl -s -H "$AUTH" "$MGMT_API/merchants/${ADYEN_MERCHANT_ACCOUNT}/riskSettings" | \
  jq -r '.rules[] | "\(.description) | Enabled: \(.enabled) | Action: \(.action)"' 2>/dev/null || echo "Risk settings require additional permissions"

echo ""
echo "=== Recent Payouts ==="
curl -s -H "$AUTH" "$MGMT_API/merchants/${ADYEN_MERCHANT_ACCOUNT}/payouts?limit=5" | \
  jq -r '.data[] | "\(.pspReference) | Amount: \(.amount.value/100) \(.amount.currency) | Status: \(.status) | Date: \(.createdAt)"' 2>/dev/null || echo "Use settlement reports for payout data"
```

## Output Format

```
ADYEN STATUS
============
Company: {name} | Merchant: {account}
Payment Methods: {count} active
Authorization Rate (7d): {percent}%
Terminals: {online}/{total} online
Webhooks: {active}/{total} active
Risk Rules: {enabled}/{total} enabled
Issues: {list_of_warnings}
```

## Common Pitfalls

- **Environment URLs**: Test vs live use different subdomains — never mix credentials
- **API versioning**: Adyen uses version numbers in paths (v71) — check for latest
- **Merchant vs Company**: Company is top-level; merchant accounts are per-business-unit
- **PCI compliance**: Never log full card numbers — Adyen handles PCI scope
