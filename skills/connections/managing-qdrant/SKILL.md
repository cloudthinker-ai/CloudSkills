---
name: managing-qdrant
description: |
  Qdrant vector database management, collection health monitoring, shard distribution analysis, and query optimization. Covers collection configuration, HNSW index parameters, quantization settings, snapshot management, and cluster consensus state. Read this skill before any Qdrant operations.
connection_type: qdrant
preload: false
---

# Qdrant Management Skill

Monitor, analyze, and optimize Qdrant vector database instances safely.

## MANDATORY: Discovery-First Pattern

**Always check cluster health and list collections before any query or indexing operations. Never assume collection names, vector dimensions, or payload schemas.**

### Phase 1: Discovery

```bash
#!/bin/bash

QDRANT_URL="${QDRANT_URL:-http://localhost:6333}"
QDRANT_AUTH="${QDRANT_API_KEY:+api-key: $QDRANT_API_KEY}"

qd_get() {
    curl -s ${QDRANT_AUTH:+-H "$QDRANT_AUTH"} "$QDRANT_URL$1"
}

echo "=== Health Check ==="
qd_get "/healthz"

echo ""
echo "=== Telemetry / Version ==="
qd_get "/telemetry" | python3 -c "
import sys, json
data = json.load(sys.stdin)
app = data.get('result', {}).get('app', {})
print(f\"Version: {app.get('version','?')}\")
print(f\"Startup: {app.get('startup','?')}\")
collections = data.get('result', {}).get('collections', {})
print(f\"Total collections: {collections.get('number_of_collections','?')}\")
" 2>/dev/null

echo ""
echo "=== Collections ==="
qd_get "/collections" | python3 -c "
import sys, json
data = json.load(sys.stdin)
for c in data.get('result', {}).get('collections', []):
    print(f\"Collection: {c['name']}\")
" 2>/dev/null

echo ""
echo "=== Collection Details ==="
for coll in $(qd_get "/collections" | python3 -c "
import sys, json
for c in json.load(sys.stdin).get('result',{}).get('collections',[]):
    print(c['name'])
" 2>/dev/null); do
    qd_get "/collections/$coll" | python3 -c "
import sys, json
r = json.load(sys.stdin).get('result', {})
config = r.get('config', {})
params = config.get('params', {})
vectors = params.get('vectors', {})
if isinstance(vectors, dict) and 'size' in vectors:
    print(f\"  {r.get('name','?')}: dim={vectors['size']} distance={vectors.get('distance','?')} points={r.get('points_count',0)} status={r.get('status','?')}\")
else:
    print(f\"  Collection: points={r.get('points_count',0)} status={r.get('status','?')}\")
    for vname, vconf in (vectors if isinstance(vectors, dict) else {}).items():
        print(f\"    vector '{vname}': dim={vconf.get('size','?')} distance={vconf.get('distance','?')}\")
" 2>/dev/null
done

echo ""
echo "=== Cluster Info ==="
qd_get "/cluster" | python3 -c "
import sys, json
data = json.load(sys.stdin).get('result', {})
print(f\"Status: {data.get('status','?')}\")
print(f\"Peer ID: {data.get('peer_id','?')}\")
print(f\"Peers: {len(data.get('peers', {}))}\")
" 2>/dev/null
```

**Phase 1 outputs:** Version, collection list with dimensions and point counts, cluster status.

### Phase 2: Analysis

```bash
#!/bin/bash

QDRANT_URL="${QDRANT_URL:-http://localhost:6333}"
QDRANT_AUTH="${QDRANT_API_KEY:+api-key: $QDRANT_API_KEY}"
COLLECTION="${1:-my_collection}"

qd_get() {
    curl -s ${QDRANT_AUTH:+-H "$QDRANT_AUTH"} "$QDRANT_URL$1"
}

echo "=== Collection Config: $COLLECTION ==="
qd_get "/collections/$COLLECTION" | python3 -c "
import sys, json
r = json.load(sys.stdin).get('result', {})
config = r.get('config', {})
hnsw = config.get('hnsw_config', {})
quant = config.get('quantization_config')
opt = config.get('optimizer_config', {})
print(f\"Points: {r.get('points_count',0)} | Indexed: {r.get('indexed_vectors_count',0)} | Segments: {r.get('segments_count',0)}\")
print(f\"HNSW: m={hnsw.get('m','?')} ef_construct={hnsw.get('ef_construct','?')} full_scan_threshold={hnsw.get('full_scan_threshold','?')}\")
print(f\"Quantization: {quant if quant else 'none'}\")
print(f\"Optimizer: indexing_threshold={opt.get('indexing_threshold','?')} memmap_threshold={opt.get('memmap_threshold','?')}\")
" 2>/dev/null

echo ""
echo "=== Shard Distribution ==="
qd_get "/collections/$COLLECTION/cluster" | python3 -c "
import sys, json
data = json.load(sys.stdin).get('result', {})
local = data.get('local_shards', [])
remote = data.get('remote_shards', [])
print(f\"Local shards: {len(local)} | Remote shards: {len(remote)}\")
for s in local:
    print(f\"  Shard {s.get('shard_id','?')}: points={s.get('points_count',0)} state={s.get('state','?')}\")
" 2>/dev/null

echo ""
echo "=== Payload Indexes ==="
qd_get "/collections/$COLLECTION" | python3 -c "
import sys, json
r = json.load(sys.stdin).get('result', {})
pi = r.get('payload_schema', {})
for field, info in pi.items():
    print(f\"  {field}: type={info.get('data_type','?')} indexed={info.get('points',0)} points\")
" 2>/dev/null

echo ""
echo "=== Snapshots ==="
qd_get "/collections/$COLLECTION/snapshots" | python3 -c "
import sys, json
for s in json.load(sys.stdin).get('result', []):
    print(f\"  {s.get('name','?')}: size={s.get('size',0)//1048576}MB created={s.get('creation_time','?')}\")
" 2>/dev/null || echo "No snapshots"
```

## Output Format

```
QDRANT ANALYSIS
===============
Version: [version] | Cluster: [status] | Peers: [count]
Collections: [count] | Total Points: [count]

ISSUES FOUND:
- [issue with affected collection/shard]

RECOMMENDATIONS:
- [actionable recommendation]
```
