---
name: managing-superset
description: |
  Use when working with Superset — apache Superset BI platform management.
  Covers chart and dashboard management, dataset analysis, query history review,
  database connections, saved query management, and alert/report scheduling. Use
  when analyzing dashboards, investigating query performance, managing datasets,
  or auditing Superset usage.
connection_type: superset
preload: false
---

# Apache Superset Management Skill

Manage and analyze Apache Superset charts, dashboards, datasets, and queries via the Superset REST API.

## MANDATORY: Discovery-First Pattern

**Always discover databases and datasets before querying specific charts or dashboards.**

### Phase 1: Discovery

```bash
#!/bin/bash

superset_api() {
    local method="${1:-GET}"
    local endpoint="$2"
    local data="${3:-}"

    if [ -n "$data" ]; then
        curl -s -X "$method" \
            -H "Authorization: Bearer ${SUPERSET_ACCESS_TOKEN}" \
            -H "Content-Type: application/json" \
            "${SUPERSET_URL}/api/v1/${endpoint}" \
            -d "$data"
    else
        curl -s -X "$method" \
            -H "Authorization: Bearer ${SUPERSET_ACCESS_TOKEN}" \
            "${SUPERSET_URL}/api/v1/${endpoint}"
    fi
}

echo "=== Databases ==="
superset_api GET "database/?q=(page_size:50)" | jq -r '
    .result[] | "\(.id)\t\(.database_name)\t\(.backend)\t\(if .allow_dml then "DML" else "RO" end)"
' | column -t

echo ""
echo "=== Datasets ==="
superset_api GET "dataset/?q=(page_size:30,order_column:changed_on_delta_humanized,order_direction:desc)" | jq -r '
    .result[] | "\(.id)\t\(.table_name)\t\(.schema // "default")\t\(.database.database_name)\t\(.kind)"
' | column -t | head -20

echo ""
echo "=== Dashboards ==="
superset_api GET "dashboard/?q=(page_size:20,order_column:changed_on_delta_humanized,order_direction:desc)" | jq -r '
    .result[] | "\(.id)\t\(.dashboard_title[0:40])\t\(.status)\t\(.changed_on_delta_humanized)"
' | column -t
```

## Core Helper Functions

```bash
#!/bin/bash

superset_api() {
    local method="${1:-GET}"
    local endpoint="$2"
    local data="${3:-}"

    if [ -n "$data" ]; then
        curl -s -X "$method" \
            -H "Authorization: Bearer ${SUPERSET_ACCESS_TOKEN}" \
            -H "Content-Type: application/json" \
            "${SUPERSET_URL}/api/v1/${endpoint}" \
            -d "$data"
    else
        curl -s -X "$method" \
            -H "Authorization: Bearer ${SUPERSET_ACCESS_TOKEN}" \
            "${SUPERSET_URL}/api/v1/${endpoint}"
    fi
}

# Authenticate and get access token
superset_login() {
    curl -s -X POST \
        -H "Content-Type: application/json" \
        "${SUPERSET_URL}/api/v1/security/login" \
        -d "{\"username\": \"${SUPERSET_USER}\", \"password\": \"${SUPERSET_PASS}\", \"provider\": \"db\"}" | jq -r '.access_token'
}

# Get CSRF token for write operations
superset_csrf() {
    curl -s -H "Authorization: Bearer ${SUPERSET_ACCESS_TOKEN}" \
        "${SUPERSET_URL}/api/v1/security/csrf_token/" | jq -r '.result'
}
```

## Output Rules
- **TOKEN EFFICIENCY**: Target ≤50 lines per output
- Use Superset's RLS-style query params `q=(page_size:N)` for pagination
- Never dump full chart configs — extract visualization type and dataset reference

## Common Operations

### Chart Management

