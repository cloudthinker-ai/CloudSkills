---
name: monitoring-tempo
description: |
  Use when working with Tempo — grafana Tempo distributed tracing with TraceQL
  queries, service graphs, span metrics, and trace analysis. Covers trace
  search, span attribute filtering, service topology, trace-to-metrics
  correlation, and backend health monitoring. Use when querying traces via
  TraceQL, analyzing service graphs, investigating latency, or monitoring Tempo
  cluster health.
connection_type: tempo
preload: false
---

# Grafana Tempo Monitoring Skill

Query and analyze distributed traces using Grafana Tempo and TraceQL.

## API Conventions

### Authentication
Tempo API uses Basic auth, Bearer token, or tenant header (`X-Scope-OrgID`) — injected by connection.

### Base URL
- Tempo API: `http://<host>:3200/`
- Use connection-injected `TEMPO_BASE_URL`.

### Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- Extract only needed span fields with `jq`
- Summarize trace data — never dump full trace payloads

### Core Helper Function

```bash
#!/bin/bash

tempo_api() {
    local endpoint="$1"
    curl -s \
        -H "X-Scope-OrgID: ${TEMPO_TENANT_ID:-default}" \
        "${TEMPO_BASE_URL}${endpoint}"
}

tempo_search() {
    local traceql="$1"
    local limit="${2:-20}"
    local start="${3:-$(( $(date +%s) - 3600 ))}"
    local end="${4:-$(date +%s)}"

    tempo_api "/api/search?q=$(python3 -c "import urllib.parse; print(urllib.parse.quote('${traceql}'))")&limit=${limit}&start=${start}&end=${end}"
}

tempo_trace() {
    local trace_id="$1"
    tempo_api "/api/traces/${trace_id}"
}
```

## Parallel Execution

```bash
{
    tempo_api "/api/search/tags" &
    tempo_api "/status/buildinfo" &
    tempo_api "/api/echo" &
}
wait
```

## Anti-Hallucination Rules

**NEVER assume span attributes, service names, or resource attributes. ALWAYS discover first.**

### Phase 1: Discovery

```bash
#!/bin/bash
echo "=== Available Tags ==="
tempo_api "/api/search/tags" | jq -r '.tagNames[]' | sort | head -30

echo ""
echo "=== Service Names ==="
tempo_api "/api/search/tag/service.name/values" | jq -r '.tagValues[]' | sort

echo ""
echo "=== Available Span Attributes ==="
for tag in "http.method" "http.status_code" "span.kind" "status.code"; do
    values=$(tempo_api "/api/search/tag/${tag}/values" | jq -r '.tagValues[]' 2>/dev/null | head -5 | tr '\n' ',')
    [ -n "$values" ] && echo "$tag: $values"
done
```

## Common Operations

### TraceQL Search

```bash
#!/bin/bash
echo "=== Error Traces (last 1h) ==="
tempo_search '{ status = error }' 20 \
    | jq -r '.traces[] | "\(.traceID)\t\(.rootServiceName)\t\(.rootTraceName)\t\(.durationMs)ms"' \
    | head -20

echo ""
echo "=== Slow Traces (>1s) ==="
tempo_search '{ duration > 1s }' 20 \
    | jq -r '.traces[] | "\(.traceID)\t\(.rootServiceName)\t\(.rootTraceName)\t\(.durationMs)ms"' \
    | sort -t$'\t' -k4 -rn | head -15

echo ""
echo "=== Traces by Service ==="
SERVICE="${1:?Service name required}"
tempo_search "{ resource.service.name = \"${SERVICE}\" }" 20 \
    | jq -r '.traces[] | "\(.traceID)\t\(.durationMs)ms\t\(.rootTraceName)"' | head -15
```

### Service Graph Analysis

```bash
#!/bin/bash
echo "=== Service Graph Metrics ==="
tempo_api "/api/metrics/service-graph" 2>/dev/null \
    | jq -r '.[] | "\(.client) -> \(.server)\treq_rate:\(.rate)\terr_rate:\(.errRate)\tp99:\(.p99)ms"' \
    | head -20

echo ""
echo "=== Service List ==="
tempo_api "/api/search/tag/service.name/values" \
    | jq -r '.tagValues[]' | while read svc; do
    count=$(tempo_search "{ resource.service.name = \"${svc}\" }" 1 | jq '.traces | length')
    echo "$svc: recent traces found=$count"
done
```

### Span Metrics & Latency Analysis

```bash
#!/bin/bash
SERVICE="${1:?Service name required}"

echo "=== Span Metrics for ${SERVICE} ==="
tempo_search "{ resource.service.name = \"${SERVICE}\" }" 50 \
    | jq -r '{
        total_traces: (.traces | length),
        avg_duration_ms: ([.traces[].durationMs] | add / length | . * 10 | round / 10),
        max_duration_ms: ([.traces[].durationMs] | max),
        min_duration_ms: ([.traces[].durationMs] | min),
        error_traces: ([.traces[] | select(.rootServiceName != null)] | length)
    }'

echo ""
echo "=== Latency Distribution ==="
tempo_search "{ resource.service.name = \"${SERVICE}\" }" 100 \
    | jq -r '.traces | sort_by(.durationMs) | [
        "p50: \(.[length/2 | floor].durationMs)ms",
        "p90: \(.[length*9/10 | floor].durationMs)ms",
        "p99: \(.[length*99/100 | floor].durationMs)ms"
    ][]'
```

### Trace Detail Inspection

```bash
#!/bin/bash
TRACE_ID="${1:?Trace ID required}"

echo "=== Trace Breakdown ==="
tempo_trace "$TRACE_ID" \
    | jq -r '.batches[].scopeSpans[].spans[] | "\(.name)\t\((.endTimeUnixNano - .startTimeUnixNano) / 1000000)ms\t\(.status.code // "OK")"' \
    | head -25

echo ""
echo "=== Error Spans ==="
tempo_trace "$TRACE_ID" \
    | jq -r '.batches[].scopeSpans[].spans[] | select(.status.code == 2) | "\(.name)\t\(.status.message // "no message")"'
```

### Backend Health

```bash
#!/bin/bash
echo "=== Tempo Status ==="
{
    tempo_api "/status/buildinfo" | jq '{version, goVersion}' &
    tempo_api "/api/echo" > /dev/null && echo "Echo: OK" || echo "Echo: FAILED" &
    echo "=== Ready Check ==="
    curl -s "${TEMPO_BASE_URL}/ready" &
}
wait
```

## Output Format

Present results as a structured report:
```
Monitoring Tempo Report
═══════════════════════
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

- **TraceQL syntax**: Uses `{ }` braces for span selectors — `{ status = error }` not `status = error`
- **Duration format**: TraceQL uses human-readable — `{ duration > 500ms }`, `{ duration > 2s }`
- **Attribute types**: String values need quotes — `{ resource.service.name = "api" }` not `= api`
- **Tag discovery**: Always use `/api/search/tags` and `/api/search/tag/{tag}/values` before filtering
- **OTLP format**: Trace responses use OTLP proto format — timestamps are nanoseconds
- **Status codes**: `0`=Unset, `1`=OK, `2`=Error in OTLP — filter errors with `.status.code == 2`
- **Multi-tenancy**: Set `X-Scope-OrgID` header for multi-tenant deployments
- **Search limits**: Default search window is limited — always specify `start` and `end` timestamps
