---
name: monitoring-instana
description: |
  Use when working with Instana — instana application performance monitoring
  with infrastructure discovery, service endpoint analysis, incident management,
  smart alert configuration, and dependency mapping. Covers automatic topology,
  call analysis, trace grouping, SLI/SLO tracking, and infrastructure health.
  Use when analyzing service performance, investigating incidents, reviewing
  infrastructure topology, or managing alerts via Instana API.
connection_type: instana
preload: false
---

# Instana Monitoring Skill

Monitor and analyze infrastructure and applications using the Instana API.

## API Conventions

### Authentication
Instana API uses `apiToken` header — injected by connection. Never hardcode tokens.

### Base URL
- API: `https://<tenant>-<unit>.instana.io/api/`
- Use connection-injected `INSTANA_BASE_URL`.

### Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- Use `jq` to extract entity snapshots and metric values
- NEVER dump full infrastructure snapshots — summarize by type

### Core Helper Function

```bash
#!/bin/bash

instana_api() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"

    if [ -n "$data" ]; then
        curl -s -X "$method" \
            -H "authorization: apiToken ${INSTANA_API_TOKEN}" \
            -H "Content-Type: application/json" \
            "${INSTANA_BASE_URL}/api${endpoint}" \
            -d "$data"
    else
        curl -s -X "$method" \
            -H "authorization: apiToken ${INSTANA_API_TOKEN}" \
            "${INSTANA_BASE_URL}/api${endpoint}"
    fi
}

instana_metrics() {
    local entity_type="$1"
    local metric="$2"
    local duration="${3:-3600000}"  # milliseconds
    local to=$(( $(date +%s) * 1000 ))
    local from=$(( to - duration ))

    instana_api POST "/infrastructure-monitoring/metrics" \
        "{\"plugin\":\"${entity_type}\",\"metrics\":[\"${metric}\"],\"timeFrame\":{\"windowSize\":${duration},\"to\":${to}}}"
}
```

## Parallel Execution

```bash
{
    instana_api GET "/application-monitoring/applications" &
    instana_api GET "/events?windowSize=3600000" &
    instana_api GET "/infrastructure-monitoring/snapshots?size=20" &
}
wait
```

## Anti-Hallucination Rules

**NEVER assume application IDs, service names, or entity types. ALWAYS discover first.**

### Phase 1: Discovery

```bash
#!/bin/bash
echo "=== Applications ==="
instana_api GET "/application-monitoring/applications" \
    | jq -r '.items[] | "\(.id)\t\(.label)"' | head -20

echo ""
echo "=== Services ==="
instana_api GET "/application-monitoring/services" \
    | jq -r '.items[] | "\(.id)\t\(.label)\t\(.technologies | join(","))"' | head -20

echo ""
echo "=== Infrastructure Snapshot Types ==="
instana_api GET "/infrastructure-monitoring/snapshots?size=50" \
    | jq -r '[.items[].plugin] | group_by(.) | map("\(.[0]): \(length)") | .[]' | head -15

echo ""
echo "=== Recent Events ==="
instana_api GET "/events?windowSize=3600000" \
    | jq -r '.[] | "\(.type)\t\(.text[0:60])"' | head -10
```

## Common Operations

### Infrastructure Discovery & Health

```bash
#!/bin/bash
echo "=== Infrastructure Overview ==="
{
    echo "--- Host Snapshots ---"
    instana_api GET "/infrastructure-monitoring/snapshots?plugin=host&size=20" \
        | jq -r '.items[] | "\(.snapshotId)\t\(.label)\tcpu:\(.data.cpu.user // "N/A")%"' | head -15 &

    echo "--- Container Snapshots ---"
    instana_api GET "/infrastructure-monitoring/snapshots?plugin=dockerContainer&size=20" \
        | jq -r '.items[] | "\(.label)\t\(.data.state // "unknown")"' | head -10 &

    echo "--- Process Snapshots ---"
    instana_api GET "/infrastructure-monitoring/snapshots?plugin=process&size=10" \
        | jq -r '.items[] | "\(.label)"' | head -10 &
}
wait
```

### Service Endpoint Analysis

