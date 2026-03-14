---
name: incident-communication-template
enabled: true
description: |
  Template for structured incident communications across all stages of an incident lifecycle. Covers initial notification, status updates, resolution announcement, and post-incident summary with audience-specific messaging for internal teams, leadership, customers, and public status pages.
required_connections:
  - prefix: slack
    label: "Slack (or messaging tool)"
  - prefix: pagerduty
    label: "PagerDuty (or alerting tool)"
config_fields:
  - key: incident_id
    label: "Incident ID"
    required: true
    placeholder: "e.g., INC-2026-0342"
  - key: severity
    label: "Severity Level"
    required: true
    placeholder: "e.g., SEV1, SEV2, SEV3"
  - key: affected_service
    label: "Affected Service"
    required: true
    placeholder: "e.g., payment-processing"
features:
  - COMPLIANCE
  - INCIDENT_RESPONSE
---

# Incident Communication Template Skill

Manage communications for **{{ incident_id }}** ({{ severity }}) affecting **{{ affected_service }}**.

## Workflow

### Phase 1 — Initial Notification

```
INCIDENT DECLARATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Incident ID: {{ incident_id }}
[ ] Severity: {{ severity }}
[ ] Affected service: {{ affected_service }}
[ ] Detected at: ___
[ ] Declared at: ___
[ ] Incident Commander: ___
[ ] Communications Lead: ___

INITIAL NOTIFICATION — INTERNAL
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Subject: [{{ severity }}] {{ incident_id }} — {{ affected_service }} impacted

We are investigating an issue affecting {{ affected_service }}.

- Impact: [describe user-facing impact]
- Start time: [when issue was first detected]
- Status: Investigating
- Incident Commander: [name]
- War room: [link to channel/bridge]

Next update in [30/60] minutes.

[ ] Sent to: #incidents channel — timestamp: ___
[ ] Sent to: engineering leadership — timestamp: ___
```

### Phase 2 — Status Updates

```
STATUS UPDATE TEMPLATE — INTERNAL
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Subject: [{{ severity }}] {{ incident_id }} — Update #___

Current status: [Investigating / Identified / Monitoring / Resolved]

Summary:
- [What we know now]
- [What has changed since last update]

Impact:
- Users affected: ___
- Error rate: ___%
- Duration so far: ___

Actions taken:
- [Action 1]
- [Action 2]

Next steps:
- [What we are doing next]

Next update in [30/60] minutes.

UPDATE LOG
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Time    | Update # | Status       | Channel    | Sent By
________|__________|______________|____________|________
        | 1        | Investigating| Internal   |
        | 2        |              |            |
        | 3        |              |            |
```

### Phase 3 — Customer-Facing Communication

```
CUSTOMER NOTIFICATION — STATUS PAGE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Title: {{ affected_service }} — Service Disruption

[Investigating]
We are currently investigating reports of [impact description].
Some users may experience [specific symptoms].
We will provide updates as we learn more.
Posted: ___

[Identified]
We have identified the cause of the {{ affected_service }} disruption.
Our team is implementing a fix.
Posted: ___

[Monitoring]
A fix has been implemented and we are monitoring the results.
Service is recovering and most users should see improvement.
Posted: ___

[Resolved]
This incident has been resolved.
{{ affected_service }} is operating normally.
Duration: ___
We apologize for any inconvenience.
Posted: ___

COMMUNICATION DECISION MATRIX
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Severity | Status Page | Customer Email | Social Media | Press
SEV1     | YES         | YES            | CONSIDER     | CONSIDER
SEV2     | YES         | TARGETED       | NO           | NO
SEV3     | OPTIONAL    | NO             | NO           | NO
```

### Phase 4 — Leadership Briefing

```
EXECUTIVE SUMMARY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Incident: {{ incident_id }} ({{ severity }})
Service: {{ affected_service }}
Duration: ___
Customer impact: ___
Revenue impact: $___

Root cause: [one sentence summary]
Resolution: [one sentence summary]
Preventive measures: [one sentence summary]

[ ] Sent to leadership: [ ] YES — timestamp: ___
```

### Phase 5 — Resolution Announcement

```
RESOLUTION — INTERNAL
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Subject: [RESOLVED] {{ incident_id }} — {{ affected_service }}

{{ incident_id }} has been resolved.

Timeline:
- Detected: ___
- Declared: ___
- Root cause identified: ___
- Fix deployed: ___
- Resolved: ___
- Total duration: ___

Root cause: [brief description]
Fix applied: [brief description]

Impact:
- Users affected: ___
- Requests failed: ___
- Revenue impact: $___

Next steps:
- Post-incident review scheduled: ___
- Action items will be tracked in: [ticket/doc link]
```

### Phase 6 — Post-Incident Summary

```
POST-INCIDENT COMMUNICATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Post-incident review completed: ___
[ ] Customer-facing post-mortem published (if required):
    [ ] What happened
    [ ] Impact
    [ ] Root cause
    [ ] What we are doing to prevent recurrence
[ ] Internal post-mortem shared
[ ] Action items assigned and tracked:
    - ___: owner: ___ due: ___
    - ___: owner: ___ due: ___
[ ] Communication retrospective:
    - Updates were timely: [ ] YES  [ ] NO
    - Messaging was accurate: [ ] YES  [ ] NO
    - All audiences reached: [ ] YES  [ ] NO
    - Improvements for next time: ___
```

## Output Format

Produce an incident communication package with:
1. **Communication timeline** (all messages sent with timestamps)
2. **Audience-specific messages** (internal, customer, leadership)
3. **Status page updates** (chronological entries)
4. **Resolution announcement** (root cause, fix, prevention)
5. **Communication retrospective** (what worked, what to improve)
