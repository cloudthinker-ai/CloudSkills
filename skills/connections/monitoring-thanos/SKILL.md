---
name: monitoring-thanos
description: |
  Use when working with Thanos — thanos long-term Prometheus storage with store
  gateway health, compactor status, query frontend analysis, sidecar management,
  and ruler evaluation. Covers PromQL queries via Thanos Query, block
  management, deduplication, downsampling status, and multi-cluster federation.
  Use when querying Thanos metrics, monitoring compaction, analyzing store
  health, or managing Thanos components.
connection_type: thanos
preload: false
---

# Thanos Monitoring Skill

Query and manage Thanos distributed Prometheus infrastructure.

## API Conventions

### Authentication
Thanos Query API is Prometheus-compatible. Auth handled by connection (Bearer token or Basic auth).

### Base URLs
- Query: `http://<query>:9090/api/v1/`
- Store Gateway: `http://<store>:10902/`
- Compactor: `http://<compactor>:10902/`
- Sidecar: `http://<sidecar>:10902/`

### Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- Use `jq` to extract metric values from Prometheus API responses
- Summarize multi-series results — never dump raw time series

### Core Helper Function

```bash
#!/bin/bash

thanos_query() {
    local promql="$1"
    local time="${2:-$(date +%s)}"
    curl -s "${THANOS_QUERY_URL}/api/v1/query" \
        --data-urlencode "query=${promql}" \
        --data-urlencode "time=${time}" \
        -H "Authorization: Bearer ${THANOS_TOKEN:-}"
}

thanos_query_range() {
    local promql="$1"
    local start="${2:-$(( $(date +%s) - 3600 ))}"
    local end="${3:-$(date +%s)}"
    local step="${4:-60}"
    curl -s "${THANOS_QUERY_URL}/api/v1/query_range" \
        --data-urlencode "query=${promql}" \
        --data-urlencode "start=${start}" \
        --data-urlencode "end=${end}" \
        --data-urlencode "step=${step}" \
        -H "Authorization: Bearer ${THANOS_TOKEN:-}"
}

thanos_component() {
    local component_url="$1"
    local endpoint="$2"
    curl -s "${component_url}${endpoint}"
}
```

## Parallel Execution

```bash
{
    thanos_query "up" &
    thanos_component "$THANOS_STORE_URL" "/api/v1/status/flags" &
    thanos_component "$THANOS_COMPACTOR_URL" "/metrics" &
}
wait
```

## Anti-Hallucination Rules

**NEVER assume metric names, label keys, or store endpoints. ALWAYS discover first.**

### Phase 1: Discovery

```bash
#!/bin/bash
echo "=== Available Stores ==="
curl -s "${THANOS_QUERY_URL}/api/v1/stores" | jq -r '.data[] | "\(.name)\t\(.type)\t\(.lastCheck[0:19])"' | head -20

echo ""
echo "=== Label Names ==="
curl -s "${THANOS_QUERY_URL}/api/v1/labels" | jq -r '.data[]' | head -20

echo ""
echo "=== Target Metadata (metric families) ==="
thanos_query 'count({__name__=~".+"}) by (__name__)' \
    | jq -r '.data.result | sort_by(-.value[1] | tonumber)[:20][] | "\(.metric.__name__)\t\(.value[1])"'
```

## Common Operations

### Store Gateway Health

```bash
#!/bin/bash
echo "=== Store Gateway Status ==="
{
    echo "--- Connected Stores ---"
    curl -s "${THANOS_QUERY_URL}/api/v1/stores" \
        | jq -r '.data[] | "\(.name)\t\(.type)\tmin:\(.minTime[0:10])\tmax:\(.maxTime[0:10])"' &

    echo "--- Store API Health ---"
    thanos_query 'thanos_store_gateway_loaded_blocks' \
        | jq -r '.data.result[] | "\(.metric.instance)\tblocks:\(.value[1])"' &

    echo "--- Block Sync Status ---"
    thanos_query 'thanos_blocks_meta_synced{state="loaded"}' \
        | jq -r '.data.result[] | "\(.metric.instance)\tloaded:\(.value[1])"' &
}
wait
```

### Compactor Status

```bash
#!/bin/bash
echo "=== Compactor Health ==="
{
    echo "--- Compaction Status ---"
    thanos_query 'thanos_compact_group_compactions_total' \
        | jq -r '.data.result[] | "\(.metric.group)\tcompactions:\(.value[1])"' | head -10 &

    echo "--- Compaction Failures ---"
    thanos_query 'thanos_compact_group_compactions_failures_total' \
        | jq -r '.data.result[] | select(.value[1] != "0") | "\(.metric.group)\tfailures:\(.value[1])"' &

    echo "--- Bucket Operations ---"
    thanos_query 'thanos_objstore_bucket_operations_total' \
        | jq -r '.data.result[] | "\(.metric.operation)\t\(.value[1])"' &
}
wait

echo ""
echo "=== Downsampling Status ==="
thanos_query 'thanos_compact_downsample_total' \
    | jq -r '.data.result[] | "\(.metric.resolution)\tcount:\(.value[1])"'
```

