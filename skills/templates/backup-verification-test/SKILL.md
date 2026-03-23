---
name: backup-verification-test
enabled: true
description: |
  Use when performing backup verification test — template for systematically
  verifying backup integrity and recoverability. Covers backup inventory,
  restore testing in isolated environments, data integrity validation, RTO/RPO
  measurement, and gap analysis to ensure backups are actually recoverable when
  needed.
required_connections:
  - prefix: aws
    label: "AWS (or cloud provider)"
config_fields:
  - key: system_name
    label: "System Name"
    required: true
    placeholder: "e.g., production-database"
  - key: backup_type
    label: "Backup Type"
    required: true
    placeholder: "e.g., full snapshot, incremental, WAL archive"
  - key: target_rpo
    label: "Target RPO"
    required: true
    placeholder: "e.g., 1 hour"
  - key: target_rto
    label: "Target RTO"
    required: true
    placeholder: "e.g., 4 hours"
features:
  - DEVOPS
  - DISASTER_RECOVERY
---

# Backup Verification Test Skill

Verify backup recoverability for **{{ system_name }}** ({{ backup_type }}). Target RPO: **{{ target_rpo }}**, Target RTO: **{{ target_rto }}**.

## Workflow

### Phase 1 — Backup Inventory

```
BACKUP CATALOG
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] System: {{ system_name }}
[ ] Backup type: {{ backup_type }}
[ ] Backup schedule: ___
[ ] Last successful backup: ___
[ ] Backup location(s):
    - Primary: ___
    - Secondary (cross-region): ___
[ ] Backup size: ___ GB
[ ] Encryption: [ ] At rest  [ ] In transit
[ ] Backup retention: ___ days
[ ] Oldest available backup: ___
```

### Phase 2 — Restore Environment Setup

```
ISOLATED RESTORE ENVIRONMENT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Isolated restore environment provisioned
[ ] Network isolation confirmed (no production access)
[ ] Sufficient compute and storage allocated
[ ] Restore credentials and access configured
[ ] Restore start timestamp: ___
```

### Phase 3 — Restore Execution

```
RESTORE TEST
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Backup retrieved from storage
[ ] Backup integrity check passed (checksum/signature)
[ ] Restore initiated — timestamp: ___
[ ] Restore progress:
    - Data restored: ___ / ___ GB
    - Estimated completion: ___
[ ] Restore completed — timestamp: ___
[ ] Actual restore time: ___ (target RTO: {{ target_rto }})

RTO ASSESSMENT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Restore duration:     ___
Target RTO:           {{ target_rto }}
RTO met:              [ ] YES  [ ] NO
```

### Phase 4 — Data Integrity Validation

```
INTEGRITY CHECKS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Database/system starts successfully from backup
[ ] Row count comparison:
    - Source: ___
    - Restored: ___
    - Delta: ___
[ ] Sample data verification (10 random records): [ ] PASS  [ ] FAIL
[ ] Application can connect and query restored data
[ ] Referential integrity intact
[ ] No corruption errors in system logs
[ ] Point-in-time accuracy:
    - Backup point-in-time: ___
    - Expected RPO: {{ target_rpo }}
    - Actual data age: ___
    - RPO met: [ ] YES  [ ] NO
```

### Phase 5 — Cleanup and Reporting

```
CLEANUP
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Restore environment torn down
[ ] Sensitive data securely deleted
[ ] Test results documented
[ ] Next verification test scheduled: ___

GAP ANALYSIS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] RTO gap: ___ (actual vs target)
[ ] RPO gap: ___ (actual vs target)
[ ] Identified risks:
    - ___
    - ___
[ ] Remediation actions:
    - ___
    - ___
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

Produce a backup verification report with:
1. **Test summary** (system, backup type, test date)
2. **RTO results** (actual restore time vs target)
3. **RPO results** (data freshness vs target)
4. **Data integrity** (validation checks and results)
5. **Gap analysis** (identified risks and remediation plan)
