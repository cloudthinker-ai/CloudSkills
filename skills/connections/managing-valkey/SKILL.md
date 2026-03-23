---
name: managing-valkey
description: |
  Use when working with Valkey — valkey (Redis fork) instance management,
  cluster health monitoring, memory analysis, and performance tuning. Covers
  keyspace inspection, replication lag, slow log analysis, client connections,
  and module compatibility checks. Read this skill before any Valkey operations.
connection_type: valkey
preload: false
---

# Valkey Management Skill

Monitor, analyze, and optimize Valkey instances safely.

## MANDATORY: Discovery-First Pattern

**Always run INFO ALL and check cluster mode before any key operations. Never assume key patterns or cluster topology.**

### Phase 1: Discovery

```bash
#!/bin/bash

valkey_cmd() {
    valkey-cli -h "$VALKEY_HOST" -p "${VALKEY_PORT:-6379}" \
               ${VALKEY_PASSWORD:+-a "$VALKEY_PASSWORD"} \
               --no-auth-warning "$@" 2>/dev/null || \
    redis-cli -h "${VALKEY_HOST:-localhost}" -p "${VALKEY_PORT:-6379}" \
              ${VALKEY_PASSWORD:+-a "$VALKEY_PASSWORD"} \
              --no-auth-warning "$@"
}

echo "=== Server Info ==="
valkey_cmd INFO server | grep -E 'valkey_version|redis_version|uptime_in_days|tcp_port|os'

echo ""
echo "=== Memory Overview ==="
valkey_cmd INFO memory | grep -E 'used_memory_human|used_memory_peak_human|maxmemory_human|mem_fragmentation_ratio|maxmemory_policy'

echo ""
echo "=== Keyspace ==="
valkey_cmd INFO keyspace

echo ""
echo "=== Cluster Mode ==="
valkey_cmd CLUSTER INFO 2>/dev/null | head -5 || echo "Standalone mode"

echo ""
echo "=== Clients ==="
valkey_cmd INFO clients | grep -E 'connected_clients|blocked_clients|maxclients'
```

**Phase 1 outputs:** Valkey version, memory usage, keyspace, cluster mode, client count.

### Phase 2: Analysis

```bash
#!/bin/bash

valkey_cmd() {
    valkey-cli -h "$VALKEY_HOST" -p "${VALKEY_PORT:-6379}" \
               ${VALKEY_PASSWORD:+-a "$VALKEY_PASSWORD"} \
               --no-auth-warning "$@" 2>/dev/null || \
    redis-cli -h "${VALKEY_HOST:-localhost}" -p "${VALKEY_PORT:-6379}" \
              ${VALKEY_PASSWORD:+-a "$VALKEY_PASSWORD"} \
              --no-auth-warning "$@"
}

echo "=== Hit Rate ==="
valkey_cmd INFO stats | awk -F: '
    /keyspace_hits/ { hits=$2 }
    /keyspace_misses/ { misses=$2 }
    END {
        total = hits + misses
        if (total > 0) printf "Hit rate: %.1f%% (%s hits, %s misses)\n", hits/total*100, hits, misses
    }'

echo ""
echo "=== Slow Log ==="
valkey_cmd SLOWLOG GET 10

echo ""
echo "=== Replication ==="
valkey_cmd INFO replication | grep -E 'role|connected_slaves|master_link_status|master_last_io'

echo ""
echo "=== Evictions & Expirations ==="
valkey_cmd INFO stats | grep -E 'evicted_keys|expired_keys|total_commands_processed|instantaneous_ops_per_sec'

echo ""
echo "=== Persistence ==="
valkey_cmd INFO persistence | grep -E 'rdb_last_save|rdb_last_bgsave_status|aof_enabled'
```

## Output Format

```
VALKEY ANALYSIS
===============
Version: [version] | Mode: [standalone/cluster]
Memory: [used]/[max] | Keys: [count] | Hit Rate: [pct]%

ISSUES FOUND:
- [issue with affected component]

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