```bash
#!/bin/bash
echo "=== Charts Summary ==="
superset_api GET "chart/?q=(page_size:100)" | jq '{
    total: .count,
    by_viz_type: ([.result[].viz_type] | group_by(.) | map({type: .[0], count: length}) | sort_by(-.count) | .[:10])
}'

echo ""
echo "=== Recently Modified Charts ==="
superset_api GET "chart/?q=(page_size:15,order_column:changed_on_delta_humanized,order_direction:desc)" | jq -r '
    .result[] | "\(.id)\t\(.slice_name[0:35])\t\(.viz_type)\t\(.datasource_name_text)\t\(.changed_on_delta_humanized)"
' | column -t

echo ""
echo "=== Charts by Dataset ==="
DATASET_ID="${1:-}"
if [ -n "$DATASET_ID" ]; then
    superset_api GET "chart/?q=(filters:!((col:datasource_id,opr:eq,value:${DATASET_ID})),page_size:20)" | jq -r '
        .result[] | "\(.id)\t\(.slice_name[0:35])\t\(.viz_type)"
    ' | column -t
fi
```

### Dashboard Analysis

```bash
#!/bin/bash
DASHBOARD_ID="${1:?Dashboard ID required}"

echo "=== Dashboard Details ==="
superset_api GET "dashboard/${DASHBOARD_ID}" | jq '{
    id: .result.id,
    title: .result.dashboard_title,
    status: .result.status,
    slug: .result.slug,
    charts: (.result.charts | length),
    owners: [.result.owners[]?.username] | join(", "),
    changed_on: .result.changed_on_delta_humanized
}'

echo ""
echo "=== Dashboard Charts ==="
superset_api GET "dashboard/${DASHBOARD_ID}/charts" | jq -r '
    .result[] | "\(.id)\t\(.slice_name[0:35])\t\(.viz_type)\t\(.datasource_name_text)"
' | column -t | head -20

echo ""
echo "=== Dashboard Datasets ==="
superset_api GET "dashboard/${DASHBOARD_ID}/datasets" | jq -r '
    .result[] | "\(.id)\t\(.table_name)\t\(.schema // "default")\t\(.database.database_name)"
' | column -t
```

### Dataset Analysis

```bash
#!/bin/bash
DATASET_ID="${1:?Dataset ID required}"

echo "=== Dataset Details ==="
superset_api GET "dataset/${DATASET_ID}" | jq '{
    id: .result.id,
    table_name: .result.table_name,
    schema: .result.schema,
    database: .result.database.database_name,
    kind: .result.kind,
    columns: (.result.columns | length),
    metrics: (.result.metrics | length),
    is_managed_externally: .result.is_managed_externally
}'

echo ""
echo "=== Dataset Columns ==="
superset_api GET "dataset/${DATASET_ID}" | jq -r '
    .result.columns[] | "\(.column_name)\t\(.type // "?")\t\(if .filterable then "filterable" else "" end)\t\(if .groupby then "groupable" else "" end)"
' | column -t | head -20

echo ""
echo "=== Dataset Metrics ==="
superset_api GET "dataset/${DATASET_ID}" | jq -r '
    .result.metrics[] | "\(.metric_name)\t\(.expression[0:50])\t\(.metric_type // "?")"
' | column -t | head -10
```

### Query History

```bash
#!/bin/bash
echo "=== Recent Queries ==="
superset_api GET "query/?q=(page_size:20,order_column:start_time,order_direction:desc)" | jq -r '
    .result[] | "\(.id)\t\(.status)\t\(.database.database_name)\t\(.executed_sql[0:50] // "?")\t\(.start_time[0:16])"
' | column -t | head -15

echo ""
echo "=== Failed Queries ==="
superset_api GET "query/?q=(filters:!((col:status,opr:eq,value:failed)),page_size:10,order_column:start_time,order_direction:desc)" | jq -r '
    .result[] | "\(.id)\t\(.database.database_name)\t\(.error_message[0:60] // "?")\t\(.start_time[0:16])"
' | column -t

echo ""
echo "=== Slow Queries (>30s) ==="
superset_api GET "query/?q=(page_size:50,order_column:start_time,order_direction:desc)" | jq -r '
    .result[] | select(.end_time != null and .start_time != null) |
    "\(.id)\t\(.database.database_name)\t\(.executed_sql[0:40] // "?")"
' | head -10
```

