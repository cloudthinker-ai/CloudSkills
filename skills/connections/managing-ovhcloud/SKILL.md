---
name: managing-ovhcloud
description: |
  OVHcloud infrastructure management via the ovh CLI and OVHcloud API. Covers dedicated servers, VPS, Public Cloud instances, databases, domains, and billing. Use when managing OVHcloud resources or reviewing infrastructure health.
connection_type: ovhcloud
preload: false
---

# Managing OVHcloud

Manage OVHcloud infrastructure using the OVHcloud API via curl.

## MANDATORY: Discovery-First Pattern

**Always discover available resources before performing analysis.**

### Phase 1: Discovery

```bash
#!/bin/bash

OVH_BASE="https://api.ovh.com/1.0"

echo "=== Account Info ==="
curl -s -H "X-Ovh-Application: $OVH_APP_KEY" \
     -H "X-Ovh-Consumer: $OVH_CONSUMER_KEY" \
     -H "X-Ovh-Timestamp: $(date +%s)" \
     -H "X-Ovh-Signature: $OVH_SIGNATURE" \
     "$OVH_BASE/me" 2>/dev/null | jq '{nichandle, email, country, currency}' || echo "Configure OVH API credentials"

echo ""
echo "=== Dedicated Servers ==="
curl -s "$OVH_BASE/dedicated/server" -H "X-Ovh-Application: $OVH_APP_KEY" \
     -H "X-Ovh-Consumer: $OVH_CONSUMER_KEY" 2>/dev/null | jq -r '.[]' | head -20

echo ""
echo "=== VPS List ==="
curl -s "$OVH_BASE/vps" -H "X-Ovh-Application: $OVH_APP_KEY" \
     -H "X-Ovh-Consumer: $OVH_CONSUMER_KEY" 2>/dev/null | jq -r '.[]' | head -20

echo ""
echo "=== Public Cloud Projects ==="
curl -s "$OVH_BASE/cloud/project" -H "X-Ovh-Application: $OVH_APP_KEY" \
     -H "X-Ovh-Consumer: $OVH_CONSUMER_KEY" 2>/dev/null | jq -r '.[]' | head -10

echo ""
echo "=== Domains ==="
curl -s "$OVH_BASE/domain/zone" -H "X-Ovh-Application: $OVH_APP_KEY" \
     -H "X-Ovh-Consumer: $OVH_CONSUMER_KEY" 2>/dev/null | jq -r '.[]' | head -10
```

### Phase 2: Analysis

```bash
#!/bin/bash

OVH_BASE="https://api.ovh.com/1.0"
PROJECT_ID="${1:?Public Cloud Project ID required}"

echo "=== Public Cloud Instances ==="
curl -s "$OVH_BASE/cloud/project/$PROJECT_ID/instance" \
     -H "X-Ovh-Application: $OVH_APP_KEY" \
     -H "X-Ovh-Consumer: $OVH_CONSUMER_KEY" 2>/dev/null | jq -r '.[] | "\(.id)\t\(.name)\t\(.region)\t\(.status)\t\(.flavor.name)\t\(.ipAddresses[0].ip // "N/A")"' | head -30

echo ""
echo "=== Storage Containers ==="
curl -s "$OVH_BASE/cloud/project/$PROJECT_ID/storage" \
     -H "X-Ovh-Application: $OVH_APP_KEY" \
     -H "X-Ovh-Consumer: $OVH_CONSUMER_KEY" 2>/dev/null | jq -r '.[] | "\(.name)\t\(.region)\t\(.storedObjects)\t\(.storedBytes)"' | head -10

echo ""
echo "=== Databases ==="
curl -s "$OVH_BASE/cloud/project/$PROJECT_ID/database/service" \
     -H "X-Ovh-Application: $OVH_APP_KEY" \
     -H "X-Ovh-Consumer: $OVH_CONSUMER_KEY" 2>/dev/null | jq -r '.[] | "\(.id)\t\(.description)\t\(.engine)\t\(.plan)\t\(.status)"' | head -10

echo ""
echo "=== Current Billing ==="
curl -s "$OVH_BASE/cloud/project/$PROJECT_ID/usage/current" \
     -H "X-Ovh-Application: $OVH_APP_KEY" \
     -H "X-Ovh-Consumer: $OVH_CONSUMER_KEY" 2>/dev/null | jq '{totalPrice: .monthlyUsage.totalPrice, instances: [.monthlyUsage.instance[] | {reference, region, totalPrice}]}' | head -20
```

## Output Format

```
ID                                    NAME     REGION  STATUS  FLAVOR    IP
abc123-def456-ghi789                  web-01   GRA11   ACTIVE  b2-7     1.2.3.4
```

## Safety Rules
- Use read-only GET API calls only
- Never run DELETE, PUT, POST without explicit user confirmation
- Use jq for structured output parsing
- Limit output with `| head -N` to stay under 50 lines
