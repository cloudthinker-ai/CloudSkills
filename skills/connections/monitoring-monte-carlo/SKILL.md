---
name: monitoring-monte-carlo
description: |
  Monte Carlo data observability platform monitoring. Covers data freshness monitors, volume anomalies, schema changes, lineage analysis, incident management, and custom monitors. Use when investigating data quality incidents, reviewing monitor alerts, analyzing table lineage, or auditing data observability coverage.
connection_type: monte_carlo
preload: false
---

# Monte Carlo Monitoring Skill

Monitor and analyze data observability using Monte Carlo's API for freshness, volume, schema, and lineage.

## MANDATORY: Discovery-First Pattern

**Always discover warehouses and tables before querying specific monitors or incidents.**

### Phase 1: Discovery

```bash
#!/bin/bash

mc_gql() {
    local query="$1"
    local variables="${2:-{}}"
    curl -s -X POST \
        -H "x-mcd-id: ${MC_API_KEY_ID}" \
        -H "x-mcd-token: ${MC_API_TOKEN}" \
        -H "Content-Type: application/json" \
        "https://api.getmontecarlo.com/graphql" \
        -d "{\"query\": \"$query\", \"variables\": $variables}"
}

echo "=== Warehouses ==="
mc_gql "{ getUser { account { warehouses { uuid name connectionType } } } }" | jq -r '
    .data.getUser.account.warehouses[] | "\(.uuid[0:8])\t\(.name)\t\(.connectionType)"
' | column -t

echo ""
echo "=== Active Incidents ==="
mc_gql "{ getIncidents(first: 15, statuses: [\"INVESTIGATING\", \"EXPECTED\", \"NO_ACTION_NEEDED\"]) { edges { node { uuid incidentType severity startTime affectedTables { fullTableId } } } } }" | jq -r '
    .data.getIncidents.edges[] | "\(.node.uuid[0:8])\t\(.node.incidentType)\t\(.node.severity)\t\(.node.startTime[0:16])\t\(.node.affectedTables[0]?.fullTableId // "?")"
' | column -t

echo ""
echo "=== Monitor Summary ==="
mc_gql "{ getMonitors(first: 50) { edges { node { uuid monitorType isActive } } } }" | jq '
    [.data.getMonitors.edges[].node] |
    group_by(.monitorType) | map({type: .[0].monitorType, total: length, active: [.[] | select(.isActive)] | length}) |
    .[] | "\(.type)\ttotal=\(.total)\tactive=\(.active)"
' -r
```

## Core Helper Functions

```bash
#!/bin/bash

mc_gql() {
    local query="$1"
    local variables="${2:-{}}"
    curl -s -X POST \
        -H "x-mcd-id: ${MC_API_KEY_ID}" \
        -H "x-mcd-token: ${MC_API_TOKEN}" \
        -H "Content-Type: application/json" \
        "https://api.getmontecarlo.com/graphql" \
        -d "{\"query\": \"$query\", \"variables\": $variables}"
}
```

## Output Rules
- **TOKEN EFFICIENCY**: Target ≤50 lines per output
- Monte Carlo uses GraphQL — request only needed fields
- Use `first` parameter to limit result sets
- Never dump full lineage graphs — summarize upstream/downstream counts

## Common Operations

### Incident Dashboard

```bash
#!/bin/bash
echo "=== Incident Summary ==="
mc_gql "{ getIncidents(first: 100) { edges { node { incidentType severity status } } } }" | jq '
    [.data.getIncidents.edges[].node] |
    group_by(.status) | map({status: .[0].status, count: length}) |
    sort_by(-.count) | .[] | "\(.status): \(.count)"
' -r

echo ""
echo "=== Critical/High Severity Incidents ==="
mc_gql "{ getIncidents(first: 20, severities: [\"SEV_1\", \"SEV_2\"]) { edges { node { uuid incidentType severity status startTime affectedTables { fullTableId } } } } }" | jq -r '
    .data.getIncidents.edges[] | "\(.node.uuid[0:8])\t\(.node.severity)\t\(.node.incidentType)\t\(.node.startTime[0:16])\t\(.node.affectedTables[0]?.fullTableId // "?")"
' | column -t

echo ""
echo "=== Incidents by Type ==="
mc_gql "{ getIncidents(first: 200) { edges { node { incidentType } } } }" | jq '
    [.data.getIncidents.edges[].node.incidentType] |
    group_by(.) | map({type: .[0], count: length}) |
    sort_by(-.count) | .[] | "\(.type): \(.count)"
' -r
```

### Freshness Monitors

