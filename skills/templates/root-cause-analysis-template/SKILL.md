---
name: root-cause-analysis-template
enabled: true
description: |
  Comprehensive root cause analysis framework combining 5-Whys analysis, Ishikawa (fishbone) diagrams, and fault tree analysis methods. Provides structured templates for identifying contributing factors, distinguishing root causes from symptoms, and generating actionable corrective and preventive actions.
required_connections:
  - prefix: slack
    label: "Slack (for RCA collaboration)"
config_fields:
  - key: incident_title
    label: "Incident Title"
    required: true
    placeholder: "e.g., Order processing failure on 2024-01-15"
  - key: incident_summary
    label: "Brief Incident Summary"
    required: true
    placeholder: "e.g., Orders failed to process for 2 hours due to database connection exhaustion"
  - key: incident_date
    label: "Incident Date"
    required: true
    placeholder: "e.g., 2024-01-15"
features:
  - INCIDENT
---

# Root Cause Analysis Template

Incident: **{{ incident_title }}**
Date: **{{ incident_date }}**
Summary: **{{ incident_summary }}**

## Method 1: 5-Whys Analysis

Start with the problem statement and ask "Why?" iteratively until you reach the root cause. Typically 3-7 levels deep.

### Problem Statement
_{{ incident_summary }}_

### Why Chain

| Level | Question | Answer | Evidence |
|-------|----------|--------|----------|
| **Why 1** | Why did [problem] occur? | _answer_ | _link to logs/metrics_ |
| **Why 2** | Why did [answer 1] happen? | _answer_ | _evidence_ |
| **Why 3** | Why did [answer 2] happen? | _answer_ | _evidence_ |
| **Why 4** | Why did [answer 3] happen? | _answer_ | _evidence_ |
| **Why 5** | Why did [answer 4] happen? | _answer_ | _evidence_ |

### 5-Whys Best Practices
- Each "Why" must be supported by evidence, not speculation
- If you branch (multiple answers to one "Why"), follow each branch
- Stop when you reach a cause that is actionable and within your control
- The root cause should be a process, system, or design flaw — not a person

## Method 2: Ishikawa (Fishbone) Diagram

Organize contributing factors across six categories:

### Categories and Contributing Factors

**People**
- [ ] Insufficient training or documentation
- [ ] Cognitive overload / fatigue
- [ ] Unfamiliarity with the system
- [ ] Communication breakdown
- _Additional factors:_

**Process**
- [ ] Missing or inadequate runbook
- [ ] Change management gaps
- [ ] Insufficient review process
- [ ] Missing pre-deployment checks
- _Additional factors:_

**Technology**
- [ ] Software bug or regression
- [ ] Infrastructure failure
- [ ] Capacity limitation
- [ ] Missing monitoring or alerting
- _Additional factors:_

**Environment**
- [ ] External dependency failure
- [ ] Network conditions
- [ ] Cloud provider issue
- [ ] Traffic pattern anomaly
- _Additional factors:_

**Measurement**
- [ ] Insufficient observability
- [ ] Missing SLIs/SLOs
- [ ] Alert threshold misconfiguration
- [ ] Delayed detection
- _Additional factors:_

**Design**
- [ ] Single point of failure
- [ ] Missing circuit breaker
- [ ] Inadequate retry/backoff logic
- [ ] Tight coupling between services
- _Additional factors:_

## Method 3: Fault Tree Analysis

Work backwards from the top-level failure event using AND/OR logic gates.

### Top Event
_{{ incident_summary }}_

### Fault Tree Structure
```
[Top Event: Service Failure]
├── OR ──┬── [Intermediate Event 1]
│        │   ├── AND ──┬── [Basic Event A]
│        │   │         └── [Basic Event B]
│        │   └── [Basic Event C]
│        │
│        └── [Intermediate Event 2]
│            ├── [Basic Event D]
│            └── [Basic Event E]
```

Fill in the fault tree with actual events:

| Event ID | Type | Description | Probability | Preventable |
|----------|------|-------------|-------------|-------------|
| TOP | Top Event | {{ incident_summary }} | — | — |
| IE-1 | Intermediate | _description_ | — | — |
| IE-2 | Intermediate | _description_ | — | — |
| BE-A | Basic Event | _description_ | _low/med/high_ | _yes/no_ |
| BE-B | Basic Event | _description_ | _low/med/high_ | _yes/no_ |

## Root Cause Classification

Classify the identified root cause(s):

| Category | Root Cause | Confidence | Actionable |
|----------|-----------|------------|------------|
| _process/technology/design_ | _description_ | _high/medium/low_ | _yes/no_ |

### Root Cause vs. Contributing Factor
- **Root cause**: The fundamental reason the incident occurred; removing it would have prevented the incident
- **Contributing factor**: Something that made the incident worse, slower to detect, or harder to resolve; removing it alone would not have prevented the incident

## Corrective and Preventive Actions

### Corrective Actions (fix the immediate problem)
| Action | Owner | Priority | Due Date | Ticket |
|--------|-------|----------|----------|--------|
| _action_ | _name_ | _P1/P2/P3_ | _date_ | _link_ |

### Preventive Actions (prevent recurrence)
| Action | Owner | Priority | Due Date | Ticket |
|--------|-------|----------|----------|--------|
| _action_ | _name_ | _P1/P2/P3_ | _date_ | _link_ |

### Detection Improvements (find it faster next time)
| Action | Owner | Priority | Due Date | Ticket |
|--------|-------|----------|----------|--------|
| _action_ | _name_ | _P1/P2/P3_ | _date_ | _link_ |
