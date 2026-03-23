---
name: database-migration-review
enabled: true
description: |
  Use when performing database migration review — database migration PR review
  template covering migration safety, rollback planning, table locking analysis,
  data integrity validation, and production deployment strategy. Provides a
  systematic framework for reviewing schema changes, data migrations, and index
  modifications to prevent downtime and data loss.
required_connections:
  - prefix: github
    label: "GitHub"
config_fields:
  - key: repository
    label: "Repository"
    required: true
    placeholder: "e.g., org/backend-service"
  - key: pr_number
    label: "PR Number"
    required: true
    placeholder: "e.g., 1234"
  - key: database_engine
    label: "Database Engine"
    required: true
    placeholder: "e.g., PostgreSQL, MySQL, MongoDB"
features:
  - CODE_REVIEW
---

# Database Migration Review Skill

Review database migration in PR **#{{ pr_number }}** in **{{ repository }}** for **{{ database_engine }}**.

## Workflow

### Phase 1 — Migration Safety

```
SAFETY CHECK
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Locking analysis:
    [ ] ALTER TABLE operations assessed for lock duration
    [ ] Large table migrations use online DDL or batching
    [ ] No exclusive locks on high-traffic tables during peak
    [ ] Lock timeout configured
[ ] Backward compatibility:
    [ ] Migration is backward-compatible with current code
    [ ] Column renames use add-copy-drop pattern
    [ ] Column type changes are safe (no data truncation)
    [ ] NOT NULL additions have default values
    [ ] New columns are nullable or have defaults
[ ] Data integrity:
    [ ] Foreign key constraints validated
    [ ] CHECK constraints tested with existing data
    [ ] UNIQUE constraints verified against current data
    [ ] No orphaned records after migration
```

### Phase 2 — Rollback Plan

```
ROLLBACK ASSESSMENT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Down migration provided: YES / NO
[ ] Down migration tested: YES / NO
[ ] Rollback is data-safe (no data loss on rollback): YES / NO
[ ] Rollback time estimate: ___
[ ] Point-of-no-return identified: YES / NO
[ ] If irreversible, backup strategy documented: YES / NO
[ ] Rollback steps documented for on-call: YES / NO
```

### Phase 3 — Performance Impact

```
PERFORMANCE IMPACT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Index changes:
    [ ] New indexes justified by query patterns
    [ ] Index creation uses CONCURRENTLY (PostgreSQL)
    [ ] Unused indexes identified for removal
    [ ] Composite index column order is optimal
[ ] Table size impact:
    [ ] Estimated table size after migration: ___
    [ ] Migration duration estimate: ___
    [ ] Disk space requirements: ___
[ ] Query impact:
    [ ] Existing queries tested with new schema
    [ ] Query plans reviewed post-migration
    [ ] ORM model changes aligned with schema
```

### Phase 4 — Deployment Strategy

```
DEPLOYMENT PLAN
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Migration sequence:
    1. Deploy migration (schema change)
    2. Deploy application code
    3. Verify application health
    4. Clean up (drop old columns if needed)
[ ] Maintenance window required: YES / NO
[ ] Expected downtime: ___
[ ] Pre-migration checklist:
    [ ] Database backup taken
    [ ] Migration tested on staging with production-size data
    [ ] Monitoring alerts configured
    [ ] Communication sent to stakeholders
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

Produce a migration review report with:
1. **Risk assessment** (safe / caution / dangerous)
2. **Locking impact analysis** per operation
3. **Rollback plan evaluation** (reversible / partially / irreversible)
4. **Deployment recommendations** (online / maintenance window / phased)
5. **Specific concerns** with remediation steps
