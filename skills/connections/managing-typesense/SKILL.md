---
name: managing-typesense
description: |
  Typesense collection management, search tuning, schema analysis, and cluster health monitoring. Covers collection schemas, search analytics, synonym management, override rules, API key scoping, and curation configuration. Read this skill before any Typesense operations.
connection_type: typesense
preload: false
---

# Typesense Management Skill

Monitor, analyze, and optimize Typesense search clusters safely.

## MANDATORY: Discovery-First Pattern

**Always check cluster health and list collections before any search or schema operations. Never assume collection names or field types.**

### Phase 1: Discovery

```bash
#!/bin/bash

TS_URL="${TYPESENSE_URL:-http://localhost:8108}"
TS_KEY="${TYPESENSE_API_KEY}"

ts_get() {
    curl -s -H "X-TYPESENSE-API-KEY: $TS_KEY" "$TS_URL$1"
}

echo "=== Cluster Health ==="
ts_get "/health"

echo ""
echo "=== Cluster Metrics ==="
ts_get "/metrics.json" | python3 -c "
import sys, json
data = json.load(sys.stdin)
print(f\"Memory: {data.get('system_memory_used_bytes',0)//1048576}MB / {data.get('system_memory_total_bytes',0)//1048576}MB\")
print(f\"Disk: {data.get('system_disk_used_bytes',0)//1073741824}GB / {data.get('system_disk_total_bytes',0)//1073741824}GB\")
print(f\"Typesense memory: {data.get('typesense_memory_active_bytes',0)//1048576}MB\")
" 2>/dev/null

echo ""
echo "=== Collections ==="
ts_get "/collections" | python3 -c "
import sys, json
for c in json.load(sys.stdin):
    print(f\"Collection: {c['name']} | Docs: {c.get('num_documents',0)} | Fields: {len(c.get('fields',[]))}\")
" 2>/dev/null
```

**Phase 1 outputs:** Cluster health, memory/disk usage, collection list with doc counts and field counts.

### Phase 2: Analysis

```bash
#!/bin/bash

TS_URL="${TYPESENSE_URL:-http://localhost:8108}"
TS_KEY="${TYPESENSE_API_KEY}"

ts_get() {
    curl -s -H "X-TYPESENSE-API-KEY: $TS_KEY" "$TS_URL$1"
}

COLLECTION="${1:-my_collection}"

echo "=== Collection Schema: $COLLECTION ==="
ts_get "/collections/$COLLECTION" | python3 -c "
import sys, json
c = json.load(sys.stdin)
print(f\"Name: {c['name']} | Docs: {c.get('num_documents',0)} | Default sorting: {c.get('default_sorting_field','none')}\")
for f in c.get('fields', []):
    print(f\"  {f['name']}: {f['type']} | facet={f.get('facet',False)} index={f.get('index',True)} optional={f.get('optional',False)}\")
" 2>/dev/null

echo ""
echo "=== Synonyms ==="
ts_get "/collections/$COLLECTION/synonyms" | python3 -c "
import sys, json
data = json.load(sys.stdin)
for s in data.get('synonyms', []):
    print(f\"  {s.get('id','?')}: {s.get('synonyms', s.get('root','?'))}\")
" 2>/dev/null || echo "No synonyms configured"

echo ""
echo "=== Overrides ==="
ts_get "/collections/$COLLECTION/overrides" | python3 -c "
import sys, json
data = json.load(sys.stdin)
for o in data.get('overrides', []):
    print(f\"  {o.get('id','?')}: rule={o.get('rule',{})}\")
" 2>/dev/null || echo "No overrides configured"
```

## Output Format

```
TYPESENSE ANALYSIS
==================
Health: [ok/unhealthy] | Memory: [used]/[total]
Collections: [count] | Total Docs: [count]

ISSUES FOUND:
- [issue with affected collection]

RECOMMENDATIONS:
- [actionable recommendation]
```
