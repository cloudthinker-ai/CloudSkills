---
name: managing-pinecone
description: |
  Use when working with Pinecone — pinecone vector database management, index
  health monitoring, namespace analysis, and query performance tuning. Covers
  index statistics, dimension configuration, pod utilization, collection
  management, and metadata filtering efficiency. Read this skill before any
  Pinecone operations.
connection_type: pinecone
preload: false
---

# Pinecone Management Skill

Monitor, analyze, and optimize Pinecone vector database instances safely.

## MANDATORY: Discovery-First Pattern

**Always list indexes and check stats before any query or upsert operations. Never assume index names, dimensions, or namespaces.**

### Phase 1: Discovery

```bash
#!/bin/bash

PINECONE_API_KEY="${PINECONE_API_KEY}"
PINECONE_ENV="${PINECONE_ENVIRONMENT}"

pc_get() {
    curl -s -H "Api-Key: $PINECONE_API_KEY" "$1"
}

echo "=== List Indexes ==="
pc_get "https://api.pinecone.io/indexes" | python3 -c "
import sys, json
data = json.load(sys.stdin)
for idx in data.get('indexes', []):
    spec = idx.get('spec', {})
    pod = spec.get('pod', {})
    serverless = spec.get('serverless', {})
    print(f\"Index: {idx['name']} | Dim: {idx.get('dimension','?')} | Metric: {idx.get('metric','?')} | Status: {idx.get('status',{}).get('state','?')}\")
    if pod:
        print(f\"  Type: pod | Env: {pod.get('environment','?')} | Pods: {pod.get('pods',0)} | Replicas: {pod.get('replicas',0)}\")
    if serverless:
        print(f\"  Type: serverless | Cloud: {serverless.get('cloud','?')} | Region: {serverless.get('region','?')}\")
" 2>/dev/null

echo ""
echo "=== Collections ==="
pc_get "https://api.pinecone.io/collections" | python3 -c "
import sys, json
data = json.load(sys.stdin)
for c in data.get('collections', []):
    print(f\"Collection: {c['name']} | Size: {c.get('size',0)//1048576}MB | Vectors: {c.get('vector_count',0)} | Status: {c.get('status','?')}\")
" 2>/dev/null || echo "No collections"
```

**Phase 1 outputs:** Index list with dimensions, metrics, pod/serverless config, collection inventory.

### Phase 2: Analysis

```bash
#!/bin/bash

PINECONE_API_KEY="${PINECONE_API_KEY}"
INDEX="${1:-my_index}"

echo "=== Index Description ==="
curl -s -H "Api-Key: $PINECONE_API_KEY" "https://api.pinecone.io/indexes/$INDEX" | python3 -c "
import sys, json
idx = json.load(sys.stdin)
print(f\"Name: {idx['name']}\")
print(f\"Dimension: {idx.get('dimension','?')}\")
print(f\"Metric: {idx.get('metric','?')}\")
print(f\"Status: {idx.get('status',{}).get('state','?')} | Ready: {idx.get('status',{}).get('ready',False)}\")
host = idx.get('host', '?')
print(f\"Host: {host}\")
" 2>/dev/null

echo ""
echo "=== Index Stats ==="
INDEX_HOST=$(curl -s -H "Api-Key: $PINECONE_API_KEY" "https://api.pinecone.io/indexes/$INDEX" | python3 -c "import sys,json; print(json.load(sys.stdin).get('host',''))" 2>/dev/null)
curl -s -H "Api-Key: $PINECONE_API_KEY" "https://$INDEX_HOST/describe_index_stats" | python3 -c "
import sys, json
data = json.load(sys.stdin)
print(f\"Total vectors: {data.get('totalVectorCount',0)}\")
print(f\"Dimension: {data.get('dimension','?')}\")
print(f\"Index fullness: {data.get('indexFullness',0):.2%}\")
namespaces = data.get('namespaces', {})
print(f\"Namespaces: {len(namespaces)}\")
for ns, info in list(namespaces.items())[:10]:
    print(f\"  '{ns}': {info.get('vectorCount',0)} vectors\")
" 2>/dev/null
```

## Output Format

```
PINECONE ANALYSIS
=================
Indexes: [count] | Type: [pod/serverless]
Total Vectors: [count] | Dimension: [dim] | Fullness: [pct]%

ISSUES FOUND:
- [issue with affected index/namespace]

RECOMMENDATIONS:
- [actionable recommendation]
```

## Anti-Hallucination Rules

1. **NEVER assume resource names** — always discover via CLI/API in Phase 1 before referencing in Phase 2.
2. **NEVER fabricate metric names or dimensions** — verify against the service documentation or `--help` output.
3. **NEVER mix CLI commands between service versions** — confirm which version/API you are targeting.
4. **ALWAYS use the discovery → verify → analyze chain** — every resource referenced must have been discovered first.
5. **ALWAYS handle empty results gracefully** — an empty response is valid data, not an error to retry.

## Counter-Rationalizations

| Shortcut | Counter | Why |
|----------|---------|-----|
| "I'll skip discovery and check known resources" | Always run Phase 1 discovery first | Resource names change, new resources appear — assumed names cause errors |
| "The user only asked for a quick check" | Follow the full discovery → analysis flow | Quick checks miss critical issues; structured analysis catches silent failures |
| "Default configuration is probably fine" | Audit configuration explicitly | Defaults often leave logging, security, and optimization features disabled |
| "Metrics aren't needed for this" | Always check relevant metrics when available | API/CLI responses show current state; metrics reveal trends and intermittent issues |
| "I don't have access to that" | Try the command and report the actual error | Assumed permission failures prevent useful investigation; actual errors are informative |

