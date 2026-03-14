---
name: managing-questdb
description: |
  QuestDB time-series database management — monitor tables, partitions, ingestion throughput, query performance, and server health. Use when inspecting table schemas, debugging slow queries, reviewing WAL status, or auditing storage utilization.
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
