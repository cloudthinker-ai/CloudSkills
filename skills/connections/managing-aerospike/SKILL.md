---
name: managing-aerospike
description: |
  Aerospike cluster management, namespace utilization, set analysis, and secondary index monitoring. Covers node health, storage engine statistics, migration tracking, UDF management, and XDR cross-datacenter replication status. Read this skill before any Aerospike operations.
connection_type: aerospike
preload: false
---

# Aerospike Management Skill

Monitor, analyze, and optimize Aerospike clusters safely.

## MANDATORY: Discovery-First Pattern

**Always check cluster health and list namespaces before any data operations. Never assume namespace names or set configurations.**

### Phase 1: Discovery

```bash
#!/bin/bash

AS_HOST="${AEROSPIKE_HOST:-localhost}"
AS_PORT="${AEROSPIKE_PORT:-3000}"

echo "=== Cluster Status ==="
asadm -e "info" 2>/dev/null || \
    asinfo -h "$AS_HOST" -p "$AS_PORT" -v "status" 2>/dev/null || \
    curl -s "http://$AS_HOST:8081/v1/cluster" 2>/dev/null

echo ""
echo "=== Node Info ==="
asinfo -h "$AS_HOST" -p "$AS_PORT" -v "build" 2>/dev/null
asinfo -h "$AS_HOST" -p "$AS_PORT" -v "node" 2>/dev/null
asinfo -h "$AS_HOST" -p "$AS_PORT" -v "statistics" 2>/dev/null | tr ';' '\n' | grep -E 'cluster_size|uptime|objects|sub_objects'

echo ""
echo "=== Namespaces ==="
asinfo -h "$AS_HOST" -p "$AS_PORT" -v "namespaces" 2>/dev/null

echo ""
echo "=== Namespace Details ==="
for ns in $(asinfo -h "$AS_HOST" -p "$AS_PORT" -v "namespaces" 2>/dev/null | tr ';' '\n'); do
    echo "--- Namespace: $ns ---"
    asinfo -h "$AS_HOST" -p "$AS_PORT" -v "namespace/$ns" 2>/dev/null | tr ';' '\n' | \
        grep -E 'type|objects|memory_used|device_used|repl-factor|high-water|stop-writes|evicted|expired'
done

echo ""
echo "=== Sets ==="
asinfo -h "$AS_HOST" -p "$AS_PORT" -v "sets" 2>/dev/null | tr ';' '\n' | head -20
```

**Phase 1 outputs:** Cluster size, node versions, namespaces with storage type and capacity, set inventory.

### Phase 2: Analysis

```bash
#!/bin/bash

AS_HOST="${AEROSPIKE_HOST:-localhost}"
AS_PORT="${AEROSPIKE_PORT:-3000}"

echo "=== Storage Engine Stats ==="
for ns in $(asinfo -h "$AS_HOST" -p "$AS_PORT" -v "namespaces" 2>/dev/null | tr ';' '\n'); do
    echo "--- $ns ---"
    asinfo -h "$AS_HOST" -p "$AS_PORT" -v "namespace/$ns" 2>/dev/null | tr ';' '\n' | \
        grep -E 'device_available_pct|device_free_pct|memory_free_pct|cache_read_pct|defrag|migrate'
done

echo ""
echo "=== Migration Status ==="
asinfo -h "$AS_HOST" -p "$AS_PORT" -v "statistics" 2>/dev/null | tr ';' '\n' | grep -E 'migrate'

echo ""
echo "=== Secondary Indexes ==="
asinfo -h "$AS_HOST" -p "$AS_PORT" -v "sindex" 2>/dev/null | tr ';' '\n' | head -10

echo ""
echo "=== XDR Status ==="
asinfo -h "$AS_HOST" -p "$AS_PORT" -v "statistics/xdr" 2>/dev/null | tr ';' '\n' | \
    grep -E 'xdr_ship|xdr_read|xdr_hotkey|xdr_active' | head -10 || echo "XDR not configured"

echo ""
echo "=== UDFs ==="
asinfo -h "$AS_HOST" -p "$AS_PORT" -v "udf-list" 2>/dev/null || echo "No UDFs registered"
```

## Output Format

```
AEROSPIKE ANALYSIS
==================
Cluster Size: [nodes] | Version: [build]
Namespaces: [count] | Total Objects: [count]

ISSUES FOUND:
- [issue with affected namespace/node]

RECOMMENDATIONS:
- [actionable recommendation]
```
