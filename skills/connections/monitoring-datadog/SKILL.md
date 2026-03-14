---
name: monitoring-datadog
description: |
  Datadog observability platform for metrics, logs, traces, dashboards, monitors, and alerts. Covers APM, infrastructure monitoring, log analytics, synthetic monitoring, SLOs, incident management, and cost analysis. Use when querying Datadog metrics, investigating monitors/alerts, analyzing application performance, reviewing logs, or managing Datadog resources via API.
connection_type: datadog
preload: false
---

# Datadog Monitoring Skill

Query, analyze, and manage Datadog observability resources using the Datadog API.

## MANDATORY: Read Before Any Datadog Operation

You MUST follow this skill before executing any Datadog API calls. It contains mandatory anti-hallucination rules, parallel execution patterns, and API conventions that prevent common errors.

## API Conventions

### Authentication
All Datadog API calls require `DD-API-KEY` and `DD-APPLICATION-KEY` headers — these are injected automatically by the connection. Never hardcode or echo credentials.

### Base URL
- US1: `https://api.datadoghq.com/api/v1/` and `/api/v2/`
- EU: `https://api.datadoghq.eu/api/v1/`
- Always use the connection-injected base URL — do NOT hardcode regions.

### Output Rules
- **TOKEN EFFICIENCY**: Output must be minimal and aggregated — target ≤50 lines
- Filter at API level using query parameters before post-processing
- Use `jq` to extract only needed fields from JSON responses
- NEVER dump full API responses — always extract specific fields

## Parallel Execution Requirement (CRITICAL)

🚨 **ALL independent Datadog API calls MUST run in parallel using background jobs (&) and wait** 🚨

```bash
# CORRECT: Parallel metric fetches
{
  curl -s "...metrics?query=avg:system.cpu.user{*}" | jq '.series[0].pointlist[-1][1]' &
  curl -s "...metrics?query=avg:system.mem.used{*}" | jq '.series[0].pointlist[-1][1]' &
  curl -s "...monitors" | jq '.[].name' &
}
wait
```

Sequential API calls for independent resources are FORBIDDEN — always parallelize.

## Core API Patterns

### Helper Function (use for ALL API calls)

```bash
#!/bin/bash

# Core Datadog API caller — always use this function
dd_api() {
    local method="$1"    # GET, POST, PUT, DELETE
    local endpoint="$2"  # e.g., /api/v1/monitors
    local data="${3:-}"  # Optional JSON body

    if [ -n "$data" ]; then
        curl -s -X "$method" \
            -H "Content-Type: application/json" \
            "${DD_API_BASE_URL}${endpoint}" \
            -d "$data"
    else
        curl -s -X "$method" \
            "${DD_API_BASE_URL}${endpoint}"
    fi
}

# Query metrics (v1 metrics query)
dd_metrics() {
    local query="$1"
    local from="${2:-$(date -d '1 hour ago' +%s)}"
    local to="${3:-$(date +%s)}"
    dd_api GET "/api/v1/query?from=${from}&to=${to}&query=$(python3 -c "import urllib.parse; print(urllib.parse.quote('${query}'))")"
}

# List monitors
dd_monitors() {
    local tags="${1:-}"
    if [ -n "$tags" ]; then
        dd_api GET "/api/v1/monitor?monitor_tags=${tags}&with_downtimes=true"
    else
        dd_api GET "/api/v1/monitor?with_downtimes=true"
    fi
}

# Search logs (v2)
dd_logs() {
    local filter_query="$1"
    local from="${2:-now-1h}"
    local to="${3:-now}"
    dd_api POST "/api/v2/logs/events/search" \
        "{\"filter\":{\"query\":\"${filter_query}\",\"from\":\"${from}\",\"to\":\"${to}\"},\"page\":{\"limit\":100}}"
}

# Get service dependencies (APM)
dd_services() {
    dd_api GET "/api/v1/services"
}
```

## Anti-Hallucination Rules

**NEVER assume metric names, tag keys, or monitor IDs exist. ALWAYS discover first.**

### Two-Phase Execution Pattern

**Phase 1: Discovery** — Always run before querying specific resources

