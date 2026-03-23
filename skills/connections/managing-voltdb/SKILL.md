---
name: managing-voltdb
description: |
  Use when working with Voltdb — voltDB cluster management, stored procedure
  performance analysis, partition tuning, and export stream monitoring. Covers
  cluster topology, DR replication, snapshot schedules, command log health, and
  latency histogram analysis. Read this skill before any VoltDB operations.
connection_type: voltdb
preload: false
---

# VoltDB Management Skill

Monitor, analyze, and optimize VoltDB clusters safely.

## MANDATORY: Discovery-First Pattern

**Always check cluster status and list tables before any SQL operations. Never assume table names or stored procedure availability.**

### Phase 1: Discovery

```bash
#!/bin/bash

VOLT_HOST="${VOLTDB_HOST:-localhost}"
VOLT_PORT="${VOLTDB_PORT:-21211}"

echo "=== Cluster Status ==="
curl -s "http://$VOLT_HOST:$VOLT_PORT/api/1.0/?Procedure=@SystemInformation&Parameters=%5B%22overview%22%5D" 2>/dev/null | python3 -c "
import sys, json
data = json.load(sys.stdin)
for row in data.get('results', [{}])[0].get('data', []):
    print(f\"  {row[1]}: {row[2]}\")
" 2>/dev/null | grep -E 'VERSION|HOSTNAME|CLUSTERID|STARTTIME|UPTIME|HOSTCOUNT' || echo "HTTP API not available"

echo ""
echo "=== Tables ==="
sqlcmd --servers="$VOLT_HOST" --port="${VOLTDB_CLIENT_PORT:-21212}" --query="SELECT TABLE_NAME, TABLE_TYPE, ESTIMATED_TUPLE_COUNT FROM TABLES ORDER BY ESTIMATED_TUPLE_COUNT DESC;" 2>/dev/null | head -20

echo ""
echo "=== Stored Procedures ==="
sqlcmd --servers="$VOLT_HOST" --port="${VOLTDB_CLIENT_PORT:-21212}" --query="SELECT PROCEDURE_NAME, PARTITION_PARAMETER FROM PROCEDUREDETAIL GROUP BY PROCEDURE_NAME, PARTITION_PARAMETER;" 2>/dev/null | head -15

echo ""
echo "=== System Procedures ==="
sqlcmd --servers="$VOLT_HOST" --port="${VOLTDB_CLIENT_PORT:-21212}" --query="EXEC @SystemInformation OVERVIEW;" 2>/dev/null | head -20
```

**Phase 1 outputs:** Cluster version, host count, table inventory with row estimates, stored procedures.

### Phase 2: Analysis

```bash
#!/bin/bash

VOLT_HOST="${VOLTDB_HOST:-localhost}"

echo "=== Procedure Statistics ==="
sqlcmd --servers="$VOLT_HOST" --port="${VOLTDB_CLIENT_PORT:-21212}" --query="SELECT PROCEDURE, INVOCATIONS, AVG_EXECUTION_TIME, MAX_EXECUTION_TIME FROM PROCEDUREPROFILE ORDER BY AVG_EXECUTION_TIME DESC LIMIT 10;" 2>/dev/null

echo ""
echo "=== Partition Info ==="
sqlcmd --servers="$VOLT_HOST" --port="${VOLTDB_CLIENT_PORT:-21212}" --query="SELECT PARTITION_ID, HOST_ID, CURRENT_ACTIVE_TRANSACTION_COUNT FROM PARTITIONCOUNT;" 2>/dev/null | head -15

echo ""
echo "=== DR Status ==="
sqlcmd --servers="$VOLT_HOST" --port="${VOLTDB_CLIENT_PORT:-21212}" --query="EXEC @Statistics DRROLE, 0;" 2>/dev/null | head -10 || echo "DR not configured"

echo ""
echo "=== Snapshot Status ==="
sqlcmd --servers="$VOLT_HOST" --port="${VOLTDB_CLIENT_PORT:-21212}" --query="EXEC @Statistics SNAPSHOTSTATUS, 0;" 2>/dev/null | head -10

echo ""
echo "=== Memory Usage ==="
sqlcmd --servers="$VOLT_HOST" --port="${VOLTDB_CLIENT_PORT:-21212}" --query="EXEC @Statistics MEMORY, 0;" 2>/dev/null | head -10

echo ""
echo "=== Latency ==="
sqlcmd --servers="$VOLT_HOST" --port="${VOLTDB_CLIENT_PORT:-21212}" --query="EXEC @Statistics LATENCY, 0;" 2>/dev/null | head -10
```

## Output Format

```
VOLTDB ANALYSIS
===============
Cluster: [id] | Hosts: [count] | Version: [version]
Tables: [count] | Procedures: [count] | Partitions: [count]

ISSUES FOUND:
- [issue with affected procedure/partition]

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

