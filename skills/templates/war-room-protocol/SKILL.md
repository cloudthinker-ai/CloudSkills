---
name: war-room-protocol
enabled: true
description: |
  Use when performing war room protocol — defines a structured war room protocol
  for managing major incidents, including role assignments, communication
  cadences, escalation paths, and decision-making frameworks. This template
  helps teams respond to critical incidents efficiently by establishing clear
  procedures before they are needed.
required_connections:
  - prefix: incident-management
    label: "Incident Management Platform"
  - prefix: collaboration
    label: "Collaboration Tool"
  - prefix: monitoring
    label: "Monitoring Platform"
config_fields:
  - key: org_name
    label: "Organization Name"
    required: true
    placeholder: "e.g., Cloud Platform Division"
  - key: severity_threshold
    label: "War Room Activation Severity"
    required: true
    placeholder: "e.g., SEV1, P0"
features:
  - INCIDENT_MANAGEMENT
  - WAR_ROOM
  - ON_CALL
---

# War Room Protocol

## Phase 1: Activation Criteria

Define when a war room should be activated.

**Activate when any of the following are true:**

- [ ] Customer-facing service is fully down
- [ ] Data loss or data integrity issue confirmed
- [ ] Security breach in progress
- [ ] Revenue impact exceeds $___ / hour
- [ ] SLA breach imminent or confirmed
- [ ] Multiple teams required for resolution

**Activation process:**

1. On-call engineer escalates to incident commander
2. Incident commander declares war room
3. War room channel/bridge is created
4. Required roles are paged

## Phase 2: Role Assignments

| Role | Responsibility | Current Assignee |
|------|---------------|-----------------|
| Incident Commander (IC) | Coordinates response, makes decisions, manages timeline | |
| Technical Lead | Drives technical investigation and resolution | |
| Communications Lead | Manages stakeholder updates (internal and external) | |
| Scribe | Documents timeline, actions, and decisions | |
| Subject Matter Experts | Provide domain expertise as needed | |

**Role Rules:**

- [ ] IC does NOT debug — they coordinate
- [ ] One person per role (no shared responsibilities)
- [ ] Roles can be handed off with explicit verbal acknowledgment
- [ ] IC can request any engineer join the war room

## Phase 3: Communication Cadence

| Audience | Channel | Frequency | Owner |
|----------|---------|-----------|-------|
| War room participants | Voice bridge + chat channel | Continuous | IC |
| Engineering leadership | Status update | Every 30 min | Communications Lead |
| Customer support | Status page + internal brief | Every 30 min | Communications Lead |
| Affected customers | Status page / email | Every 60 min or on status change | Communications Lead |
| Executive team | Summary brief | Every 60 min | IC |

**Update Template:**

```
Status: Investigating / Identified / Monitoring / Resolved
Impact: [description of customer impact]
Current action: [what is being done right now]
Next update: [time]
```

## Phase 4: Resolution Workflow

1. **Assess** (first 15 minutes)
   - [ ] Confirm and quantify impact
   - [ ] Identify affected systems and services
   - [ ] Review recent changes (deploys, config changes, infra changes)

2. **Stabilize** (parallel workstreams)
   - [ ] Attempt rollback of recent changes if applicable
   - [ ] Apply mitigation (failover, traffic shift, feature disable)
   - [ ] Scale resources if capacity-related

3. **Resolve**
   - [ ] Identify root cause
   - [ ] Apply fix
   - [ ] Verify fix in production
   - [ ] Monitor for recurrence (minimum 30 minutes)

4. **Close**
   - [ ] IC declares incident resolved
   - [ ] Send final communication to all audiences
   - [ ] Schedule postmortem within 48 hours
   - [ ] Create follow-up tickets for permanent fixes

## Phase 5: War Room Etiquette

- [ ] Keep the voice bridge clear — use chat for non-urgent items
- [ ] Prefix messages: `[UPDATE]`, `[QUESTION]`, `[ACTION]`, `[FYI]`
- [ ] No blame — focus on resolution
- [ ] All decisions and actions are logged by the scribe
- [ ] Anyone can call a timeout if the approach is not working

## Counter-Rationalizations

| Shortcut | Counter | Why |
|----------|---------|-----|
| "We can skip some steps for this case" | Adapt the workflow steps, don't skip them | Skipped steps are where incidents and oversights originate |
| "The user seems to already know what to do" | Complete all workflow phases with the user | The workflow catches blind spots that experience alone misses |
| "This is a minor case, full process is overkill" | Scale the process down, don't turn it off | Minor cases become major when unstructured; the process scales, not disappears |
| "I'll fill in the details later" | Complete each section before moving on | Deferred details are forgotten; real-time capture is more accurate |
| "The template output isn't necessary" | Always produce the structured output format | Structured output enables comparison, audit trails, and handoff to other teams |

## Output Format

### Summary

- **Incident:** ___
- **Severity:** ___
- **Duration:** ___
- **Impact:** ___
- **Root cause:** ___
- **Resolution:** ___

### Action Items

- [ ] Conduct postmortem within 48 hours
- [ ] File tickets for all follow-up remediation items
- [ ] Update runbooks based on lessons learned
- [ ] Review and update war room protocol if gaps were found
- [ ] Recognize team members who contributed to resolution