```bash
#!/bin/bash
# PHASE 1: Discover available metrics namespaces
echo "=== Available Metric Namespaces ==="
dd_api GET "/api/v1/metrics?q=" | jq -r '.metrics[]' | cut -d'.' -f1 | sort -u | head -20

echo "=== Active Monitors (ALERT/WARN state) ==="
dd_api GET "/api/v1/monitor?monitor_tags=&with_downtimes=true" \
    | jq -r '.[] | select(.overall_state == "Alert" or .overall_state == "Warn") | "\(.id)\t\(.overall_state)\t\(.name)"' \
    | head -20

echo "=== Available Tags ==="
dd_api GET "/api/v1/tags/hosts" | jq -r '.tags | keys[]' | head -20

echo "=== Services (APM) ==="
dd_api GET "/api/v2/apm/services" | jq -r '.data[].attributes.name' 2>/dev/null | head -20
```

**Phase 2: Query** — Only after Phase 1 confirms resources exist

```bash
# Only query metrics that were confirmed in Phase 1
```

## Common Operations

### Infrastructure Monitoring

```bash
#!/bin/bash
# Get host infrastructure overview (parallel)
echo "=== Host Summary ==="
{
    # Host count by status
    dd_api GET "/api/v1/hosts?count=true" | jq '{total: .total_matching, up: .total_up, muted: .total_muted}' &

    # Top hosts by CPU (last hour)
    dd_metrics "avg:system.cpu.user{*} by {host}" \
        $(date -d '1 hour ago' +%s) $(date +%s) \
        | jq -r '.series[] | "\(.scope)\t\(.pointlist[-1][1] // "N/A")"' \
        | sort -t$'\t' -k2 -rn | head -10 &

    # Memory usage per host
    dd_metrics "avg:system.mem.pct_usable{*} by {host}" \
        $(date -d '1 hour ago' +%s) $(date +%s) \
        | jq -r '.series[] | "\(.scope)\t\(100 - (.pointlist[-1][1] * 100 // 0))"' \
        | sort -t$'\t' -k2 -rn | head -10 &
}
wait
```

### Monitor Management

```bash
#!/bin/bash
# List monitors by status
echo "=== Monitor Status Summary ==="
dd_monitors | jq -r 'group_by(.overall_state) | .[] | "\(.[0].overall_state): \(length)"'

echo ""
echo "=== Alerting Monitors ==="
dd_monitors | jq -r '.[] | select(.overall_state == "Alert") | "\(.id)\t\(.name)\t\(.query)"' | head -20

echo ""
echo "=== Monitors in No Data ==="
dd_monitors | jq -r '.[] | select(.overall_state == "No Data") | "\(.id)\t\(.name)"' | head -10
```

### APM / Tracing

```bash
#!/bin/bash
# APM service performance overview
FROM=$(date -d '1 hour ago' +%s)
TO=$(date +%s)

echo "=== APM Service Latency (p95) ==="
{
    # Service latency
    dd_metrics "p95:trace.web.request.duration{env:production} by {service}" $FROM $TO \
        | jq -r '.series[] | "\(.scope | split(",")[0] | split(":")[1])\t\((.pointlist | map(.[1]) | add / length * 1000 // 0 | floor))ms"' \
        | sort -t$'\t' -k2 -rn | head -10 &

    # Error rates
    dd_metrics "sum:trace.web.request.errors{env:production} by {service}" $FROM $TO \
        | jq -r '.series[] | "\(.scope | split(",")[0] | split(":")[1])\t\(.pointlist[-1][1] // 0 | floor) errors"' \
        | sort -t$'\t' -k2 -rn | head -10 &

    # Request throughput
    dd_metrics "sum:trace.web.request.hits{env:production} by {service}" $FROM $TO \
        | jq -r '.series[] | "\(.scope | split(",")[0] | split(":")[1])\t\(.pointlist[-1][1] // 0 | floor) req/s"' \
        | sort -t$'\t' -k2 -rn | head -10 &
}
wait
```

### Log Analysis

