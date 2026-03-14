---
name: managing-singlestore-deep
description: |
  Advanced SingleStore (MemSQL) cluster management, pipeline monitoring, columnstore analysis, and workload profiling. Covers aggregator/leaf health, partition distribution, resource pools, pipeline lag, and query plan optimization. Read this skill before any advanced SingleStore operations.
connection_type: singlestore
preload: false
---

# SingleStore Deep Management Skill

Advanced cluster management, pipeline monitoring, and query optimization for SingleStore.

## MANDATORY: Discovery-First Pattern

**Always check cluster status and list databases before any query operations. Never assume database names or table engines.**

### Phase 1: Discovery

```bash
#!/bin/bash

SS_HOST="${SINGLESTORE_HOST:-localhost}"
SS_PORT="${SINGLESTORE_PORT:-3306}"
SS_USER="${SINGLESTORE_USER:-root}"
SS_PASS="${SINGLESTORE_PASSWORD}"

ss_query() {
    mysql -h "$SS_HOST" -P "$SS_PORT" -u "$SS_USER" ${SS_PASS:+-p"$SS_PASS"} -e "$1" 2>/dev/null
}

echo "=== Cluster Status ==="
ss_query "SHOW CLUSTER STATUS;"

echo ""
echo "=== Version ==="
ss_query "SELECT @@memsql_version AS version, @@NODE_TYPE AS node_type;"

echo ""
echo "=== Databases ==="
ss_query "SELECT SCHEMA_NAME, DEFAULT_CHARACTER_SET_NAME FROM information_schema.SCHEMATA WHERE SCHEMA_NAME NOT IN ('cluster','information_schema','memsql');"

echo ""
echo "=== Aggregator/Leaf Nodes ==="
ss_query "SHOW AGGREGATORS;" 2>/dev/null
ss_query "SHOW LEAVES;" 2>/dev/null

echo ""
echo "=== Resource Pools ==="
ss_query "SELECT * FROM information_schema.RESOURCE_POOLS;" 2>/dev/null || echo "Resource pools not available"
```

**Phase 1 outputs:** Cluster state, node types (aggregator/leaf), database list, resource pool configuration.

### Phase 2: Analysis

```bash
#!/bin/bash

SS_HOST="${SINGLESTORE_HOST:-localhost}"
SS_PORT="${SINGLESTORE_PORT:-3306}"
SS_USER="${SINGLESTORE_USER:-root}"
SS_PASS="${SINGLESTORE_PASSWORD}"
DB="${1:-my_database}"

ss_query() {
    mysql -h "$SS_HOST" -P "$SS_PORT" -u "$SS_USER" ${SS_PASS:+-p"$SS_PASS"} -e "$1" 2>/dev/null
}

echo "=== Table Sizes ==="
ss_query "SELECT TABLE_NAME, TABLE_ROWS, ROUND(DATA_LENGTH/1048576,2) AS data_mb, ROUND(INDEX_LENGTH/1048576,2) AS index_mb FROM information_schema.TABLES WHERE TABLE_SCHEMA='$DB' ORDER BY DATA_LENGTH DESC LIMIT 15;"

echo ""
echo "=== Pipelines ==="
ss_query "SELECT DATABASE_NAME, PIPELINE_NAME, STATE, ERRORS_COUNT FROM information_schema.PIPELINES WHERE DATABASE_NAME='$DB';" 2>/dev/null || echo "No pipelines"

echo ""
echo "=== Running Queries ==="
ss_query "SHOW PROCESSLIST;" | head -15

echo ""
echo "=== Columnstore Segment Stats ==="
ss_query "SELECT TABLE_NAME, COUNT(*) as segments, SUM(ROWS_COUNT) as total_rows FROM information_schema.COLUMNAR_SEGMENTS WHERE DATABASE_NAME='$DB' GROUP BY TABLE_NAME ORDER BY total_rows DESC LIMIT 10;" 2>/dev/null

echo ""
echo "=== Partition Distribution ==="
ss_query "SELECT TABLE_NAME, COUNT(DISTINCT PARTITION_ID) as partitions FROM information_schema.TABLE_STATISTICS WHERE DATABASE_NAME='$DB' GROUP BY TABLE_NAME ORDER BY partitions DESC LIMIT 10;" 2>/dev/null

echo ""
echo "=== Memory Usage ==="
ss_query "SHOW STATUS EXTENDED LIKE '%memory%';" 2>/dev/null | head -15
```

## Output Format

```
SINGLESTORE DEEP ANALYSIS
==========================
Cluster: [status] | Aggregators: [count] | Leaves: [count]
Databases: [count] | Pipelines: [active/total]

ISSUES FOUND:
- [issue with affected database/pipeline]

RECOMMENDATIONS:
- [actionable recommendation]
```
