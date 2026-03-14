---
name: major-incident-communication-it
enabled: true
description: |
  IT-wide incident communication workflow for notifying end users and stakeholders during major IT outages or service disruptions. Covers initial impact notification, periodic status updates, resolution announcements, and post-incident summaries with templates for each communication stage.
required_connections:
  - prefix: itsm
    label: "ITSM Tool (ServiceNow, Freshservice, etc.)"
config_fields:
  - key: incident_title
    label: "Incident Title"
    required: true
    placeholder: "e.g., Email Service Outage, VPN Connectivity Issues"
  - key: severity
    label: "Severity (SEV1 / SEV2 / SEV3)"
    required: true
    placeholder: "e.g., SEV1"
  - key: affected_services
    label: "Affected Services"
    required: true
    placeholder: "e.g., Email, VPN, Intranet, All Cloud Applications"
  - key: estimated_impact
    label: "Estimated User Impact"
    required: true
    placeholder: "e.g., All employees, EMEA region, Engineering department"
  - key: communication_channel
    label: "Communication Channel"
    required: false
    placeholder: "e.g., Slack #it-announcements, email, status page"
features:
  - HELPDESK
---

# Major Incident Communication — IT

Incident: **{{ incident_title }}** | Severity: **{{ severity }}**
Affected: {{ affected_services }} | Impact: {{ estimated_impact }}
Channel: {{ communication_channel }}

## Communication Timeline

```
INCIDENT DETECTED
    │
    ├─ T+0 min:   Initial notification (within 15 min of detection)
    ├─ T+30 min:  First status update
    ├─ T+60 min:  Hourly updates (SEV1) / 2-hour updates (SEV2)
    ├─ Resolution: Resolution announcement
    └─ T+48 hrs:  Post-incident summary (for SEV1/SEV2)
```

## Template 1 — Initial Notification

**Subject:** [{{ severity }}] {{ incident_title }} — Service Disruption

```
IT SERVICE NOTIFICATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

We are aware of an issue affecting {{ affected_services }}.

WHAT IS HAPPENING:
[Brief description of the problem in non-technical language]

WHO IS AFFECTED:
{{ estimated_impact }}

WHAT WE ARE DOING:
Our IT team is actively investigating this issue and working
toward a resolution. We will provide updates every
[30 minutes / 1 hour] until this is resolved.

WORKAROUND (if available):
[Describe any temporary workaround, or "None at this time"]

NEXT UPDATE:
We will provide the next update by [time].

If you have questions, please contact the IT helpdesk at
[contact info]. Please do NOT submit individual tickets for
this issue — we are tracking it centrally.

IT Operations Team
```

## Template 2 — Status Update

**Subject:** [UPDATE {{ update_number }}] {{ incident_title }}

```
IT SERVICE UPDATE #[number]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

STATUS: [Investigating / Identified / Mitigating / Monitoring]

CURRENT SITUATION:
[What has been found or changed since last update]

AFFECTED SERVICES:
{{ affected_services }}
[Update if scope has changed]

WHAT WE ARE DOING:
[Current remediation actions in progress]

ESTIMATED TIME TO RESOLUTION:
[Provide estimate if possible, or "We are still assessing"]

WORKAROUND:
[Updated workaround if available]

NEXT UPDATE:
We will provide the next update by [time].

IT Operations Team
```

## Template 3 — Resolution Announcement

**Subject:** [RESOLVED] {{ incident_title }}

```
IT SERVICE RESOLUTION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

The issue affecting {{ affected_services }} has been RESOLVED.

DURATION:
[Start time] to [End time] ([total duration])

WHAT HAPPENED:
[Brief, non-technical explanation of what caused the issue]

WHAT WE DID:
[Brief explanation of how it was fixed]

WHAT YOU NEED TO DO:
[Any user actions needed, e.g., "Please restart your VPN client"
 or "No action needed — service has been fully restored"]

PREVENTION:
We are taking steps to prevent this from recurring, including
[brief mention of preventive measures].

A detailed post-incident review will be shared within 48 hours.

We apologize for any inconvenience this may have caused.

IT Operations Team
```

## Template 4 — Post-Incident Summary (SEV1/SEV2 only)

**Subject:** Post-Incident Summary — {{ incident_title }}

```
POST-INCIDENT SUMMARY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

INCIDENT:        {{ incident_title }}
SEVERITY:        {{ severity }}
DURATION:        [total duration]
IMPACT:          {{ estimated_impact }}

TIMELINE OF EVENTS:
[HH:MM] Issue detected / first report
[HH:MM] IT team began investigation
[HH:MM] Root cause identified
[HH:MM] Fix implemented
[HH:MM] Service restored and verified

ROOT CAUSE:
[Non-technical explanation of what went wrong]

RESOLUTION:
[What was done to fix the issue]

PREVENTIVE MEASURES:
To prevent this from happening again, we are:
1. [Action item 1]
2. [Action item 2]
3. [Action item 3]

We value your patience during this disruption. If you
continue to experience issues, please contact the
IT helpdesk at [contact info].

IT Operations Team
```

## Communication Checklist

### Before Sending
- [ ] Have the facts been verified with the incident team?
- [ ] Is the language clear and non-technical for the audience?
- [ ] Is the severity level accurate?
- [ ] Has the communication been reviewed by incident commander?
- [ ] Is the affected scope correctly described?

### Distribution
- [ ] Post to {{ communication_channel }}
- [ ] Update status page (if applicable)
- [ ] Notify executive stakeholders separately (for SEV1)
- [ ] Inform customer-facing teams (support, account management)
- [ ] Update IVR/phone system message if phone systems affected

### After Resolution
- [ ] Send resolution announcement
- [ ] Close status page incident
- [ ] Schedule post-incident review
- [ ] Publish post-incident summary within 48 hours

## Output Format

Generate communications ready to send with:
1. **Appropriate template** selected based on communication stage
2. **Filled-in details** from incident information
3. **Distribution checklist** for tracking delivery
