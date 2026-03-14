---
name: managing-hypertrace
description: |
  Hypertrace distributed tracing and observability platform for service dependency mapping, trace analysis, API monitoring, and performance analysis. Covers service discovery, endpoint performance, trace querying, span analysis, and API-level observability. Use when investigating distributed traces, analyzing API performance, mapping service dependencies, or reviewing span-level details.
connection_type: hypertrace
preload: false
---

# Hypertrace Monitoring Skill

Query, analyze, and manage Hypertrace observability data using the Hypertrace GraphQL API.

## API Overview

Hypertrace uses a GraphQL API at `https://<HYPERTRACE_HOST>/graphql`.

### Core Helper Function

```bash
#!/bin/bash

ht_gql() {
    local query="$1"
    curl -s -X POST "${HYPERTRACE_URL}/graphql" \
        -H "Content-Type: application/json" \
        ${HYPERTRACE_AUTH:+-H "Authorization: Bearer $HYPERTRACE_AUTH"} \
        -d "{\"query\": $(echo "$query" | jq -Rs .)}"
}

ht_time_range() {
    local hours="${1:-1}"
    local end=$(($(date +%s) * 1000))
    local start=$(( ($(date +%s) - ${hours} * 3600) * 1000 ))
    echo "startTime: \"${start}\", endTime: \"${end}\""
}
```

## MANDATORY: Discovery-First Pattern

**Always discover services, APIs, and backends before querying.**

### Phase 1: Discovery

```bash
#!/bin/bash
TIME_RANGE=$(ht_time_range 1)

echo "=== Services ==="
ht_gql "{
    explore(scope: API_TRACE, limit: 100, groupBy: [{key: \"serviceName\"}],
        selections: [{key: \"serviceName\"}, {key: \"numCalls\", aggregation: SUM}],
        timeRange: {${TIME_RANGE}}) {
        results { serviceName numCalls }
    }
}" | jq -r '.data.explore.results[] | "\(.serviceName)\tcalls:\(.numCalls)"' | sort -t$'\t' -k2 -rn | head -20

echo ""
echo "=== APIs / Endpoints ==="
ht_gql "{
    explore(scope: API, limit: 30, groupBy: [{key: \"apiName\"}],
        selections: [{key: \"apiName\"}, {key: \"serviceName\"}, {key: \"numCalls\", aggregation: SUM}],
        timeRange: {${TIME_RANGE}}) {
        results { apiName serviceName numCalls }
    }
}" | jq -r '.data.explore.results[] | "\(.serviceName)\t\(.apiName)\tcalls:\(.numCalls)"' | head -20

echo ""
echo "=== Backends ==="
ht_gql "{
    explore(scope: BACKEND, limit: 20, groupBy: [{key: \"backendName\"}],
        selections: [{key: \"backendName\"}, {key: \"backendType\"}, {key: \"numCalls\", aggregation: SUM}],
        timeRange: {${TIME_RANGE}}) {
        results { backendName backendType numCalls }
    }
}" | jq -r '.data.explore.results[] | "\(.backendName)\t\(.backendType)\tcalls:\(.numCalls)"' | head -15
```

### Phase 2: Analysis

```bash
#!/bin/bash
TIME_RANGE=$(ht_time_range 1)

echo "=== Service Performance (P99 Latency) ==="
ht_gql "{
    explore(scope: API_TRACE, limit: 15, groupBy: [{key: \"serviceName\"}],
        selections: [{key: \"serviceName\"}, {key: \"duration\", aggregation: P99}, {key: \"numCalls\", aggregation: SUM}, {key: \"errorCount\", aggregation: SUM}],
        timeRange: {${TIME_RANGE}}, orderBy: [{key: \"duration\", aggregation: P99, order: DESC}]) {
        results { serviceName duration numCalls errorCount }
    }
}" | jq -r '.data.explore.results[] | "\(.serviceName)\tp99:\(.duration / 1000 | . * 10 | round / 10)ms\tcalls:\(.numCalls)\terrors:\(.errorCount)"' | head -15

echo ""
echo "=== Slowest Endpoints ==="
ht_gql "{
    explore(scope: API, limit: 15, groupBy: [{key: \"apiName\"}, {key: \"serviceName\"}],
        selections: [{key: \"apiName\"}, {key: \"serviceName\"}, {key: \"duration\", aggregation: AVG}, {key: \"numCalls\", aggregation: SUM}],
        timeRange: {${TIME_RANGE}}, orderBy: [{key: \"duration\", aggregation: AVG, order: DESC}]) {
        results { apiName serviceName duration numCalls }
    }
}" | jq -r '.data.explore.results[] | "\(.serviceName)\t\(.apiName[0:40])\tavg:\(.duration / 1000 | . * 10 | round / 10)ms\tcalls:\(.numCalls)"' | head -15

echo ""
echo "=== Error Endpoints ==="
ht_gql "{
    explore(scope: API, limit: 15, groupBy: [{key: \"apiName\"}, {key: \"serviceName\"}],
        selections: [{key: \"apiName\"}, {key: \"serviceName\"}, {key: \"errorCount\", aggregation: SUM}, {key: \"numCalls\", aggregation: SUM}],
        timeRange: {${TIME_RANGE}}, filterBy: [{key: \"errorCount\", operator: GT, value: \"0\"}],
        orderBy: [{key: \"errorCount\", aggregation: SUM, order: DESC}]) {
        results { apiName serviceName errorCount numCalls }
    }
}" | jq -r '.data.explore.results[] | "\(.serviceName)\t\(.apiName[0:40])\terrors:\(.errorCount)\tcalls:\(.numCalls)"' | head -15
```

## Output Rules
- **TOKEN EFFICIENCY**: Target ≤50 lines — use `limit` and `orderBy` for top-N results
- Duration values are in microseconds — divide by 1000 for ms
- Scopes: API_TRACE (service-level), API (endpoint-level), BACKEND (dependency-level)
- Use `filterBy` for server-side filtering and `groupBy` for aggregation
