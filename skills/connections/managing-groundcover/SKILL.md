---
name: managing-groundcover
description: |
  Groundcover eBPF-based Kubernetes observability platform for APM, infrastructure monitoring, log management, and network analysis without code instrumentation. Covers service map discovery, golden signal metrics, log querying, alert management, and Kubernetes workload analysis. Use when monitoring Kubernetes services, investigating performance issues, querying container logs, or managing groundcover alerts.
connection_type: groundcover
preload: false
---

# Groundcover Monitoring Skill

Query, analyze, and manage groundcover observability data using the groundcover API.

## API Overview

Groundcover uses a REST API at `https://app.groundcover.com/api/v1`.

### Core Helper Function

```bash
#!/bin/bash

gc_api() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"
    if [ -n "$data" ]; then
        curl -s -X "$method" "${GROUNDCOVER_URL:-https://app.groundcover.com}/api/v1/${endpoint}" \
            -H "Authorization: Bearer $GROUNDCOVER_API_KEY" \
            -H "Content-Type: application/json" \
            -d "$data"
    else
        curl -s -X "$method" "${GROUNDCOVER_URL:-https://app.groundcover.com}/api/v1/${endpoint}" \
            -H "Authorization: Bearer $GROUNDCOVER_API_KEY"
    fi
}
```

## MANDATORY: Discovery-First Pattern

**Always discover clusters, namespaces, and services before querying.**

### Phase 1: Discovery

```bash
#!/bin/bash

echo "=== Clusters ==="
gc_api GET "clusters" | jq -r '.data[] | "\(.id)\t\(.name)\t\(.status)"' | head -10

echo ""
echo "=== Namespaces ==="
gc_api GET "namespaces" | jq -r '.data[] | "\(.namespace)\t\(.cluster)\tworkloads:\(.workloadCount // 0)"' | head -20

echo ""
echo "=== Services ==="
gc_api GET "services?period=1h" | jq -r '.data[] | "\(.name)\t\(.namespace)\t\(.protocol // "unknown")"' | head -20

echo ""
echo "=== Alert Rules ==="
gc_api GET "alerts" | jq -r '.data[] | "\(.id)\t\(.name)\t\(.state // "unknown")"' | head -15
```

### Phase 2: Analysis

```bash
#!/bin/bash

echo "=== Service Golden Signals (last 1h) ==="
gc_api GET "services/metrics?period=1h" \
    | jq -r '.data[] | "\(.name)\t\(.namespace)\tp99:\(.p99Latency // 0)ms\terror%:\(.errorRate // 0)\treqs:\(.requestRate // 0)/s"' \
    | sort -t$'\t' -k4 -rn | head -15

echo ""
echo "=== Kubernetes Workload Health ==="
gc_api GET "workloads?period=1h" \
    | jq -r '.data[] | "\(.name)\t\(.namespace)\t\(.kind)\tready:\(.readyReplicas)/\(.replicas)\tcpu:\(.cpuUsage // "N/A")"' | head -15

echo ""
echo "=== Recent Error Logs ==="
gc_api POST "logs/search" '{"query":"level:error","from":"now-1h","to":"now","limit":20}' \
    | jq -r '.data[] | "\(.timestamp[0:19])\t\(.namespace)/\(.pod)\t\(.message[0:70])"' | head -15

echo ""
echo "=== Network Issues ==="
gc_api GET "network/anomalies?period=1h" \
    | jq -r '.data[] | "\(.source) -> \(.destination)\t\(.anomalyType)\t\(.severity)"' | head -10
```

## Output Rules
- **TOKEN EFFICIENCY**: Target ≤50 lines — use `period` and `limit` parameters
- Use golden signals (latency, error rate, throughput) for service-level overview
- Leverage namespace scoping to narrow queries
