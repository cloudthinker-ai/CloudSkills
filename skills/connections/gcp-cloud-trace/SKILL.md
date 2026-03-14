---
name: gcp-cloud-trace
description: |
  Google Cloud Trace latency analysis, trace exploration, sampling configuration, and span diagnostics via gcloud CLI.
connection_type: gcp
preload: false
---

# Cloud Trace Skill

Manage and analyze Google Cloud Trace using `gcloud trace` and monitoring commands.

## Discovery-First Rule

**ALWAYS discover before acting.** Never assume trace IDs, span names, or service names. Discover available traces and services first.

```bash
# Discover recent traces
gcloud trace traces list --limit=20 --format=json \
  | jq '[.[] | {traceId: .traceId, projectId: .projectId, spans: [.spans[:3][] | {spanId: .spanId, name: .name, startTime: .startTime, endTime: .endTime}]}]'
```

## Parallel Execution Requirement

**ALL independent operations MUST run in parallel using background jobs (&) and wait.**

```bash
for trace_id in $(gcloud trace traces list --limit=10 --format="value(traceId)"); do
  {
    gcloud trace traces describe "$trace_id" --format=json
  } &
done
wait
```

## Helper Functions

```bash
# Get trace details
get_trace() {
  local trace_id="$1"
  gcloud trace traces describe "$trace_id" --format=json \
    | jq '{traceId: .traceId, spans: [.spans[] | {spanId: .spanId, name: .name, kind: .kind, startTime: .startTime, endTime: .endTime, status: .status, labels: .labels, parentSpanId: .parentSpanId}]}'
}

# List traces with filter
list_traces() {
  local filter="$1" limit="${2:-20}"
  gcloud trace traces list --filter="$filter" --limit="$limit" --format=json
}

# Get trace latency metrics via monitoring
get_latency_metrics() {
  local service="$1"
  gcloud monitoring time-series list \
    --filter="metric.type=\"cloudtrace.googleapis.com/http/server/response_latencies\" AND metric.labels.service=\"$service\"" \
    --interval-start-time="$(date -u -v-1H +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%SZ)" \
    --format=json
}

# Get trace count metrics
get_trace_counts() {
  gcloud monitoring time-series list \
    --filter="metric.type=\"cloudtrace.googleapis.com/http/server/response_count\"" \
    --interval-start-time="$(date -u -v-1H +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%SZ)" \
    --format=json
}
```

## Common Operations

### 1. Latency Analysis

```bash
# Overall request latency distribution
gcloud monitoring time-series list \
  --filter="metric.type=\"cloudtrace.googleapis.com/http/server/response_latencies\"" \
  --interval-start-time="$(date -u -v-1H +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%SZ)" \
  --format=json

# Latency by service
gcloud monitoring time-series list \
  --filter="metric.type=\"cloudtrace.googleapis.com/http/server/response_latencies\"" \
  --interval-start-time="$(date -u -v-1H +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%SZ)" \
  --format=json \
  | jq '[.[] | {service: .metric.labels.service, method: .metric.labels.method, distributionValue: .points[0].value.distributionValue}]'
```

### 2. Trace Exploration

```bash
# Recent slow traces (sorted by duration)
gcloud trace traces list --limit=50 --format=json \
  | jq '[.[] | {traceId: .traceId, rootSpan: .spans[0].name, startTime: .spans[0].startTime, durationMs: ((.spans[0].endTime | sub("Z$";"") | split(".")[0] | strptime("%Y-%m-%dT%H:%M:%S") | mktime) - (.spans[0].startTime | sub("Z$";"") | split(".")[0] | strptime("%Y-%m-%dT%H:%M:%S") | mktime)) * 1000}] | sort_by(-.durationMs) | .[:10]'

# Trace with specific span name
list_traces "span:\"$SPAN_NAME\"" 20

# Error traces
list_traces "status.code!=0" 20
```

### 3. Span Analysis

```bash
# Get full span tree for a trace
get_trace "$TRACE_ID"

# Find slowest spans in a trace
gcloud trace traces describe "$TRACE_ID" --format=json \
  | jq '[.spans[] | {name: .name, kind: .kind, labels: .labels, parentSpanId: .parentSpanId}] | sort_by(-.durationMs) | .[:5]'
```

### 4. Sampling Configuration

```bash
# Check trace sampling via monitoring (sampled vs total)
gcloud monitoring time-series list \
  --filter="metric.type=\"cloudtrace.googleapis.com/http/server/response_count\"" \
  --interval-start-time="$(date -u -v-1H +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%SZ)" \
  --format=json

# Trace configuration is typically set in application code or via Cloud Trace agent config
# Check if any oversampling settings exist
gcloud services list --filter="name:cloudtrace.googleapis.com" --format=json
```

### 5. Cross-Service Trace Correlation

```bash
# Find traces spanning multiple services
gcloud trace traces list --limit=20 --format=json \
  | jq '[.[] | {traceId: .traceId, services: [.spans[].labels."g.co/agent" // .spans[].labels.component // "unknown"] | unique, spanCount: (.spans | length)}] | [.[] | select(.services | length > 1)]'

# Get detailed view of a cross-service trace
get_trace "$TRACE_ID"
```

## Common Pitfalls

1. **Sampling rate**: Cloud Trace samples approximately 0.1 requests per second per project by default. Low-traffic services may have very few traces. Force tracing with `X-Cloud-Trace-Context` header.
2. **Trace retention**: Traces are retained for 30 days. Older traces are automatically deleted and cannot be recovered.
3. **Span limits**: A single trace can have at most 128 spans. Large distributed transactions may be truncated.
4. **Latency vs duration**: Trace latency includes network time between services. Individual span duration is the time spent in that service only.
5. **Missing spans**: Missing child spans usually indicate the downstream service is not instrumented or sampling dropped the span. Check instrumentation on all services in the call chain.
