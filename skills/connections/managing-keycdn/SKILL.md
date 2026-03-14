---
name: managing-keycdn
description: |
  KeyCDN management covering zones, zone aliases, cache settings, SSL certificates, and usage analytics. Use when managing KeyCDN zones, analyzing bandwidth and request metrics, configuring cache behavior, managing SSL, or troubleshooting content delivery through KeyCDN's edge network.
connection_type: keycdn
preload: false
---

# KeyCDN Skill

Manage KeyCDN zones, cache settings, zone aliases, and delivery analytics.

## Core Helper Functions

```bash
#!/bin/bash

KEYCDN_API="https://api.keycdn.com"

# KeyCDN API wrapper (uses HTTP Basic Auth)
keycdn_api() {
    local endpoint="$1"
    shift
    curl -s -u "$KEYCDN_API_KEY:" "$KEYCDN_API/$endpoint.json" "$@"
}
```

## MANDATORY: Discovery-First Pattern

### Phase 1: Discovery

```bash
#!/bin/bash

echo "=== KeyCDN Zones ==="
keycdn_api "zones" | jq -r '
    .data.zones[] | "\(.id)\t\(.name)\t\(.status)\t\(.type)\t\(.originurl)\t\(.sslcert)"
' | column -t | head -20

echo ""
echo "=== Zone Aliases ==="
keycdn_api "zonealiases" | jq -r '
    .data.zonealiases[] | "\(.id)\t\(.zone_id)\t\(.name)\t\(.sslstatus)"
' | column -t | head -15

echo ""
echo "=== Traffic Statistics (24h) ==="
keycdn_api "reports/traffic" | jq -r '
    .data.stats[] | "\(.zone_id)\t\(.amount / 1073741824 | round)GB\tRequests: \(.requests // 0)"
' | column -t | head -15
```

### Phase 2: Analysis

```bash
#!/bin/bash
ZONE_ID="${1:?Zone ID required}"

echo "=== Zone Configuration ==="
keycdn_api "zones/$ZONE_ID" | jq '.data.zone | {
    name, status, type, originurl,
    cacheignorecachecontrol, cacheignorequerystring,
    cachestripcookies, cachekeyscheme,
    cachecanonicalheader, expire: .expire,
    sslcert, forcesslconnection,
    gzip, http2, imgproc
}'

echo ""
echo "=== Bandwidth Report ==="
keycdn_api "reports/traffic?zone_id=$ZONE_ID" | jq -r '
    .data.stats[] | "\(.timestamp | todate)\t\(.amount / 1048576 | round)MB\t\(.requests) reqs"
' | column -t | head -15

echo ""
echo "=== Cache Status Report ==="
keycdn_api "reports/statestats?zone_id=$ZONE_ID" | jq -r '
    .data.stats[] | "\(.timestamp | todate)\tHIT: \(.hit // 0)\tMISS: \(.miss // 0)\tSHIELD: \(.shield // 0)"
' | column -t | head -10

echo ""
echo "=== HTTP Status Codes ==="
keycdn_api "reports/credits?zone_id=$ZONE_ID" | jq -r '
    .data.stats[] | "\(.timestamp | todate)\t2xx: \(.s2xx // 0)\t3xx: \(.s3xx // 0)\t4xx: \(.s4xx // 0)\t5xx: \(.s5xx // 0)"
' | column -t | head -10
```

## Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- Use jq to parse KeyCDN JSON responses
- Convert bytes to GB/MB for bandwidth display

## Safety Rules
- **Read-only by default**: Use GET endpoints for inspection
- **Never purge zones** without explicit user confirmation
- **Zone alias SSL** provisioning requires DNS validation first
- **Zone deletion** is permanent -- confirm before proceeding

## Common Pitfalls
- **API authentication**: Uses HTTP Basic Auth with API key as username, empty password
- **Zone types**: Pull vs Push zones have different configuration options
- **Cache expiry**: Default TTL is set per zone; origin headers can override if configured
- **SSL cert provisioning**: Shared SSL is automatic; custom certs require manual upload
- **Rate limits**: API is rate-limited; batch queries when possible
