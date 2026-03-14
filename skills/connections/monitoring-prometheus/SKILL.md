---
name: monitoring-prometheus
description: |
  Prometheus metrics monitoring, PromQL query building, alerting rule analysis, target scrape health, and TSDB storage management. Covers service discovery, recording rules, federation, remote write, and integration with Alertmanager. Use when querying Prometheus metrics, investigating alerting rules, analyzing scrape targets, or building PromQL expressions.
connection_type: prometheus
preload: false
---

# Prometheus Monitoring Skill

Query, analyze, and manage Prometheus metrics using the HTTP API and PromQL.

## MANDATORY: Discovery-First Pattern

**Always discover available metrics and labels before writing PromQL. Never guess metric names.**

### Phase 1: Discovery

```bash
#!/bin/bash

prom_api() {
    curl -s "${PROMETHEUS_URL}/api/v1/$1"
}

echo "=== Prometheus Build Info ==="
prom_api "status/buildinfo" | jq '{version: .data.version, goVersion: .data.goVersion}'

echo ""
echo "=== Active Targets ==="
prom_api "targets" | jq -r '.data.activeTargets[] | "\(.health)\t\(.scrapePool)\t\(.labels.instance // .scrapeUrl)"' \
    | sort | head -30

echo ""
echo "=== Failed Targets ==="
prom_api "targets" | jq -r '.data.activeTargets[] | select(.health != "up") | "\(.health)\t\(.scrapePool)\t\(.lastError)"' | head -10

echo ""
echo "=== Available Metric Namespaces (sampling) ==="
prom_api "label/__name__/values" | jq -r '.data[]' | cut -d_ -f1 | sort -u | head -30

echo ""
echo "=== Alerting Rules ==="
prom_api "rules" | jq -r '.data.groups[].rules[] | select(.type=="alerting") | "\(.state)\t\(.name)\t\(.labels.severity // "none")"' | sort | head -20
```

### Phase 2: PromQL Query

Only reference metrics confirmed in Phase 1 discovery.

## PromQL Patterns

### Helper Function

```bash
#!/bin/bash

prom_api() {
    local endpoint="$1"
    curl -s "${PROMETHEUS_URL}/api/v1/${endpoint}"
}

# Instant query
prom_query() {
    local query="$1"
    local time="${2:-}"  # Optional: unix timestamp
    local params="query=$(python3 -c "import urllib.parse; print(urllib.parse.quote('${query}'))")"
    [ -n "$time" ] && params="${params}&time=${time}"
    prom_api "query?${params}"
}

# Range query
prom_range() {
    local query="$1"
    local start="$2"
    local end="$3"
    local step="${4:-60}"  # seconds
    local params="query=$(python3 -c "import urllib.parse; print(urllib.parse.quote('${query}'))")"
    prom_api "query_range?${params}&start=${start}&end=${end}&step=${step}"
}

# Get label values
prom_labels() {
    local metric="$1"
    local label="$2"
    prom_api "label/${label}/values?match[]=${metric}"
}
```

## Common PromQL Patterns

### Infrastructure Metrics

```bash
#!/bin/bash
NOW=$(date +%s)
ONE_HOUR_AGO=$((NOW - 3600))

echo "=== CPU Usage by Instance ==="
prom_query 'sort_desc(100 - (avg by (instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100))' \
    | jq -r '.data.result[] | "\(.metric.instance)\t\(.value[1] | tonumber | . * 10 | round / 10)%"' \
    | column -t | head -15

echo ""
echo "=== Memory Usage by Instance ==="
prom_query 'sort_desc(100 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes * 100))' \
    | jq -r '.data.result[] | "\(.metric.instance)\t\(.value[1] | tonumber | . * 10 | round / 10)%"' \
    | column -t | head -15

echo ""
echo "=== Disk Usage (>70%) ==="
prom_query '(node_filesystem_avail_bytes{fstype!~"tmpfs|squashfs"} / node_filesystem_size_bytes{fstype!~"tmpfs|squashfs"} * 100) < 30' \
    | jq -r '.data.result[] | "\(.metric.instance)\t\(.metric.mountpoint)\t\(100 - (.value[1] | tonumber) | . * 10 | round / 10)% used"' \
    | column -t | head -15

echo ""
echo "=== Network Traffic (top 10) ==="
prom_query 'sort_desc(sum by (instance) (irate(node_network_receive_bytes_total[5m])) + sum by (instance) (irate(node_network_transmit_bytes_total[5m])))' \
    | jq -r '.data.result[] | "\(.metric.instance)\t\(.value[1] | tonumber / 1024 / 1024 | . * 10 | round / 10) MB/s"' \
    | column -t | head -10
```

### Application / HTTP Metrics

