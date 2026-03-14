---
name: managing-chroma
description: |
  Chroma vector database management, collection inspection, embedding analysis, and query performance monitoring. Covers collection metadata, document counts, distance metrics, index health, and tenant/database configuration. Read this skill before any Chroma operations.
connection_type: chroma
preload: false
---

# Chroma Management Skill

Monitor, analyze, and optimize Chroma vector database instances safely.

## MANDATORY: Discovery-First Pattern

**Always check server health and list collections before any query operations. Never assume collection names or embedding dimensions.**

### Phase 1: Discovery

```bash
#!/bin/bash

CHROMA_URL="${CHROMA_URL:-http://localhost:8000}"

echo "=== Server Health ==="
curl -s "$CHROMA_URL/api/v1/heartbeat"

echo ""
echo "=== Version ==="
curl -s "$CHROMA_URL/api/v1/version"

echo ""
echo "=== Collections ==="
curl -s "$CHROMA_URL/api/v1/collections" | python3 -c "
import sys, json
data = json.load(sys.stdin)
for c in data:
    meta = c.get('metadata', {}) or {}
    print(f\"Collection: {c['name']} | ID: {c['id'][:12]}... | Distance: {meta.get('hnsw:space', 'l2')}\")
" 2>/dev/null

echo ""
echo "=== Collection Details ==="
for coll_id in $(curl -s "$CHROMA_URL/api/v1/collections" 2>/dev/null | python3 -c "
import sys, json
for c in json.load(sys.stdin):
    print(c['id'])
" 2>/dev/null); do
    count=$(curl -s "$CHROMA_URL/api/v1/collections/$coll_id/count" 2>/dev/null)
    name=$(curl -s "$CHROMA_URL/api/v1/collections/$coll_id" 2>/dev/null | python3 -c "import sys,json; print(json.load(sys.stdin).get('name','?'))" 2>/dev/null)
    echo "  $name: $count documents"
done
```

**Phase 1 outputs:** Server health, version, collection list with doc counts and distance metrics.

### Phase 2: Analysis

```bash
#!/bin/bash

CHROMA_URL="${CHROMA_URL:-http://localhost:8000}"
COLLECTION="${1:-my_collection}"

echo "=== Collection Info ==="
COLL_ID=$(curl -s "$CHROMA_URL/api/v1/collections" | python3 -c "
import sys, json
for c in json.load(sys.stdin):
    if c['name'] == '$COLLECTION':
        print(c['id'])
        break
" 2>/dev/null)

curl -s "$CHROMA_URL/api/v1/collections/$COLL_ID" | python3 -c "
import sys, json
c = json.load(sys.stdin)
meta = c.get('metadata', {}) or {}
print(f\"Name: {c['name']}\")
print(f\"ID: {c['id']}\")
print(f\"Distance function: {meta.get('hnsw:space', 'l2')}\")
print(f\"HNSW construction EF: {meta.get('hnsw:construction_ef', 'default')}\")
print(f\"HNSW M: {meta.get('hnsw:M', 'default')}\")
print(f\"HNSW search EF: {meta.get('hnsw:search_ef', 'default')}\")
" 2>/dev/null

echo ""
echo "=== Document Count ==="
curl -s "$CHROMA_URL/api/v1/collections/$COLL_ID/count"

echo ""
echo "=== Sample Documents ==="
curl -s -X POST "$CHROMA_URL/api/v1/collections/$COLL_ID/get" \
    -H "Content-Type: application/json" \
    -d '{"limit": 3, "include": ["metadatas", "documents"]}' | python3 -c "
import sys, json
data = json.load(sys.stdin)
ids = data.get('ids', [])
docs = data.get('documents', [])
metas = data.get('metadatas', [])
for i, id in enumerate(ids[:3]):
    doc = docs[i][:80] if docs and i < len(docs) and docs[i] else '?'
    meta = metas[i] if metas and i < len(metas) else {}
    print(f\"  {id}: {doc}... | meta={meta}\")
" 2>/dev/null
```

## Output Format

```
CHROMA ANALYSIS
===============
Server: [healthy/unhealthy] | Version: [version]
Collections: [count] | Total Documents: [count]

ISSUES FOUND:
- [issue with affected collection]

RECOMMENDATIONS:
- [actionable recommendation]
```
