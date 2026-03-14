---
name: customer-communication-during-incident
enabled: true
description: |
  Customer-facing incident communication templates for status page updates, email notifications, social media responses, and support team talking points. Provides tone guidelines, timing recommendations, and templates for each phase of an incident from initial acknowledgment through resolution and follow-up.
required_connections:
  - prefix: slack
    label: "Slack (for internal coordination)"
config_fields:
  - key: incident_title
    label: "Incident Title"
    required: true
    placeholder: "e.g., Intermittent API errors in EU region"
  - key: severity
    label: "Severity"
    required: true
    placeholder: "e.g., SEV1"
  - key: affected_product
    label: "Affected Product/Feature"
    required: true
    placeholder: "e.g., REST API, Dashboard, Mobile App"
  - key: customer_impact
    label: "Customer Impact Description"
    required: false
    placeholder: "e.g., Users may experience slow page loads"
features:
  - INCIDENT
---

# Customer Communication During Incident

Incident: **{{ incident_title }}**
Severity: **{{ severity }}** | Product: **{{ affected_product }}**
Impact: **{{ customer_impact }}**

## Communication Principles

1. **Be transparent** — acknowledge the issue, do not hide or minimize
2. **Be empathetic** — lead with customer impact, not technical details
3. **Be timely** — communicate within 20 minutes of SEV1, 30 minutes of SEV2
4. **Be specific** — state what is affected, what is not, and when the next update is
5. **Avoid blame** — never point fingers at vendors, teams, or individuals publicly

## Timing Guidelines

| Severity | First Update | Ongoing Updates | Resolution Update |
|----------|-------------|-----------------|-------------------|
| SEV1 | Within 15 min | Every 30 min | Within 1 hour of resolution |
| SEV2 | Within 30 min | Every 60 min | Within 2 hours of resolution |
| SEV3 | Within 2 hours | As needed | Next business day |

## Status Page Templates

### Investigating
```
Title: Degraded Performance — {{ affected_product }}

We are investigating reports of {{ customer_impact }}. Our engineering team
is actively working to identify the root cause.

Affected: {{ affected_product }}
Current status: Investigating
Next update: [time, within 30 minutes]
```

### Identified
```
Title: Degraded Performance — {{ affected_product }}

We have identified the cause of {{ customer_impact }}. Our team is
implementing a fix and we expect to have an update within [timeframe].

Affected: {{ affected_product }}
Current status: Identified
Next update: [time]
```

### Monitoring
```
Title: Degraded Performance — {{ affected_product }}

A fix has been implemented for the issue causing {{ customer_impact }}.
We are monitoring the situation to ensure full recovery.

Affected: {{ affected_product }}
Current status: Monitoring
Next update: [time, within 60 minutes]
```

### Resolved
```
Title: Resolved — {{ affected_product }}

The issue causing {{ customer_impact }} has been resolved. Service has
returned to normal operation.

Duration: [start time] to [end time]
Root cause: [brief, non-technical summary]

We apologize for any inconvenience and are taking steps to prevent
recurrence. A detailed post-incident report will be published within
[48 hours / 5 business days].
```

## Email Templates

### Customer Notification Email
```
Subject: [Service Update] {{ affected_product }} — {{ incident_title }}

Dear [Customer],

We are writing to let you know that we are currently experiencing an issue
with {{ affected_product }} that may be affecting your experience.

What is happening:
{{ customer_impact }}

What we are doing:
Our engineering team identified the issue and is actively working on a
resolution. We expect to have this resolved by [estimated time].

What you can do:
[Provide workaround if available, or state "No action is needed on your end."]

We will provide another update by [time]. You can also follow real-time
updates on our status page at [URL].

We sincerely apologize for the disruption.

[Your Team]
```

### Resolution Email
```
Subject: [Resolved] {{ affected_product }} — {{ incident_title }}

Dear [Customer],

The issue with {{ affected_product }} has been resolved as of [time].
All services are operating normally.

What happened:
[Brief, non-technical explanation]

Duration: [start] to [end]

What we are doing to prevent recurrence:
[List 1-2 concrete preventive measures]

If you continue to experience any issues, please contact our support
team at [support email/link].

Thank you for your patience.

[Your Team]
```

## Social Media Templates

### Twitter/X — Acknowledging
```
We're aware of an issue affecting {{ affected_product }} and our team is
investigating. We'll share updates on our status page: [URL]
```

### Twitter/X — Resolved
```
The issue affecting {{ affected_product }} has been resolved. We apologize
for the inconvenience. Details: [status page URL]
```

## Support Team Talking Points

Provide these to customer support during the incident:

- **What is happening:** {{ customer_impact }}
- **Who is affected:** [specific user segment or "all users"]
- **ETA for resolution:** [provide if known, otherwise "our team is actively working on it"]
- **Workaround:** [describe if available]
- **Escalation path:** [do not escalate individual tickets during active incident, refer to status page]
- **What NOT to say:** Do not speculate on root cause, do not provide technical details, do not commit to specific timelines unless confirmed by IC
