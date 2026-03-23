---
name: managing-ovhcloud
description: |
  Use when working with Ovhcloud — oVHcloud infrastructure management via the
  ovh CLI and OVHcloud API. Covers dedicated servers, VPS, Public Cloud
  instances, databases, domains, and billing. Use when managing OVHcloud
  resources or reviewing infrastructure health.
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

