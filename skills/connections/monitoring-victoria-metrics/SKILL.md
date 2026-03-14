---
name: monitoring-victoria-metrics
description: |
  VictoriaMetrics time-series database with MetricsQL queries, vmstorage health, vmselect performance, retention management, and cluster monitoring. Covers metric ingestion, cardinality analysis, query optimization, and multi-tenant operations. Use when querying metrics via MetricsQL, analyzing storage health, investigating cardinality, or managing VictoriaMetrics clusters.
connection_type: victoria-metrics
preload: false
---

# VictoriaMetrics Monitoring Skill

Query and manage VictoriaMetrics time-series infrastructure using MetricsQL.

## API Conventions

### Authentication
VictoriaMetrics uses Basic auth or Bearer token — injected by connection.

### Base URL
- Single-node: `http://<host>:8428/`
- vmselect: `http://<vmselect>:8481/select/<accountID>/prometheus/`
- vminsert: `http://<vminsert>:8480/insert/<accountID>/prometheus/`
- Use connection-injected `VM_BASE_URL`.

### Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- Use `jq` for JSON extraction from Prometheus-compatible API
- NEVER dump raw time series — always summarize

### Core Helper Function

```bash
#!/bin/bash

vm_query() {
    local metricsql="$1"
    local time="${2:-$(date +%s)}"
    curl -s "${VM_BASE_URL}/api/v1/query" \
        --data-urlencode "query=${metricsql}" \
        --data-urlencode "time=${time}"
}

vm_query_range() {
    local metricsql="$1"
    local start="${2:-$(( $(date +%s) - 3600 ))}"
    local end="${3:-$(date +%s)}"
    local step="${4:-60}"
    curl -s "${VM_BASE_URL}/api/v1/query_range" \
        --data-urlencode "query=${metricsql}" \
        --data-urlencode "start=${start}" \
        --data-urlencode "end=${end}" \
        --data-urlencode "step=${step}"
}

vm_api() {
    local endpoint="$1"
    curl -s "${VM_BASE_URL}${endpoint}"
}
```

## Parallel Execution

```bash
{
    vm_query "up" &
    vm_api "/api/v1/status/tsdb" &
    vm_api "/api/v1/status/active_queries" &
}
wait
```

## Anti-Hallucination Rules

**NEVER assume metric names or label keys. ALWAYS discover first.**

### Phase 1: Discovery

```bash
#!/bin/bash
echo "=== Available Metric Names (top 20) ==="
vm_api "/api/v1/label/__name__/values" | jq -r '.data[:20][]'

echo ""
echo "=== Label Names ==="
vm_api "/api/v1/labels" | jq -r '.data[]' | head -20

echo ""
echo "=== TSDB Status ==="
vm_api "/api/v1/status/tsdb" | jq '{
    totalSeries: .data.totalSeries,
    totalLabelValuePairs: .data.totalLabelValuePairs,
    seriesCountByMetricName: [.data.seriesCountByMetricName[:10][] | "\(.name): \(.value)"]
}'
```

## Common Operations

### Storage Health & Performance

```bash
#!/bin/bash
echo "=== VictoriaMetrics Storage Health ==="
{
    echo "--- TSDB Stats ---"
    vm_api "/api/v1/status/tsdb" | jq '{
        totalSeries: .data.totalSeries,
        totalLabelValuePairs: .data.totalLabelValuePairs
    }' &

    echo "--- Active Queries ---"
    vm_api "/api/v1/status/active_queries" | jq '.data | length | "Active queries: \(.)"' -r &

    echo "--- Build Info ---"
    vm_api "/flags" 2>/dev/null | grep -E "retentionPeriod|storageDataPath" | head -5 &
}
wait

echo ""
echo "=== Top Series by Metric Name ==="
vm_api "/api/v1/status/tsdb" \
    | jq -r '.data.seriesCountByMetricName[:15][] | "\(.name)\t\(.value) series"'
```

### Cardinality Analysis

