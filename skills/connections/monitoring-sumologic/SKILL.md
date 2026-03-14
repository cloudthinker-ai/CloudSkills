---
name: monitoring-sumologic
description: |
  Sumo Logic cloud-native log analytics, metrics queries, monitors, dashboards, and content management. Covers log search, metrics exploration, alerting rules, folder/content management, and data ingestion health. Use when searching logs, querying metrics, managing monitors, or analyzing Sumo Logic resources via API.
connection_type: sumologic
preload: false
---

# Sumo Logic Monitoring Skill

Search, analyze, and manage Sumo Logic resources using the Sumo Logic API.

## API Conventions

### Authentication
Uses HTTP Basic auth with `accessId:accessKey` — injected automatically. Never hardcode credentials.

### Base URL
Region-specific deployment URLs:
- US1: `https://api.sumologic.com/api/v1/`
- US2: `https://api.us2.sumologic.com/api/v1/`
- EU: `https://api.eu.sumologic.com/api/v1/`
- Always use connection-injected `SUMOLOGIC_BASE_URL`.

### Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- Use `jq` to extract only needed fields
- NEVER dump full API responses

### Core Helper Function

```bash
#!/bin/bash

sumo_api() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"

    if [ -n "$data" ]; then
        curl -s -X "$method" \
            -u "${SUMOLOGIC_ACCESS_ID}:${SUMOLOGIC_ACCESS_KEY}" \
            -H "Content-Type: application/json" \
            "${SUMOLOGIC_BASE_URL}${endpoint}" \
            -d "$data"
    else
        curl -s -X "$method" \
            -u "${SUMOLOGIC_ACCESS_ID}:${SUMOLOGIC_ACCESS_KEY}" \
            -H "Content-Type: application/json" \
            "${SUMOLOGIC_BASE_URL}${endpoint}"
    fi
}

sumo_search() {
    local query="$1"
    local from="${2:--1h}"
    local to="${3:-now}"

    local job_id=$(sumo_api POST "/search/jobs" \
        "{\"query\":\"${query}\",\"from\":\"${from}\",\"to\":\"${to}\",\"timeZone\":\"UTC\"}" \
        | jq -r '.id')

    while true; do
        local state=$(sumo_api GET "/search/jobs/${job_id}" | jq -r '.state')
        [ "$state" = "DONE GATHERING RESULTS" ] && break
        sleep 2
    done

    sumo_api GET "/search/jobs/${job_id}/messages?offset=0&limit=100"
}
```

## Parallel Execution

```bash
{
    sumo_api GET "/monitors?limit=50" &
    sumo_api GET "/collectors?limit=50" &
    sumo_api GET "/content/folders/personal" &
}
wait
```

## Anti-Hallucination Rules

**NEVER assume source categories, collector names, or field names exist. ALWAYS discover first.**

### Phase 1: Discovery

```bash
#!/bin/bash
echo "=== Installed Collectors ==="
sumo_api GET "/collectors?limit=50" \
    | jq -r '.collectors[] | "\(.name)\t\(.collectorType)\t\(.alive)"' | head -20

echo "=== Source Categories ==="
sumo_search "_sourceCategory=* | count by _sourceCategory | sort by _count desc | limit 20" "-1h" \
    | jq -r '.messages[].map | "\(._sourcecategory)\t\(._count)"'

echo "=== Active Monitors ==="
sumo_api GET "/monitors?limit=50" \
    | jq -r '.[] | "\(.name)\t\(.monitorType)\t\(.status)"' | head -20
```

## Common Operations

### Log Search & Analysis

```bash
#!/bin/bash
echo "=== Error Logs (last 1h) ==="
sumo_search "_sourceCategory=* error | count by _sourceCategory, _sourceHost | sort by _count desc | limit 20" "-1h" \
    | jq -r '.messages[].map | "\(._sourcecategory)\t\(._sourcehost)\t\(._count)"'

echo ""
echo "=== Top Error Patterns ==="
sumo_search "error OR exception | parse \"*Error: *\" as errorType, errorMsg | count by errorType | sort by _count desc | limit 10" "-1h" \
    | jq -r '.messages[].map | "\(.errortype)\t\(._count)"'
```

