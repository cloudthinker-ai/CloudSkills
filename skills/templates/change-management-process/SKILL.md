---
name: change-management-process
enabled: true
description: |
  Template for managing infrastructure and application changes through a structured change management process. Covers change classification, risk assessment, approval workflows, implementation planning, rollback procedures, and post-implementation review aligned with ITIL best practices.
required_connections:
  - prefix: jira
    label: "Jira (or project tracker)"
config_fields:
  - key: change_title
    label: "Change Title"
    required: true
    placeholder: "e.g., Database engine upgrade to v15"
  - key: change_type
    label: "Change Type"
    required: true
    placeholder: "e.g., standard, normal, emergency"
  - key: environment
    label: "Target Environment"
    required: true
    placeholder: "e.g., production, staging"
features:
  - COMPLIANCE
  - OPERATIONS
---

# Change Management Process Skill

Process change request: **{{ change_title }}** ({{ change_type }}) targeting **{{ environment }}**.

## Workflow

### Phase 1 — Change Request

```
CHANGE DETAILS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Title: {{ change_title }}
[ ] Type: {{ change_type }}
[ ] Environment: {{ environment }}
[ ] Requester: ___
[ ] Date requested: ___
[ ] Proposed implementation date: ___
[ ] Business justification: ___
[ ] Description of change: ___
[ ] Systems affected: ___
[ ] Users affected: ___
```

### Phase 2 — Risk Assessment

```
RISK EVALUATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Impact assessment:
[ ] Service disruption expected: [ ] YES (duration: ___) [ ] NO
[ ] Data loss potential: [ ] YES  [ ] NO
[ ] Security implications: [ ] YES  [ ] NO
[ ] Compliance implications: [ ] YES  [ ] NO

RISK MATRIX
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
              | Low Impact | Medium Impact | High Impact
High Likelihood    | MEDIUM    | HIGH          | CRITICAL
Medium Likelihood  | LOW       | MEDIUM        | HIGH
Low Likelihood     | LOW       | LOW           | MEDIUM

Likelihood: ___
Impact: ___
Overall risk: ___

APPROVAL REQUIREMENTS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Risk Level | Standard Change | Normal Change    | Emergency Change
LOW        | Pre-approved    | Team lead        | Post-hoc
MEDIUM     | Pre-approved    | Manager + peer   | Manager
HIGH       | N/A             | CAB review       | VP + CAB post-hoc
CRITICAL   | N/A             | VP + CAB review  | CTO + post-hoc CAB
```

### Phase 3 — Implementation Plan

```
IMPLEMENTATION STEPS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Pre-implementation:
[ ] Change window confirmed: ___ to ___
[ ] Maintenance notification sent (if applicable)
[ ] Backup taken: [ ] YES — verified: [ ] YES
[ ] Runbook prepared and reviewed
[ ] Team members assigned:
    - Implementer: ___
    - Reviewer: ___
    - On-call backup: ___

Implementation:
[ ] Step 1: ___  (estimated: ___ min)
[ ] Step 2: ___  (estimated: ___ min)
[ ] Step 3: ___  (estimated: ___ min)
[ ] Step 4: ___  (estimated: ___ min)
Total estimated duration: ___

Verification:
[ ] Smoke tests pass
[ ] Monitoring confirms normal operation
[ ] No new errors in logs
[ ] Stakeholders notified of completion
```

### Phase 4 — Rollback Plan

```
ROLLBACK PROCEDURE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Rollback trigger: ___
Rollback decision owner: ___
Rollback deadline: ___

[ ] Step 1: ___
[ ] Step 2: ___
[ ] Step 3: ___

Estimated rollback duration: ___
Rollback tested: [ ] YES  [ ] NO
```

### Phase 5 — Post-Implementation Review

```
POST-CHANGE REVIEW
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Change completed successfully: [ ] YES  [ ] PARTIAL  [ ] ROLLED BACK
[ ] Actual implementation time: ___ (estimated: ___)
[ ] Issues encountered:
    - ___
    - ___
[ ] Unplanned changes required: [ ] YES  [ ] NO
[ ] Customer impact: [ ] NONE  [ ] MINOR  [ ] MAJOR
[ ] Lessons learned:
    - ___
    - ___
[ ] Process improvements identified:
    - ___
[ ] Change record closed: [ ] YES
```

## Output Format

Produce a change management record with:
1. **Change summary** (title, type, risk level, environment)
2. **Risk assessment** (impact, likelihood, approval chain)
3. **Implementation log** (steps executed, timing, issues)
4. **Rollback status** (used or not, effectiveness)
5. **Post-implementation review** (lessons learned, process improvements)
