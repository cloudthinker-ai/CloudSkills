---
name: disaster-recovery-plan
enabled: true
description: |
  Use when performing disaster recovery plan — disaster recovery planning
  template covering RTO/RPO definitions, failover procedures, communication
  plans, testing schedules, and recovery validation. Use for establishing DR
  strategy, documenting runbooks, or preparing for DR audits.
required_connections:
  - prefix: aws
    label: "AWS (or cloud provider)"
config_fields:
  - key: service_name
    label: "Service / System Name"
    required: true
    placeholder: "e.g., order-platform"
  - key: rto_target
    label: "RTO Target"
    required: true
    placeholder: "e.g., 4 hours"
  - key: rpo_target
    label: "RPO Target"
    required: true
    placeholder: "e.g., 1 hour"
  - key: dr_region
    label: "DR Region"
    required: false
    placeholder: "e.g., us-west-2"
features:
  - SRE
  - DISASTER_RECOVERY
---

# Disaster Recovery Plan Skill

Build a disaster recovery plan for **{{ service_name }}** with RTO **{{ rto_target }}** and RPO **{{ rpo_target }}**.

## Workflow

### Step 1 — DR Strategy Classification

Identify the DR tier for {{ service_name }}:

| Tier | Strategy | RTO | RPO | Cost |
|------|----------|-----|-----|------|
| 1 | Multi-site active-active | <15 min | ~0 | High |
| 2 | Warm standby | <1 hour | <15 min | Medium-High |
| 3 | Pilot light | <4 hours | <1 hour | Medium |
| 4 | Backup & restore | <24 hours | <24 hours | Low |

**Selected tier based on RTO {{ rto_target }} / RPO {{ rpo_target }}**: [auto-determine]

### Step 2 — Infrastructure Inventory

```
INFRASTRUCTURE INVENTORY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Compute:
  - [ ] Primary: [region, instance types, count]
  - [ ] DR: [{{ dr_region }}, instance types, count]

Data Stores:
  - [ ] Primary databases: [type, size, replication method]
  - [ ] Replica lag monitoring configured
  - [ ] Backup schedule: [frequency, retention]

Storage:
  - [ ] Object storage replication (cross-region)
  - [ ] File system backups

Networking:
  - [ ] DNS failover configuration
  - [ ] Load balancer in DR region
  - [ ] VPN/connectivity to DR region

Dependencies:
  - [ ] Third-party services with DR capability
  - [ ] Internal dependencies and their DR status
```

### Step 3 — Failover Procedure

```
FAILOVER RUNBOOK
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
DECISION CRITERIA
- [ ] Define who can declare a disaster (roles authorized)
- [ ] Define thresholds for automatic vs manual failover
- [ ] Define communication tree (who gets notified, in what order)

PRE-FAILOVER (T+0 to T+15min)
1. [ ] Confirm primary region is unrecoverable (not transient)
2. [ ] Notify incident commander and stakeholders
3. [ ] Verify DR region health and readiness
4. [ ] Confirm data replication is current (check lag)

FAILOVER EXECUTION (T+15min to T+RTO)
5. [ ] Promote read replica to primary (database)
6. [ ] Start compute resources in DR region (if pilot light)
7. [ ] Update application configuration for DR region
8. [ ] Switch DNS / traffic routing to DR region
9. [ ] Verify application health checks pass
10. [ ] Run smoke tests against DR deployment

POST-FAILOVER VALIDATION
11. [ ] All services responding in DR region
12. [ ] Data integrity verified (spot check recent records)
13. [ ] Monitoring and alerting active in DR region
14. [ ] Customer-facing functionality confirmed
15. [ ] Status page updated
```

### Step 4 — Failback Procedure

```
FAILBACK RUNBOOK (return to primary)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
1. [ ] Primary region confirmed healthy and stable
2. [ ] Data synchronized from DR back to primary
3. [ ] Verify data consistency between regions
4. [ ] Schedule maintenance window for failback
5. [ ] Execute traffic shift back to primary (gradual)
6. [ ] Monitor for 24 hours post-failback
7. [ ] Reset DR environment to standby mode
8. [ ] Update DR documentation with lessons learned
```

### Step 5 — Communication Plan

```
COMMUNICATION PLAN
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Internal:
  - [ ] Incident bridge channel: [Slack/Teams channel]
  - [ ] Executive escalation: [contact list]
  - [ ] Engineering teams: [notification method]

External:
  - [ ] Status page updates: [URL]
  - [ ] Customer notification template prepared
  - [ ] Partner/vendor notification list
  - [ ] Regulatory notification (if required)

Cadence:
  - [ ] Updates every 30 minutes during failover
  - [ ] Final all-clear notification when stable
```

### Step 6 — Testing Schedule

| Test Type | Frequency | Last Tested | Next Due | Owner |
|-----------|-----------|-------------|----------|-------|
| Backup restore | Monthly | [date] | [date] | [name] |
| Tabletop exercise | Quarterly | [date] | [date] | [name] |
| Partial failover | Semi-annual | [date] | [date] | [name] |
| Full failover | Annual | [date] | [date] | [name] |

### Step 7 — DR Readiness Assessment

```
DR READINESS CHECKLIST
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] RTO/RPO targets documented and achievable
[ ] Failover runbook tested within last 12 months
[ ] Backups verified with restore test within last 30 days
[ ] DR infrastructure provisioned and maintained
[ ] Replication lag within RPO target
[ ] Communication plan current with valid contacts
[ ] All team members trained on DR procedures
[ ] DR plan reviewed and updated within last 6 months
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

Produce a DR plan document with:
1. **Strategy summary** (tier, RTO/RPO, architecture)
2. **Infrastructure inventory** with primary and DR mappings
3. **Failover runbook** with step-by-step procedure
4. **Failback runbook** with validation steps
5. **Communication plan** with contacts and templates
6. **Testing schedule** with last/next test dates
7. **Readiness assessment** with current status
