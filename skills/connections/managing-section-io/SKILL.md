---
name: managing-section-io
description: |
  Section.io edge compute and CDN management covering applications, environments, proxy stack configuration, Varnish cache settings, and real-time monitoring. Use when managing Section.io edge applications, analyzing cache performance, configuring proxy stacks, or troubleshooting edge compute delivery.
connection_type: section-io
preload: false
---

# Section.io Edge Compute Skill

Manage Section.io edge applications, proxy stacks, caching, and real-time monitoring.

## Core Helper Functions

```bash
#!/bin/bash

SECTION_API="https://aperture.section.io/api/v1"

# Section.io API wrapper
section_api() {
    local endpoint="$1"
    shift
    curl -s -u "$SECTION_USERNAME:$SECTION_PASSWORD" \
         -H "Content-Type: application/json" \
         "$SECTION_API/$endpoint" "$@"
}
```

## MANDATORY: Discovery-First Pattern

### Phase 1: Discovery

```bash
#!/bin/bash

echo "=== Accounts ==="
section_api "account" | jq -r '
    .[] | "\(.id)\t\(.account_name)\t\(.plan_name)"
' | column -t | head -10

ACCOUNT_ID=$(section_api "account" | jq -r '.[0].id')

echo ""
echo "=== Applications ==="
section_api "account/$ACCOUNT_ID/application" | jq -r '
    .[] | "\(.id)\t\(.application_name)\t\(.domain_name)\t\(.environment // "default")"
' | column -t | head -20

echo ""
echo "=== Environments ==="
for APP_ID in $(section_api "account/$ACCOUNT_ID/application" | jq -r '.[].id'); do
    section_api "account/$ACCOUNT_ID/application/$APP_ID/environment" | jq -r --arg app "$APP_ID" '
        .[] | "\($app)\t\(.id)\t\(.environment_name)\t\(.domain_name)"
    '
done | column -t | head -15

echo ""
echo "=== Proxy Stack ==="
for APP_ID in $(section_api "account/$ACCOUNT_ID/application" | jq -r '.[].id' | head -5); do
    section_api "account/$ACCOUNT_ID/application/$APP_ID/environment/Production/proxy" | jq -r --arg app "$APP_ID" '
        .[] | "\($app)\t\(.name)\t\(.image)\t\(.status)"
    '
done | column -t | head -15
```

### Phase 2: Analysis

```bash
#!/bin/bash
ACCOUNT_ID="${1:?Account ID required}"
APP_ID="${2:?Application ID required}"
ENV="${3:-Production}"

echo "=== Application Config ==="
section_api "account/$ACCOUNT_ID/application/$APP_ID/environment/$ENV" | jq '{
    environment_name, domain_name, origin,
    proxy_stack: [.proxies[]? | {name, image, status}]
}'

echo ""
echo "=== Varnish Cache Stats ==="
section_api "account/$ACCOUNT_ID/application/$APP_ID/environment/$ENV/proxy/varnish/state" | jq '{
    cache_hit_ratio, cache_hits, cache_misses,
    backend_connections, backend_errors,
    current_connections
}' 2>/dev/null

echo ""
echo "=== Real-time Metrics ==="
section_api "account/$ACCOUNT_ID/application/$APP_ID/environment/$ENV/metrics?period=1h" | jq '{
    requests: .total_requests,
    bandwidth_mb: (.total_bytes / 1048576 | round),
    cache_hit_pct: .cache_hit_percentage,
    avg_response_time_ms: .avg_response_time
}' 2>/dev/null

echo ""
echo "=== Origin Health ==="
section_api "account/$ACCOUNT_ID/application/$APP_ID/environment/$ENV/origin" | jq '{
    origin_address, origin_port, origin_scheme,
    health_check_status
}'
```

## Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- Use jq to parse Section.io API responses
- Always include account/application/environment context

## Safety Rules
- **Read-only by default**: Use GET endpoints for inspection
- **Proxy stack changes** trigger redeployment at the edge
- **VCL changes** (Varnish) can break caching if syntax is invalid
- **Never modify production** proxy stack without user confirmation

## Common Pitfalls
- **Proxy stack order matters**: Requests flow through proxies in defined order
- **Environment isolation**: Production and staging have separate configurations
- **VCL syntax**: Varnish Configuration Language errors prevent deployment
- **Origin failover**: Must be configured explicitly per environment
- **Git-based config**: Some configurations are managed via git repositories
