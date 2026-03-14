---
name: managing-ns1
description: |
  NS1 managed DNS platform covering zones, records, filter chains, monitoring jobs, DNSSEC, and traffic steering. Use when managing NS1 DNS zones, configuring intelligent traffic routing via filter chains, monitoring DNS health checks, analyzing query analytics, or troubleshooting DNS resolution.
connection_type: ns1
preload: false
---

# NS1 DNS Skill

Manage NS1 DNS zones, records, filter chains, monitoring, and traffic steering.

## Core Helper Functions

```bash
#!/bin/bash

NS1_API="https://api.nsone.net/v1"

ns1_api() {
    local endpoint="$1"
    shift
    curl -s -H "X-NSONE-Key: $NS1_API_KEY" \
         -H "Content-Type: application/json" \
         "$NS1_API/$endpoint" "$@"
}
```

## MANDATORY: Discovery-First Pattern

### Phase 1: Discovery

```bash
#!/bin/bash

echo "=== DNS Zones ==="
ns1_api "zones" | jq -r '
    .[] | "\(.zone)\t\(.dns_servers | length) NS\tRecords: \(.records // 0)\t\(.nx_ttl)s NX-TTL"
' | column -t | head -20

echo ""
echo "=== Monitoring Jobs ==="
ns1_api "monitoring/jobs" | jq -r '
    .[] | "\(.id[:12])\t\(.name)\t\(.job_type)\t\(.status)\t\(.regions | join(","))"
' | column -t | head -15

echo ""
echo "=== Data Sources ==="
ns1_api "data/sources" | jq -r '
    .[] | "\(.id[:12])\t\(.name)\t\(.sourcetype)\t\(.status)"
' | column -t | head -10

echo ""
echo "=== Account Usage ==="
ns1_api "account/usagewarnings" | jq '.'
```

### Phase 2: Analysis

```bash
#!/bin/bash
ZONE="${1:?Zone name required}"

echo "=== Zone Details ==="
ns1_api "zones/$ZONE" | jq '{
    zone, ttl, nx_ttl, retry, refresh, expiry,
    dnssec: .dnssec, primary: .primary,
    dns_servers, networks: .networks,
    record_count: (.records | length)
}'

echo ""
echo "=== DNS Records ==="
ns1_api "zones/$ZONE" | jq -r '
    .records[] | "\(.type)\t\(.domain)\t\(.short_answers | join("; "))\t\(.ttl)s"
' | sort | column -t | head -25

echo ""
echo "=== Filter Chains ==="
ns1_api "zones/$ZONE" | jq '
    .records[] | select(.filters | length > 0) | {
        domain, type,
        filters: [.filters[] | {filter: .filter, config}]
    }' | head -20

echo ""
echo "=== Query Analytics ==="
ns1_api "stats/qps/$ZONE" | jq -r '
    .[] | "\(.timestamp)\t\(.qps) qps"
' | tail -10
```

## Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- Use jq to parse NS1 API JSON responses
- Show filter chain details for intelligent routing records

## Safety Rules
- **Read-only by default**: Use GET endpoints for inspection
- **Never delete zones** without explicit confirmation
- **Filter chain changes** affect traffic routing immediately
- **Monitoring job changes** can trigger failover if misconfigured

## Common Pitfalls
- **Filter chains are ordered**: Filters execute top-to-bottom; order matters for routing logic
- **Answer metadata**: Each answer can have metadata for filter chain decisions (e.g., geo, weight)
- **Monitoring regions**: Jobs must run from multiple regions for reliable health checks
- **API rate limits**: 500 requests per second per API key
- **DNSSEC**: Must be enabled at both NS1 and the registrar level
