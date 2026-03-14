---
name: monitoring-opentelemetry
description: |
  OpenTelemetry collector management, pipeline configuration, exporter health, instrumentation analysis, and receiver status. Covers collector metrics, pipeline topology, processor performance, batch/queue monitoring, and SDK configuration review. Use when managing OTel collectors, analyzing pipeline health, reviewing exporter status, or troubleshooting instrumentation.
connection_type: opentelemetry
preload: false
---

# OpenTelemetry Monitoring Skill

Monitor and manage OpenTelemetry collectors, pipelines, and instrumentation health.

## API Conventions

### Collector Endpoints
OTel collectors expose health and metrics endpoints:
- Health: `http://<collector>:13133/` (health_check extension)
- Metrics: `http://<collector>:8888/metrics` (Prometheus format)
- zPages: `http://<collector>:55679/debug/tracez` (debug extension)
- pprof: `http://<collector>:1777/debug/pprof/` (performance profiling)

### Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- Parse Prometheus metrics format with `grep` and `awk`
- NEVER dump full metric endpoints — always filter to relevant metrics

### Core Helper Function

```bash
#!/bin/bash

otel_metrics() {
    local host="${1:-localhost}"
    local port="${2:-8888}"
    curl -s "http://${host}:${port}/metrics"
}

otel_health() {
    local host="${1:-localhost}"
    local port="${2:-13133}"
    curl -s "http://${host}:${port}/"
}

otel_zpages() {
    local host="${1:-localhost}"
    local port="${2:-55679}"
    local path="${3:-tracez}"
    curl -s "http://${host}:${port}/debug/${path}"
}

# Parse Prometheus metrics for a specific metric name
otel_metric_value() {
    local host="$1"
    local metric_name="$2"
    otel_metrics "$host" | grep "^${metric_name}" | grep -v "^#"
}
```

## Parallel Execution

```bash
{
    otel_health "collector-1" &
    otel_health "collector-2" &
    otel_metrics "collector-1" | grep "otelcol_receiver" &
    otel_metrics "collector-2" | grep "otelcol_receiver" &
}
wait
```

## Anti-Hallucination Rules

**NEVER assume collector endpoints, pipeline names, or exporter types. ALWAYS discover first.**

### Phase 1: Discovery

```bash
#!/bin/bash
COLLECTOR="${1:-localhost}"

echo "=== Collector Health ==="
otel_health "$COLLECTOR"

echo "=== Active Pipelines ==="
otel_metrics "$COLLECTOR" | grep "otelcol_process" | grep -v "^#" | head -5

echo "=== Configured Receivers ==="
otel_metrics "$COLLECTOR" | grep "otelcol_receiver_accepted" | grep -v "^#" \
    | sed 's/.*receiver="\([^"]*\)".*/\1/' | sort -u

echo "=== Configured Exporters ==="
otel_metrics "$COLLECTOR" | grep "otelcol_exporter_sent" | grep -v "^#" \
    | sed 's/.*exporter="\([^"]*\)".*/\1/' | sort -u

echo "=== Configured Processors ==="
otel_metrics "$COLLECTOR" | grep "otelcol_processor" | grep -v "^#" \
    | sed 's/.*processor="\([^"]*\)".*/\1/' | sort -u
```

## Common Operations

### Collector Health Overview

```bash
#!/bin/bash
COLLECTOR="${1:-localhost}"

echo "=== Collector Process Metrics ==="
{
    echo "--- Uptime & Resource Usage ---"
    otel_metric_value "$COLLECTOR" "otelcol_process_uptime" &
    otel_metric_value "$COLLECTOR" "otelcol_process_memory_rss" &
    otel_metric_value "$COLLECTOR" "otelcol_process_cpu_seconds" &
}
wait

echo ""
echo "=== Build Info ==="
otel_metrics "$COLLECTOR" | grep "otelcol_build_info" | grep -v "^#"
```

### Pipeline Throughput Analysis

