---
name: managing-pi-hole
description: |
  Pi-hole DNS sinkhole management covering ad-blocking statistics, query logs, blocklist management, client activity, gravity database, and network-wide DNS filtering. Use when managing Pi-hole instances, analyzing blocked query patterns, managing whitelists and blacklists, monitoring client DNS activity, or troubleshooting DNS filtering.
connection_type: pi-hole
preload: false
---

# Pi-hole DNS Skill

Manage Pi-hole DNS filtering, blocklists, query logs, client activity, and statistics.

## Core Helper Functions

```bash
#!/bin/bash

PIHOLE_API="http://$PIHOLE_HOST/admin/api.php"

pihole_api() {
    local endpoint="$1"
    curl -s "$PIHOLE_API?$endpoint&auth=$PIHOLE_API_TOKEN"
}

# Pi-hole CLI wrapper (if SSH access available)
pihole_cmd() {
    ssh "$PIHOLE_HOST" "pihole $*" 2>/dev/null
}
```

## MANDATORY: Discovery-First Pattern

### Phase 1: Discovery

```bash
#!/bin/bash

echo "=== Pi-hole Summary ==="
pihole_api "summaryRaw" | jq '{
    domains_being_blocked, dns_queries_today,
    ads_blocked_today, ads_percentage_today,
    unique_domains, queries_forwarded,
    queries_cached, clients_ever_seen,
    unique_clients, status
}'

echo ""
echo "=== Top Blocked Domains ==="
pihole_api "topItems=15" | jq -r '
    .top_ads | to_entries[] | "\(.value)\t\(.key)"
' | sort -rn | column -t | head -15

echo ""
echo "=== Top Permitted Domains ==="
pihole_api "topItems=10" | jq -r '
    .top_queries | to_entries[] | "\(.value)\t\(.key)"
' | sort -rn | column -t | head -10

echo ""
echo "=== Top Clients ==="
pihole_api "getQuerySources=10" | jq -r '
    .top_sources | to_entries[] | "\(.value)\t\(.key)"
' | sort -rn | column -t | head -10

echo ""
echo "=== Upstream DNS Servers ==="
pihole_api "getForwardDestinations" | jq -r '
    .forward_destinations | to_entries[] | "\(.key)\t\(.value)%"
' | column -t | head -10
```

### Phase 2: Analysis

```bash
#!/bin/bash

echo "=== Query Types Distribution ==="
pihole_api "getQueryTypes" | jq -r '
    .querytypes | to_entries[] | "\(.key)\t\(.value)%"
' | column -t | head -10

echo ""
echo "=== Queries Over Time (24h) ==="
pihole_api "overTimeData10mins" | jq -r '
    .domains_over_time | to_entries | sort_by(.key) | last(10) | .[] |
    "\(.key | tonumber | todate)\t\(.value) queries"
' | column -t 2>/dev/null | tail -10

echo ""
echo "=== Recent Blocked Queries ==="
pihole_api "getAllQueries=50" | jq -r '
    .data[] | select(.[2] | test("Pi-holed|Blocked")) |
    "\(.[0] | tonumber | todate)\t\(.[2])\t\(.[3])\t\(.[4])"
' | tail -15 | column -t

echo ""
echo "=== Gravity Database Status ==="
pihole_api "getGravity" | jq '{
    file_exists: .file_exists, last_update: .absolute,
    domains_in_gravity: .domains_being_blocked
}' 2>/dev/null
pihole_cmd "-g -l" 2>/dev/null | tail -5

echo ""
echo "=== Blocklist Sources ==="
pihole_cmd "adlist" 2>/dev/null || \
    curl -s "http://$PIHOLE_HOST/admin/api.php?list=adlist&auth=$PIHOLE_API_TOKEN" | jq -r '
    .data[]? | "\(.enabled)\t\(.address[:60])\t\(.number // 0) domains"
' | column -t | head -15
```

## Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- Use jq to parse Pi-hole API JSON responses
- Show percentages for blocked vs allowed traffic

## Safety Rules
- **Read-only by default**: Use query/summary endpoints for inspection
- **Never disable Pi-hole** without confirmation -- disables network-wide ad blocking
- **Whitelist changes** take effect after gravity rebuild
- **Blacklist additions** block domains for all clients on the network

## Common Pitfalls
- **API token required**: Most endpoints need the `auth` parameter with the web password hash
- **Gravity updates**: Adding blocklists requires `pihole -g` to rebuild the gravity database
- **Client groups**: Pi-hole v5+ supports per-client group management for different filter lists
- **CNAME cloaking**: Some trackers use CNAME cloaking to bypass Pi-hole; needs deep CNAME inspection
- **DNS cache**: Pi-hole caches responses; recently unblocked domains may still be cached as blocked
