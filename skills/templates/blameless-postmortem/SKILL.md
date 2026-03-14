---
name: blameless-postmortem
enabled: true
description: |
  Blameless postmortem template covering incident timeline, contributing factors analysis, impact assessment, what went well, what could be improved, and concrete action items. Focuses on systemic improvements over individual blame. Use after any SEV1/SEV2 incident.
required_connections:
  - prefix: slack
    label: "Slack (for incident history)"
config_fields:
  - key: incident_title
    label: "Incident Title"
    required: true
    placeholder: "e.g., Checkout service outage - 2026-03-10"
  - key: severity
    label: "Severity"
    required: true
    placeholder: "e.g., SEV1, SEV2"
  - key: incident_date
    label: "Incident Date"
    required: true
    placeholder: "e.g., 2026-03-10"
  - key: duration
    label: "Incident Duration"
    required: false
    placeholder: "e.g., 2 hours 15 minutes"
features:
  - INCIDENT
  - RCA
---

# Blameless Postmortem Skill

Conduct a blameless postmortem for: **{{ incident_title }}**

## Blameless Culture Principles

Before beginning, remember:
- **People are not the root cause.** Systems, processes, and tools failed.
- **Focus on "how" not "who."** Ask "how did the system allow this?" not "who did this?"
- **Every action made sense at the time** given the information available.
- **The goal is learning**, not punishment.

## Workflow

### Step 1 — Incident Summary

```
INCIDENT SUMMARY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Title: {{ incident_title }}
Severity: {{ severity }}
Date: {{ incident_date }}
Duration: {{ duration | "TBD" }}

Detection time: ___
Resolution time: ___
Incident commander: ___
Authors of this postmortem: ___
Postmortem date: ___

ONE-LINE SUMMARY:
[One sentence describing what happened and the user impact]
```

### Step 2 — Impact Assessment

```
IMPACT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
USER IMPACT
  Users affected: ___ (___% of total)
  Duration of user impact: ___
  User experience: [what users saw — errors, slowness, data loss]
  User-facing services affected: [list]

BUSINESS IMPACT
  Revenue impact: $___  (estimated)
  SLA/SLO impact: ___ minutes of error budget consumed
  Support tickets generated: ___
  Social media / press mentions: ___

DATA IMPACT
  Data loss: YES / NO
  Data corruption: YES / NO
  If yes, describe: [details, records affected, recovery status]
```

### Step 3 — Timeline

Build a detailed chronological timeline:

```
TIMELINE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[HH:MM UTC] — TRIGGER: [event that initiated the incident]
[HH:MM UTC] — DETECTION: [how/when the incident was detected]
[HH:MM UTC] — [key event, investigation step, or decision]
[HH:MM UTC] — [key event, investigation step, or decision]
[HH:MM UTC] — MITIGATION: [action that stopped the bleeding]
[HH:MM UTC] — RESOLUTION: [action that fully resolved the issue]
[HH:MM UTC] — ALL CLEAR: [confirmation that service recovered]

Time to detect: ___ minutes
Time to mitigate: ___ minutes
Time to resolve: ___ minutes
```

### Step 4 — Contributing Factors

Identify systemic factors (NOT individual blame):

```
CONTRIBUTING FACTORS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
ROOT CAUSE:
[Technical root cause — be specific about the system failure]

CONTRIBUTING FACTORS (systemic):
1. [Factor]: [How did the system/process allow this to happen?]
2. [Factor]: [What guardrails were missing?]
3. [Factor]: [What made detection or recovery slow?]

TRIGGER vs ROOT CAUSE:
  Trigger: [The immediate event that started the incident]
  Root cause: [The underlying systemic issue that made the trigger dangerous]

"5 WHYS" ANALYSIS:
  Why 1: [surface cause]
  Why 2: [deeper cause]
  Why 3: [deeper cause]
  Why 4: [deeper cause]
  Why 5: [systemic root cause]
```

### Step 5 — What Went Well

```
WHAT WENT WELL
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] [Thing that worked — detection, response, communication, tooling]
[ ] [Thing that worked]
[ ] [Thing that worked]

Acknowledge the good: rapid detection, effective communication,
quick mitigation, teamwork, existing runbooks that helped, etc.
```

### Step 6 — What Could Be Improved

```
WHAT COULD BE IMPROVED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] [Gap in detection — how could we have caught this sooner?]
[ ] [Gap in prevention — what guardrail would have prevented this?]
[ ] [Gap in response — what slowed down mitigation?]
[ ] [Gap in communication — were stakeholders informed promptly?]
[ ] [Gap in tooling — what tools were missing or inadequate?]
```

### Step 7 — Action Items

```
ACTION ITEMS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PREVENT (stop this from happening again):
| # | Action | Owner | Due Date | Ticket | Status |
|---|--------|-------|----------|--------|--------|
| 1 | [action] | [name] | [date] | [link] | TODO |
| 2 | [action] | [name] | [date] | [link] | TODO |

DETECT (find this faster next time):
| # | Action | Owner | Due Date | Ticket | Status |
|---|--------|-------|----------|--------|--------|
| 1 | [action] | [name] | [date] | [link] | TODO |

MITIGATE (reduce impact if it happens again):
| # | Action | Owner | Due Date | Ticket | Status |
|---|--------|-------|----------|--------|--------|
| 1 | [action] | [name] | [date] | [link] | TODO |

PROCESS (improve response process):
| # | Action | Owner | Due Date | Ticket | Status |
|---|--------|-------|----------|--------|--------|
| 1 | [action] | [name] | [date] | [link] | TODO |
```

### Step 8 — Follow-Up

```
FOLLOW-UP
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Postmortem reviewed with team (meeting held)
[ ] Action items assigned and tracked in issue tracker
[ ] Action item review scheduled (2 weeks out)
[ ] Postmortem published to shared knowledge base
[ ] Related runbooks updated
[ ] Monitoring/alerting improvements deployed
```

## Output Format

Produce a blameless postmortem document with:
1. **Incident summary** (title, severity, duration, impact)
2. **Detailed timeline** with timestamps
3. **Contributing factors** with 5-whys analysis
4. **What went well** (acknowledge the good)
5. **Action items** categorized by prevent/detect/mitigate/process
6. **Follow-up tracker** with review dates
