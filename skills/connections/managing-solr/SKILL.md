---
name: managing-solr
description: |
  Apache Solr collection management, core administration, query performance tuning, and schema analysis. Covers SolrCloud cluster health, shard states, replica placement, config sets, commit strategies, and cache hit ratios. Read this skill before any Solr operations.
connection_type: solr
preload: false
---

# Solr Management Skill

Monitor, analyze, and optimize Apache Solr instances and SolrCloud clusters safely.

## MANDATORY: Discovery-First Pattern

**Always check cluster status and list collections before any query or config operations. Never assume collection or field names.**

### Phase 1: Discovery

```bash
#!/bin/bash

SOLR_URL="${SOLR_URL:-http://localhost:8983/solr}"

echo "=== System Info ==="
curl -s "$SOLR_URL/admin/info/system?wt=json" | python3 -c "
import sys, json
d = json.load(sys.stdin)
print(f\"Solr Version: {d.get('lucene',{}).get('solr-spec-version','?')}\")
print(f\"JVM: {d.get('jvm',{}).get('version','?')}\")
print(f\"Uptime: {d.get('jvm',{}).get('jmx',{}).get('upTimeMS',0)//86400000}d\")
" 2>/dev/null

echo ""
echo "=== Collections ==="
curl -s "$SOLR_URL/admin/collections?action=LIST&wt=json" | python3 -c "
import sys, json
data = json.load(sys.stdin)
for c in data.get('collections', []):
    print(f\"  {c}\")
" 2>/dev/null

echo ""
echo "=== Cluster Status ==="
curl -s "$SOLR_URL/admin/collections?action=CLUSTERSTATUS&wt=json" | python3 -c "
import sys, json
data = json.load(sys.stdin)
cluster = data.get('cluster', {})
live = cluster.get('live_nodes', [])
print(f\"Live nodes: {len(live)}\")
for name, coll in cluster.get('collections', {}).items():
    shards = coll.get('shards', {})
    print(f\"Collection: {name} | Shards: {len(shards)} | RF: {coll.get('replicationFactor','?')}\")
" 2>/dev/null

echo ""
echo "=== Core Status ==="
curl -s "$SOLR_URL/admin/cores?action=STATUS&wt=json" | python3 -c "
import sys, json
data = json.load(sys.stdin)
for name, core in data.get('status', {}).items():
    idx = core.get('index', {})
    print(f\"Core: {name} | Docs: {idx.get('numDocs',0)} | Size: {idx.get('sizeInBytes',0)//1048576}MB\")
" 2>/dev/null
```

**Phase 1 outputs:** Solr version, collection list, cluster topology, core doc counts and sizes.

### Phase 2: Analysis

```bash
#!/bin/bash

SOLR_URL="${SOLR_URL:-http://localhost:8983/solr}"
COLLECTION="${1:-my_collection}"

echo "=== Schema Fields for $COLLECTION ==="
curl -s "$SOLR_URL/$COLLECTION/schema/fields?wt=json" | python3 -c "
import sys, json
for f in json.load(sys.stdin).get('fields', []):
    print(f\"  {f['name']}: {f.get('type','?')} indexed={f.get('indexed','?')} stored={f.get('stored','?')}\")
" 2>/dev/null | head -20

echo ""
echo "=== Cache Stats ==="
curl -s "$SOLR_URL/$COLLECTION/admin/mbeans?cat=CACHE&stats=true&wt=json" | python3 -c "
import sys, json
data = json.load(sys.stdin)
beans = data.get('solr-mbeans', [])
i = 0
while i < len(beans)-1:
    if isinstance(beans[i+1], dict):
        for name, info in beans[i+1].items():
            stats = info.get('stats', {})
            if stats:
                print(f\"{name}: hits={stats.get('hits','?')} lookups={stats.get('lookups','?')} hitratio={stats.get('hitratio','?')}\")
    i += 2
" 2>/dev/null

echo ""
echo "=== Query Handler Stats ==="
curl -s "$SOLR_URL/$COLLECTION/admin/mbeans?cat=QUERYHANDLER&stats=true&wt=json" | python3 -c "
import sys, json
data = json.load(sys.stdin)
beans = data.get('solr-mbeans', [])
i = 0
while i < len(beans)-1:
    if isinstance(beans[i+1], dict):
        for name, info in beans[i+1].items():
            stats = info.get('stats', {})
            if stats and stats.get('requests',0) > 0:
                print(f\"{name}: requests={stats.get('requests')} avgTime={stats.get('avgTimePerRequest','?')}ms errors={stats.get('errors',0)}\")
    i += 2
" 2>/dev/null | head -10
```

## Output Format

```
SOLR ANALYSIS
=============
Version: [version] | Mode: [standalone/SolrCloud]
Collections: [count] | Live Nodes: [count]

ISSUES FOUND:
- [issue with affected collection/core]

RECOMMENDATIONS:
- [actionable recommendation]
```
