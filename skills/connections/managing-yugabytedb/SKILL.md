---
name: managing-yugabytedb
description: |
  Use when working with Yugabytedb — yugabyteDB cluster management, tablet
  distribution analysis, YSQL/YCQL performance tuning, and replication
  monitoring. Covers master/tserver health, tablet leader balancing, xCluster
  replication, CDC streams, and distributed transaction diagnostics. Read this
  skill before any YugabyteDB operations.
connection_type: yugabytedb
preload: false
---

# YugabyteDB Management Skill

Monitor, analyze, and optimize YugabyteDB clusters safely.

## MANDATORY: Discovery-First Pattern

**Always check cluster health and list databases/keyspaces before any query operations. Never assume table names or tablet counts.**

### Phase 1: Discovery

```bash
#!/bin/bash

YB_MASTER="${YUGABYTE_MASTER:-localhost:7100}"
YB_TSERVER="${YUGABYTE_TSERVER:-localhost:9000}"
YB_HOST="${YUGABYTE_HOST:-localhost}"

echo "=== Master Health ==="
curl -s "http://${YB_MASTER%:*}:7000/api/v1/health-check" 2>/dev/null || \
    curl -s "http://${YB_MASTER%:*}:7000/status" 2>/dev/null

echo ""
echo "=== Cluster Config ==="
curl -s "http://${YB_MASTER%:*}:7000/api/v1/cluster-config" 2>/dev/null | python3 -c "
import sys, json
data = json.load(sys.stdin)
print(f\"Replication factor: {data.get('replication_info',{}).get('replication_factor','?')}\")
print(f\"Cluster UUID: {data.get('cluster_uuid','?')}\")
" 2>/dev/null

echo ""
echo "=== Tablet Servers ==="
curl -s "http://${YB_MASTER%:*}:7000/api/v1/tablet-servers" 2>/dev/null | python3 -c "
import sys, json
data = json.load(sys.stdin)
for ts in data.get('servers', data if isinstance(data, list) else []):
    print(f\"TServer: {ts.get('host','?')} | Alive: {ts.get('alive','?')} | Tablets: {ts.get('tablet_count','?')} | Read ops: {ts.get('read_ops_per_sec','?')}\")
" 2>/dev/null

echo ""
echo "=== YSQL Databases ==="
ysqlsh -h "$YB_HOST" -c "SELECT datname, pg_size_pretty(pg_database_size(datname)) as size FROM pg_database WHERE datistemplate = false;" 2>/dev/null || \
    psql -h "$YB_HOST" -p 5433 -U yugabyte -c "SELECT datname, pg_size_pretty(pg_database_size(datname)) as size FROM pg_database WHERE datistemplate = false;" 2>/dev/null

echo ""
echo "=== YCQL Keyspaces ==="
ycqlsh "$YB_HOST" -e "DESCRIBE KEYSPACES;" 2>/dev/null || echo "YCQL not available"
```

**Phase 1 outputs:** Master health, tablet server list, database/keyspace inventory, replication factor.

### Phase 2: Analysis

```bash
#!/bin/bash

YB_MASTER="${YUGABYTE_MASTER:-localhost:7100}"
YB_HOST="${YUGABYTE_HOST:-localhost}"

echo "=== Tablet Distribution ==="
curl -s "http://${YB_MASTER%:*}:7000/api/v1/tablet-servers" 2>/dev/null | python3 -c "
import sys, json
data = json.load(sys.stdin)
for ts in data.get('servers', data if isinstance(data, list) else []):
    leader = ts.get('leader_count', '?')
    total = ts.get('tablet_count', '?')
    print(f\"  {ts.get('host','?')}: leaders={leader} total={total}\")
" 2>/dev/null

echo ""
echo "=== Under-Replicated Tablets ==="
curl -s "http://${YB_MASTER%:*}:7000/api/v1/tablets?state=UNDER_REPLICATED" 2>/dev/null | head -10

echo ""
echo "=== YSQL Active Queries ==="
psql -h "$YB_HOST" -p 5433 -U yugabyte -c "SELECT pid, state, query_start, query FROM pg_stat_activity WHERE state != 'idle' LIMIT 10;" 2>/dev/null

echo ""
echo "=== Table Sizes ==="
psql -h "$YB_HOST" -p 5433 -U yugabyte -c "SELECT schemaname, tablename, pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size FROM pg_tables WHERE schemaname NOT IN ('pg_catalog','information_schema') ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC LIMIT 15;" 2>/dev/null
```

## Output Format

```
YUGABYTEDB ANALYSIS
===================
Cluster: [uuid] | RF: [factor] | TServers: [count]
Databases (YSQL): [count] | Keyspaces (YCQL): [count]

ISSUES FOUND:
- [issue with affected table/tablet]

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

