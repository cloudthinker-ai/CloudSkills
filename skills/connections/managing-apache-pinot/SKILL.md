---
name: managing-apache-pinot
description: |
  Apache Pinot management — monitor cluster health, tables, segments, ingestion jobs, query performance, and controller/broker/server status. Use when debugging ingestion issues, inspecting segment distribution, optimizing query latency, or auditing cluster capacity.
connection_type: apache-pinot
preload: false
---

# Managing Apache Pinot

Manage and monitor Apache Pinot cluster — tables, segments, ingestion, queries, and cluster health.

## Discovery Phase

```bash
#!/bin/bash

PINOT_API="${PINOT_CONTROLLER_URL:-http://localhost:9000}"

echo "=== Cluster Info ==="
curl -s "$PINOT_API/cluster/info" | jq '.'

echo ""
echo "=== Tables ==="
curl -s "$PINOT_API/tables" \
  | jq -r '.tables[]' | head -15

echo ""
echo "=== Table Details ==="
for TABLE in $(curl -s "$PINOT_API/tables" | jq -r '.tables[:10][]'); do
  SIZE=$(curl -s "$PINOT_API/tables/$TABLE/size?detailed=false" | jq -r '.estimatedSizeInBytes // 0')
  SEGMENTS=$(curl -s "$PINOT_API/segments/$TABLE" | jq 'length')
  echo -e "$TABLE\t$SEGMENTS segments\t$SIZE bytes"
done | column -t

echo ""
echo "=== Instances ==="
curl -s "$PINOT_API/instances" \
  | jq -r '.instances[] | [.instanceName, .host, .port, .enabled] | @tsv' | column -t | head -10

echo ""
echo "=== Tenants ==="
curl -s "$PINOT_API/tenants" \
  | jq -r '{brokerTenants: .BROKER_TENANTS, serverTenants: .SERVER_TENANTS}'
```

## Analysis Phase

```bash
#!/bin/bash

PINOT_API="${PINOT_CONTROLLER_URL:-http://localhost:9000}"

echo "=== Segment Status ==="
curl -s "$PINOT_API/segments/$PINOT_TABLE/metadata" \
  | jq -r 'to_entries[:10][] | [.key, .value.segment.totalDocs, .value.segment.startTime, .value.segment.endTime] | @tsv' | column -t

echo ""
echo "=== Table Ideal State ==="
curl -s "$PINOT_API/tables/$PINOT_TABLE/idealstate" \
  | jq '{numSegments: (.record.mapFields | length), replicationFactor: (.record.simpleFields.REPLICATION // "N/A")}'

echo ""
echo "=== Running Tasks ==="
curl -s "$PINOT_API/tasks/schedulerJobDetails" \
  | jq -r 'to_entries[] | [.key, .value] | @tsv' | column -t | head -10

echo ""
echo "=== Query Performance (sample) ==="
curl -s -X POST "$PINOT_API/sql" \
  -H "Content-Type: application/json" \
  -d "{\"sql\": \"SELECT count(*) FROM $PINOT_TABLE LIMIT 1\", \"trace\": true}" \
  | jq '{numDocsScanned: .numDocsScanned, totalDocs: .totalDocs, timeUsedMs: .timeUsedMs, numSegmentsQueried: .numSegmentsQueried}'

echo ""
echo "=== Segment Reload Status ==="
curl -s "$PINOT_API/segments/$PINOT_TABLE/reload/status" \
  | jq '.'

echo ""
echo "=== Table Index Configuration ==="
curl -s "$PINOT_API/tables/$PINOT_TABLE" \
  | jq '.OFFLINE.tableIndexConfig // .REALTIME.tableIndexConfig | {loadMode: .loadMode, invertedIndexColumns: .invertedIndexColumns, sortedColumn: .sortedColumn, bloomFilterColumns: .bloomFilterColumns}'
```

## Output Format

```
CLUSTER
Name:        <cluster-name>

TABLES
Name             Segments   Size
<table-name>     <n>        <bytes>

INSTANCES
Name             Host       Port    Enabled
<instance>       <host>     <port>  true

SEGMENT STATUS
Segment          Total Docs   Start Time   End Time
<segment-name>   <n>          <time>       <time>

QUERY PERFORMANCE
Docs Scanned:       <n>
Total Docs:         <n>
Time Used:          <ms>ms
Segments Queried:   <n>
```
