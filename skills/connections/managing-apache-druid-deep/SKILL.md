---
name: managing-apache-druid-deep
description: |
  Apache Druid deep management — monitor cluster health, datasources, ingestion tasks, segments, query performance, and coordinator/overlord status. Use when debugging ingestion failures, inspecting segment distribution, optimizing query latency, or auditing cluster capacity.
connection_type: apache-druid
preload: false
---

# Managing Apache Druid (Deep)

Manage and monitor Apache Druid cluster — datasources, ingestion, segments, queries, and cluster health.

## Discovery Phase

```bash
#!/bin/bash

DRUID_API="${DRUID_ROUTER_URL:-http://localhost:8888}"

echo "=== Cluster Health ==="
curl -s "$DRUID_API/status" \
  | jq '{version: .version, memory: .memory}'

echo ""
echo "=== Datasources ==="
curl -s "$DRUID_API/druid/coordinator/v1/datasources?simple" \
  | jq -r '.[] | [.name, .properties.segments.count, .properties.segments.size] | @tsv' | column -t | head -15

echo ""
echo "=== Services ==="
curl -s "$DRUID_API/druid/coordinator/v1/servers?simple" \
  | jq -r '.[] | [.host, .type, .tier, .currSize, .maxSize] | @tsv' | column -t | head -10

echo ""
echo "=== Supervisors ==="
curl -s "$DRUID_API/druid/indexer/v1/supervisor" \
  | jq -r '.[] | [.id, .state // "unknown"] | @tsv' | column -t | head -10

echo ""
echo "=== Load Queue ==="
curl -s "$DRUID_API/druid/coordinator/v1/loadqueue?simple" \
  | jq -r 'to_entries[] | [.key, .value.segmentsToLoad, .value.segmentsToDrop] | @tsv' | column -t | head -10
```

## Analysis Phase

```bash
#!/bin/bash

DRUID_API="${DRUID_ROUTER_URL:-http://localhost:8888}"

echo "=== Running Tasks ==="
curl -s "$DRUID_API/druid/indexer/v1/tasks?state=running" \
  | jq -r '.[] | [.id[:40], .type, .dataSource, .createdTime] | @tsv' | column -t | head -10

echo ""
echo "=== Failed Tasks (Recent) ==="
curl -s "$DRUID_API/druid/indexer/v1/tasks?state=failed&max=10" \
  | jq -r '.[] | [.id[:40], .dataSource, .createdTime, .errorMsg[:50] // ""] | @tsv' | column -t

echo ""
echo "=== Segment Distribution ==="
curl -s "$DRUID_API/druid/coordinator/v1/datasources/$DRUID_DATASOURCE/intervals?simple" \
  | jq -r 'to_entries[:10][] | [.key, .value.count, .value.size] | @tsv' | column -t

echo ""
echo "=== Compaction Status ==="
curl -s "$DRUID_API/druid/coordinator/v1/compaction/status" \
  | jq -r '.latestStatus[] | [.dataSource, .byteCountAwaitingCompaction, .segmentCountAwaitingCompaction] | @tsv' | column -t | head -10

echo ""
echo "=== Query Metrics ==="
curl -s -X POST "$DRUID_API/druid/v2/sql" \
  -H "Content-Type: application/json" \
  -d '{"query": "SELECT datasource, COUNT(*) AS num_segments, SUM(size) AS total_size, SUM(num_rows) AS total_rows FROM sys.segments WHERE is_published = 1 GROUP BY datasource ORDER BY total_size DESC LIMIT 10"}' \
  | jq -r '.[] | [.datasource, .num_segments, .total_size, .total_rows] | @tsv' | column -t

echo ""
echo "=== Supervisor Status ==="
for SUP_ID in $(curl -s "$DRUID_API/druid/indexer/v1/supervisor" | jq -r '.[:5][].id'); do
  curl -s "$DRUID_API/druid/indexer/v1/supervisor/$SUP_ID/status" \
    | jq -r '[.id, .payload.state, .payload.healthy] | @tsv'
done | column -t
```

## Output Format

```
CLUSTER
Version:     <version>
Services:    <count> nodes

DATASOURCES
Name             Segments   Size
<datasource>     <n>        <bytes>

SUPERVISORS
ID               State       Healthy
<supervisor>     RUNNING     true

RUNNING TASKS
ID               Type        Datasource      Created
<task-id>        <type>      <datasource>    <timestamp>

FAILED TASKS
ID               Datasource      Created         Error
<task-id>        <datasource>    <timestamp>     <message>

COMPACTION
Datasource       Bytes Awaiting   Segments Awaiting
<datasource>     <bytes>          <n>
```