```bash
#!/bin/bash
COLLECTOR="${1:-localhost}"

echo "=== Receiver Throughput (accepted vs refused) ==="
otel_metrics "$COLLECTOR" | grep -E "otelcol_receiver_(accepted|refused)_" | grep -v "^#" \
    | awk -F'[{}]' '{split($2,a,","); for(i in a) if(a[i] ~ /receiver=/) print a[i], $0}' \
    | head -20

echo ""
echo "=== Exporter Throughput (sent vs failed) ==="
otel_metrics "$COLLECTOR" | grep -E "otelcol_exporter_(sent|send_failed)_" | grep -v "^#" \
    | head -20

echo ""
echo "=== Processor Metrics ==="
otel_metrics "$COLLECTOR" | grep "otelcol_processor" | grep -v "^#" | head -15
```

### Queue & Batch Monitoring

```bash
#!/bin/bash
COLLECTOR="${1:-localhost}"

echo "=== Exporter Queue Size ==="
otel_metric_value "$COLLECTOR" "otelcol_exporter_queue_size"
otel_metric_value "$COLLECTOR" "otelcol_exporter_queue_capacity"

echo ""
echo "=== Batch Processor Stats ==="
otel_metric_value "$COLLECTOR" "otelcol_processor_batch_batch_send_size_sum"
otel_metric_value "$COLLECTOR" "otelcol_processor_batch_batch_send_size_count"
otel_metric_value "$COLLECTOR" "otelcol_processor_batch_timeout_trigger_send"

echo ""
echo "=== Retry Queue ==="
otel_metric_value "$COLLECTOR" "otelcol_exporter_enqueue_failed_spans"
otel_metric_value "$COLLECTOR" "otelcol_exporter_enqueue_failed_metric_points"
otel_metric_value "$COLLECTOR" "otelcol_exporter_enqueue_failed_log_records"
```

### Configuration Review

```bash
#!/bin/bash
# Review collector config file
CONFIG_PATH="${1:-/etc/otelcol/config.yaml}"

echo "=== Collector Configuration ==="
if [ -f "$CONFIG_PATH" ]; then
    echo "--- Receivers ---"
    grep -A2 "^receivers:" "$CONFIG_PATH" | head -10
    echo "--- Processors ---"
    grep -A2 "^processors:" "$CONFIG_PATH" | head -10
    echo "--- Exporters ---"
    grep -A2 "^exporters:" "$CONFIG_PATH" | head -10
    echo "--- Service Pipelines ---"
    grep -A10 "^service:" "$CONFIG_PATH" | head -15
else
    echo "Config file not found at $CONFIG_PATH"
fi
```

### Multi-Collector Fleet Health

```bash
#!/bin/bash
COLLECTORS="${@:-collector-1 collector-2 collector-3}"

echo "=== Fleet Health Summary ==="
for host in $COLLECTORS; do
    {
        status=$(otel_health "$host" 2>/dev/null && echo "UP" || echo "DOWN")
        if [ "$status" = "UP" ]; then
            uptime=$(otel_metric_value "$host" "otelcol_process_uptime" | awk '{print $NF}')
            mem=$(otel_metric_value "$host" "otelcol_process_memory_rss" | awk '{printf "%.0fMB", $NF/1048576}')
            echo "$host\t$status\tuptime:${uptime}s\tmem:${mem}"
        else
            echo "$host\t$status"
        fi
    } &
done
wait
```

## Common Pitfalls

- **Metric format**: Collector metrics are in Prometheus exposition format — use grep/awk, not jq
- **Port defaults**: Health=13133, metrics=8888, zPages=55679, OTLP gRPC=4317, OTLP HTTP=4318
- **Pipeline isolation**: Metrics are labeled by pipeline (`traces`, `metrics`, `logs`) — filter accordingly
- **Queue backpressure**: Monitor `otelcol_exporter_queue_size` vs `queue_capacity` — near-capacity indicates backpressure
- **Dropped data**: Check `otelcol_receiver_refused_*` and `otelcol_exporter_send_failed_*` for data loss
- **Config validation**: Use `otelcol validate --config=config.yaml` before applying changes
- **Extensions**: Health check and zPages must be explicitly enabled in config — not available by default
- **Memory limiter**: Critical processor — check `otelcol_processor_refused_spans` for memory pressure drops