```bash
#!/bin/bash
echo "=== High Cardinality Metrics ==="
vm_api "/api/v1/status/tsdb" \
    | jq -r '.data.seriesCountByMetricName | sort_by(-.value)[:15][] | "\(.name)\t\(.value) series"'

echo ""
echo "=== High Cardinality Labels ==="
vm_api "/api/v1/status/tsdb" \
    | jq -r '.data.seriesCountByLabelValuePair | sort_by(-.value)[:15][] | "\(.name)\t\(.value) series"'

echo ""
echo "=== Label Value Counts ==="
for label in $(vm_api "/api/v1/labels" | jq -r '.data[]' | head -10); do
    count=$(vm_api "/api/v1/label/${label}/values" | jq '.data | length')
    echo "$label: $count unique values"
done | sort -t: -k2 -rn
```

### MetricsQL Queries

```bash
#!/bin/bash
echo "=== CPU Usage by Instance ==="
vm_query 'avg(rate(node_cpu_seconds_total{mode!="idle"}[5m])) by (instance) * 100' \
    | jq -r '.data.result[] | "\(.metric.instance)\t\(.value[1] | tonumber | . * 10 | round / 10)%"' \
    | sort -t$'\t' -k2 -rn | head -15

echo ""
echo "=== Memory Usage ==="
vm_query '(1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) * 100' \
    | jq -r '.data.result[] | "\(.metric.instance)\t\(.value[1] | tonumber | round)%"' \
    | sort -t$'\t' -k2 -rn | head -15

echo ""
echo "=== Disk Usage ==="
vm_query '(1 - node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"}) * 100' \
    | jq -r '.data.result[] | "\(.metric.instance)\t\(.value[1] | tonumber | round)%"' | head -15
```

### Ingestion & Retention

```bash
#!/bin/bash
echo "=== Ingestion Rate ==="
vm_query 'rate(vm_rows_inserted_total[5m])' \
    | jq -r '.data.result[] | "\(.metric.type // "total")\t\(.value[1] | tonumber | round) rows/s"'

echo ""
echo "=== Storage Size ==="
vm_query 'vm_data_size_bytes' \
    | jq -r '.data.result[] | "\(.metric.type // "total")\t\(.value[1] | tonumber / 1073741824 | . * 100 | round / 100)GB"'

echo ""
echo "=== Merge Operations ==="
vm_query 'rate(vm_merges_total[5m])' \
    | jq -r '.data.result[] | "\(.metric.type)\t\(.value[1] | tonumber | . * 100 | round / 100) merges/s"'
```

### Cluster Health (vmselect/vminsert/vmstorage)

```bash
#!/bin/bash
echo "=== Cluster Node Status ==="
{
    echo "--- vmselect ---"
    vm_query 'up{job=~".*vmselect.*"}' \
        | jq -r '.data.result[] | "\(.metric.instance)\tup:\(.value[1])"' &

    echo "--- vmstorage ---"
    vm_query 'up{job=~".*vmstorage.*"}' \
        | jq -r '.data.result[] | "\(.metric.instance)\tup:\(.value[1])"' &

    echo "--- vminsert ---"
    vm_query 'up{job=~".*vminsert.*"}' \
        | jq -r '.data.result[] | "\(.metric.instance)\tup:\(.value[1])"' &
}
wait
```

## Common Pitfalls

- **MetricsQL extensions**: VictoriaMetrics supports PromQL plus extensions like `range_median`, `rollup_rate` — use them for better accuracy
- **Multi-tenant paths**: Cluster mode uses `/select/{accountID}/prometheus/` — include account ID in URL
- **Retention**: Set via `-retentionPeriod` flag — not configurable via API at runtime
- **Deduplication**: Enable `-dedup.minScrapeInterval` for HA Prometheus setups
- **Cardinality limits**: Monitor `vm_series_created_total` — high cardinality degrades performance
- **Query timeouts**: Long-range queries may timeout — use `-search.maxQueryDuration` to adjust
- **Downsampling**: VictoriaMetrics auto-selects resolution — use `step` parameter to control
- **API compatibility**: Fully Prometheus-compatible API — PromQL works without changes
