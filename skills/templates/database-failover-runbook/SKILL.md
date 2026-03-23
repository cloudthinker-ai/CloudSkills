---
name: database-failover-runbook
enabled: true
description: |
  Use when performing database failover runbook — step-by-step runbook for
  executing controlled and emergency database failovers. Covers pre-failover
  health checks, replication lag verification, connection draining, promotion of
  standby, application reconnection, and post-failover validation to minimize
  data loss and downtime.
required_connections:
  - prefix: aws
    label: "AWS (or cloud provider)"
  - prefix: pagerduty
    label: "PagerDuty (or alerting tool)"
config_fields:
  - key: database_cluster
    label: "Database Cluster Name"
    required: true
    placeholder: "e.g., prod-orders-postgres"
  - key: database_engine
    label: "Database Engine"
    required: true
    placeholder: "e.g., PostgreSQL 15, MySQL 8, Aurora"
  - key: failover_type
    label: "Failover Type"
    required: true
    placeholder: "e.g., planned, emergency"
features:
  - DEVOPS
  - RUNBOOK
---

# Database Failover Runbook

Execute a **{{ failover_type }}** failover for database cluster **{{ database_cluster }}** ({{ database_engine }}).

## Workflow

### Phase 1 — Pre-Failover Assessment

```
CLUSTER STATUS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Current primary node: ___
[ ] Standby/replica node(s): ___
[ ] Replication lag: ___ms (must be < 1s for planned failover)
[ ] Replication status: STREAMING / ASYNC / SYNC
[ ] Active connections on primary: ___
[ ] Long-running transactions: [ ] NONE  [ ] IDENTIFIED
[ ] Last successful backup: ___
```

### Phase 2 — Pre-Failover Checklist

```
READINESS CHECKS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Standby node is healthy and accepting read queries
[ ] Replication lag is within acceptable threshold
[ ] No active DDL operations in progress
[ ] Application connection pool supports failover
[ ] DNS TTL is low enough for endpoint switch (current TTL: ___s)
[ ] On-call team notified of failover window
[ ] Monitoring dashboards open and visible
[ ] Rollback plan reviewed

DECISION MATRIX
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Condition                    | Planned | Emergency
Replication lag < 1s         | REQUIRED| BEST EFFORT
Long transactions drained    | REQUIRED| SKIP
Stakeholder notification     | REQUIRED| POST-HOC
Backup verified              | REQUIRED| REQUIRED
```

### Phase 3 — Execute Failover

```
FAILOVER EXECUTION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Timestamp of failover initiation: ___

For planned failover:
  [ ] 1. Set primary to read-only mode
  [ ] 2. Wait for replication lag to reach 0
  [ ] 3. Promote standby to primary
  [ ] 4. Update DNS/endpoint to new primary
  [ ] 5. Verify new primary accepting writes

For emergency failover:
  [ ] 1. Promote standby immediately
  [ ] 2. Update DNS/endpoint to new primary
  [ ] 3. Verify new primary accepting writes
  [ ] 4. Assess data loss window (last lag value: ___ms)

[ ] Failover complete — timestamp: ___
[ ] Total failover duration: ___s
```

### Phase 4 — Post-Failover Validation

```
POST-FAILOVER CHECKS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] New primary accepting read and write queries
[ ] Application connections re-established:
    - Connection count: ___
    - Connection errors: ___
[ ] Query performance baseline met:
    - P50 latency: ___ms
    - P95 latency: ___ms
[ ] No data integrity issues detected
[ ] Old primary reconfigured as standby (if recoverable)
[ ] Replication re-established to new standby
[ ] Monitoring alerts updated for new topology
```

### Phase 5 — Recovery and Documentation

```
RECOVERY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Old primary recovered and added as replica
[ ] Replication verified on new replica
[ ] Backup schedule validated on new primary
[ ] Failover event documented in incident log
[ ] Runbook updated with any lessons learned
[ ] Stakeholders notified of completion
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

Produce a failover execution report with:
1. **Failover summary** (cluster, type, timeline, duration)
2. **Replication status** at time of failover (lag, data loss window)
3. **Application impact** (connection errors, downtime duration)
4. **Post-failover health** (performance metrics, replication status)
5. **Action items** for follow-up (topology hardening, runbook updates)
