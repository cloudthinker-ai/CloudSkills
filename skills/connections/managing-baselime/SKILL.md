---
name: managing-baselime
description: |
  Baselime serverless observability platform for AWS Lambda, CloudFlare Workers, and Vercel functions. Covers log and trace querying, alert management, service discovery, and performance analysis of serverless workloads. Use when investigating serverless function performance, querying Baselime events, managing alerts, or analyzing cold start and duration metrics.
connection_type: baselime
preload: false
---

# Baselime Monitoring Skill

Query, analyze, and manage Baselime observability data using the Baselime API.

## API Overview

Baselime uses a REST API at `https://api.baselime.io/v1`.

### Core Helper Function

```bash
#!/bin/bash

bl_api() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"
    if [ -n "$data" ]; then
        curl -s -X "$method" "https://api.baselime.io/v1/${endpoint}" \
            -H "Authorization: Bearer $BASELIME_API_KEY" \
            -H "Content-Type: application/json" \
            -d "$data"
    else
        curl -s -X "$method" "https://api.baselime.io/v1/${endpoint}" \
            -H "Authorization: Bearer $BASELIME_API_KEY"
    fi
}

bl_query() {
    local query_json="$1"
    bl_api POST "query" "$query_json"
}
```

## MANDATORY: Discovery-First Pattern

**Always discover environments, services, and datasets before querying.**

### Phase 1: Discovery

```bash
#!/bin/bash

echo "=== Environments ==="
bl_api GET "environments" | jq -r '.[] | "\(.id)\t\(.name)"' | head -10

echo ""
echo "=== Services ==="
bl_api GET "services" | jq -r '.[] | "\(.name)\t\(.type // "unknown")\t\(.runtime // "N/A")"' | head -20

echo ""
echo "=== Datasets ==="
bl_api GET "datasets" | jq -r '.[] | "\(.id)\t\(.name)"' | head -15

echo ""
echo "=== Alerts ==="
bl_api GET "alerts" | jq -r '.[] | "\(.id)\t\(.name)\t\(.enabled)\t\(.threshold // "N/A")"' | head -15
```

### Phase 2: Analysis

```bash
#!/bin/bash

echo "=== Lambda Performance (last 1h) ==="
bl_query '{
    "datasets": ["lambda-logs"],
    "calculations": [
        {"operator": "COUNT"},
        {"operator": "P95", "key": "duration"},
        {"operator": "AVG", "key": "duration"}
    ],
    "groupBy": ["@service"],
    "timeframe": "1h",
    "limit": 15
}' | jq -r '.results[] | "\(.group["@service"])\tcount:\(.COUNT)\tp95:\(.P95 // "N/A")ms\tavg:\(.AVG // "N/A")ms"' | head -15

echo ""
echo "=== Error Events ==="
bl_query '{
    "datasets": ["lambda-logs"],
    "filters": [{"key": "@level", "operator": "=", "value": "error"}],
    "calculations": [{"operator": "COUNT"}],
    "groupBy": ["@service"],
    "timeframe": "1h",
    "limit": 15
}' | jq -r '.results[] | "\(.group["@service"])\t\(.COUNT) errors"' | sort -t$'\t' -k2 -rn | head -15

echo ""
echo "=== Cold Starts ==="
bl_query '{
    "datasets": ["lambda-logs"],
    "filters": [{"key": "@initDuration", "operator": "exists"}],
    "calculations": [{"operator": "COUNT"}, {"operator": "AVG", "key": "@initDuration"}],
    "groupBy": ["@service"],
    "timeframe": "1h",
    "limit": 15
}' | jq -r '.results[] | "\(.group["@service"])\tcold_starts:\(.COUNT)\tavg_init:\(.AVG // "N/A")ms"' | head -15
```

## Output Rules
- **TOKEN EFFICIENCY**: Target ≤50 lines — use `limit` and `groupBy` for aggregation
- Use calculations with groupBy for service-level summaries
- Filter at query level before post-processing
