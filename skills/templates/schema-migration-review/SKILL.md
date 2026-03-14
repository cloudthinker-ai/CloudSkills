---
name: schema-migration-review
enabled: true
description: |
  Reviews database schema migrations for safety, performance impact, and backward compatibility. This template ensures migrations are evaluated for lock contention, data integrity, rollback capability, and deployment sequencing before execution in production environments.
required_connections:
  - prefix: database
    label: "Database Platform"
  - prefix: vcs
    label: "Version Control System"
config_fields:
  - key: database_type
    label: "Database Type"
    required: true
    placeholder: "e.g., PostgreSQL, MySQL, MongoDB"
  - key: migration_id
    label: "Migration ID"
    required: true
    placeholder: "e.g., 20260314_add_user_preferences"
  - key: table_row_count
    label: "Affected Table Row Count"
    required: false
    placeholder: "e.g., 50 million"
features:
  - SCHEMA_MIGRATION
  - DATABASE
  - ARCHITECTURE
---

# Schema Migration Review

## Phase 1: Migration Inventory

Document all changes in this migration.

| Change | Table | Column/Index | Operation | Nullable | Default |
|--------|-------|-------------|-----------|----------|---------|
|        |       |             | ADD/DROP/ALTER/RENAME | Y/N | |

## Phase 2: Safety Assessment

**Lock Analysis:**

| Operation | Lock Type | Table Size | Estimated Lock Duration | Acceptable? |
|-----------|----------|------------|------------------------|-------------|
|           | AccessExclusive/ShareLock/None | | | Y/N |

**Safety Checklist:**

- [ ] No `ALTER TABLE` on large tables without online DDL strategy
- [ ] No `DROP COLUMN` without confirming no application reads
- [ ] No `NOT NULL` constraint added without default value
- [ ] No full table rewrite on tables >1M rows during peak hours
- [ ] No index creation without `CONCURRENTLY` (PostgreSQL) or equivalent
- [ ] Foreign key constraints evaluated for lock implications
- [ ] No data type changes that could truncate or corrupt data

## Phase 3: Backward Compatibility

**Decision Matrix:**

| Change Type | Backward Compatible | Strategy |
|-------------|-------------------|----------|
| Add nullable column | Yes | Deploy migration, then code |
| Add non-nullable column with default | Depends on DB | Test lock behavior first |
| Drop column | No | Deploy code ignoring column, then migration |
| Rename column | No | Add new column, migrate data, update code, drop old |
| Change column type | No | Add new column, dual-write, backfill, switch, drop old |
| Add index | Yes (if concurrent) | Deploy anytime |
| Drop index | Yes | Verify no queries depend on it first |

- [ ] Application code compatible with both pre- and post-migration schema
- [ ] Deployment order documented (code first or migration first)
- [ ] Multi-phase migration plan for breaking changes

## Phase 4: Rollback Plan

- [ ] Rollback migration script exists and tested
- [ ] Rollback does not cause data loss
- [ ] Rollback can complete within acceptable downtime window
- [ ] Rollback has been tested against a copy of production data

**Rollback Steps:**

1. - [ ] Step description
2. - [ ] Verification after rollback

## Phase 5: Execution Plan

- [ ] Migration tested against production-size dataset
- [ ] Execution time estimated: ___
- [ ] Maintenance window required: Y/N
- [ ] Application deployment coordination plan
- [ ] Monitoring plan during migration
- [ ] Communication plan for stakeholders

**Pre-execution Checklist:**

- [ ] Database backup taken
- [ ] Replica lag acceptable
- [ ] Connection pool capacity sufficient
- [ ] Statement timeout configured
- [ ] Lock timeout configured

## Output Format

### Summary

- **Migration:** ___
- **Database:** ___
- **Risk level:** Low / Medium / High / Critical
- **Estimated execution time:** ___
- **Backward compatible:** Y/N
- **Requires maintenance window:** Y/N

### Action Items

- [ ] Address all safety checklist failures
- [ ] Test migration on staging with production-size data
- [ ] Test rollback procedure
- [ ] Schedule execution window
- [ ] Notify affected teams
- [ ] Monitor database metrics during and after migration
