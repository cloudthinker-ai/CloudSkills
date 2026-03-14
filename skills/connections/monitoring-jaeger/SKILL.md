---
name: monitoring-jaeger
description: |
  Jaeger distributed tracing for trace search, service dependency analysis, span analysis, sampling configuration, and performance monitoring. Covers trace lookup, service topology, operation latency analysis, and comparison workflows. Use when searching traces, analyzing service dependencies, investigating latency, or managing Jaeger configuration via API.
connection_type: jaeger
preload: false
---

# Jaeger Monitoring Skill

Search, analyze, and manage distributed traces using the Jaeger API.

## API Conventions

### Authentication
Jaeger Query API is typically unauthenticated or uses reverse proxy auth. Connection handles auth injection.

### Base URL
- Query API: `http://<host>:16686/api/`
- gRPC Query: `<host>:16685`
- Use connection-injected `JAEGER_BASE_URL`.

### Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- Extract only needed span fields with `jq`
- Summarize trace data — never dump full trace payloads

### Core Helper Function

```bash
#!/bin/bash

jaeger_api() {
    local endpoint="$1"
    curl -s "${JAEGER_BASE_URL}/api${endpoint}"
}

jaeger_traces() {
    local service="$1"
    local operation="${2:-}"
    local limit="${3:-20}"
    local lookback="${4:-1h}"

    local params="service=${service}&limit=${limit}&lookback=${lookback}"
    [ -n "$operation" ] && params="${params}&operation=${operation}"

    jaeger_api "/traces?${params}"
}

jaeger_trace() {
    local trace_id="$1"
    jaeger_api "/traces/${trace_id}"
}
```

## Parallel Execution

```bash
{
    jaeger_api "/services" &
    jaeger_api "/dependencies?endTs=$(date +%s000)&lookback=86400000" &
}
wait
```

## Anti-Hallucination Rules

**NEVER assume service names, operation names, or trace IDs. ALWAYS discover first.**

### Phase 1: Discovery

```bash
#!/bin/bash
echo "=== Available Services ==="
jaeger_api "/services" | jq -r '.data[]' | sort

echo ""
echo "=== Operations per Service ==="
for svc in $(jaeger_api "/services" | jq -r '.data[]' | head -10); do
    ops=$(jaeger_api "/services/${svc}/operations" | jq -r '.data | length')
    echo "$svc: $ops operations"
done

echo ""
echo "=== Service Dependencies (24h) ==="
jaeger_api "/dependencies?endTs=$(date +%s000)&lookback=86400000" \
    | jq -r '.data[] | "\(.parent) -> \(.child) (\(.callCount) calls)"'
```

## Common Operations

### Trace Search & Analysis

```bash
#!/bin/bash
SERVICE="${1:?Service name required}"

echo "=== Recent Traces for ${SERVICE} ==="
jaeger_traces "$SERVICE" "" 20 "1h" \
    | jq -r '.data[] | "\(.traceID)\t\(.spans | length) spans\t\(.spans[0].duration / 1000)ms\t\(.spans[0].operationName)"' \
    | head -20

echo ""
echo "=== Slowest Traces (last 1h) ==="
jaeger_traces "$SERVICE" "" 50 "1h" \
    | jq -r '.data | sort_by(-.spans[0].duration) | .[:10][] | "\(.traceID)\t\(.spans[0].duration / 1000)ms\t\(.spans[0].operationName)"'
```

### Service Dependency Map

```bash
#!/bin/bash
echo "=== Service Dependency Graph ==="
jaeger_api "/dependencies?endTs=$(date +%s000)&lookback=86400000" \
    | jq -r '.data | sort_by(-.callCount)[] | "\(.parent) -> \(.child)\tcalls:\(.callCount)"'

echo ""
echo "=== Inbound/Outbound per Service ==="
DEPS=$(jaeger_api "/dependencies?endTs=$(date +%s000)&lookback=86400000")
echo "$DEPS" | jq -r '.data | group_by(.parent) | .[] | "\(.[0].parent)\toutbound:\(length)\tcalls:\([.[].callCount] | add)"' | sort -t$'\t' -k3 -rn | head -10
echo "$DEPS" | jq -r '.data | group_by(.child) | .[] | "\(.[0].child)\tinbound:\(length)\tcalls:\([.[].callCount] | add)"' | sort -t$'\t' -k3 -rn | head -10
```

### Span Analysis & Latency Breakdown

```bash
#!/bin/bash
TRACE_ID="${1:?Trace ID required}"

echo "=== Trace Span Breakdown ==="
jaeger_trace "$TRACE_ID" \
    | jq -r '.data[0].spans | sort_by(-.duration)[] | "\(.operationName)\t\(.duration / 1000)ms\t\(.processID)\t\(.logs | length) logs"' \
    | head -20

echo ""
echo "=== Critical Path (top 5 slowest spans) ==="
jaeger_trace "$TRACE_ID" \
    | jq -r '.data[0].spans | sort_by(-.duration)[:5][] | {
        operation: .operationName,
        duration_ms: (.duration / 1000),
        service: .processID,
        tags: ([.tags[] | "\(.key)=\(.value)"] | join(", "))
    }'

echo ""
echo "=== Error Spans ==="
jaeger_trace "$TRACE_ID" \
    | jq -r '.data[0].spans[] | select(.tags[] | select(.key == "error" and .value == true)) | "\(.operationName)\t\(.duration / 1000)ms"'
```

### Operation Latency Analysis

```bash
#!/bin/bash
SERVICE="${1:?Service name required}"

echo "=== Operations for ${SERVICE} ==="
jaeger_api "/services/${SERVICE}/operations" \
    | jq -r '.data[]' | head -20

echo ""
echo "=== Latency Distribution per Operation ==="
for op in $(jaeger_api "/services/${SERVICE}/operations" | jq -r '.data[]' | head -5); do
    echo "--- $op ---"
    jaeger_traces "$SERVICE" "$op" 50 "1h" \
        | jq -r '.data | [.[].spans[0].duration / 1000] | {
            count: length,
            min_ms: min,
            max_ms: max,
            avg_ms: (add / length | . * 10 | round / 10),
            p95_ms: (sort | .[length * 95 / 100 | floor])
        }' &
done
wait
```

### Sampling Configuration Review

```bash
#!/bin/bash
echo "=== Sampling Strategies ==="
for svc in $(jaeger_api "/services" | jq -r '.data[]' | head -10); do
    strategy=$(jaeger_api "/sampling?service=${svc}" 2>/dev/null \
        | jq -r '.strategyType // "unknown"')
    echo "$svc: $strategy"
done
```

## Common Pitfalls

- **Timestamps**: Jaeger uses microseconds for span durations — divide by 1000 for milliseconds
- **endTs format**: Dependencies endpoint uses milliseconds since epoch — `$(date +%s)000`
- **lookback format**: Query uses string format (`1h`, `2d`) but dependencies use milliseconds (`86400000`)
- **Trace size**: Large traces can have hundreds of spans — always limit output with `head` or jq slicing
- **Process mapping**: Span `processID` maps to process in trace's `processes` object — resolve for service names
- **Tag values**: Tags can be string, bool, or numeric — check `.type` field when filtering
- **No aggregation API**: Jaeger has no built-in aggregation — compute percentiles client-side from trace data
- **Storage limits**: Trace retention depends on backend (Elasticsearch, Cassandra) — old traces may be purged
