---
name: managing-etcd
description: |
  etcd cluster management, member health monitoring, key-space analysis, and Raft consensus diagnostics. Covers endpoint health, leader election status, alarm states, compaction/defragmentation, snapshot management, and watch/lease inspection. Read this skill before any etcd operations.
connection_type: etcd
preload: false
---

# etcd Management Skill

Monitor, analyze, and optimize etcd clusters safely.

## MANDATORY: Discovery-First Pattern

**Always check cluster health and member list before any key operations. Never assume key prefixes or cluster topology.**

### Phase 1: Discovery

```bash
#!/bin/bash

ETCD_ENDPOINTS="${ETCD_ENDPOINTS:-localhost:2379}"
ETCD_OPTS="${ETCD_CACERT:+--cacert=$ETCD_CACERT} ${ETCD_CERT:+--cert=$ETCD_CERT} ${ETCD_KEY:+--key=$ETCD_KEY}"

echo "=== Endpoint Health ==="
etcdctl endpoint health --endpoints="$ETCD_ENDPOINTS" $ETCD_OPTS 2>&1

echo ""
echo "=== Endpoint Status ==="
etcdctl endpoint status --endpoints="$ETCD_ENDPOINTS" $ETCD_OPTS -w table 2>&1

echo ""
echo "=== Member List ==="
etcdctl member list --endpoints="$ETCD_ENDPOINTS" $ETCD_OPTS -w table 2>&1

echo ""
echo "=== Alarms ==="
etcdctl alarm list --endpoints="$ETCD_ENDPOINTS" $ETCD_OPTS 2>&1

echo ""
echo "=== Version ==="
etcdctl version 2>&1
```

**Phase 1 outputs:** Endpoint health, leader ID, Raft term/index, member list, active alarms.

### Phase 2: Analysis

```bash
#!/bin/bash

ETCD_ENDPOINTS="${ETCD_ENDPOINTS:-localhost:2379}"
ETCD_OPTS="${ETCD_CACERT:+--cacert=$ETCD_CACERT} ${ETCD_CERT:+--cert=$ETCD_CERT} ${ETCD_KEY:+--key=$ETCD_KEY}"

echo "=== DB Size per Member ==="
etcdctl endpoint status --endpoints="$ETCD_ENDPOINTS" $ETCD_OPTS -w json 2>/dev/null | python3 -c "
import sys, json
data = json.load(sys.stdin)
for ep in (data if isinstance(data, list) else [data]):
    status = ep.get('Status', ep)
    print(f\"  Endpoint: {ep.get('Endpoint','?')} | DB size: {status.get('dbSize',0)//1048576}MB | Leader: {status.get('leader','?')} | RaftIndex: {status.get('raftIndex','?')}\")
" 2>/dev/null

echo ""
echo "=== Key Count by Prefix (top-level) ==="
etcdctl get / --prefix --keys-only --endpoints="$ETCD_ENDPOINTS" $ETCD_OPTS 2>/dev/null | \
    awk -F'/' '{if(NF>1) print "/"$2}' | sort | uniq -c | sort -rn | head -15

echo ""
echo "=== Active Leases ==="
etcdctl lease list --endpoints="$ETCD_ENDPOINTS" $ETCD_OPTS 2>/dev/null | head -10

echo ""
echo "=== Auth Status ==="
etcdctl auth status --endpoints="$ETCD_ENDPOINTS" $ETCD_OPTS 2>&1

echo ""
echo "=== Compaction Info ==="
etcdctl endpoint status --endpoints="$ETCD_ENDPOINTS" $ETCD_OPTS -w json 2>/dev/null | python3 -c "
import sys, json
data = json.load(sys.stdin)
for ep in (data if isinstance(data, list) else [data]):
    status = ep.get('Status', ep)
    print(f\"  Raft term: {status.get('raftTerm','?')} | Applied: {status.get('raftApplied', status.get('raftIndex','?'))}\")
" 2>/dev/null
```

## Output Format

```
ETCD ANALYSIS
=============
Members: [count] | Leader: [member_id]
DB Size: [size] | Raft Term: [term] | Alarms: [count]

ISSUES FOUND:
- [issue with affected member/alarm]

RECOMMENDATIONS:
- [actionable recommendation]
```