### Query Frontend Performance

```bash
#!/bin/bash
echo "=== Query Performance ==="
{
    thanos_query 'histogram_quantile(0.99, rate(http_request_duration_seconds_bucket{handler="query"}[5m]))' \
        | jq -r '.data.result[] | "p99 query latency: \(.value[1])s"' &

    thanos_query 'rate(http_requests_total{handler="query"}[5m])' \
        | jq -r '.data.result[] | "Query rate: \(.value[1]) req/s"' &

    thanos_query 'thanos_query_concurrent_gate_queries_in_flight' \
        | jq -r '.data.result[] | "In-flight queries: \(.value[1])"' &
}
wait

echo ""
echo "=== Cache Hit Rate ==="
thanos_query 'rate(thanos_store_bucket_cache_hits_total[5m]) / (rate(thanos_store_bucket_cache_hits_total[5m]) + rate(thanos_store_bucket_cache_misses_total[5m]))' \
    | jq -r '.data.result[] | "\(.metric.instance)\thit_rate:\(.value[1] | tonumber * 100 | round)%"'
```

### Sidecar Management

```bash
#!/bin/bash
echo "=== Sidecar Health ==="
thanos_query 'thanos_sidecar_prometheus_up' \
    | jq -r '.data.result[] | "\(.metric.instance)\tprometheus_up:\(.value[1])"'

echo ""
echo "=== Sidecar Upload Status ==="
thanos_query 'thanos_shipper_uploads_total' \
    | jq -r '.data.result[] | "\(.metric.instance)\tuploads:\(.value[1])"'

echo ""
echo "=== Sidecar Upload Failures ==="
thanos_query 'thanos_shipper_upload_failures_total' \
    | jq -r '.data.result[] | select(.value[1] != "0") | "\(.metric.instance)\tfailures:\(.value[1])"'
```

### Multi-Cluster PromQL Queries

```bash
#!/bin/bash
echo "=== Cross-Cluster CPU Usage ==="
thanos_query 'avg(rate(node_cpu_seconds_total{mode!="idle"}[5m])) by (cluster) * 100' \
    | jq -r '.data.result[] | "\(.metric.cluster)\t\(.value[1] | tonumber | . * 10 | round / 10)%"' \
    | sort -t$'\t' -k2 -rn

echo ""
echo "=== Cross-Cluster Memory ==="
thanos_query '(1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) * 100' \
    | jq -r '.data.result[] | "\(.metric.cluster // .metric.instance)\t\(.value[1] | tonumber | round)%"' \
    | sort -t$'\t' -k2 -rn | head -15
```

## Output Format

Present results as a structured report:
```
Monitoring Thanos Report
════════════════════════
Resources discovered: [count]

Resource       Status    Key Metric    Issues
──────────────────────────────────────────────
[name]         [ok/warn] [value]       [findings]

Summary: [total] resources | [ok] healthy | [warn] warnings | [crit] critical
Action Items: [list of prioritized findings]
```

Target ≤50 lines of output. Use tables for multi-resource comparisons.

## Counter-Rationalizations

| Shortcut | Counter | Why |
|----------|---------|-----|
| "I'll skip discovery and check known resources" | Always run Phase 1 discovery first | Resource names change, new resources appear — assumed names cause errors |
| "The user only asked for a quick check" | Follow the full discovery → analysis flow | Quick checks miss critical issues; structured analysis catches silent failures |
| "Default configuration is probably fine" | Audit configuration explicitly | Defaults often leave logging, security, and optimization features disabled |
| "Metrics aren't needed for this" | Always check relevant metrics when available | API/CLI responses show current state; metrics reveal trends and intermittent issues |
| "I don't have access to that" | Try the command and report the actual error | Assumed permission failures prevent useful investigation; actual errors are informative |

## Common Pitfalls

- **Deduplication**: Enable `--query.replica-label` on Thanos Query to deduplicate across replicas
- **Partial responses**: Thanos may return partial data if stores are down — check `warnings` in response
- **Store lag**: Store gateway may lag behind real-time data — use sidecar for recent data
- **Compaction resolution**: 0=raw, 300000=5m, 3600000=1h — query the right resolution for time range
- **Block retention**: Compactor manages retention — check `--retention.resolution-raw` settings
- **Query timeout**: Long-range queries can timeout — use `step` parameter to reduce points
- **External labels**: Thanos uses external labels for dedup — verify `external_labels` in Prometheus config
- **API compatibility**: Thanos Query is Prometheus-compatible — standard PromQL works as-is
