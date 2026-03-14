---
name: managing-apache-kudu
description: |
  Apache Kudu cluster management, tablet server health monitoring, table partition analysis, and replication diagnostics. Covers master health, tablet distribution, column encoding efficiency, compaction metrics, and maintenance window scheduling. Read this skill before any Kudu operations.
connection_type: kudu
preload: false
---

# Apache Kudu Management Skill

Monitor, analyze, and optimize Apache Kudu clusters safely.

## MANDATORY: Discovery-First Pattern

**Always check cluster health and list tables before any data operations. Never assume table names or partition schemas.**

### Phase 1: Discovery

```bash
#!/bin/bash

KUDU_MASTER="${KUDU_MASTER:-localhost:7051}"

echo "=== Cluster Health ==="
kudu cluster ksck "$KUDU_MASTER" --sections=MASTER_SUMMARIES,TSERVER_SUMMARIES 2>&1 | head -30

echo ""
echo "=== Master Info ==="
curl -s "http://${KUDU_MASTER%:*}:8051/api/v1/masters" 2>/dev/null | python3 -c "
import sys, json
data = json.load(sys.stdin)
for m in data.get('masters', []):
    reg = m.get('registration', {})
    print(f\"Master: {reg.get('rpc_addresses',[{}])[0].get('host','?')} | Role: {m.get('role','?')}\")
" 2>/dev/null || echo "Master web UI not available"

echo ""
echo "=== Tablet Servers ==="
kudu tserver list "$KUDU_MASTER" --columns=uuid,rpc-addresses,state 2>&1

echo ""
echo "=== Tables ==="
kudu table list "$KUDU_MASTER" 2>&1

echo ""
echo "=== Table Statistics ==="
for table in $(kudu table list "$KUDU_MASTER" 2>/dev/null); do
    stats=$(kudu table statistics "$KUDU_MASTER" "$table" 2>/dev/null)
    echo "  $table: $stats"
done | head -15
```

**Phase 1 outputs:** Master health, tablet server list, table inventory with statistics.

### Phase 2: Analysis

```bash
#!/bin/bash

KUDU_MASTER="${KUDU_MASTER:-localhost:7051}"
TABLE="${1:-my_table}"

echo "=== Table Schema ==="
kudu table describe "$KUDU_MASTER" "$TABLE" 2>&1

echo ""
echo "=== Partition Info ==="
kudu table list "$KUDU_MASTER" --columns=name,num_tablets,num_replicas 2>&1

echo ""
echo "=== Tablet Distribution ==="
kudu cluster ksck "$KUDU_MASTER" --sections=TABLET_SUMMARIES --tables="$TABLE" 2>&1 | head -20

echo ""
echo "=== Cluster Rebalance Check ==="
kudu cluster rebalance "$KUDU_MASTER" --report_only 2>&1 | head -15

echo ""
echo "=== Health Summary ==="
kudu cluster ksck "$KUDU_MASTER" --sections=CHECKSUM_RESULTS,TOTAL_COUNT 2>&1 | tail -10
```

## Output Format

```
KUDU ANALYSIS
=============
Masters: [count] | TServers: [count] | Status: [healthy/unhealthy]
Tables: [count] | Total Tablets: [count]

ISSUES FOUND:
- [issue with affected table/tablet]

RECOMMENDATIONS:
- [actionable recommendation]
```