```bash
#!/bin/bash
echo "=== HTTP Request Rate by Service ==="
prom_query 'sort_desc(sum by (job) (rate(http_requests_total[5m])))' \
    | jq -r '.data.result[] | "\(.metric.job)\t\(.value[1] | tonumber | . * 100 | round / 100) req/s"' \
    | column -t | head -15

echo ""
echo "=== HTTP Error Rate (5xx) ==="
prom_query 'sort_desc(sum by (job) (rate(http_requests_total{status=~"5.."}[5m])) / sum by (job) (rate(http_requests_total[5m])) * 100)' \
    | jq -r '.data.result[] | "\(.metric.job)\t\(.value[1] | tonumber | . * 100 | round / 100)% errors"' \
    | column -t | head -10

echo ""
echo "=== P99 Latency by Service ==="
prom_query 'histogram_quantile(0.99, sum by (job, le) (rate(http_request_duration_seconds_bucket[5m])))' \
    | jq -r '.data.result[] | "\(.metric.job)\t\(.value[1] | tonumber * 1000 | . * 10 | round / 10)ms"' \
    | column -t | head -10

echo ""
echo "=== Apdex Score (target 300ms) ==="
prom_query 'sum by (job) (rate(http_request_duration_seconds_bucket{le="0.3"}[5m])) / sum by (job) (rate(http_request_duration_seconds_count[5m]))' \
    | jq -r '.data.result[] | "\(.metric.job)\t\(.value[1] | tonumber | . * 1000 | round / 1000)"' \
    | column -t | head -10
```

### Alerting Rules Analysis

```bash
#!/bin/bash
echo "=== All Alerting Rules ==="
prom_api "rules" | jq -r '
    .data.groups[] as $group |
    $group.rules[] |
    select(.type == "alerting") |
    "\($group.name)\t\(.name)\t\(.state)\t\(.labels.severity // "none")"
' | column -t | sort -k3

echo ""
echo "=== Firing Alerts ==="
prom_api "alerts" | jq -r '
    .data.alerts[] |
    select(.state == "firing") |
    "\(.labels.severity // "none")\t\(.labels.alertname)\t\(.labels.instance // "")\t\(.activeAt[0:16])"
' | sort | column -t

echo ""
echo "=== Pending Alerts (about to fire) ==="
prom_api "alerts" | jq -r '
    .data.alerts[] |
    select(.state == "pending") |
    "\(.labels.alertname)\t\(.labels.instance // "")\t\(.activeAt[0:16])"
' | column -t | head -10
```

### TSDB Storage Analysis

```bash
#!/bin/bash
echo "=== TSDB Head Stats ==="
prom_api "tsdb/head_stats" | jq '.data | {
    numSeries: .numSeries,
    numLabelPairs: .numLabelPairs,
    chunkCount: .chunkCount,
    minTime_epoch: .minTime,
    maxTime_epoch: .maxTime
}'

echo ""
echo "=== TSDB Block Stats ==="
prom_api "tsdb/blocks" | jq '.data | length | "Total blocks: \(.)"'

echo ""
echo "=== Cardinality Analysis (top label values) ==="
# High cardinality labels cause memory issues
prom_query 'topk(10, count by (__name__) ({__name__=~".+"}))' \
    | jq -r '.data.result[] | "\(.metric.__name__)\t\(.value[1])"' \
    | sort -t$'\t' -k2 -rn | head -10
```

### Scrape Target Health

```bash
#!/bin/bash
echo "=== Scrape Target Summary ==="
prom_api "targets" | jq '
    .data.activeTargets |
    {
        total: length,
        up: [.[] | select(.health == "up")] | length,
        down: [.[] | select(.health != "up")] | length
    }'

echo ""
echo "=== Down Targets ==="
prom_api "targets" | jq -r '
    .data.activeTargets[] |
    select(.health != "up") |
    "\(.scrapePool)\t\(.labels.instance // .scrapeUrl)\t\(.lastError // "unknown")"
' | column -t

echo ""
echo "=== Scrape Duration (slowest targets) ==="
prom_query 'sort_desc(scrape_duration_seconds)' \
    | jq -r '.data.result[] | "\(.metric.instance)\t\(.value[1] | tonumber | . * 1000 | round)ms"' \
    | column -t | head -10
```

### Recording Rules Check

```bash
#!/bin/bash
echo "=== Recording Rules ==="
prom_api "rules" | jq -r '
    .data.groups[] as $group |
    $group.rules[] |
    select(.type == "recording") |
    "\($group.name)\t\(.name)\t\(.health)"
' | column -t | head -20

echo ""
echo "=== Rule Evaluation Errors ==="
prom_api "rules" | jq -r '
    .data.groups[].rules[] |
    select(.lastError != null and .lastError != "") |
    "\(.name): \(.lastError)"
' | head -10
```

## Common Pitfalls

- **Metric name guessing**: Use `label/__name__/values` to list actual metric names — never guess namespaces
- **Rate vs irate**: `rate()` smooths over the window; `irate()` uses last 2 samples — prefer `rate()` for dashboards, `irate()` for alerting
- **Range vector requirement**: `rate()`, `irate()`, `increase()` require range vectors (`[5m]`) — instant vectors cause parse errors
- **`[5m]` window too small**: If scrape interval is 60s, `[5m]` gives only 5 samples — use at least 4x scrape interval
- **Histogram quantiles**: `histogram_quantile()` needs `_bucket` metric with `le` label — verify bucket metric exists first
- **Counter resets**: `rate()` handles counter resets automatically; `delta()` does not — use `rate()` for counters
- **High cardinality queries**: `count by ()` across all metrics can be slow — limit with label matchers
- **Step alignment**: Range query `step` should be ≥ scrape interval to avoid gaps
- **Alertmanager vs Prometheus alerts**: Alerts fire in Prometheus, route via Alertmanager — check both for full picture
