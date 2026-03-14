---
name: managing-redis-deep
description: |
  Advanced Redis management including cluster topology, sentinel failover, streams analysis, Lua script auditing, module inspection, and memory defragmentation. Covers RDB/AOF persistence tuning, pub/sub diagnostics, client-side caching, and ACL configuration. Read this skill before any advanced Redis operations.
connection_type: redis
preload: false
---

# Redis Deep Management Skill

Advanced Redis cluster, streams, and module management beyond basic key/value operations.

## MANDATORY: Discovery-First Pattern

**Always run INFO ALL and check cluster/sentinel mode before any advanced operations. Never assume topology or module availability.**

### Phase 1: Discovery

```bash
#!/bin/bash

redis_cmd() {
    redis-cli -h "$REDIS_HOST" -p "${REDIS_PORT:-6379}" \
              ${REDIS_PASSWORD:+-a "$REDIS_PASSWORD"} \
              --no-auth-warning "$@"
}

echo "=== Server & Mode ==="
redis_cmd INFO server | grep -E 'redis_version|redis_mode|os|uptime_in_days|executable|config_file'

echo ""
echo "=== Cluster Detection ==="
redis_cmd CLUSTER INFO 2>/dev/null | head -5 || echo "Cluster mode: disabled"

echo ""
echo "=== Sentinel Detection ==="
redis_cmd INFO sentinel 2>/dev/null | head -10 || echo "Sentinel: not running"

echo ""
echo "=== Loaded Modules ==="
redis_cmd MODULE LIST 2>/dev/null || echo "No modules loaded (or Redis < 4.0)"

echo ""
echo "=== ACL Users ==="
redis_cmd ACL LIST 2>/dev/null | head -10 || echo "ACL not available (Redis < 6.0)"

echo ""
echo "=== Streams Overview ==="
redis_cmd SCAN 0 TYPE stream COUNT 100 2>/dev/null | tail -n +2 | while read key; do
    len=$(redis_cmd XLEN "$key" 2>/dev/null)
    groups=$(redis_cmd XINFO GROUPS "$key" 2>/dev/null | grep -c "name" || echo "0")
    echo "Stream: $key | Length: $len | Groups: $groups"
done
```

**Phase 1 outputs:** Redis version/mode, cluster/sentinel state, loaded modules, ACL users, stream inventory.

### Phase 2: Analysis

```bash
#!/bin/bash

redis_cmd() {
    redis-cli -h "$REDIS_HOST" -p "${REDIS_PORT:-6379}" \
              ${REDIS_PASSWORD:+-a "$REDIS_PASSWORD"} \
              --no-auth-warning "$@"
}

echo "=== Memory Defragmentation ==="
redis_cmd INFO memory | grep -E 'mem_fragmentation|active_defrag|allocator_frag'

echo ""
echo "=== Persistence Health ==="
redis_cmd INFO persistence | grep -E 'rdb_|aof_|loading'

echo ""
echo "=== Pub/Sub Channels ==="
redis_cmd PUBSUB CHANNELS '*' 2>/dev/null | head -10
redis_cmd PUBSUB NUMSUB 2>/dev/null | head -10

echo ""
echo "=== Client List Summary ==="
redis_cmd CLIENT LIST | awk -F'[ =]' '{
    for(i=1;i<=NF;i++) {
        if($i=="cmd") cmd=$(i+1)
        if($i=="flags") flags=$(i+1)
    }
    print cmd, flags
}' | sort | uniq -c | sort -rn | head -10

echo ""
echo "=== Latency History ==="
redis_cmd LATENCY LATEST 2>/dev/null || echo "Latency monitoring not enabled"

echo ""
echo "=== Cluster Slot Coverage ==="
redis_cmd CLUSTER SLOTS 2>/dev/null | head -20 || echo "Not in cluster mode"
```

## Output Format

```
REDIS DEEP ANALYSIS
====================
Version: [version] | Mode: [standalone/cluster/sentinel]
Modules: [list] | Streams: [count]

ISSUES FOUND:
- [issue with affected component]

RECOMMENDATIONS:
- [actionable recommendation]
```
