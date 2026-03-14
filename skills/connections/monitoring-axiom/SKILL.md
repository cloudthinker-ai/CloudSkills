---
name: monitoring-axiom
description: |
  Axiom observability platform with dataset management, APL (Axiom Processing Language) queries, monitors, dashboards, and virtual fields. Covers log and event ingestion analysis, dataset statistics, alerting rules, annotation management, and data retention. Use when querying datasets with APL, managing monitors, analyzing ingestion volume, or reviewing dashboards via Axiom API.
connection_type: axiom
preload: false
---

# Axiom Monitoring Skill

Query and manage Axiom datasets, monitors, and dashboards using the Axiom API.

## API Conventions

### Authentication
Axiom API uses Bearer token or API token — injected by connection. Never hardcode tokens.

### Base URL
- API: `https://api.axiom.co/v2/`
- Cloud US: `https://cloud.axiom.co/api/v1/`
- Use connection-injected `AXIOM_BASE_URL`.

### Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- Use `jq` to extract query results and dataset metadata
- NEVER dump full query results — summarize and limit output

### Core Helper Function

```bash
#!/bin/bash

axiom_api() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"

    if [ -n "$data" ]; then
        curl -s -X "$method" \
            -H "Authorization: Bearer ${AXIOM_API_TOKEN}" \
            -H "Content-Type: application/json" \
            "${AXIOM_BASE_URL}/v2${endpoint}" \
            -d "$data"
    else
        curl -s -X "$method" \
            -H "Authorization: Bearer ${AXIOM_API_TOKEN}" \
            "${AXIOM_BASE_URL}/v2${endpoint}"
    fi
}

axiom_query() {
    local apl="$1"
    local start="${2:-1h}"
    local end="${3:-}"

    axiom_api POST "/datasets/_apl" \
        "{\"apl\":\"${apl}\",\"startTime\":\"$(date -u -d "-${start}" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -v-${start} +%Y-%m-%dT%H:%M:%SZ)\"${end:+,\"endTime\":\"${end}\"}}"
}
```

## Parallel Execution

```bash
{
    axiom_api GET "/datasets" &
    axiom_api GET "/monitors" &
    axiom_api GET "/dashboards" &
}
wait
```

## Anti-Hallucination Rules

**NEVER assume dataset names, field names, or monitor IDs. ALWAYS discover first.**

### Phase 1: Discovery

```bash
#!/bin/bash
echo "=== Datasets ==="
axiom_api GET "/datasets" \
    | jq -r '.[] | "\(.name)\t\(.description // "no description")"' | head -20

echo ""
echo "=== Dataset Fields ==="
DATASET="${1:-}"
if [ -n "$DATASET" ]; then
    axiom_api GET "/datasets/${DATASET}/info" \
        | jq -r '.fields[] | "\(.name)\t\(.type)"' | head -20
fi

echo ""
echo "=== Monitors ==="
axiom_api GET "/monitors" \
    | jq -r '.[] | "\(.id)\t\(.name)\t\(.disabled)"' | head -15

echo ""
echo "=== Dashboards ==="
axiom_api GET "/dashboards" \
    | jq -r '.[] | "\(.id)\t\(.name)"' | head -15
```

## Common Operations

### APL Queries

```bash
#!/bin/bash
DATASET="${1:?Dataset name required}"

echo "=== Recent Events ==="
axiom_query "['${DATASET}'] | take 10" "1h" \
    | jq -r '.matches[:10][] | "\(._time)\t\(.data | to_entries[:3] | map("\(.key)=\(.value)") | join(", "))"'

echo ""
echo "=== Event Count by Field ==="
axiom_query "['${DATASET}'] | summarize count() by bin(_time, 5m)" "1h" \
    | jq -r '.buckets.totals[]? // .matches[]? | "\(._time // "")\t\(.["count_"]  // "")"' | head -15

echo ""
echo "=== Error Events ==="
axiom_query "['${DATASET}'] | where level == 'error' or severity == 'error' | take 20" "1h" \
    | jq -r '.matches[:20][] | "\(._time)\t\(.data | to_entries[:3] | map("\(.key)=\(.value)") | join(", "))"'
```

