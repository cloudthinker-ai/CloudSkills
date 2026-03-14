---
name: managing-klaviyo
description: |
  Klaviyo marketing automation platform management including email and SMS campaigns, flows, lists, segments, metrics, and revenue attribution. Covers deliverability monitoring, flow performance, list growth, and A/B testing results.
connection_type: klaviyo
preload: false
---

# Klaviyo Management Skill

Monitor and manage Klaviyo email and SMS marketing automation.

## MANDATORY: Discovery-First Pattern

**Always discover account metrics and lists before querying campaign or flow data.**

### Phase 1: Discovery

```bash
#!/bin/bash
KL_API="https://a.klaviyo.com/api"
AUTH="Authorization: Klaviyo-API-Key ${KLAVIYO_API_KEY}"
REV="revision: 2024-10-15"

echo "=== Account Info ==="
curl -s -H "$AUTH" -H "$REV" "$KL_API/accounts/" | \
  jq -r '.data[] | "ID: \(.id)\nIndustry: \(.attributes.industry)\nTimezone: \(.attributes.timezone)"'

echo ""
echo "=== Lists ==="
curl -s -H "$AUTH" -H "$REV" "$KL_API/lists/" | \
  jq -r '.data[] | "\(.attributes.name) | ID: \(.id) | Created: \(.attributes.created)"'

echo ""
echo "=== Segments ==="
curl -s -H "$AUTH" -H "$REV" "$KL_API/segments/" | \
  jq -r '.data[] | "\(.attributes.name) | ID: \(.id) | Created: \(.attributes.created)"'

echo ""
echo "=== Flows ==="
curl -s -H "$AUTH" -H "$REV" "$KL_API/flows/" | \
  jq -r '.data[] | "\(.attributes.name) | Status: \(.attributes.status) | Created: \(.attributes.created)"'

echo ""
echo "=== Active Metrics ==="
curl -s -H "$AUTH" -H "$REV" "$KL_API/metrics/" | \
  jq -r '.data[:10] | .[] | "\(.attributes.name) | Integration: \(.attributes.integration.name // "custom")"'
```

**Phase 1 outputs:** Account info, lists, segments, flows, metrics

### Phase 2: Analysis

```bash
#!/bin/bash
echo "=== Recent Campaigns ==="
curl -s -H "$AUTH" -H "$REV" "$KL_API/campaigns/?filter=equals(messages.channel,'email')&sort=-created_at" | \
  jq -r '.data[:10] | .[] | "\(.attributes.name) | Status: \(.attributes.status) | Sent: \(.attributes.send_time // "draft")"'

echo ""
echo "=== Flow Performance ==="
for flow_id in $(curl -s -H "$AUTH" -H "$REV" "$KL_API/flows/" | jq -r '.data[:5] | .[].id'); do
  name=$(curl -s -H "$AUTH" -H "$REV" "$KL_API/flows/$flow_id/" | jq -r '.data.attributes.name')
  echo "$name (ID: $flow_id) | Status: $(curl -s -H "$AUTH" -H "$REV" "$KL_API/flows/$flow_id/" | jq -r '.data.attributes.status')"
done

echo ""
echo "=== List Profiles Count ==="
for list_id in $(curl -s -H "$AUTH" -H "$REV" "$KL_API/lists/" | jq -r '.data[:5] | .[].id'); do
  name=$(curl -s -H "$AUTH" -H "$REV" "$KL_API/lists/$list_id/" | jq -r '.data.attributes.name')
  echo "$name | ID: $list_id"
done

echo ""
echo "=== Suppressed Profiles ==="
curl -s -H "$AUTH" -H "$REV" "$KL_API/profiles/?filter=equals(subscriptions.email.marketing.suppression.reason,'HARD_BOUNCE')&page[size]=1" | \
  jq -r '"Hard bounces in suppression: check total via pagination"'
```

## Output Format

```
KLAVIYO STATUS
==============
Account: {id} ({industry})
Lists: {count} | Segments: {count}
Active Flows: {count}/{total}
Recent Campaigns: {count}
Tracked Metrics: {count}
Issues: {list_of_warnings}
```

## Common Pitfalls

- **API revision header**: Klaviyo requires a revision date header — always include it
- **Rate limits**: 75 requests/second for most endpoints — use bulk endpoints for profiles
- **Flows vs Campaigns**: Flows are automated triggers; campaigns are one-time sends
- **Pagination**: All list endpoints are paginated — check `links.next` for more data
