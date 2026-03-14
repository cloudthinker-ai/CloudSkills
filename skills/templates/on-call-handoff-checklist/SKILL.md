---
name: on-call-handoff-checklist
enabled: true
description: |
  Structured on-call rotation handoff checklist ensuring effective context transfer between outgoing and incoming on-call engineers. Covers active incidents, known issues, recent deployments, pending alerts, escalation contacts, and environment health summary to minimize knowledge gaps during rotation transitions.
required_connections:
  - prefix: slack
    label: "Slack (for handoff notes)"
config_fields:
  - key: outgoing_engineer
    label: "Outgoing On-Call Engineer"
    required: true
    placeholder: "e.g., Alice Johnson"
  - key: incoming_engineer
    label: "Incoming On-Call Engineer"
    required: true
    placeholder: "e.g., Bob Smith"
  - key: rotation_name
    label: "Rotation/Team Name"
    required: false
    placeholder: "e.g., Platform Team Primary"
features:
  - INCIDENT
---

# On-Call Handoff Checklist

Rotation: **{{ rotation_name }}**
Outgoing: **{{ outgoing_engineer }}** | Incoming: **{{ incoming_engineer }}**

## Pre-Handoff Preparation (Outgoing Engineer)

Complete these items before the handoff meeting:

- [ ] Review all incidents from your rotation
- [ ] Document any ongoing or recently resolved issues
- [ ] Note any recent deployments or config changes
- [ ] Check for pending maintenance windows
- [ ] Verify alerting and monitoring tools are functioning
- [ ] Prepare summary of on-call experience (noisy alerts, false positives)

## Handoff Meeting Agenda (15-30 min)

### 1. Active Incidents and Open Issues
| Issue | Status | Severity | Notes | Tracking |
|-------|--------|----------|-------|----------|
| _fill in_ | _open/monitoring_ | _SEV level_ | _context_ | _ticket link_ |

### 2. Recently Resolved Incidents
| Issue | Resolved | Root Cause | Follow-up Needed |
|-------|----------|-----------|-----------------|
| _fill in_ | _date/time_ | _brief description_ | _yes/no + details_ |

### 3. Recent Deployments and Changes
| Change | When | Service | Risk Level | Rollback Plan |
|--------|------|---------|-----------|---------------|
| _fill in_ | _date/time_ | _service_ | _low/med/high_ | _how to rollback_ |

### 4. Known Flaky Alerts
| Alert | Frequency | Action | Notes |
|-------|-----------|--------|-------|
| _fill in_ | _how often_ | _acknowledge/investigate/ignore_ | _context_ |

### 5. Upcoming Maintenance Windows
| Window | When | Impact | Owner |
|--------|------|--------|-------|
| _fill in_ | _date/time_ | _expected impact_ | _who is driving_ |

### 6. Environment Health Summary

- **Production:** _healthy / degraded / issues_
- **Staging:** _healthy / degraded / issues_
- **Key metrics:** _any concerning trends_
- **Capacity:** _any resources approaching limits_

### 7. Escalation Contacts

| Situation | Contact | Method |
|-----------|---------|--------|
| Database issues | _name_ | _phone/slack_ |
| Network/infra | _name_ | _phone/slack_ |
| Security | _name_ | _phone/slack_ |
| Management escalation | _name_ | _phone/slack_ |
| Vendor support | _vendor_ | _support portal/phone_ |

## Incoming Engineer Verification

- [ ] Confirm PagerDuty/OpsGenie/on-call tool shows you as active on-call
- [ ] Verify phone notifications are working (send test page)
- [ ] Confirm access to all required dashboards and runbooks
- [ ] Review escalation policy and confirm you know how to escalate
- [ ] Verify VPN/remote access is working
- [ ] Confirm laptop is charged and available for off-hours response

## Post-Handoff Actions

### Outgoing Engineer
- [ ] Post handoff summary to team Slack channel
- [ ] Remain available for questions for 2 hours after handoff
- [ ] File tickets for any on-call improvement suggestions

### Incoming Engineer
- [ ] Acknowledge handoff in Slack channel
- [ ] Review linked runbooks for any active issues
- [ ] Set personal reminder for upcoming maintenance windows
- [ ] Check alert dashboards for current state

## On-Call Health Metrics to Share

- Total pages received during rotation: ___
- After-hours pages: ___
- False positive alerts: ___
- Average time to acknowledge: ___
- Incidents that required escalation: ___
- Sleep interruptions: ___

These metrics help the team identify on-call burden and improve alert quality over time.