### Metrics Queries

```bash
#!/bin/bash
echo "=== Available Metric Dimensions ==="
sumo_api POST "/metrics/results" \
    '{"query":[{"query":"metric=CPU_*","rowId":"A"}],"startTime":"'-1h'","endTime":"now"}' \
    | jq -r '.response[] | .results[].metric.dimensions | to_entries[] | "\(.key)=\(.value)"' \
    | sort -u | head -20

echo ""
echo "=== CPU Metrics by Host ==="
sumo_api POST "/metrics/results" \
    '{"query":[{"query":"metric=CPU_Total | avg by host","rowId":"A"}],"startTime":"-1h","endTime":"now"}' \
    | jq -r '.response[].results[] | "\(.metric.dimensions.host)\t\(.datapoints.value[-1])"' | head -15
```

### Monitor & Alert Management

```bash
#!/bin/bash
echo "=== Monitor Status Summary ==="
sumo_api GET "/monitors?limit=100" \
    | jq -r 'group_by(.status) | .[] | "\(.[0].status): \(length)"'

echo ""
echo "=== Triggered Monitors ==="
sumo_api GET "/monitors?limit=100" \
    | jq -r '.[] | select(.status == "Critical" or .status == "Warning") | "\(.status)\t\(.name)\t\(.monitorType)"' | head -15

echo ""
echo "=== Monitor Notification Channels ==="
sumo_api GET "/monitors?limit=50" \
    | jq -r '.[] | "\(.name)\t\(.notifications | length) notifications"' | head -15
```

### Content & Dashboard Management

```bash
#!/bin/bash
echo "=== Personal Folder Content ==="
FOLDER_ID=$(sumo_api GET "/content/folders/personal" | jq -r '.id')
sumo_api GET "/content/folders/${FOLDER_ID}" \
    | jq -r '.children[] | "\(.itemType)\t\(.name)\t\(.createdAt[0:10])"' | head -20

echo ""
echo "=== Recent Dashboards ==="
sumo_api GET "/dashboards?limit=20" \
    | jq -r '.dashboards[] | "\(.id)\t\(.title)\t\(.folderId)"' | head -15
```

### Collector & Source Health

```bash
#!/bin/bash
echo "=== Collector Health ==="
{
    sumo_api GET "/collectors?limit=50" \
        | jq -r '.collectors[] | "\(.name)\t\(.collectorType)\talive:\(.alive)\t\(.lastSeenAlive[0:16] // "never")"' | head -15 &

    echo "=== Dead Collectors ==="
    sumo_api GET "/collectors?limit=100" \
        | jq -r '.collectors[] | select(.alive == false) | "\(.name)\t\(.collectorType)\tlast_seen:\(.lastSeenAlive[0:16] // "never")"' | head -10 &
}
wait

echo ""
echo "=== Ingestion Volume ==="
sumo_search "_index=sumologic_volume | sum(_size) by _sourceCategory | sort by _sum desc | limit 15" "-24h" \
    | jq -r '.messages[].map | "\(._sourcecategory)\t\(._sum)"'
```

## Common Pitfalls

- **Async search jobs**: Log searches are async — poll `state` until `DONE GATHERING RESULTS`
- **Rate limits**: 4 concurrent search jobs max, 240 API calls/min — stagger parallel calls
- **Time format**: Use ISO 8601 (`2024-01-01T00:00:00Z`) or relative (`-1h`, `-24h`)
- **Source categories**: Case-sensitive — always discover first via search
- **Metrics vs Logs**: Different API endpoints — `/metrics/results` vs `/search/jobs`
- **Content permissions**: Folder-based access control — personal vs shared folders
- **Pagination**: Use `offset` and `limit` — check `total` field for remaining items
- **Query syntax**: Uses pipe-based query language — `| count by field | sort by _count`
