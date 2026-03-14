---
name: managing-middleware-io
description: |
  Middleware.io full-stack observability platform for infrastructure monitoring, APM, log management, synthetic monitoring, and Kubernetes observability. Covers host metrics, application traces, log analysis, alert management, and dashboard review. Use when monitoring infrastructure health, investigating application performance, searching logs, or managing Middleware.io alerts.
connection_type: middleware-io
preload: false
---

# Middleware.io Monitoring Skill

Query, analyze, and manage Middleware.io observability data using the Middleware.io API.

## API Overview

Middleware.io uses a REST API at `https://app.middleware.io/api/v1`.

### Core Helper Function

```bash
#!/bin/bash

mw_api() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"
    if [ -n "$data" ]; then
        curl -s -X "$method" "${MIDDLEWARE_URL:-https://app.middleware.io}/api/v1/${endpoint}" \
            -H "Authorization: Bearer $MIDDLEWARE_API_KEY" \
            -H "Content-Type: application/json" \
            -d "$data"
    else
        curl -s -X "$method" "${MIDDLEWARE_URL:-https://app.middleware.io}/api/v1/${endpoint}" \
            -H "Authorization: Bearer $MIDDLEWARE_API_KEY"
    fi
}
```

## MANDATORY: Discovery-First Pattern

**Always discover hosts, services, and alert rules before querying.**

### Phase 1: Discovery

```bash
#!/bin/bash

echo "=== Infrastructure Hosts ==="
mw_api GET "hosts" | jq -r '.data[] | "\(.hostId)\t\(.hostname)\t\(.os)\t\(.status)"' | head -20

echo ""
echo "=== APM Services ==="
mw_api GET "apm/services" | jq -r '.data[] | "\(.serviceName)\t\(.language // "N/A")\t\(.status // "unknown")"' | head -20

echo ""
echo "=== Alert Rules ==="
mw_api GET "alerts/rules" | jq -r '.data[] | "\(.id)\t\(.name)\t\(.severity)\t\(.state)"' | head -15

echo ""
echo "=== Dashboards ==="
mw_api GET "dashboards" | jq -r '.data[] | "\(.id)\t\(.title)"' | head -15
```

### Phase 2: Analysis

```bash
#!/bin/bash

echo "=== Host Metrics (CPU/Memory) ==="
mw_api GET "hosts/metrics?period=1h" \
    | jq -r '.data[] | "\(.hostname)\tcpu:\(.cpuPercent // 0)%\tmem:\(.memPercent // 0)%\tdisk:\(.diskPercent // 0)%"' | head -15

echo ""
echo "=== APM Service Performance ==="
mw_api GET "apm/services/metrics?period=1h" \
    | jq -r '.data[] | "\(.serviceName)\tp99:\(.p99Latency // 0)ms\terror_rate:\(.errorRate // 0)%\treqs:\(.requestCount // 0)"' \
    | sort -t$'\t' -k3 -rn | head -15

echo ""
echo "=== Recent Error Logs ==="
mw_api POST "logs/search" '{"query":"level:error","from":"now-1h","to":"now","limit":20}' \
    | jq -r '.data[] | "\(.timestamp[0:19])\t\(.service // "unknown")\t\(.message[0:80])"' | head -15

echo ""
echo "=== Active Alerts ==="
mw_api GET "alerts/active" | jq -r '.data[] | "\(.triggeredAt[0:19])\t\(.severity)\t\(.ruleName)\t\(.target)"' | head -10
```

## Output Rules
- **TOKEN EFFICIENCY**: Target ≤50 lines — use `period` and `limit` parameters
- Use host-level and service-level aggregations before drilling down
- Filter logs at API level with query parameter