```bash
#!/bin/bash
# Search and analyze logs
echo "=== Error Logs (last 1h) ==="
dd_logs "status:error" "now-1h" "now" \
    | jq -r '.data[] | "\(.attributes.timestamp)\t\(.attributes.service // "unknown")\t\(.attributes.message[0:100])"' \
    | head -20

echo ""
echo "=== Error Count by Service ==="
dd_api POST "/api/v2/logs/analytics/aggregate" \
    '{"compute":[{"aggregation":"count","type":"total"}],"filter":{"query":"status:error","from":"now-1h","to":"now"},"group_by":[{"facet":"service","limit":10,"sort":{"aggregation":"count","order":"desc"}}]}' \
    | jq -r '.data.buckets[] | "\(.by.service // "unknown")\t\(.computes.c0)"'
```

### SLO Monitoring

```bash
#!/bin/bash
# Review SLO status
echo "=== SLO Status ==="
dd_api GET "/api/v1/slo" \
    | jq -r '.data[] | "\(.name)\t\(.type)"' | head -20

echo ""
echo "=== SLO Error Budget Remaining ==="
# Get SLO IDs first
SLO_IDS=$(dd_api GET "/api/v1/slo" | jq -r '.data[].id' | head -5)

for slo_id in $SLO_IDS; do
    dd_api GET "/api/v1/slo/${slo_id}/history?from_ts=$(date -d '30 days ago' +%s)&to_ts=$(date +%s)" \
        | jq -r '"SLO \(.data.slo.name): \(.data.overall.sli_value // "N/A")%"' &
done
wait
```

### Dashboard Overview

```bash
#!/bin/bash
# List all dashboards
echo "=== Dashboards ==="
dd_api GET "/api/v1/dashboard" \
    | jq -r '.dashboards[] | "\(.id)\t\(.title)\t\(.modified_at[0:10])"' \
    | sort -t$'\t' -k3 -r | head -20
```

### Incident Management

```bash
#!/bin/bash
# Active incidents
echo "=== Active Incidents ==="
dd_api GET "/api/v2/incidents?filter[status]=active&page[size]=10" \
    | jq -r '.data[] | "\(.id)\t\(.attributes.severity // "UNKNOWN")\t\(.attributes.title)"' | head -10

echo ""
echo "=== Recent Resolved Incidents (7d) ==="
dd_api GET "/api/v2/incidents?filter[status]=resolved&page[size]=10" \
    | jq -r '.data[] | "\(.attributes.resolved[0:10])\t\(.attributes.severity // "?")\t\(.attributes.title)"' | head -10
```

## Cost & Usage Analysis

```bash
#!/bin/bash
# Estimated Datadog usage (billable metrics)
echo "=== Custom Metric Count ==="
dd_api GET "/api/v1/usage/timeseries?start_hr=$(date -d 'first day of this month' +%Y-%m-%dT%H:00:00Z)&end_hr=$(date +%Y-%m-%dT%H:00:00Z)" \
    | jq '[.usage[].num_custom_timeseries // 0] | add / length | floor | "Avg custom metrics: \(.)"' -r 2>/dev/null || echo "N/A"

echo ""
echo "=== Host Count Trend ==="
dd_api GET "/api/v1/usage/hosts?start_hr=$(date -d '7 days ago' +%Y-%m-%dT%H:00:00Z)&end_hr=$(date +%Y-%m-%dT%H:00:00Z)" \
    | jq -r '.usage[] | "\(.hour[0:10])\t\(.host_count // 0)"' | head -10
```

## Common Pitfalls

- **Metric names**: Always discover via `/api/v1/metrics` before querying — never guess namespaces
- **Timestamps**: Datadog uses **Unix epoch seconds** for v1 and **ISO 8601** for v2 — match the API version
- **Rate limits**: 300 requests/hour for most endpoints; parallelize but add small stagger (`sleep 0.1`) for >20 concurrent calls
- **Tag format**: `key:value` (not `key=value`) — e.g., `env:production`, `service:api`
- **Metric rollups**: `/api/v1/query` returns rolled-up points — for fine-grained data use shorter time windows
- **Log query syntax**: Uses Lucene-like syntax — `service:api AND status:error` (not SQL)
- **Pagination**: v2 endpoints use cursor pagination — check `meta.page.after` for next page cursor
- **Unit handling**: CPU metrics are percentages (0-100), memory bytes, latency in nanoseconds for traces
