---
name: incident-metrics-review
enabled: true
description: |
  Use when performing incident metrics review — incident response metrics
  analysis framework covering MTTR (Mean Time to Resolve), MTTA (Mean Time to
  Acknowledge), MTBF (Mean Time Between Failures), and MTTD (Mean Time to
  Detect). Provides calculation methods, benchmarking guidance, trend analysis
  templates, and actionable improvement recommendations for each metric.
required_connections:
  - prefix: slack
    label: "Slack (for metrics reporting)"
config_fields:
  - key: team_name
    label: "Team Name"
    required: true
    placeholder: "e.g., Platform Engineering"
  - key: review_period
    label: "Review Period"
    required: true
    placeholder: "e.g., Q4 2024, January 2024"
  - key: incident_source
    label: "Incident Data Source"
    required: false
    placeholder: "e.g., PagerDuty, OpsGenie, Jira"
features:
  - INCIDENT
---

# Incident Metrics Review

Team: **{{ team_name }}** | Period: **{{ review_period }}**
Data Source: **{{ incident_source }}**

## Core Metrics Definitions

### MTTD — Mean Time to Detect
Time from when an incident begins to when it is detected by monitoring or reported.

**Formula:** `MTTD = Average(detection_time - incident_start_time)`

**Why it matters:** Long MTTD means incidents are silently impacting users before anyone knows.

### MTTA — Mean Time to Acknowledge
Time from when an alert fires to when a responder acknowledges it.

**Formula:** `MTTA = Average(acknowledge_time - alert_fire_time)`

**Why it matters:** High MTTA indicates on-call responsiveness issues or alert fatigue.

### MTTR — Mean Time to Resolve
Time from incident detection to full resolution.

**Formula:** `MTTR = Average(resolution_time - detection_time)`

**Why it matters:** Primary measure of incident response effectiveness.

### MTBF — Mean Time Between Failures
Time between the resolution of one incident and the start of the next.

**Formula:** `MTBF = Average(next_incident_start - previous_incident_resolution)`

**Why it matters:** Low MTBF indicates systemic reliability issues.

## Data Collection Template

### Incident Log for {{ review_period }}

| # | Incident | Severity | Start Time | Detected | Acknowledged | Resolved | MTTD | MTTA | MTTR |
|---|----------|----------|------------|----------|-------------|----------|------|------|------|
| 1 | _title_ | _SEV_ | _time_ | _time_ | _time_ | _time_ | _min_ | _min_ | _min_ |
| 2 | _title_ | _SEV_ | _time_ | _time_ | _time_ | _time_ | _min_ | _min_ | _min_ |

### Summary Statistics

| Metric | SEV1 | SEV2 | SEV3 | All |
|--------|------|------|------|-----|
| Count | _n_ | _n_ | _n_ | _n_ |
| MTTD (avg) | _min_ | _min_ | _min_ | _min_ |
| MTTA (avg) | _min_ | _min_ | _min_ | _min_ |
| MTTR (avg) | _min_ | _min_ | _min_ | _min_ |
| MTBF (avg) | _days_ | _days_ | _days_ | _days_ |

## Benchmarks

Industry benchmarks for reference (adjust based on your context):

| Metric | Excellent | Good | Needs Improvement |
|--------|-----------|------|-------------------|
| MTTD | < 5 min | 5-15 min | > 15 min |
| MTTA | < 5 min | 5-15 min | > 15 min |
| MTTR (SEV1) | < 30 min | 30-60 min | > 60 min |
| MTTR (SEV2) | < 2 hours | 2-4 hours | > 4 hours |
| MTBF | > 30 days | 14-30 days | < 14 days |

## Trend Analysis

### Month-over-Month Comparison

| Metric | Previous Period | Current Period | Change | Trend |
|--------|----------------|---------------|--------|-------|
| Incident Count | _n_ | _n_ | _+/-_ | _improving/stable/declining_ |
| MTTD | _min_ | _min_ | _+/-_ | _improving/stable/declining_ |
| MTTA | _min_ | _min_ | _+/-_ | _improving/stable/declining_ |
| MTTR | _min_ | _min_ | _+/-_ | _improving/stable/declining_ |
| MTBF | _days_ | _days_ | _+/-_ | _improving/stable/declining_ |

### Distribution Analysis
- Incidents by severity: _% SEV1, % SEV2, % SEV3, % SEV4_
- Incidents by time of day: _% business hours, % after-hours, % weekends_
- Incidents by service: _top 3 services by incident count_
- Incidents by root cause category: _deployment, infrastructure, dependency, etc._

## Improvement Recommendations

### If MTTD is High
- Implement synthetic monitoring for critical user journeys
- Add anomaly detection to key business metrics
- Review alert coverage for gaps in observability
- Consider real-user monitoring (RUM) for client-side detection

### If MTTA is High
- Review on-call notification channels (push vs. SMS vs. phone)
- Audit alert routing rules for correctness
- Address alert fatigue by reducing false positives
- Review on-call engineer workload and burnout indicators

### If MTTR is High
- Invest in runbook automation for common incident types
- Improve diagnostic tooling and dashboards
- Conduct game days to practice incident response
- Review escalation policies for faster expert engagement
- Pre-build rollback procedures for every deployment

### If MTBF is Low
- Focus on systemic reliability improvements (redundancy, resilience)
- Review and prioritize postmortem action items
- Invest in chaos engineering to proactively find weaknesses
- Increase test coverage for failure scenarios

## Action Items

| Action | Impact on Metric | Effort | Owner | Target Date |
|--------|-----------------|--------|-------|-------------|
| _action_ | _MTTD/MTTA/MTTR/MTBF_ | _low/med/high_ | _name_ | _date_ |

## Counter-Rationalizations

| Shortcut | Counter | Why |
|----------|---------|-----|
| "We can skip some steps for this case" | Adapt the workflow steps, don't skip them | Skipped steps are where incidents and oversights originate |
| "The user seems to already know what to do" | Complete all workflow phases with the user | The workflow catches blind spots that experience alone misses |
| "This is a minor case, full process is overkill" | Scale the process down, don't turn it off | Minor cases become major when unstructured; the process scales, not disappears |
| "I'll fill in the details later" | Complete each section before moving on | Deferred details are forgotten; real-time capture is more accurate |
| "The template output isn't necessary" | Always produce the structured output format | Structured output enables comparison, audit trails, and handoff to other teams |

