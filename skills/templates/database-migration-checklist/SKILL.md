---
name: database-migration-checklist
enabled: true
description: |
  Use when performing database migration checklist — database migration safety
  checklist covering pre-migration validation, backup verification,
  compatibility checks, migration execution, data validation, rollback
  procedures, and post-migration monitoring. Use for schema changes, engine
  migrations, or data platform transitions.
required_connections:
  - prefix: github
    label: "GitHub (for migration scripts)"
config_fields:
  - key: source_db
    label: "Source Database"
    required: true
    placeholder: "e.g., PostgreSQL 14 (prod-db-1)"
  - key: target_db
    label: "Target Database"
    required: true
    placeholder: "e.g., PostgreSQL 16 (prod-db-2)"
  - key: migration_type
    label: "Migration Type"
    required: true
    placeholder: "e.g., schema-change, engine-upgrade, platform-migration"
features:
  - DATABASE
  - DEPLOYMENT
---

# Database Migration Checklist Skill

Execute a safe database migration from **{{ source_db }}** to **{{ target_db }}** ({{ migration_type }}).

## Workflow

### Step 1 — Migration Assessment

```
MIGRATION SCOPE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Source: {{ source_db }}
Target: {{ target_db }}
Type: {{ migration_type }}

[ ] Database size documented: ___ GB
[ ] Number of tables/collections: ___
[ ] Active connections (peak): ___
[ ] Write throughput (peak): ___ ops/sec
[ ] Estimated migration duration: ___
[ ] Maintenance window required: YES / NO
[ ] Zero-downtime migration possible: YES / NO
```

### Step 2 — Pre-Migration Checklist

```
PRE-MIGRATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
BACKUP & RECOVERY
[ ] Full backup taken and verified (test restore)
[ ] Point-in-time recovery confirmed working
[ ] Backup stored in separate region/account
[ ] Backup retention extended for migration window

COMPATIBILITY
[ ] Schema compatibility verified on target
[ ] Data type compatibility checked (edge cases: dates, JSON, arrays)
[ ] Character encoding confirmed (UTF-8 consistency)
[ ] Stored procedures / functions compatible with target
[ ] Views and materialized views compatible
[ ] Triggers and constraints reviewed
[ ] Extensions / plugins available on target
[ ] Application ORM compatibility tested

TESTING
[ ] Migration script tested on staging with production-size data
[ ] Application tested against target database version
[ ] Performance benchmarks captured on staging
[ ] Query plan analysis on critical queries (no regressions)
[ ] Connection string changes tested in application config
```

### Step 3 — Migration Execution Plan

```
EXECUTION PLAN
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
T-24h:
  [ ] Final staging test pass confirmed
  [ ] Notify stakeholders of migration window
  [ ] Verify monitoring dashboards ready
  [ ] Pre-create target database infrastructure

T-1h:
  [ ] Take fresh backup of source database
  [ ] Verify backup integrity
  [ ] Reduce application traffic (if applicable)
  [ ] Pause non-critical batch jobs and crons

T-0 (Migration Start):
  [ ] Enable maintenance mode (if downtime required)
  [ ] Stop writes to source (if not live migration)
  [ ] Record current WAL/binlog position
  [ ] Execute migration script / start replication
  [ ] Monitor migration progress

During Migration:
  [ ] Track replication lag (if live migration)
  [ ] Monitor source database load
  [ ] Monitor target database health
  [ ] Log any errors or warnings
```

### Step 4 — Data Validation

```
DATA VALIDATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Row counts match: source vs target (per table)
[ ] Checksum validation on critical tables
[ ] Spot-check recent records (last 1000 rows)
[ ] Verify auto-increment / sequence values
[ ] Validate foreign key relationships intact
[ ] Check indexes exist and are valid on target
[ ] Verify constraints (unique, check, not-null) on target
[ ] Test critical queries return identical results
[ ] Verify data in special columns (JSON, arrays, bytea)
```

### Step 5 — Cutover

```
CUTOVER STEPS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Final replication caught up (lag = 0)
[ ] Stop writes to source database
[ ] Verify final data consistency
[ ] Update application connection strings to target
[ ] Deploy application with new connection config
[ ] Verify application health checks pass
[ ] Verify read and write operations work
[ ] Disable maintenance mode
[ ] Monitor error rates for 30 minutes
```

### Step 6 — Rollback Procedure

```
ROLLBACK PLAN
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Rollback window: [X hours after cutover]
Rollback trigger: [error rate >X%, latency >Xms, data corruption]

Steps:
1. [ ] Revert application connection strings to source
2. [ ] Deploy application with original config
3. [ ] Verify source database is current (apply delta if needed)
4. [ ] Confirm application healthy against source
5. [ ] Investigate failure cause before retry
6. [ ] Document what went wrong
```

### Step 7 — Post-Migration

```
POST-MIGRATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Immediate (0-24h):
[ ] Monitor query performance (no regressions)
[ ] Monitor connection pool utilization
[ ] Monitor replication (if applicable)
[ ] Verify backup schedule running on target
[ ] Verify monitoring alerts configured for target

Short-term (1-7 days):
[ ] Decommission source database (after safe period)
[ ] Update documentation and runbooks
[ ] Update infrastructure-as-code
[ ] Remove old connection strings and credentials
[ ] Close migration tracking ticket
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

Produce a migration execution report with:
1. **Migration summary** (source, target, type, size, duration)
2. **Pre-migration checklist** results with PASS/FAIL
3. **Execution log** with timestamps for each step
4. **Data validation** results with row counts and checksums
5. **Post-migration** monitoring observations
6. **Issues encountered** and resolutions