### Dataset Management

```bash
#!/bin/bash
echo "=== Dataset Statistics ==="
for ds in $(axiom_api GET "/datasets" | jq -r '.[].name' | head -10); do
    {
        info=$(axiom_api GET "/datasets/${ds}/info")
        events=$(echo "$info" | jq '.numEvents // 0')
        size=$(echo "$info" | jq '.compressedBytes // 0 | . / 1048576 | . * 100 | round / 100')
        fields=$(echo "$info" | jq '.fields | length')
        echo "$ds\tevents:${events}\tsize:${size}MB\tfields:${fields}"
    } &
done
wait

echo ""
echo "=== Dataset Field Analysis ==="
DATASET="${1:-}"
if [ -n "$DATASET" ]; then
    axiom_api GET "/datasets/${DATASET}/info" \
        | jq -r '.fields | sort_by(.name)[] | "\(.name)\t\(.type)\t\(.description // "")"' | head -20
fi
```

### Monitor Management

```bash
#!/bin/bash
echo "=== All Monitors ==="
axiom_api GET "/monitors" \
    | jq -r '.[] | "\(.id)\t\(.name)\t\(.disabled)\t\(.dataset)"' | head -20

echo ""
echo "=== Active Monitors ==="
axiom_api GET "/monitors" \
    | jq -r '.[] | select(.disabled == false) | "\(.name)\t\(.dataset)\t\(.comparison)\t\(.threshold)"' | head -15

echo ""
echo "=== Monitor Alert History ==="
MONITOR_ID="${1:-}"
if [ -n "$MONITOR_ID" ]; then
    axiom_api GET "/monitors/${MONITOR_ID}" \
        | jq '{name, dataset, query: .aplQuery, threshold, comparison, frequency: .intervalMinutes}'
fi
```

### Dashboard Analysis

```bash
#!/bin/bash
echo "=== Dashboards ==="
axiom_api GET "/dashboards" \
    | jq -r '.[] | "\(.id)\t\(.name)\t\(.charts | length) charts"' | head -15

echo ""
echo "=== Dashboard Details ==="
DASHBOARD_ID="${1:-}"
if [ -n "$DASHBOARD_ID" ]; then
    axiom_api GET "/dashboards/${DASHBOARD_ID}" \
        | jq -r '{name, description, charts: [.charts[] | {name, dataset, query: (.aplQuery // .query)[0:60]}]}'
fi
```

### Virtual Fields

```bash
#!/bin/bash
DATASET="${1:?Dataset name required}"

echo "=== Virtual Fields ==="
axiom_api GET "/datasets/${DATASET}/virtualfields" \
    | jq -r '.[] | "\(.name)\t\(.type)\t\(.expression[0:60])"' | head -15

echo ""
echo "=== Dataset Schema with Virtual Fields ==="
axiom_api GET "/datasets/${DATASET}/info" \
    | jq -r '.fields[] | "\(.name)\t\(.type)\t\(if .virtual then "virtual" else "physical" end)"' | head -20
```

## Common Pitfalls

- **APL syntax**: Dataset names in square brackets — `['my-dataset'] | where status == 500`
- **Dataset names**: Case-sensitive and may contain hyphens — always discover first
- **Time field**: `_time` is the default timestamp field — always present in events
- **Query response format**: Results in `.matches[]` for raw events, `.buckets` for aggregations
- **Virtual fields**: Computed at query time — do not appear in raw ingestion data
- **Rate limits**: Depends on plan tier — check `X-RateLimit-Remaining` response header
- **APL vs SQL**: APL uses pipe syntax like KQL — `| where`, `| summarize`, `| project`, not SQL
- **Ingestion format**: JSON array or NDJSON — timestamps should be ISO 8601 in `_time` field
