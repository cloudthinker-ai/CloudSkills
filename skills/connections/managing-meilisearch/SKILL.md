---
name: managing-meilisearch
description: |
  Meilisearch index management, search performance analysis, ranking rule optimization, and filterable/sortable attribute configuration. Covers index health, task queues, document counts, typo tolerance settings, and API key management. Read this skill before any Meilisearch operations.
connection_type: meilisearch
preload: false
---

# Meilisearch Management Skill

Monitor, analyze, and optimize Meilisearch instances safely.

## MANDATORY: Discovery-First Pattern

**Always check instance health and list indexes before any search or config operations. Never assume index UIDs or field names.**

### Phase 1: Discovery

```bash
#!/bin/bash

MEILI_URL="${MEILI_URL:-http://localhost:7700}"
MEILI_AUTH="${MEILI_MASTER_KEY:+Authorization: Bearer $MEILI_MASTER_KEY}"

echo "=== Instance Health ==="
curl -s "$MEILI_URL/health" ${MEILI_AUTH:+-H "$MEILI_AUTH"}

echo ""
echo "=== Version ==="
curl -s "$MEILI_URL/version" ${MEILI_AUTH:+-H "$MEILI_AUTH"}

echo ""
echo "=== Indexes ==="
curl -s "$MEILI_URL/indexes?limit=100" ${MEILI_AUTH:+-H "$MEILI_AUTH"} | python3 -c "
import sys, json
data = json.load(sys.stdin)
for idx in data.get('results', []):
    print(f\"Index: {idx['uid']} | PrimaryKey: {idx.get('primaryKey','none')} | Docs: {idx.get('numberOfDocuments','?')} | Created: {idx.get('createdAt','?')}\")
" 2>/dev/null

echo ""
echo "=== Stats ==="
curl -s "$MEILI_URL/stats" ${MEILI_AUTH:+-H "$MEILI_AUTH"} | python3 -c "
import sys, json
data = json.load(sys.stdin)
print(f\"Database size: {data.get('databaseSize',0)//1048576}MB\")
for idx, stats in data.get('indexes', {}).items():
    print(f\"  {idx}: {stats.get('numberOfDocuments',0)} docs, fields: {list(stats.get('fieldDistribution',{}).keys())[:5]}\")
" 2>/dev/null

echo ""
echo "=== Recent Tasks ==="
curl -s "$MEILI_URL/tasks?limit=10" ${MEILI_AUTH:+-H "$MEILI_AUTH"} | python3 -c "
import sys, json
data = json.load(sys.stdin)
for t in data.get('results', []):
    print(f\"Task {t['uid']}: {t['type']} | {t['status']} | Index: {t.get('indexUid','?')}\")
" 2>/dev/null
```

**Phase 1 outputs:** Instance version, index list with doc counts, field distributions, recent task status.

### Phase 2: Analysis

```bash
#!/bin/bash

MEILI_URL="${MEILI_URL:-http://localhost:7700}"
MEILI_AUTH="${MEILI_MASTER_KEY:+Authorization: Bearer $MEILI_MASTER_KEY}"
INDEX="${1:-my_index}"

echo "=== Index Settings: $INDEX ==="
curl -s "$MEILI_URL/indexes/$INDEX/settings" ${MEILI_AUTH:+-H "$MEILI_AUTH"} | python3 -c "
import sys, json
s = json.load(sys.stdin)
print(f\"Ranking rules: {s.get('rankingRules',[])}\")
print(f\"Searchable: {s.get('searchableAttributes',['*'])}\")
print(f\"Filterable: {s.get('filterableAttributes',[])}\")
print(f\"Sortable: {s.get('sortableAttributes',[])}\")
print(f\"Typo tolerance: {s.get('typoTolerance',{}).get('enabled', True)}\")
print(f\"Pagination limit: {s.get('pagination',{}).get('maxTotalHits', 1000)}\")
" 2>/dev/null

echo ""
echo "=== Failed Tasks ==="
curl -s "$MEILI_URL/tasks?statuses=failed&limit=5" ${MEILI_AUTH:+-H "$MEILI_AUTH"} | python3 -c "
import sys, json
data = json.load(sys.stdin)
for t in data.get('results', []):
    err = t.get('error', {})
    print(f\"Task {t['uid']}: {t['type']} | {err.get('message','?')}\")
" 2>/dev/null || echo "No failed tasks"
```

## Output Format

```
MEILISEARCH ANALYSIS
====================
Version: [version] | Health: [available/unavailable]
Indexes: [count] | Total Docs: [count] | DB Size: [size]

ISSUES FOUND:
- [issue with affected index]

RECOMMENDATIONS:
- [actionable recommendation]
```
