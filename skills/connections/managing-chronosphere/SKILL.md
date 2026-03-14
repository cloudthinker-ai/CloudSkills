---
name: managing-chronosphere
description: |
  Chronosphere cloud-native observability platform for metrics, tracing, and alerting at scale. Covers PromQL-based metric queries, trace analysis, monitor management, dashboards, and control plane configuration. Use when querying Chronosphere metrics, investigating service performance, managing alerting rules, or analyzing distributed traces.
connection_type: chronosphere
preload: false
---

# Chronosphere Monitoring Skill

Query, analyze, and manage Chronosphere observability data using the Chronosphere API.

## API Overview

Chronosphere uses a REST API at your tenant URL: `https://<TENANT>.chronosphere.io/api`.

### Core Helper Function

```bash
#!/bin/bash

chrono_api() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"
    local url="${CHRONOSPHERE_URL}/api/v1/${endpoint}"
    if [ -n "$data" ]; then
        curl -s -X "$method" "$url" \
            -H "Authorization: Bearer $CHRONOSPHERE_API_TOKEN" \
            -H "Content-Type: application/json" \
            -d "$data"
    else
        curl -s -X "$method" "$url" \
            -H "Authorization: Bearer $CHRONOSPHERE_API_TOKEN"
    fi
}

chrono_query() {
    local promql="$1"
    local time="${2:-$(date +%s)}"
    chrono_api GET "query?query=$(python3 -c "import urllib.parse; print(urllib.parse.quote('${promql}'))")&time=${time}"
}
```

## MANDATORY: Discovery-First Pattern

**Always discover available metrics, services, and monitors before querying.**

### Phase 1: Discovery

```bash
#!/bin/bash

echo "=== Available Metric Namespaces ==="
chrono_api GET "label/__name__/values" | jq -r '.data[]' | cut -d'_' -f1 | sort -u | head -20

echo ""
echo "=== Monitors ==="
chrono_api GET "config/monitors" | jq -r '.monitors[] | "\(.slug)\t\(.name)\t\(.state // "unknown")"' | head -20

echo ""
echo "=== Dashboards ==="
chrono_api GET "config/dashboards" | jq -r '.dashboards[] | "\(.slug)\t\(.name)"' | head -20

echo ""
echo "=== Collections (Metric Groupings) ==="
chrono_api GET "config/collections" | jq -r '.collections[] | "\(.slug)\t\(.name)"' | head -15
```

### Phase 2: Analysis

```bash
#!/bin/bash

echo "=== CPU Usage by Service (top 15) ==="
chrono_query 'avg by (service) (rate(process_cpu_seconds_total[5m]) * 100)' \
    | jq -r '.data.result[] | "\(.metric.service)\t\(.value[1])%"' | sort -t$'\t' -k2 -rn | head -15

echo ""
echo "=== Request Rate by Service ==="
chrono_query 'sum by (service) (rate(http_requests_total[5m]))' \
    | jq -r '.data.result[] | "\(.metric.service)\t\(.value[1]) req/s"' | sort -t$'\t' -k2 -rn | head -15

echo ""
echo "=== Error Rate by Service ==="
chrono_query 'sum by (service) (rate(http_requests_total{status=~"5.."}[5m])) / sum by (service) (rate(http_requests_total[5m])) * 100' \
    | jq -r '.data.result[] | "\(.metric.service)\t\(.value[1])%"' | sort -t$'\t' -k2 -rn | head -15

echo ""
echo "=== Firing Monitors ==="
chrono_api GET "config/monitors" | jq -r '.monitors[] | select(.state == "firing") | "\(.slug)\t\(.name)"' | head -10
```

## Output Rules
- **TOKEN EFFICIENCY**: Target ≤50 lines — use PromQL aggregation and `head` in output
- Use `avg by`, `sum by` for grouping instead of raw series
- Prefer instant queries over range queries unless trend analysis is needed