```bash
#!/bin/bash
echo "=== Freshness Anomalies ==="
mc_gql "{ getIncidents(first: 20, incidentTypes: [\"FRESHNESS_ANOMALY\"]) { edges { node { uuid severity startTime affectedTables { fullTableId } feedback { status } } } } }" | jq -r '
    .data.getIncidents.edges[] | "\(.node.uuid[0:8])\t\(.node.severity)\t\(.node.startTime[0:16])\t\(.node.affectedTables[0]?.fullTableId // "?")\t\(.node.feedback?.status // "open")"
' | column -t | head -15

echo ""
echo "=== Table Freshness Status ==="
TABLE_ID="${1:-}"
if [ -n "$TABLE_ID" ]; then
    mc_gql "{ getTable(fullTableId: \"${TABLE_ID}\") { tableStats { lastUpdatedTime bytesCount rowCount } freshness { status lastUpdated expectedFrequency } } }" | jq '{
        last_updated: .data.getTable.tableStats.lastUpdatedTime,
        row_count: .data.getTable.tableStats.rowCount,
        freshness_status: .data.getTable.freshness?.status,
        expected_frequency: .data.getTable.freshness?.expectedFrequency
    }'
fi
```

### Schema Change Tracking

```bash
#!/bin/bash
echo "=== Recent Schema Changes ==="
mc_gql "{ getIncidents(first: 20, incidentTypes: [\"SCHEMA_CHANGE\"]) { edges { node { uuid startTime affectedTables { fullTableId } } } } }" | jq -r '
    .data.getIncidents.edges[] | "\(.node.uuid[0:8])\t\(.node.startTime[0:16])\t\(.node.affectedTables[0]?.fullTableId // "?")"
' | column -t

echo ""
echo "=== Schema Change Details ==="
INCIDENT_ID="${1:-}"
if [ -n "$INCIDENT_ID" ]; then
    mc_gql "{ getIncident(incidentId: \"${INCIDENT_ID}\") { incidentType events { eventType description timestamp } affectedTables { fullTableId } } }" | jq -r '
        .data.getIncident.events[] | "\(.timestamp[0:16])\t\(.eventType)\t\(.description[0:80])"
    ' | column -t
fi
```

### Lineage Analysis

```bash
#!/bin/bash
TABLE_ID="${1:?Table ID required (e.g., database:schema.table)}"

echo "=== Table Lineage: $TABLE_ID ==="
mc_gql "{ getTableLineage(fullTableId: \"${TABLE_ID}\", direction: UPSTREAM, depth: 2) { edges { sourceTableId destinationTableId } } }" | jq -r '
    .data.getTableLineage.edges[] | "UPSTREAM: \(.sourceTableId) -> \(.destinationTableId)"
' | head -15

echo ""
mc_gql "{ getTableLineage(fullTableId: \"${TABLE_ID}\", direction: DOWNSTREAM, depth: 2) { edges { sourceTableId destinationTableId } } }" | jq -r '
    .data.getTableLineage.edges[] | "DOWNSTREAM: \(.sourceTableId) -> \(.destinationTableId)"
' | head -15

echo ""
echo "=== Table Details ==="
mc_gql "{ getTable(fullTableId: \"${TABLE_ID}\") { tableStats { lastUpdatedTime bytesCount rowCount } importanceScore monitorCount } }" | jq '.data.getTable'
```

### Custom Monitor Management

```bash
#!/bin/bash
echo "=== Custom SQL Monitors ==="
mc_gql "{ getMonitors(first: 30, monitorTypes: [\"CUSTOM_SQL\"]) { edges { node { uuid name isActive schedule description } } } }" | jq -r '
    .data.getMonitors.edges[] | "\(.node.uuid[0:8])\t\(if .node.isActive then "ACTIVE" else "PAUSED" end)\t\(.node.name)\t\(.node.schedule // "?")"
' | column -t | head -20

echo ""
echo "=== Monitors by Table ==="
TABLE_ID="${1:-}"
if [ -n "$TABLE_ID" ]; then
    mc_gql "{ getTable(fullTableId: \"${TABLE_ID}\") { monitors { uuid monitorType isActive name } } }" | jq -r '
        .data.getTable.monitors[] | "\(.uuid[0:8])\t\(.monitorType)\t\(if .isActive then "ACTIVE" else "PAUSED" end)\t\(.name // "auto")"
    ' | column -t
fi
```

## Common Pitfalls

- **GraphQL API**: Monte Carlo is GraphQL-only — all queries must be valid GQL with proper field selection
- **Table IDs**: Full table IDs follow the format `warehouse:database:schema.table` — always use fully qualified names
- **Incident vs anomaly**: Incidents group related anomalies — a single incident may contain multiple anomalous observations
- **Severity levels**: `SEV_1` (critical) through `SEV_4` (informational) — not all incidents are actionable
- **Monitor types**: `FRESHNESS`, `VOLUME`, `SCHEMA_CHANGE`, `CUSTOM_SQL`, `FIELD_HEALTH`, `DIMENSION` — each has different alert logic
- **Lineage depth**: Deep lineage queries can be slow — use `depth` parameter to limit traversal
- **Importance score**: Monte Carlo auto-assigns importance (0-10) based on query patterns — high-importance tables get stricter monitoring
- **Feedback loop**: Marking incidents as "expected" trains the ML model — false positives should be marked, not ignored
- **API rate limits**: GraphQL endpoint has rate limits — avoid deeply nested queries that fan out
