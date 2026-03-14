---
name: managing-risingwave
description: |
  RisingWave streaming database management — monitor sources, sinks, materialized views, clusters, query performance, and ingestion health. Use when debugging stream processing lag, inspecting view dependencies, auditing data freshness, or reviewing cluster capacity.
connection_type: risingwave
preload: false
---

# Managing RisingWave

Manage and monitor RisingWave streaming database — sources, sinks, materialized views, and cluster health.

## Discovery Phase

```bash
#!/bin/bash

rw_cmd() {
    psql "$RISINGWAVE_URL" --no-psqlrc -t -A -F $'\t' -c "$1" 2>/dev/null
}

echo "=== Databases ==="
rw_cmd "SELECT datname FROM pg_database ORDER BY datname;" | head -10

echo ""
echo "=== Schemas ==="
rw_cmd "SELECT schema_name FROM information_schema.schemata ORDER BY schema_name;" | head -10

echo ""
echo "=== Sources ==="
rw_cmd "SELECT name, connector, owner, definition
        FROM rw_sources
        ORDER BY name
        LIMIT 15;" | column -t

echo ""
echo "=== Materialized Views ==="
rw_cmd "SELECT name, owner, definition
        FROM rw_materialized_views
        ORDER BY name
        LIMIT 15;" | column -t

echo ""
echo "=== Sinks ==="
rw_cmd "SELECT name, connector, sink_type, owner
        FROM rw_sinks
        ORDER BY name
        LIMIT 10;" | column -t

echo ""
echo "=== Tables ==="
rw_cmd "SELECT table_name, table_schema
        FROM information_schema.tables
        WHERE table_schema NOT IN ('pg_catalog', 'information_schema', 'rw_catalog')
        ORDER BY table_name
        LIMIT 15;" | column -t
```

## Analysis Phase

```bash
#!/bin/bash

rw_cmd() {
    psql "$RISINGWAVE_URL" --no-psqlrc -t -A -F $'\t' -c "$1" 2>/dev/null
}

echo "=== Cluster Nodes ==="
rw_cmd "SELECT host, role, state
        FROM rw_worker_nodes
        ORDER BY role;" | column -t | head -10

echo ""
echo "=== Source Throughput ==="
rw_cmd "SELECT source_name, split_id,
               rows_per_second, bytes_per_second
        FROM rw_source_stats
        ORDER BY rows_per_second DESC
        LIMIT 10;" | column -t

echo ""
echo "=== Barrier Latency ==="
rw_cmd "SELECT worker_id, barrier_latency_ms, inflight_barrier_count
        FROM rw_streaming_stats
        ORDER BY barrier_latency_ms DESC
        LIMIT 10;" | column -t

echo ""
echo "=== MV Dependencies ==="
rw_cmd "SELECT mv.name AS mv_name, dep.name AS depends_on
        FROM rw_materialized_views mv
        JOIN rw_relations dep ON mv.definition LIKE '%' || dep.name || '%'
        LIMIT 15;" | column -t

echo ""
echo "=== Running Queries ==="
rw_cmd "SELECT pid, state, LEFT(query, 80) AS query_preview,
               now() - query_start AS duration
        FROM pg_stat_activity
        WHERE state = 'active' AND pid != pg_backend_pid()
        LIMIT 10;" | column -t

echo ""
echo "=== Sink Status ==="
rw_cmd "SELECT name, connector, sink_type
        FROM rw_sinks
        LIMIT 10;" | column -t
```

## Output Format

```
CLUSTER NODES
Host          Role        State
<host>        <role>      running

SOURCES
Name          Connector    Owner
<source>      <connector>  <owner>

MATERIALIZED VIEWS
Name          Owner       Definition
<mv-name>     <owner>     <definition>

SOURCE THROUGHPUT
Source        Split    Rows/sec    Bytes/sec
<source>      <id>     <n>         <n>

BARRIER LATENCY
Worker       Latency (ms)   Inflight Barriers
<worker>     <ms>           <n>
```