```bash
#!/bin/bash
APP_ID="${1:?Application ID required}"

echo "=== Service Endpoints ==="
instana_api GET "/application-monitoring/applications/${APP_ID}/services" \
    | jq -r '.items[] | "\(.id)\t\(.label)\t\(.technologies | join(","))"' | head -15

echo ""
echo "=== Endpoint Performance ==="
TO=$(( $(date +%s) * 1000 ))
FROM=$(( TO - 3600000 ))

instana_api POST "/application-monitoring/analyze/call-groups" \
    "{\"timeFrame\":{\"to\":${TO},\"windowSize\":3600000},\"tagFilterExpression\":{\"type\":\"TAG_FILTER\",\"name\":\"application.id\",\"operator\":\"EQUALS\",\"value\":\"${APP_ID}\"},\"groupBy\":[\"endpoint.name\"],\"metrics\":[{\"metric\":\"latency\",\"aggregation\":\"MEAN\"},{\"metric\":\"calls\",\"aggregation\":\"SUM\"},{\"metric\":\"errors\",\"aggregation\":\"SUM\"}]}" \
    | jq -r '.items[:15][] | "\(.name)\tlatency:\(.metrics.latency.MEAN // 0)ms\tcalls:\(.metrics.calls.SUM // 0)\terrors:\(.metrics.errors.SUM // 0)"'
```

### Incident Management

```bash
#!/bin/bash
echo "=== Open Incidents ==="
instana_api GET "/events?windowSize=86400000" \
    | jq -r '.[] | select(.state == "OPEN") | "\(.id)\t\(.type)\t\(.severity)\t\(.text[0:60])"' | head -15

echo ""
echo "=== Incident Types ==="
instana_api GET "/events?windowSize=86400000" \
    | jq -r '[.[] | .type] | group_by(.) | map("\(.[0]): \(length)") | .[]'

echo ""
echo "=== Critical Events ==="
instana_api GET "/events?windowSize=86400000" \
    | jq -r '.[] | select(.severity >= 10) | "\(.start / 1000 | strftime("%Y-%m-%d %H:%M"))\t\(.text[0:80])"' | head -10
```

### Smart Alert Configuration

```bash
#!/bin/bash
echo "=== Alert Configurations ==="
instana_api GET "/events/settings/alerts" \
    | jq -r '.[] | "\(.id)\t\(.name)\t\(.enabled)\t\(.severity)"' | head -20

echo ""
echo "=== Alert Channels ==="
instana_api GET "/events/settings/alertingChannels" \
    | jq -r '.[] | "\(.id)\t\(.name)\t\(.kind)"' | head -15

echo ""
echo "=== Website Alert Rules ==="
instana_api GET "/events/settings/website-alert-configs" \
    | jq -r '.[] | "\(.id)\t\(.name)\t\(.enabled)"' | head -10
```

### Trace Analysis

```bash
#!/bin/bash
echo "=== Recent Slow Traces ==="
TO=$(( $(date +%s) * 1000 ))

instana_api POST "/application-monitoring/analyze/traces" \
    "{\"timeFrame\":{\"to\":${TO},\"windowSize\":3600000},\"order\":{\"by\":\"duration\",\"direction\":\"DESC\"},\"pagination\":{\"page\":1,\"pageSize\":15}}" \
    | jq -r '.items[] | "\(.traceId)\t\(.duration)ms\t\(.rootSpan.name[0:40])\terrors:\(.errorCount)"' | head -15

echo ""
echo "=== Error Traces ==="
instana_api POST "/application-monitoring/analyze/traces" \
    "{\"timeFrame\":{\"to\":${TO},\"windowSize\":3600000},\"tagFilterExpression\":{\"type\":\"TAG_FILTER\",\"name\":\"call.erroneous\",\"operator\":\"EQUALS\",\"value\":\"true\"},\"pagination\":{\"page\":1,\"pageSize\":10}}" \
    | jq -r '.items[] | "\(.traceId)\t\(.duration)ms\t\(.rootSpan.name[0:40])"'
```

## Output Format

Present results as a structured report:
```
Monitoring Instana Report
═════════════════════════
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

- **Time format**: Instana uses milliseconds since epoch — multiply Unix seconds by 1000
- **Window size**: `windowSize` is in milliseconds — `3600000`=1h, `86400000`=24h
- **Tag filter expressions**: Complex nested JSON structure — use `TAG_FILTER` type with `EQUALS`/`CONTAINS`
- **Auto-discovery**: Instana auto-discovers infrastructure — entity snapshots change dynamically
- **Plugin types**: `host`, `dockerContainer`, `process`, `jvmRuntimePlatform`, `kubernetes` etc.
- **Pagination**: Use `page` and `pageSize` in request body — not query parameters
- **Severity levels**: Numeric 1-10 — higher is more critical, 10=critical
- **API token scope**: Tokens have scoped permissions — some endpoints may return 403
