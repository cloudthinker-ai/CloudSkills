---
name: managing-milvus
description: |
  Milvus vector database management, collection schema inspection, index build monitoring, and query node health analysis. Covers partition management, segment compaction, resource group allocation, replica configuration, and consistency level tuning. Read this skill before any Milvus operations.
connection_type: milvus
preload: false
---

# Milvus Management Skill

Monitor, analyze, and optimize Milvus vector database instances safely.

## MANDATORY: Discovery-First Pattern

**Always check cluster health and list collections before any search or insert operations. Never assume collection names, field schemas, or index types.**

### Phase 1: Discovery

```bash
#!/bin/bash

MILVUS_URL="${MILVUS_URL:-http://localhost:9091}"
MILVUS_GRPC="${MILVUS_HOST:-localhost}:${MILVUS_PORT:-19530}"

echo "=== Health Check ==="
curl -s "$MILVUS_URL/healthz" 2>/dev/null || curl -s "$MILVUS_URL/api/v1/health" 2>/dev/null

echo ""
echo "=== Metrics Summary ==="
curl -s "$MILVUS_URL/metrics" 2>/dev/null | grep -E "^milvus_" | grep -E "num_collections|num_partitions|num_loaded|query_node" | head -15

echo ""
echo "=== Collections (via REST v2) ==="
curl -s -X POST "${MILVUS_URL%:9091}:19530/v2/vectordb/collections/list" \
    -H "Content-Type: application/json" \
    -d '{}' 2>/dev/null | python3 -c "
import sys, json
data = json.load(sys.stdin)
for c in data.get('data', []):
    print(f\"Collection: {c}\")
" 2>/dev/null || echo "REST v2 not available"

echo ""
echo "=== Using pymilvus if available ==="
python3 -c "
from pymilvus import connections, utility
connections.connect(host='${MILVUS_HOST:-localhost}', port=${MILVUS_PORT:-19530})
collections = utility.list_collections()
print(f'Collections: {len(collections)}')
for c in collections:
    print(f'  {c}')
" 2>/dev/null || echo "pymilvus not available"

echo ""
echo "=== Component Health ==="
curl -s "$MILVUS_URL/api/v1/health" 2>/dev/null | python3 -c "
import sys, json
data = json.load(sys.stdin)
print(f\"isHealthy: {data.get('isHealthy','?')}\")
for reason in data.get('reasons', []):
    print(f\"  {reason}\")
" 2>/dev/null
```

**Phase 1 outputs:** Health status, collection list, component health, key metrics.

### Phase 2: Analysis

```bash
#!/bin/bash

MILVUS_URL="${MILVUS_URL:-http://localhost:9091}"
COLLECTION="${1:-my_collection}"

echo "=== Collection Details ==="
python3 -c "
from pymilvus import connections, Collection, utility
connections.connect(host='${MILVUS_HOST:-localhost}', port=${MILVUS_PORT:-19530})
c = Collection('$COLLECTION')
c.load()
schema = c.schema
print(f'Collection: {c.name}')
print(f'Description: {schema.description}')
print(f'Num entities: {c.num_entities}')
print(f'Fields:')
for f in schema.fields:
    print(f'  {f.name}: {f.dtype.name} | primary={f.is_primary} | dim={f.params.get(\"dim\",\"-\")}')
print(f'Indexes:')
for idx in c.indexes:
    print(f'  Field: {idx.field_name} | Type: {idx.params.get(\"index_type\",\"?\")} | Metric: {idx.params.get(\"metric_type\",\"?\")}')
print(f'Partitions: {[p.name for p in c.partitions]}')
" 2>/dev/null || echo "pymilvus required for detailed inspection"

echo ""
echo "=== Compaction Status ==="
curl -s "$MILVUS_URL/metrics" 2>/dev/null | grep -E "compaction" | head -5

echo ""
echo "=== Query Node Stats ==="
curl -s "$MILVUS_URL/metrics" 2>/dev/null | grep -E "query_node" | grep -E "search|query|loaded" | head -10

echo ""
echo "=== Resource Groups ==="
python3 -c "
from pymilvus import connections, utility
connections.connect(host='${MILVUS_HOST:-localhost}', port=${MILVUS_PORT:-19530})
groups = utility.list_resource_groups()
print(f'Resource groups: {groups}')
" 2>/dev/null || echo "Resource group info not available"

echo ""
echo "=== Replica Info ==="
python3 -c "
from pymilvus import connections, Collection
connections.connect(host='${MILVUS_HOST:-localhost}', port=${MILVUS_PORT:-19530})
c = Collection('$COLLECTION')
replicas = c.get_replicas()
for g in replicas.groups:
    print(f'  Group {g.id}: shards={len(g.shards)} nodes={g.group_nodes}')
" 2>/dev/null || echo "Replica info not available"
```

## Output Format

```
MILVUS ANALYSIS
===============
Health: [healthy/unhealthy] | Collections: [count]
Total Entities: [count] | Query Nodes: [count]

ISSUES FOUND:
- [issue with affected collection/index]

RECOMMENDATIONS:
- [actionable recommendation]
```