### Alerts and Reports

```bash
#!/bin/bash
echo "=== Scheduled Reports ==="
superset_api GET "report/?q=(page_size:20)" | jq -r '
    .result[] | "\(.id)\t\(.name[0:30])\t\(.type)\t\(if .active then "ACTIVE" else "PAUSED" end)\t\(.crontab)"
' | column -t | head -15

echo ""
echo "=== Report Execution Log ==="
REPORT_ID="${1:-}"
if [ -n "$REPORT_ID" ]; then
    superset_api GET "report/${REPORT_ID}/log/?q=(page_size:10,order_column:end_dttm,order_direction:desc)" | jq -r '
        .result[] | "\(.id)\t\(.state)\t\(.end_dttm[0:16] // "?")\t\(.error_message[0:50] // "ok")"
    ' | column -t
fi
```

## Output Format

Present results as a structured report:
```
Managing Superset Report
════════════════════════
Resources discovered: [count]

Resource       Status    Key Metric    Issues
──────────────────────────────────────────────
[name]         [ok/warn] [value]       [findings]

Summary: [total] resources | [ok] healthy | [warn] warnings | [crit] critical
Action Items: [list of prioritized findings]
```

Target ≤50 lines of output. Use tables for multi-resource comparisons.

## Anti-Hallucination Rules

1. **NEVER assume resource names** — always discover via CLI/API in Phase 1 before referencing in Phase 2.
2. **NEVER fabricate metric names or dimensions** — verify against the service documentation or `--help` output.
3. **NEVER mix CLI commands between service versions** — confirm which version/API you are targeting.
4. **ALWAYS use the discovery → verify → analyze chain** — every resource referenced must have been discovered first.
5. **ALWAYS handle empty results gracefully** — an empty response is valid data, not an error to retry.

## Counter-Rationalizations

| Shortcut | Counter | Why |
|----------|---------|-----|
| "I'll skip discovery and check known resources" | Always run Phase 1 discovery first | Resource names change, new resources appear — assumed names cause errors |
| "The user only asked for a quick check" | Follow the full discovery → analysis flow | Quick checks miss critical issues; structured analysis catches silent failures |
| "Default configuration is probably fine" | Audit configuration explicitly | Defaults often leave logging, security, and optimization features disabled |
| "Metrics aren't needed for this" | Always check relevant metrics when available | API/CLI responses show current state; metrics reveal trends and intermittent issues |
| "I don't have access to that" | Try the command and report the actual error | Assumed permission failures prevent useful investigation; actual errors are informative |

## Common Pitfalls

- **Auth flow**: Superset uses JWT tokens from `/api/v1/security/login` — tokens expire (default 5 min for access, 30 days for refresh)
- **CSRF tokens**: Write operations (POST/PUT/DELETE) require CSRF token in `X-CSRFToken` header — fetch via `/api/v1/security/csrf_token/`
- **Query params format**: Superset uses Rison encoding for query params — `q=(page_size:10)` not `?page_size=10`
- **Dataset types**: `kind` can be "physical" (table/view) or "virtual" (SQL query) — virtual datasets have SQL definitions
- **Dashboard status**: `published` vs `draft` — draft dashboards are only visible to editors
- **Permissions**: Row Level Security (RLS) filters data per-role — API results may differ from UI depending on user permissions
- **Chart viz types**: Over 40 visualization types — chart configs are stored as JSON and vary by viz type
- **Database connections**: `allow_dml` controls whether data modification SQL is permitted — check before running write queries
- **Async queries**: Large queries may run asynchronously — check query status endpoint for results
