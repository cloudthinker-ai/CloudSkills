---
name: managing-pi-hole
description: |
  Use when working with Pi Hole — pi-hole DNS sinkhole management covering
  ad-blocking statistics, query logs, blocklist management, client activity,
  gravity database, and network-wide DNS filtering. Use when managing Pi-hole
  instances, analyzing blocked query patterns, managing whitelists and
  blacklists, monitoring client DNS activity, or troubleshooting DNS filtering.
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

## Output Format

Present results as a structured report:
```
Managing Pi Hole Report
═══════════════════════
Resources discovered: [count]

Resource       Status    Key Metric    Issues
──────────────────────────────────────────────
[name]         [ok/warn] [value]       [findings]

Summary: [total] resources | [ok] healthy | [warn] warnings | [crit] critical
Action Items: [list of prioritized findings]
```

Target ≤50 lines of output. Use tables for multi-resource comparisons.

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
- **API token required**: Most endpoints need the `auth` parameter with the web password hash
- **Gravity updates**: Adding blocklists requires `pihole -g` to rebuild the gravity database
- **Client groups**: Pi-hole v5+ supports per-client group management for different filter lists
- **CNAME cloaking**: Some trackers use CNAME cloaking to bypass Pi-hole; needs deep CNAME inspection
- **DNS cache**: Pi-hole caches responses; recently unblocked domains may still be cached as blocked
