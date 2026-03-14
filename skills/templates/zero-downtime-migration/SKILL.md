---
name: zero-downtime-migration
enabled: true
description: |
  Structured runbook for executing zero-downtime data and service migrations. Covers pre-migration validation, dual-write setup, incremental data sync, cutover orchestration, and rollback procedures to ensure continuous availability throughout the migration process.
required_connections:
  - prefix: aws
    label: "AWS (or cloud provider)"
  - prefix: datadog
    label: "Datadog (or monitoring tool)"
config_fields:
  - key: source_system
    label: "Source System"
    required: true
    placeholder: "e.g., legacy-postgres-cluster"
  - key: target_system
    label: "Target System"
    required: true
    placeholder: "e.g., aurora-postgres-v15"
  - key: migration_window
    label: "Migration Window"
    required: true
    placeholder: "e.g., 2026-04-01 02:00 UTC"
  - key: rollback_deadline
    label: "Rollback Deadline"
    required: false
    placeholder: "e.g., 72 hours post-cutover"
features:
  - DEVOPS
  - MIGRATION
---

# Zero-Downtime Migration Skill

Execute a zero-downtime migration from **{{ source_system }}** to **{{ target_system }}** scheduled for **{{ migration_window }}**.

## Workflow

### Phase 1 — Pre-Migration Assessment

```
PRE-MIGRATION CHECKLIST
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Source system inventory complete:
    - Schema version: ___
    - Data volume: ___ GB
    - Peak QPS: ___
    - Active connections: ___
[ ] Target system provisioned and validated
[ ] Network connectivity verified (source <-> target)
[ ] Schema compatibility confirmed
[ ] Application compatibility tested against target
[ ] Rollback procedure documented and tested
```

### Phase 2 — Dual-Write Configuration

```
DUAL-WRITE SETUP
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Change Data Capture (CDC) pipeline configured
[ ] Dual-write proxy or application-level writes enabled
[ ] Write conflict resolution strategy defined:
    [ ] Last-write-wins
    [ ] Source-priority
    [ ] Custom merge logic
[ ] Dual-write monitoring dashboards deployed
[ ] Write latency impact measured:
    - Baseline write latency: ___ms
    - Dual-write latency: ___ms
    - Acceptable threshold: ___ms
```

### Phase 3 — Historical Data Sync

```
DATA BACKFILL
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Backfill strategy selected:
    [ ] Batch ETL
    [ ] Streaming replay
    [ ] Snapshot + CDC
[ ] Backfill initiated — start time: ___
[ ] Progress tracking:
    - Tables/collections migrated: ___ / ___
    - Records processed: ___ / ___
    - Estimated completion: ___
[ ] Data integrity verification:
    - Row count match: [ ] YES  [ ] NO
    - Checksum validation: [ ] PASS  [ ] FAIL
    - Sample record comparison: [ ] PASS  [ ] FAIL
```

### Phase 4 — Shadow Read Validation

```
SHADOW READS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Shadow read traffic enabled (read from both, compare)
[ ] Comparison results over 24h window:
    - Total reads compared: ___
    - Mismatches found: ___
    - Mismatch rate: ___%
    - Root causes identified for mismatches: [ ] YES
[ ] Performance comparison:
    - Source P95 read latency: ___ms
    - Target P95 read latency: ___ms
[ ] Shadow reads running clean for ___h (target: 24h minimum)
```

### Phase 5 — Cutover Execution

```
CUTOVER
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Final sync lag < 100ms confirmed
[ ] On-call team briefed and standing by
[ ] Communication sent to stakeholders
[ ] Cutover initiated — timestamp: ___

Cutover steps:
[ ] 1. Pause application writes (< 5s window)
[ ] 2. Drain remaining CDC events
[ ] 3. Verify final consistency check
[ ] 4. Switch read/write endpoint to target
[ ] 5. Resume application writes
[ ] 6. Verify writes landing on target system

Total cutover duration: ___s
```

### Phase 6 — Post-Cutover Monitoring

```
POST-CUTOVER VALIDATION (4h window)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
T+15min:
[ ] Error rates within baseline
[ ] Read/write latency within SLO
[ ] No data corruption signals

T+1h:
[ ] All application features verified
[ ] Background jobs executing correctly
[ ] Replication healthy (if applicable)

T+4h:
[ ] Metrics stable across all dashboards
[ ] No customer-reported issues
[ ] Migration declared SUCCESSFUL / ROLLBACK NEEDED
```

### Phase 7 — Rollback (if needed)

```
ROLLBACK PROCEDURE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Trigger criteria:
- Error rate > 5% for 5 minutes
- Data corruption detected
- P95 latency > 3x baseline for 10 minutes

[ ] Switch read/write endpoint back to source
[ ] Re-enable CDC from target to source (reverse sync)
[ ] Verify source system accepting writes
[ ] Notify stakeholders of rollback
[ ] Schedule post-mortem

Rollback deadline: {{ rollback_deadline }}
```

## Output Format

Produce a migration execution report with:
1. **Migration summary** (source, target, timeline, data volume)
2. **Data integrity results** (row counts, checksums, mismatch analysis)
3. **Performance comparison** (latency, throughput before vs after)
4. **Cutover log** (exact timestamps, duration of write pause)
5. **Final status** (SUCCESS / ROLLED BACK) with follow-up actions
