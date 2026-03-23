---
name: managing-questdb
description: |
  Use when working with Questdb — questDB time-series database management —
  monitor tables, partitions, ingestion throughput, query performance, and
  server health. Use when inspecting table schemas, debugging slow queries,
  reviewing WAL status, or auditing storage utilization.
connection_type: questdb
preload: false
---

# Managing QuestDB

Manage and monitor QuestDB time-series database — tables, partitions, ingestion, queries, and server health.

## Discovery Phase

```bash
#!/bin/bash

QUESTDB_API="${QUESTDB_URL:-http://localhost:9000}"

qdb_query() {
    curl -s -G "$QUESTDB_API/exec" --data-urlencode "query=$1" | jq -r '.dataset[] | @tsv'
}

echo "=== Server Status ==="
curl -s "$QUESTDB_API/status" | jq '.' 2>/dev/null || echo "Status endpoint not available"

echo ""
echo "=== Tables ==="
qdb_query "SELECT name, partitionBy, maxUncommittedRows, walEnabled, directoryName
           FROM tables()
           ORDER BY name
           LIMIT 20;" | column -t

echo ""
echo "=== Table Sizes ==="
qdb_query "SELECT table_name, row_count, disk_size
           FROM table_storage()
           ORDER BY disk_size DESC
           LIMIT 15;" | column -t

echo ""
echo "=== Table Columns (sample) ==="
qdb_query "SELECT table_name, column_name, column_type, indexed, indexValueBlockCapacity
           FROM table_columns('${QUESTDB_TABLE:-trades}')
           LIMIT 20;" | column -t
```

## Analysis Phase

```bash
#!/bin/bash

QUESTDB_API="${QUESTDB_URL:-http://localhost:9000}"

qdb_query() {
    curl -s -G "$QUESTDB_API/exec" --data-urlencode "query=$1" | jq -r '.dataset[] | @tsv'
}

qdb_meta() {
    curl -s -G "$QUESTDB_API/exec" --data-urlencode "query=$1" | jq '.'
}

echo "=== Partition Info ==="
qdb_query "SELECT * FROM table_partitions('${QUESTDB_TABLE:-trades}')
           ORDER BY index DESC
           LIMIT 10;" | column -t

echo ""
echo "=== WAL Status ==="
qdb_query "SELECT * FROM wal_tables()
           LIMIT 10;" | column -t

echo ""
echo "=== Query Performance (sample) ==="
RESULT=$(qdb_meta "SELECT count() FROM ${QUESTDB_TABLE:-trades}")
echo "$RESULT" | jq '{count: .dataset[0][0], timing: .timings}'

echo ""
echo "=== Recent Data Check ==="
qdb_query "SELECT min(timestamp), max(timestamp), count()
           FROM ${QUESTDB_TABLE:-trades}
           WHERE timestamp > dateadd('d', -1, now());" | column -t

echo ""
echo "=== Active Writers ==="
qdb_query "SELECT * FROM writer_pool()
           LIMIT 10;" | column -t

echo ""
echo "=== Memory Usage ==="
curl -s "$QUESTDB_API/exec" --data-urlencode "query=SELECT * FROM memory()" \
  | jq -r '.dataset[] | @tsv' | column -t

echo ""
echo "=== Detached Partitions ==="
qdb_query "SELECT table_name, partition_name, reason
           FROM detached_partitions()
           LIMIT 10;" | column -t
```

## Output Format

```
TABLES
Name             Partition By   WAL Enabled   Max Uncommitted
<table-name>     DAY            true          <n>

TABLE SIZES
Table            Rows           Disk Size
<table-name>     <n>            <bytes>

PARTITIONS
Index    Name         Row Count    Size
<n>      <partition>  <n>          <bytes>

WAL STATUS
Table            Seq Txn    Writer Txn   Segment Count
<table-name>     <n>        <n>          <n>

DATA FRESHNESS
Min Timestamp     Max Timestamp     Count (24h)
<timestamp>       <timestamp>       <n>
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

