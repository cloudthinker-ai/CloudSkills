---
name: managing-starrocks
description: |
  Use when working with Starrocks — starRocks management — monitor cluster
  health, databases, tables, materialized views, query performance, and load
  jobs. Use when inspecting schema layout, debugging slow queries, reviewing
  compaction status, or auditing data loading pipelines.
connection_type: starrocks
preload: false
---

# Managing StarRocks

Manage and monitor StarRocks analytical database — databases, tables, materialized views, queries, and load jobs.

## Discovery Phase

```bash
#!/bin/bash

sr_cmd() {
    mysql -h "$STARROCKS_HOST" -P "${STARROCKS_PORT:-9030}" \
          -u "$STARROCKS_USER" -p"$STARROCKS_PASSWORD" \
          --batch --skip-column-names -e "$1" 2>/dev/null
}

echo "=== Cluster Status ==="
sr_cmd "SHOW FRONTENDS\G" | grep -E 'Name|Host|Alive|Role' | head -12

echo ""
echo "=== Backends ==="
sr_cmd "SHOW BACKENDS;" | column -t | head -10

echo ""
echo "=== Databases ==="
sr_cmd "SHOW DATABASES;" | head -15

echo ""
echo "=== Tables (current database) ==="
sr_cmd "USE ${STARROCKS_DATABASE:-default_catalog.default_db}; SHOW TABLES;" | head -20

echo ""
echo "=== Materialized Views ==="
sr_cmd "SHOW MATERIALIZED VIEWS FROM ${STARROCKS_DATABASE:-default_catalog.default_db};" | column -t | head -10
```

## Analysis Phase

```bash
#!/bin/bash

sr_cmd() {
    mysql -h "$STARROCKS_HOST" -P "${STARROCKS_PORT:-9030}" \
          -u "$STARROCKS_USER" -p"$STARROCKS_PASSWORD" \
          --batch --skip-column-names -e "$1" 2>/dev/null
}
DB="${STARROCKS_DATABASE:-default_catalog.default_db}"

echo "=== Table Stats ==="
sr_cmd "SELECT TABLE_NAME, TABLE_ROWS, DATA_LENGTH, INDEX_LENGTH, TABLE_TYPE
        FROM information_schema.tables
        WHERE TABLE_SCHEMA = '$DB'
        ORDER BY DATA_LENGTH DESC
        LIMIT 15;" | column -t

echo ""
echo "=== Slow Queries (last 24h) ==="
sr_cmd "SELECT query_id, db, LEFT(query, 80) AS query_preview,
               query_time, scan_rows, scan_bytes
        FROM information_schema.slow_query_log
        WHERE start_time >= DATE_SUB(NOW(), INTERVAL 24 HOUR)
        ORDER BY query_time DESC
        LIMIT 10;" | column -t

echo ""
echo "=== Running Queries ==="
sr_cmd "SHOW PROCESSLIST;" | column -t | head -10

echo ""
echo "=== Load Jobs (recent) ==="
sr_cmd "SHOW ROUTINE LOAD;" | column -t | head -10

echo ""
echo "=== Compaction Status ==="
sr_cmd "SHOW TABLET FROM $DB.${STARROCKS_TABLE:-''};" 2>/dev/null | column -t | head -10

echo ""
echo "=== MV Refresh Status ==="
sr_cmd "SELECT TABLE_NAME, REFRESH_TYPE, IS_ACTIVE, LAST_REFRESH_STATE,
               LAST_REFRESH_START_TIME, LAST_REFRESH_FINISHED_TIME
        FROM information_schema.materialized_views
        WHERE TABLE_SCHEMA = '$DB'
        LIMIT 10;" | column -t
```

## Output Format

```
CLUSTER
Frontends:    <n> (alive)
Backends:     <n> (alive)

TABLES
Table Name       Rows         Data Size    Index Size
<table-name>     <n>          <bytes>      <bytes>

SLOW QUERIES (24h)
Query ID         DB       Preview              Time     Scan Rows
<id>             <db>     <query-preview>      <sec>    <n>

MATERIALIZED VIEWS
Name             Refresh Type   Active   Last State   Last Refresh
<mv-name>        <type>         true     SUCCESS      <timestamp>

LOAD JOBS
Name             State       Progress
<job-name>       RUNNING     <progress>
```

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

