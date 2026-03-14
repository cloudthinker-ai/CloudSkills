---
name: database-cloud-migration
enabled: true
description: |
  Guides the migration of databases to cloud-managed services, covering schema compatibility analysis, data transfer methods, replication setup, cutover procedures, and post-migration validation. Supports relational, NoSQL, and data warehouse migrations with minimal data loss risk.
required_connections:
  - prefix: database
    label: "Source Database"
  - prefix: cloud-db
    label: "Target Cloud Database Service"
config_fields:
  - key: source_db_engine
    label: "Source Database Engine"
    required: true
    placeholder: "e.g., PostgreSQL 14, Oracle 19c, MongoDB 6"
  - key: target_db_service
    label: "Target Cloud Database Service"
    required: true
    placeholder: "e.g., Amazon RDS, Cloud SQL, Azure SQL"
  - key: data_volume_gb
    label: "Approximate Data Volume (GB)"
    required: true
    placeholder: "e.g., 500"
features:
  - CLOUD_MIGRATION
  - DATABASE
---

# Database Cloud Migration Plan

## Phase 1: Database Assessment
1. Profile the source database
   - [ ] Database engine and version
   - [ ] Schema count, table count, total data size
   - [ ] Stored procedures, triggers, and functions inventory
   - [ ] Extensions and plugins in use
   - [ ] Connection patterns and peak concurrent connections
2. Identify compatibility issues with target service
3. Document RPO (Recovery Point Objective) and RTO (Recovery Time Objective)
4. Baseline current performance metrics

### Compatibility Checklist

| Feature | Source DB | Target DB | Compatible | Action Needed |
|---------|-----------|-----------|------------|---------------|
| Data types | | | [ ] | |
| Stored procedures | | | [ ] | |
| Triggers | | | [ ] | |
| Extensions | | | [ ] | |
| Character encoding | | | [ ] | |
| Collation | | | [ ] | |

## Phase 2: Migration Method Selection

### Decision Matrix

| Method | Downtime | Complexity | Data Loss Risk | Best For |
|--------|----------|------------|----------------|----------|
| Dump & Restore | High | Low | Low | Small DBs (<50GB) |
| Continuous Replication | Low | High | Very Low | Large production DBs |
| Cloud Migration Service | Medium | Medium | Low | Supported engines |
| Application-level | Variable | Medium | Medium | Schema changes needed |

1. Select migration method based on requirements
2. Plan schema conversion if changing engines
3. Design replication topology for continuous sync
4. Plan cutover window and communication

## Phase 3: Pre-Migration Setup
1. Provision target cloud database instance
2. Configure networking (VPC peering, private endpoints)
3. Set up replication user and permissions on source
4. Test connectivity between source and target
5. Run schema migration or conversion scripts

## Phase 4: Data Migration
1. Execute initial full data load
2. Set up continuous replication (if applicable)
3. Monitor replication lag and error rates
4. Validate row counts and checksums
5. Test application connectivity to target database

## Phase 5: Cutover
1. Stop application writes to source database
2. Wait for replication to catch up (lag = 0)
3. Verify data consistency with checksums
4. Update application connection strings
5. Start application against target database
6. Monitor error rates and performance

## Phase 6: Post-Migration Validation
1. Run data integrity checks (row counts, checksums, spot checks)
2. Execute application test suite against new database
3. Compare query performance against baseline
4. Validate backup and recovery procedures
5. Keep source database available for rollback period

## Output Format
- **Assessment Report**: Source DB profile and compatibility analysis
- **Migration Runbook**: Step-by-step procedures with rollback at each phase
- **Data Validation Report**: Integrity checks and comparison results
- **Performance Comparison**: Query latency before and after migration
- **Cutover Communication**: Timeline and stakeholder notifications

## Action Items
- [ ] Complete source database profiling
- [ ] Resolve compatibility issues identified in assessment
- [ ] Provision and configure target database
- [ ] Execute and validate test migration in staging
- [ ] Schedule production cutover window
- [ ] Monitor target database for 7 days post-migration
- [ ] Decommission source database after stabilization
