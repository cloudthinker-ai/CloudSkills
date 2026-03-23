---
name: runbook-database-failover
enabled: true
description: |
  Use when performing runbook database failover — database failover procedure
  covering pre-checks, failover execution, validation, and DNS update. Use when
  performing planned database failover, responding to primary database failure,
  or testing failover readiness.
required_connections: []
config_fields:
  - key: database_name
    label: "Database Name"
    required: true
    placeholder: "e.g., prod-users-primary"
  - key: db_engine
    label: "Database Engine"
    required: true
    placeholder: "e.g., PostgreSQL, MySQL, Aurora"
  - key: primary_endpoint
    label: "Primary Endpoint"
    required: true
    placeholder: "e.g., db-primary.internal.example.com"
  - key: replica_endpoint
    label: "Replica / Standby Endpoint"
    required: false
    placeholder: "e.g., db-replica.internal.example.com"
  - key: failover_reason
    label: "Failover Reason"
    required: false
    placeholder: "e.g., planned maintenance, primary degradation"
features:
  - RUNBOOK
  - DATABASE
---

# Database Failover Runbook Skill

Execute database failover for **{{ database_name }}** ({{ db_engine }}).
Failover from **{{ primary_endpoint }}** to **{{ replica_endpoint }}**.
Reason: **{{ failover_reason }}**

## Workflow

### Phase 1 — Pre-Failover Checks

```
PRE-FAILOVER CHECKLIST
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
REPLICATION HEALTH
[ ] Replication lag < 1 second on standby
[ ] Replication status: streaming / in-sync
[ ] No replication errors in last 24 hours
[ ] WAL / binlog position confirmed on both nodes

STANDBY VALIDATION
[ ] Standby is reachable: {{ replica_endpoint }}
[ ] Standby read queries returning correct data
[ ] Standby resource utilization acceptable (CPU, memory, disk)
[ ] Standby has identical schema version as primary
[ ] Standby connection pool capacity sufficient

APPLICATION READINESS
[ ] All application connection strings use DNS / virtual endpoint
[ ] No long-running transactions on primary
[ ] No active schema migrations or DDL operations
[ ] Maintenance window communicated to stakeholders
[ ] On-call engineer confirmed available
```

### Phase 2 — Pre-Failover Preparation

```
PREPARATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Create fresh backup of primary database
[ ] Record current primary state:
    - Active connections: ___
    - Transactions per second: ___
    - Replication lag: ___ ms
    - WAL/binlog position: ___
[ ] Pause non-critical batch jobs and cron tasks
[ ] Reduce application connection pool sizes (if possible)
[ ] Drain active connections gracefully (planned failover only)
[ ] Notify monitoring team to expect alerts
```

### Phase 3 — Failover Execution

```
FAILOVER EXECUTION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PLANNED FAILOVER:
1. [ ] Stop writes to primary (set read-only or block connections)
2. [ ] Wait for replication lag to reach zero
3. [ ] Promote standby to primary role
4. [ ] Record promotion timestamp: ___
5. [ ] Verify new primary accepts writes (test INSERT)

UNPLANNED FAILOVER:
1. [ ] Confirm primary is unavailable / degraded
2. [ ] Check replication lag at time of failure: ___ ms
3. [ ] Accept potential data loss window: ___ transactions
4. [ ] Force-promote standby to primary
5. [ ] Record promotion timestamp: ___
6. [ ] Verify new primary accepts writes (test INSERT)
```

### Phase 4 — DNS and Endpoint Update

```
DNS / ENDPOINT UPDATE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Update DNS record: {{ primary_endpoint }} -> new primary IP
[ ] Update virtual IP or proxy target (if applicable)
[ ] Update connection string in secrets manager (if hardcoded)
[ ] Verify DNS propagation (dig {{ primary_endpoint }})
[ ] Confirm applications reconnecting to new primary
[ ] Check connection count stabilizing on new primary
```

### Phase 5 — Post-Failover Validation

```
POST-FAILOVER VALIDATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
HEALTH CHECKS (at T+5min, T+15min, T+1h)
[ ] New primary accepting reads and writes
[ ] Query latency within baseline (p50/p95/p99)
[ ] Error rate returned to normal
[ ] Connection pool utilization stable
[ ] No deadlocks or lock contention

DATA INTEGRITY
[ ] Row counts match expected values on critical tables
[ ] Recent transactions visible (spot-check latest records)
[ ] Auto-increment / sequence values correct
[ ] Foreign key constraints intact

APPLICATION HEALTH
[ ] All application instances connected to new primary
[ ] API response times within SLA
[ ] No 5xx errors related to database connectivity
[ ] Background jobs processing successfully
```

### Phase 6 — Rebuild Standby and Cleanup

```
REBUILD STANDBY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Configure old primary as new standby (or provision new standby)
[ ] Start replication from new primary to new standby
[ ] Verify replication streaming and lag decreasing
[ ] Wait for standby to fully catch up
[ ] Test read queries on new standby

CLEANUP
[ ] Re-enable batch jobs and cron tasks
[ ] Restore normal connection pool sizes
[ ] Update runbook with new primary/standby endpoints
[ ] Update monitoring targets and alert thresholds
[ ] Notify stakeholders of completed failover
[ ] Document any data loss or issues encountered
```

## Counter-Rationalizations

| Shortcut | Counter | Why |
|----------|---------|-----|
| "We can skip some steps for this case" | Adapt the workflow steps, don't skip them | Skipped steps are where incidents and oversights originate |
| "The user seems to already know what to do" | Complete all workflow phases with the user | The workflow catches blind spots that experience alone misses |
| "This is a minor case, full process is overkill" | Scale the process down, don't turn it off | Minor cases become major when unstructured; the process scales, not disappears |
| "I'll fill in the details later" | Complete each section before moving on | Deferred details are forgotten; real-time capture is more accurate |
| "The template output isn't necessary" | Always produce the structured output format | Structured output enables comparison, audit trails, and handoff to other teams |

## Output Format

Produce a database failover execution report with:
1. **Failover summary** (database, engine, reason, timestamps)
2. **Pre-failover health** snapshot (replication lag, connection count)
3. **Execution log** with step-by-step confirmation
4. **DNS update** confirmation and propagation status
5. **Post-failover validation** results (latency, error rate, data integrity)
6. **Standby rebuild** status and next steps
