---
name: managing-graylog
description: |
  Graylog centralized log management platform for log collection, search, dashboards, alerting, and pipeline processing. Covers log querying with Lucene syntax, stream management, alert condition configuration, dashboard review, and input/output management. Use when searching Graylog logs, managing streams and pipelines, investigating incidents, or configuring alert rules.
connection_type: graylog
preload: false
---

# Graylog Monitoring Skill

Query, analyze, and manage Graylog log data using the Graylog REST API.

## API Overview

Graylog uses a REST API at `https://<GRAYLOG_HOST>/api`.

### Core Helper Function

```bash
#!/bin/bash

gl_api() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"
    if [ -n "$data" ]; then
        curl -s -X "$method" "${GRAYLOG_URL}/api/${endpoint}" \
            -H "Authorization: Bearer $GRAYLOG_API_TOKEN" \
            -H "Content-Type: application/json" \
            -H "Accept: application/json" \
            -d "$data"
    else
        curl -s -X "$method" "${GRAYLOG_URL}/api/${endpoint}" \
            -H "Authorization: Bearer $GRAYLOG_API_TOKEN" \
            -H "Accept: application/json"
    fi
}

gl_search() {
    local query="$1"
    local range="${2:-3600}"
    local limit="${3:-50}"
    gl_api GET "search/universal/relative?query=$(python3 -c "import urllib.parse; print(urllib.parse.quote('${query}'))")&range=${range}&limit=${limit}&sort=timestamp:desc"
}
```

## MANDATORY: Discovery-First Pattern

**Always discover streams, inputs, and indices before querying.**

### Phase 1: Discovery

```bash
#!/bin/bash

echo "=== System Overview ==="
gl_api GET "system" | jq -r '"Cluster ID: \(.cluster_id)\nNode ID: \(.node_id)\nVersion: \(.version)\nStatus: \(.lifecycle)"'

echo ""
echo "=== Streams ==="
gl_api GET "streams" | jq -r '.streams[] | "\(.id)\t\(.title)\t\(.disabled)"' | head -20

echo ""
echo "=== Inputs ==="
gl_api GET "system/inputs" | jq -r '.inputs[] | "\(.id)\t\(.title)\t\(.type)\t\(.global)"' | head -15

echo ""
echo "=== Index Sets ==="
gl_api GET "system/indices/index_sets" | jq -r '.index_sets[] | "\(.id)\t\(.title)\t\(.total_number_of_indices) indices"' | head -10

echo ""
echo "=== Alert Conditions ==="
gl_api GET "alerts/conditions" | jq -r '.conditions[] | "\(.id)\t\(.title)\t\(.type)"' | head -15
```

### Phase 2: Analysis

```bash
#!/bin/bash
QUERY="${1:-level:3 OR level:4}"

echo "=== Log Search: ${QUERY} ==="
gl_search "$QUERY" 3600 30 | jq -r '.messages[] | "\(.message.timestamp[0:19])\t\(.message.source)\t\(.message.message[0:80])"' | head -20

echo ""
echo "=== Message Count by Source (last 1h) ==="
gl_api GET "search/universal/relative/terms?field=source&query=*&range=3600&size=15" \
    | jq -r '.terms | to_entries[] | "\(.key)\t\(.value)"' | sort -t$'\t' -k2 -rn | head -15

echo ""
echo "=== Recent Alerts ==="
gl_api GET "streams/alerts?since=$(date -d '24 hours ago' +%s)&limit=15" \
    | jq -r '.[] | "\(.triggered_at[0:19])\t\(.condition_id)\t\(.description[0:60])"' | head -15

echo ""
echo "=== Node Health ==="
gl_api GET "system/cluster" | jq -r '.[] | "\(.node_id[0:8])\t\(.hostname)\t\(.lifecycle)\t\(.is_leader)"' | head -10
```

## Output Rules
- **TOKEN EFFICIENCY**: Target ≤50 lines — use `limit` parameter and `terms` aggregation endpoint
- Use Lucene query syntax for log search (e.g., `source:nginx AND level:3`)
- Prefer terms aggregation for volume breakdowns over counting raw messages
