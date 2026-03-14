---
name: managing-elasticsearch-deep
description: |
  Deep Elasticsearch cluster management including shard allocation, index lifecycle policies, snapshot/restore operations, mapping optimization, and advanced query tuning. Covers node roles, circuit breakers, thread pools, watermark thresholds, and cross-cluster replication diagnostics. Read this skill before any advanced Elasticsearch operations.
connection_type: elasticsearch
preload: false
---

# Elasticsearch Deep Management Skill

Advanced cluster management, shard tuning, and index lifecycle operations for Elasticsearch.

## MANDATORY: Discovery-First Pattern

**Always run cluster health and node info before any management operations. Never assume index names or shard states.**

### Phase 1: Discovery

```bash
#!/bin/bash

ES_URL="${ELASTICSEARCH_URL:-http://localhost:9200}"

echo "=== Cluster Health ==="
curl -s "$ES_URL/_cluster/health?pretty"

echo ""
echo "=== Node Roles & Versions ==="
curl -s "$ES_URL/_cat/nodes?v&h=name,role,version,heap.percent,ram.percent,cpu,load_1m"

echo ""
echo "=== Index Summary ==="
curl -s "$ES_URL/_cat/indices?v&h=index,health,status,docs.count,store.size&s=store.size:desc" | head -20

echo ""
echo "=== Shard Allocation ==="
curl -s "$ES_URL/_cat/shards?v&h=index,shard,prirep,state,docs,store,node&s=store:desc" | head -20

echo ""
echo "=== Pending Tasks ==="
curl -s "$ES_URL/_cluster/pending_tasks?pretty"
```

**Phase 1 outputs:** Cluster state, node topology, index list with sizes, shard distribution, pending tasks.

### Phase 2: Analysis

```bash
#!/bin/bash

ES_URL="${ELASTICSEARCH_URL:-http://localhost:9200}"

echo "=== Unassigned Shards ==="
curl -s "$ES_URL/_cat/shards?v&h=index,shard,prirep,state,unassigned.reason" | grep UNASSIGNED | head -10

echo ""
echo "=== Disk Watermarks ==="
curl -s "$ES_URL/_cluster/settings?include_defaults=true&flat_settings=true" | \
    python3 -c "import sys,json; d=json.load(sys.stdin); [print(k,v) for k,v in d.get('defaults',{}).items() if 'watermark' in k]" 2>/dev/null

echo ""
echo "=== Thread Pool Rejections ==="
curl -s "$ES_URL/_cat/thread_pool?v&h=node_name,name,active,rejected,completed" | grep -E "write|search|get" | head -15

echo ""
echo "=== Circuit Breakers ==="
curl -s "$ES_URL/_nodes/stats/breaker?pretty" | python3 -c "
import sys, json
data = json.load(sys.stdin)
for nid, node in data.get('nodes', {}).items():
    print(f\"Node: {node['name']}\")
    for name, info in node.get('breakers', {}).items():
        print(f\"  {name}: limit={info['limit_size']}, estimated={info['estimated_size']}, tripped={info['tripped']}\")
" 2>/dev/null

echo ""
echo "=== ILM Policy Status ==="
curl -s "$ES_URL/_ilm/status?pretty"
curl -s "$ES_URL/_cat/indices?v&h=index,health,status,docs.count,store.size&s=index" | grep -E "^(shrink|rollover|delete)" | head -10
```

## Output Format

Present findings as:

```
ELASTICSEARCH DEEP ANALYSIS
===========================
Cluster: [name] | Status: [green/yellow/red]
Nodes: [count] | Shards: [active]/[total] | Unassigned: [count]

ISSUES FOUND:
- [issue description with affected index/node]

RECOMMENDATIONS:
- [actionable recommendation]
```
