---
name: it-change-management-process
enabled: true
description: |
  ITIL-aligned change management process covering change request submission, risk assessment, CAB review, approval workflows, implementation planning, and post-implementation review. Ensures all IT changes follow a controlled process to minimize risk and service disruption.
required_connections:
  - prefix: itsm
    label: "ITSM Tool (ServiceNow, Freshservice, etc.)"
config_fields:
  - key: change_title
    label: "Change Title"
    required: true
    placeholder: "e.g., Upgrade production database to PostgreSQL 16"
  - key: change_type
    label: "Change Type (standard/normal/emergency)"
    required: true
    placeholder: "e.g., standard, normal, emergency"
  - key: requested_by
    label: "Requested By"
    required: true
    placeholder: "e.g., Jane Smith, Platform Team"
  - key: target_date
    label: "Target Implementation Date"
    required: true
    placeholder: "e.g., 2026-04-15 02:00 UTC"
  - key: affected_services
    label: "Affected Services"
    required: false
    placeholder: "e.g., payment-api, user-auth, database-cluster"
features:
  - HELPDESK
---

# IT Change Management Process

Change: **{{ change_title }}**
Type: **{{ change_type }}** | Requested by: {{ requested_by }}
Target Date: {{ target_date }} | Affected: {{ affected_services }}

## Change Type Definitions

| Type | Description | Approval Required | Lead Time |
|------|-------------|-------------------|-----------|
| Standard | Pre-approved, low-risk, routine | Pre-approved (no CAB) | 24 hours |
| Normal | Requires assessment and approval | CAB approval | 5 business days |
| Emergency | Critical fix, cannot wait for CAB | Emergency CAB (expedited) | ASAP |

## Step 1 — Change Request Submission

- [ ] Complete change request form:
  - Title: {{ change_title }}
  - Description: detailed technical scope
  - Business justification
  - Affected services: {{ affected_services }}
  - Requested implementation date: {{ target_date }}
  - Expected duration
  - Requestor: {{ requested_by }}

## Step 2 — Risk Assessment

### Impact & Risk Matrix
```
RISK ASSESSMENT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Impact:
  [ ] Low — Single user/non-critical system
  [ ] Medium — Department or non-critical service
  [ ] High — Organization-wide or business-critical service
  [ ] Critical — Revenue-impacting or security-related

Probability of Failure:
  [ ] Low — Routine, well-tested, done many times
  [ ] Medium — Some complexity, tested but not routine
  [ ] High — Complex, first-time, multiple dependencies

Risk Level = Impact x Probability:
  [ ] Low Risk → Standard approval
  [ ] Medium Risk → Manager + CAB approval
  [ ] High Risk → CAB + Director approval
  [ ] Critical Risk → CAB + VP/CTO approval
```

### Pre-Implementation Checklist
- [ ] Change tested in non-production environment
- [ ] Rollback plan documented and tested
- [ ] Backup of affected systems completed or scheduled
- [ ] Communication plan prepared for affected users
- [ ] Maintenance window scheduled ({{ target_date }})
- [ ] On-call resources identified for implementation

## Step 3 — Approval

### Standard Change
- [ ] Verify change matches pre-approved standard change template
- [ ] Technical lead approval
- [ ] Proceed to implementation

### Normal Change
- [ ] Technical review completed by peer
- [ ] Manager approval
- [ ] Submit to CAB for review
- [ ] CAB meeting date: ______
- [ ] CAB decision: [ ] Approved / [ ] Rejected / [ ] Deferred
- [ ] If rejected: document reason and required modifications

### Emergency Change
- [ ] Emergency CAB (minimum: change manager + service owner)
- [ ] Verbal approval documented
- [ ] Formal documentation completed within 24 hours post-implementation

## Step 4 — Implementation Plan

```
IMPLEMENTATION PLAN
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Date/Time:      {{ target_date }}
Duration:       [estimated duration]
Implementer:    {{ requested_by }}
Approver:       [name]

PRE-IMPLEMENTATION:
  [ ] Notify stakeholders
  [ ] Verify backups completed
  [ ] Confirm rollback plan ready

IMPLEMENTATION STEPS:
  1. [Step 1 with expected duration]
  2. [Step 2 with expected duration]
  3. [Step 3 with expected duration]

VERIFICATION:
  [ ] [Test 1 — expected result]
  [ ] [Test 2 — expected result]
  [ ] [Test 3 — expected result]

ROLLBACK TRIGGER:
  If any verification fails or [specific condition],
  execute rollback plan immediately.

ROLLBACK PLAN:
  1. [Rollback step 1]
  2. [Rollback step 2]
  3. [Verify rollback successful]
```

## Step 5 — Post-Implementation Review

- [ ] All verification tests passed
- [ ] No unexpected errors or degradation observed
- [ ] Monitor for 30 minutes (standard) / 2 hours (high risk) post-change
- [ ] Update CMDB if configuration items changed
- [ ] Notify stakeholders of successful completion
- [ ] If issues detected:
  - [ ] Determine if rollback is needed
  - [ ] Document issues and resolution
- [ ] Close change request in ITSM
- [ ] Record actual vs planned duration
- [ ] Document lessons learned (for non-standard changes)

## Output Format

Generate a change management report with:
1. **Change summary** (title, type, risk level)
2. **Approval chain** with timestamps
3. **Implementation result** (success/rollback)
4. **Post-implementation status** and observations
