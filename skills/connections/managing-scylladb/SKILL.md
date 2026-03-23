---
name: managing-scylladb
description: |
  Use when working with Scylladb — scyllaDB cluster management, shard-per-core
  analysis, compaction strategy tuning, and CQL performance diagnostics. Covers
  node health, tablet distribution, workload prioritization, repair scheduling,
  and latency histogram analysis. Read this skill before any ScyllaDB
  operations.
connection_type: scylladb
preload: false
---

# ScyllaDB Management Skill

Monitor, analyze, and optimize ScyllaDB clusters safely.

## MANDATORY: Discovery-First Pattern

**Always check cluster status and list keyspaces before any CQL operations. Never assume keyspace or table names.**

### Phase 1: Discovery

```bash
#!/bin/bash

SCYLLA_HOST="${SCYLLADB_HOST:-localhost}"
SCYLLA_PORT="${SCYLLADB_PORT:-9042}"

echo "=== Cluster Status ==="
nodetool -h "$SCYLLA_HOST" status

echo ""
echo "=== Scylla Version ==="
nodetool -h "$SCYLLA_HOST" version

echo ""
echo "=== Keyspaces ==="
cqlsh "$SCYLLA_HOST" "$SCYLLA_PORT" -e "DESCRIBE KEYSPACES;"

echo ""
echo "=== Cluster Description ==="
nodetool -h "$SCYLLA_HOST" describecluster

echo ""
echo "=== Shard Info ==="
curl -s "http://$SCYLLA_HOST:10000/system/uptime_ms" 2>/dev/null
curl -s "http://$SCYLLA_HOST:10000/storage_service/hostid/local" 2>/dev/null
```

**Phase 1 outputs:** Node states, Scylla version, keyspace list, cluster topology, shard count.

### Phase 2: Analysis

```bash
#!/bin/bash

SCYLLA_HOST="${SCYLLADB_HOST:-localhost}"
KEYSPACE="${1:-my_keyspace}"

echo "=== Keyspace Details ==="
cqlsh "$SCYLLA_HOST" -e "DESCRIBE KEYSPACE $KEYSPACE;"

echo ""
echo "=== Table Stats ==="
nodetool -h "$SCYLLA_HOST" tablestats "$KEYSPACE" | grep -E "Table:|Space used|Number of|Compaction|Read Latency|Write Latency" | head -30

echo ""
echo "=== Compaction Stats ==="
nodetool -h "$SCYLLA_HOST" compactionstats

echo ""
echo "=== Scheduling Groups (Workload Prioritization) ==="
curl -s "http://$SCYLLA_HOST:10000/task_manager/list_module_tasks/compaction" 2>/dev/null | head -10

echo ""
echo "=== Repair Status ==="
nodetool -h "$SCYLLA_HOST" repair_status 2>/dev/null || \
    nodetool -h "$SCYLLA_HOST" netstats | grep -A5 "Repair"

echo ""
echo "=== Thread Pool Stats ==="
nodetool -h "$SCYLLA_HOST" tpstats | head -25
```

## Output Format

```
SCYLLADB ANALYSIS
=================
Cluster: [name] | Nodes: [count] | Version: [version]
Keyspaces: [count] | Shards/Node: [count]

ISSUES FOUND:
- [issue with affected keyspace/node]

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

