---
name: managing-weaviate
description: |
  Weaviate vector database management, schema inspection, module health monitoring, and query performance analysis. Covers class definitions, shard distribution, vectorizer configuration, multi-tenancy status, and backup/restore operations. Read this skill before any Weaviate operations.
connection_type: weaviate
preload: false
---

# Weaviate Management Skill

Monitor, analyze, and optimize Weaviate vector database instances safely.

## MANDATORY: Discovery-First Pattern

**Always check node health and list schema classes before any query operations. Never assume class names, property types, or vectorizer modules.**

### Phase 1: Discovery

```bash
#!/bin/bash

WEAVIATE_URL="${WEAVIATE_URL:-http://localhost:8080}"
WEAVIATE_AUTH="${WEAVIATE_API_KEY:+Authorization: Bearer $WEAVIATE_API_KEY}"

wv_get() {
    curl -s ${WEAVIATE_AUTH:+-H "$WEAVIATE_AUTH"} "$WEAVIATE_URL$1"
}

echo "=== Node Health ==="
wv_get "/v1/nodes" | python3 -c "
import sys, json
data = json.load(sys.stdin)
for n in data.get('nodes', []):
    print(f\"Node: {n['name']} | Status: {n['status']} | Version: {n.get('version','?')} | Objects: {n.get('stats',{}).get('objectCount',0)} | Shards: {n.get('stats',{}).get('shardCount',0)}\")
" 2>/dev/null

echo ""
echo "=== Meta / Version ==="
wv_get "/v1/meta" | python3 -c "
import sys, json
data = json.load(sys.stdin)
print(f\"Version: {data.get('version','?')}\")
print(f\"Modules: {list(data.get('modules',{}).keys())}\")
" 2>/dev/null

echo ""
echo "=== Schema Classes ==="
wv_get "/v1/schema" | python3 -c "
import sys, json
data = json.load(sys.stdin)
for c in data.get('classes', []):
    props = len(c.get('properties', []))
    vectorizer = c.get('vectorizer', 'none')
    mt = c.get('multiTenancyConfig', {}).get('enabled', False)
    print(f\"Class: {c['class']} | Props: {props} | Vectorizer: {vectorizer} | MultiTenant: {mt}\")
" 2>/dev/null
```

**Phase 1 outputs:** Node health, version, loaded modules, schema classes with vectorizer config.

### Phase 2: Analysis

```bash
#!/bin/bash

WEAVIATE_URL="${WEAVIATE_URL:-http://localhost:8080}"
WEAVIATE_AUTH="${WEAVIATE_API_KEY:+Authorization: Bearer $WEAVIATE_API_KEY}"
CLASS="${1:-MyClass}"

wv_get() {
    curl -s ${WEAVIATE_AUTH:+-H "$WEAVIATE_AUTH"} "$WEAVIATE_URL$1"
}

echo "=== Class Schema: $CLASS ==="
wv_get "/v1/schema/$CLASS" | python3 -c "
import sys, json
c = json.load(sys.stdin)
print(f\"Class: {c.get('class','?')}\")
print(f\"Vectorizer: {c.get('vectorizer','?')}\")
print(f\"Vector index: {c.get('vectorIndexType','hnsw')}\")
vi = c.get('vectorIndexConfig', {})
print(f\"HNSW EF: {vi.get('ef','-1')} | EF construction: {vi.get('efConstruction','-1')} | Max connections: {vi.get('maxConnections','-1')}\")
print(f\"Replication factor: {c.get('replicationConfig',{}).get('factor','?')}\")
print(f\"Properties:\")
for p in c.get('properties', []):
    print(f\"  {p['name']}: {','.join(p['dataType'])} | tokenization={p.get('tokenization','?')}\")
" 2>/dev/null

echo ""
echo "=== Object Count ==="
wv_get "/v1/objects?class=$CLASS&limit=0" | python3 -c "
import sys, json
data = json.load(sys.stdin)
print(f\"Total objects: {data.get('totalResults', '?')}\")
" 2>/dev/null

echo ""
echo "=== Shard Status ==="
wv_get "/v1/schema/$CLASS/shards" | python3 -c "
import sys, json
for s in json.load(sys.stdin):
    print(f\"  Shard: {s.get('name','?')} | Status: {s.get('status','?')} | Objects: {s.get('objectCount',0)}\")
" 2>/dev/null

echo ""
echo "=== Backups ==="
wv_get "/v1/backups" 2>/dev/null | head -5 || echo "No backup info available"
```

## Output Format

```
WEAVIATE ANALYSIS
=================
Version: [version] | Nodes: [count] | Status: [healthy/degraded]
Classes: [count] | Total Objects: [count]

ISSUES FOUND:
- [issue with affected class/shard]

RECOMMENDATIONS:
- [actionable recommendation]
```
