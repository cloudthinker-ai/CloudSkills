---
name: data-loss-incident-response
enabled: true
description: |
  Use when performing data loss incident response — data loss and data
  corruption incident response playbook covering immediate containment, impact
  assessment, recovery procedures from backups and replicas, data integrity
  verification, customer notification, and preventive measures. Guides teams
  through the critical decisions required when data is lost, corrupted, or
  inadvertently modified.
required_connections:
  - prefix: slack
    label: "Slack (for incident coordination)"
config_fields:
  - key: data_type
    label: "Type of Data Affected"
    required: true
    placeholder: "e.g., user records, transaction logs, configuration data"
  - key: incident_description
    label: "Incident Description"
    required: true
    placeholder: "e.g., Accidental deletion of production database table"
  - key: database_system
    label: "Database/Storage System"
    required: false
    placeholder: "e.g., PostgreSQL, MongoDB, S3"
features:
  - INCIDENT
---

# Data Loss Incident Response

Data Type: **{{ data_type }}**
Description: **{{ incident_description }}**
System: **{{ database_system }}**

## CRITICAL: Stop the Bleeding First

**Before investigating, prevent further data loss:**

1. **STOP** any running migrations, scripts, or batch jobs that may be causing the loss
2. **BLOCK** write access to affected tables/collections/buckets if safe to do so
3. **DO NOT** attempt recovery before understanding the scope — you may overwrite good data with bad data

## Phase 1 — Immediate Containment (0-15 min)

- [ ] Identify the source of data loss (accidental deletion, bug, migration, corruption)
- [ ] Stop the process causing data loss (kill query, halt migration, disable service)
- [ ] Assess if data loss is still ongoing or has stopped
- [ ] Declare incident and assign severity
- [ ] Prevent further writes to affected data stores if needed

### Severity Classification for Data Loss

| Severity | Criteria |
|----------|----------|
| SEV1 | Production data permanently lost, no backup, customer-facing |
| SEV1 | Active data corruption spreading to replicas/backups |
| SEV2 | Data lost but recoverable from backup within hours |
| SEV2 | Data corruption contained, not spreading |
| SEV3 | Non-critical data lost, minimal customer impact |
| SEV3 | Data recoverable from alternative sources |

## Phase 2 — Impact Assessment (15-60 min)

### Scope the Loss
- [ ] How many records/objects/rows are affected?
- [ ] What time range of data is affected?
- [ ] Which customers/users are impacted?
- [ ] Is the lost data reproducible from other sources?
- [ ] Are there downstream systems with copies of the data?

### Data Classification
| Question | Answer |
|----------|--------|
| Is this PII/sensitive data? | _yes/no_ |
| Is this financial/transactional data? | _yes/no_ |
| Is this user-generated content? | _yes/no_ |
| Is this system configuration? | _yes/no_ |
| Regulatory implications? | _GDPR/HIPAA/PCI/none_ |

## Phase 3 — Recovery

### Recovery Options (in order of preference)

#### Option 1: Point-in-Time Recovery (PITR)
- [ ] Identify the exact timestamp before the data loss event
- [ ] Verify PITR is available and covers the needed time range
- [ ] Restore to a SEPARATE instance (never overwrite production)
- [ ] Extract only the lost data from the restored instance
- [ ] Merge recovered data back into production

#### Option 2: Restore from Backup
- [ ] Identify the most recent backup before the data loss
- [ ] Verify backup integrity (checksums, test restore)
- [ ] Restore backup to a separate instance
- [ ] Identify and extract only the missing data
- [ ] Apply any transactions that occurred between backup and loss event
- [ ] Merge recovered data into production

#### Option 3: Recover from Replicas
- [ ] Check if read replicas still have the data (replication lag may help)
- [ ] Check if any replica was paused or delayed
- [ ] Extract data from replica before it catches up to the deletion

#### Option 4: Reconstruct from Alternative Sources
- [ ] Check application-level caches
- [ ] Check CDN caches
- [ ] Check data warehouse/analytics copies
- [ ] Check audit logs for original data values
- [ ] Check event streams/message queues for replay
- [ ] Contact customers for re-submission (last resort)

### Recovery Execution Checklist
- [ ] Create recovery plan document before executing
- [ ] Get approval from IC and data owner
- [ ] Restore to staging/test environment first
- [ ] Validate recovered data integrity
- [ ] Perform recovery in production
- [ ] Verify data counts match expected values
- [ ] Run application-level consistency checks

## Phase 4 — Data Integrity Verification

- [ ] Compare record counts: before vs. after
- [ ] Verify referential integrity (foreign keys, cross-references)
- [ ] Check for duplicate records introduced during recovery
- [ ] Validate data types and constraints
- [ ] Run business logic validation queries
- [ ] Check downstream systems for consistency
- [ ] Verify search indexes are updated
- [ ] Confirm cache invalidation completed

## Phase 5 — Communication

### Internal
- [ ] Update incident channel with recovery status
- [ ] Notify affected service owners
- [ ] Inform data governance team

### Customer Communication (if customer data affected)
- [ ] Determine which customers lost data
- [ ] Quantify what each customer lost
- [ ] Notify affected customers with:
  - What data was lost
  - What has been recovered
  - What cannot be recovered
  - What they need to do (re-enter, re-upload, etc.)
  - Preventive measures being taken

## Phase 6 — Prevention

### Root Cause Remediation
- [ ] Implement safeguards against the specific failure mode
- [ ] Add confirmation prompts for destructive operations
- [ ] Implement soft-delete instead of hard-delete where possible
- [ ] Add transaction logging for all write operations

### Backup and Recovery Improvements
- [ ] Verify backup schedule meets RPO requirements
- [ ] Test backup restoration regularly (quarterly minimum)
- [ ] Enable PITR if not already active
- [ ] Implement cross-region backup replication
- [ ] Add backup integrity monitoring

## Counter-Rationalizations

| Shortcut | Counter | Why |
|----------|---------|-----|
| "We can skip some steps for this case" | Adapt the workflow steps, don't skip them | Skipped steps are where incidents and oversights originate |
| "The user seems to already know what to do" | Complete all workflow phases with the user | The workflow catches blind spots that experience alone misses |
| "This is a minor case, full process is overkill" | Scale the process down, don't turn it off | Minor cases become major when unstructured; the process scales, not disappears |
| "I'll fill in the details later" | Complete each section before moving on | Deferred details are forgotten; real-time capture is more accurate |
| "The template output isn't necessary" | Always produce the structured output format | Structured output enables comparison, audit trails, and handoff to other teams |

