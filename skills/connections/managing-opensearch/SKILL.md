---
name: managing-opensearch
description: |
  OpenSearch cluster management including index operations, ISM policies, snapshot management, security analytics, and performance tuning. Covers cluster health, shard allocation, anomaly detection, alerting configuration, and observability pipelines. Read this skill before any OpenSearch operations.
connection_type: opensearch
preload: false
---

# OpenSearch Management Skill

Monitor, analyze, and optimize OpenSearch clusters safely.

## MANDATORY: Discovery-First Pattern

**Always run cluster health and list indices before any operations. Never guess index names or field mappings.**

### Phase 1: Discovery

```bash
#!/bin/bash

OS_URL="${OPENSEARCH_URL:-https://localhost:9200}"
CURL_OPTS="-s -k ${OPENSEARCH_USER:+-u $OPENSEARCH_USER:$OPENSEARCH_PASSWORD}"

echo "=== Cluster Health ==="
curl $CURL_OPTS "$OS_URL/_cluster/health?pretty"

echo ""
echo "=== Node Overview ==="
curl $CURL_OPTS "$OS_URL/_cat/nodes?v&h=name,role,version,heap.percent,ram.percent,cpu,load_1m"

echo ""
echo "=== Indices ==="
curl $CURL_OPTS "$OS_URL/_cat/indices?v&h=index,health,status,docs.count,store.size&s=store.size:desc" | head -20

echo ""
echo "=== ISM Policies ==="
curl $CURL_OPTS "$OS_URL/_plugins/_ism/policies" | python3 -c "
import sys, json
data = json.load(sys.stdin)
for p in data.get('policies', []):
    print(f\"Policy: {p['policy']['policy_id']} | States: {len(p['policy'].get('states', []))}\")
" 2>/dev/null

echo ""
echo "=== Plugin List ==="
curl $CURL_OPTS "$OS_URL/_cat/plugins?v"
```

**Phase 1 outputs:** Cluster state, node count, index inventory, ISM policies, installed plugins.

### Phase 2: Analysis

```bash
#!/bin/bash

OS_URL="${OPENSEARCH_URL:-https://localhost:9200}"
CURL_OPTS="-s -k ${OPENSEARCH_USER:+-u $OPENSEARCH_USER:$OPENSEARCH_PASSWORD}"

echo "=== Unassigned Shards ==="
curl $CURL_OPTS "$OS_URL/_cat/shards?v" | grep UNASSIGNED | head -10

echo ""
echo "=== Thread Pool Rejections ==="
curl $CURL_OPTS "$OS_URL/_cat/thread_pool?v&h=node_name,name,active,rejected,completed" | grep -v "0$" | head -15

echo ""
echo "=== Anomaly Detectors ==="
curl $CURL_OPTS "$OS_URL/_plugins/_anomaly_detection/detectors/_search" -H 'Content-Type: application/json' \
    -d '{"query":{"match_all":{}},"size":10}' 2>/dev/null | python3 -c "
import sys, json
data = json.load(sys.stdin)
for hit in data.get('hits',{}).get('hits',[]):
    src = hit['_source']
    print(f\"Detector: {src.get('name','?')} | Index: {src.get('indices',['?'])} | Enabled: {src.get('enabled','?')}\")
" 2>/dev/null || echo "No anomaly detectors configured"

echo ""
echo "=== Alerting Monitors ==="
curl $CURL_OPTS "$OS_URL/_plugins/_alerting/monitors/_search" -H 'Content-Type: application/json' \
    -d '{"query":{"match_all":{}},"size":10}' 2>/dev/null | python3 -c "
import sys, json
data = json.load(sys.stdin)
for hit in data.get('hits',{}).get('hits',[]):
    src = hit['_source']
    print(f\"Monitor: {src.get('name','?')} | Enabled: {src.get('enabled','?')} | Type: {src.get('monitor_type','?')}\")
" 2>/dev/null || echo "No alerting monitors configured"
```

## Output Format

```
OPENSEARCH ANALYSIS
===================
Cluster: [name] | Status: [green/yellow/red]
Nodes: [count] | Indices: [count] | Unassigned Shards: [count]

ISSUES FOUND:
- [issue with affected resource]

RECOMMENDATIONS:
- [actionable recommendation]
```
