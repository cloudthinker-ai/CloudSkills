---
name: managing-convertkit
description: |
  ConvertKit (Kit) creator marketing platform management including subscriber management, forms, sequences, broadcasts, tags, and automation rules. Covers subscriber growth, email deliverability, sequence performance, and form conversion tracking.
connection_type: convertkit
preload: false
---

# ConvertKit Management Skill

Monitor and manage ConvertKit email marketing for creators.

## MANDATORY: Discovery-First Pattern

**Always discover account info and subscriber count before querying forms or sequences.**

### Phase 1: Discovery

```bash
#!/bin/bash
CK_API="https://api.convertkit.com/v3"
API_SECRET="${CONVERTKIT_API_SECRET}"

echo "=== Account Info ==="
curl -s "$CK_API/account?api_secret=$API_SECRET" | \
  jq -r '"Name: \(.name)\nPlan: \(.plan_name)\nSubscribers: \(.total_subscribers)"'

echo ""
echo "=== Forms ==="
curl -s "$CK_API/forms?api_secret=$API_SECRET" | \
  jq -r '.forms[] | "\(.name) | ID: \(.id) | Type: \(.type) | Subscribers: \(.total_subscriptions) | Created: \(.created_at)"'

echo ""
echo "=== Sequences ==="
curl -s "$CK_API/sequences?api_secret=$API_SECRET" | \
  jq -r '.courses[] | "\(.name) | ID: \(.id) | Subscribers: \(.total_subscriptions) | Created: \(.created_at)"'

echo ""
echo "=== Tags ==="
curl -s "$CK_API/tags?api_secret=$API_SECRET" | \
  jq -r '.tags[] | "\(.name) | ID: \(.id) | Created: \(.created_at)"' | head -20
```

**Phase 1 outputs:** Account plan, forms, sequences, tags

### Phase 2: Analysis

```bash
#!/bin/bash
echo "=== Subscriber Growth (recent) ==="
curl -s "$CK_API/subscribers?api_secret=$API_SECRET&sort_order=desc&per_page=5" | \
  jq -r '.subscribers[] | "\(.email_address) | State: \(.state) | Created: \(.created_at)"'

echo ""
echo "=== Subscriber States ==="
total=$(curl -s "$CK_API/subscribers?api_secret=$API_SECRET" | jq '.total_subscribers')
echo "Total subscribers: $total"

echo ""
echo "=== Broadcasts (recent) ==="
curl -s "$CK_API/broadcasts?api_secret=$API_SECRET" | \
  jq -r '.broadcasts[:10] | .[] | "\(.subject) | Status: \(.status) | Sent: \(.sent_at // "not sent")"'

echo ""
echo "=== Automations ==="
curl -s "$CK_API/automations?api_secret=$API_SECRET" | \
  jq -r '.automations[] | "\(.name) | Status: \(.status) | Subscribers: \(.subscriber_count)"' | head -10

echo ""
echo "=== Form Conversion Rates ==="
curl -s "$CK_API/forms?api_secret=$API_SECRET" | \
  jq -r '.forms[] | "\(.name): \(.total_subscriptions) subs from \(.total_unique_visitors // "N/A") visitors"'
```

## Output Format

```
CONVERTKIT STATUS
=================
Account: {name} ({plan})
Total Subscribers: {count}
Forms: {count} | Sequences: {count} | Tags: {count}
Recent Broadcasts: {count}
Active Automations: {count}
Top Form: {name} ({conversions} conversions)
Issues: {list_of_warnings}
```

## Common Pitfalls

- **API key vs API secret**: Most endpoints need api_secret, not api_key
- **Subscriber states**: active, cancelled, bounced, complained — filter accordingly
- **Rate limits**: 120 requests/minute — batch subscriber queries
- **Sequences vs Automations**: Sequences are linear email series; automations are rule-based workflows
