---
name: managing-lightstep
description: |
  Lightstep (now ServiceNow Cloud Observability) platform for distributed tracing, service health monitoring, change intelligence, and SLOs. Covers querying traces, analyzing service performance, reviewing deployments, managing alert conditions, and SLO tracking. Use when investigating latency regressions, analyzing service dependencies, or managing observability configurations.
connection_type: lightstep
preload: false
---

# Lightstep Monitoring Skill

Query, analyze, and manage Lightstep observability data using the Lightstep API.

## API Overview

Lightstep uses a REST API at `https://api.lightstep.com`.

### Core Helper Function

```bash
#!/bin/bash

ls_api() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"
    local org="$LIGHTSTEP_ORG"
    local project="$LIGHTSTEP_PROJECT"
    local url="https://api.lightstep.com/public/v0.2/${org}/projects/${project}/${endpoint}"
    if [ -n "$data" ]; then
        curl -s -X "$method" "$url" \
            -H "Authorization: Bearer $LIGHTSTEP_API_KEY" \
            -H "Content-Type: application/json" \
            -d "$data"
    else
        curl -s -X "$method" "$url" \
            -H "Authorization: Bearer $LIGHTSTEP_API_KEY"
    fi
}
```

## MANDATORY: Discovery-First Pattern

**Always discover services, streams, and conditions before querying.**

### Phase 1: Discovery

```bash
#!/bin/bash

echo "=== Services ==="
ls_api GET "services" | jq -r '.data[] | "\(.id)\t\(.attributes.name)"' | head -20

echo ""
echo "=== Streams (Saved Queries) ==="
ls_api GET "streams" | jq -r '.data[] | "\(.id)\t\(.attributes.name)\t\(.attributes.query)"' | head -20

echo ""
echo "=== Alert Conditions ==="
ls_api GET "conditions" | jq -r '.data[] | "\(.id)\t\(.attributes.name)\t\(.attributes.expression)"' | head -15

echo ""
echo "=== SLOs ==="
ls_api GET "slos" | jq -r '.data[] | "\(.id)\t\(.attributes.name)\t\(.attributes.objective_percentage)%"' | head -15
```

### Phase 2: Analysis

```bash
#!/bin/bash
SERVICE="${1:?Service name required}"

echo "=== Service Health ==="
ls_api GET "services/${SERVICE}" | jq -r '.data.attributes | "Latency P50: \(.latency_p50 // "N/A")ms\nLatency P99: \(.latency_p99 // "N/A")ms\nError Rate: \(.error_rate // "N/A")%\nOps/sec: \(.ops_per_sec // "N/A")"'

echo ""
echo "=== Recent Exemplar Traces ==="
ls_api GET "stored-traces?filter=service%3D${SERVICE}&limit=10" \
    | jq -r '.data[] | "\(.attributes.start_time[0:19])\t\(.attributes.duration_micros/1000)ms\t\(.attributes.root_span_name)"' | head -10

echo ""
echo "=== Service Dependencies ==="
ls_api GET "services/${SERVICE}/dependencies" \
    | jq -r '.data[] | "\(.attributes.direction)\t\(.attributes.name)\t\(.attributes.ops_per_sec) ops/s"' | head -15

echo ""
echo "=== Firing Conditions ==="
ls_api GET "conditions" | jq -r '.data[] | select(.attributes.state == "firing") | "\(.id)\t\(.attributes.name)\t\(.attributes.expression)"' | head -10
```

## Output Rules
- **TOKEN EFFICIENCY**: Target ≤50 lines — use `limit` query params and `head` in output
- Use service-level aggregations before drilling into traces
- Check service health before querying individual spans
