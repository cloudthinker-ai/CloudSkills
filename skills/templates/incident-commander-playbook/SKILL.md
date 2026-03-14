---
name: incident-commander-playbook
enabled: true
description: |
  Comprehensive incident commander (IC) playbook covering IC responsibilities, communication cadence, escalation decision frameworks, delegation patterns, and handoff procedures. Guides the IC through each phase of incident response from declaration through resolution and post-incident review.
required_connections:
  - prefix: slack
    label: "Slack (for incident coordination)"
config_fields:
  - key: incident_title
    label: "Incident Title"
    required: true
    placeholder: "e.g., API gateway returning 503 for all regions"
  - key: severity
    label: "Severity (SEV1 / SEV2 / SEV3)"
    required: true
    placeholder: "e.g., SEV1"
  - key: ic_name
    label: "Incident Commander Name"
    required: false
    placeholder: "e.g., Jane Smith"
features:
  - INCIDENT
---

# Incident Commander Playbook

Incident: **{{ incident_title }}**
Severity: **{{ severity }}** | IC: **{{ ic_name }}**

## IC Core Responsibilities

The Incident Commander is the single decision-maker during an incident. The IC does NOT debug — the IC coordinates.

1. **Own the incident** — you are the single point of authority
2. **Communicate** — keep all stakeholders informed at regular intervals
3. **Delegate** — assign roles and tasks, do not do the debugging yourself
4. **Decide** — make escalation, rollback, and communication decisions
5. **Document** — ensure the timeline is being captured

## Role Assignments

Upon assuming IC, assign these roles immediately:

| Role | Responsibility | Assigned To |
|------|---------------|-------------|
| **Incident Commander** | Coordination, decisions, communication | {{ ic_name }} |
| **Tech Lead** | Technical investigation and mitigation | _assign_ |
| **Communications Lead** | Customer/stakeholder updates | _assign_ |
| **Scribe** | Timeline documentation | _assign_ |

## Phase 1 — Declaration (0-5 min)

- [ ] Confirm incident is real (not false alarm)
- [ ] Assign severity: **{{ severity }}**
- [ ] Open incident channel in Slack
- [ ] Post initial situation summary
- [ ] Assign Tech Lead, Comms Lead, Scribe
- [ ] Start incident timer

**Initial Announcement Template:**
```
INCIDENT DECLARED: {{ incident_title }}
Severity: {{ severity }}
IC: {{ ic_name }}
Status: Investigating
Impact: [describe user impact]
Bridge: [link to call/channel]
Next update in: 15 minutes
```

## Phase 2 — Investigation (5-30 min)

- [ ] Tech Lead reports initial findings
- [ ] Identify blast radius (which services, which users)
- [ ] Check recent deployments, config changes, and dependency status
- [ ] Determine if rollback is viable
- [ ] Decide: mitigate vs. fix-forward vs. rollback

**Communication Cadence:**
| Severity | Update Frequency | Stakeholder Notification |
|----------|-----------------|------------------------|
| SEV1 | Every 15 minutes | Exec team, all engineering |
| SEV2 | Every 30 minutes | Engineering leadership |
| SEV3 | Every 60 minutes | Team leads |

## Phase 3 — Mitigation (30 min+)

- [ ] Mitigation action identified and approved by IC
- [ ] Communicate mitigation plan before executing
- [ ] Execute mitigation (rollback, scaling, failover, hotfix)
- [ ] Verify mitigation effectiveness with monitoring
- [ ] Update status page and stakeholders

**Escalation Decision Framework:**

Escalate severity if ANY of these are true:
- Mitigation attempt failed
- Blast radius is expanding
- Impact duration exceeds MTTR target for current severity
- Customer-reported impact increasing
- Root cause unknown after 30 minutes (SEV1) or 60 minutes (SEV2)

## Phase 4 — Resolution

- [ ] Confirm service restored to normal operation
- [ ] Monitoring shows metrics returned to baseline
- [ ] Update status page to "Resolved"
- [ ] Post final update to incident channel
- [ ] Schedule post-incident review within 48 hours
- [ ] Thank the response team

**Resolution Announcement Template:**
```
INCIDENT RESOLVED: {{ incident_title }}
Duration: [total time]
Impact: [summary of user impact]
Root cause: [brief description]
Mitigation: [what was done]
Post-incident review: [scheduled date/time]
```

## Phase 5 — Handoff (if IC rotation needed)

- [ ] Brief incoming IC on current status, timeline, and open actions
- [ ] Introduce incoming IC to the bridge/channel
- [ ] Transfer all role assignments
- [ ] Outgoing IC remains available for questions for 30 minutes

## IC Anti-Patterns to Avoid

- **Do NOT debug** — delegate to Tech Lead
- **Do NOT go silent** — communicate even when there is no new information
- **Do NOT skip updates** — stakeholders assume the worst in silence
- **Do NOT make unilateral changes** — announce actions before executing
- **Do NOT let the incident run without a timer** — track duration actively
