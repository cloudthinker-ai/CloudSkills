---
name: incident-timeline-reconstruction
enabled: true
description: |
  Use when performing incident timeline reconstruction — post-incident timeline
  building framework for reconstructing the sequence of events from logs,
  alerts, chat messages, deployment records, and monitoring data. Provides
  structured approaches to gathering evidence, correlating timestamps,
  identifying gaps, and producing an authoritative incident timeline for
  postmortem analysis.
required_connections:
  - prefix: slack
    label: "Slack (for chat history retrieval)"
config_fields:
  - key: incident_title
    label: "Incident Title"
    required: true
    placeholder: "e.g., Cart service outage on 2024-01-15"
  - key: incident_start
    label: "Approximate Incident Start Time"
    required: true
    placeholder: "e.g., 2024-01-15 14:30 UTC"
  - key: incident_end
    label: "Approximate Incident End Time"
    required: true
    placeholder: "e.g., 2024-01-15 16:45 UTC"
features:
  - INCIDENT
---

# Incident Timeline Reconstruction

Incident: **{{ incident_title }}**
Window: **{{ incident_start }}** to **{{ incident_end }}**

## Purpose

A precise, evidence-backed timeline is the foundation of every good postmortem. This skill guides you through gathering data from multiple sources, correlating events, and producing a single authoritative timeline.

## Data Sources to Collect

### 1. Monitoring and Alerting
- [ ] Alert firing times from PagerDuty/OpsGenie/monitoring tool
- [ ] Dashboard screenshots at key moments
- [ ] Metric anomalies (latency spikes, error rate jumps, traffic drops)
- [ ] Health check failures and recovery times
- [ ] SLO/SLI breach timestamps

### 2. Deployment and Change Records
- [ ] CI/CD pipeline executions around the incident window
- [ ] Git commits and merges in the 24 hours before the incident
- [ ] Infrastructure changes (Terraform, CloudFormation, Kubernetes applies)
- [ ] Feature flag changes
- [ ] Database migrations
- [ ] Config changes (environment variables, secrets rotation)

### 3. Communication Records
- [ ] Incident Slack channel messages (with timestamps)
- [ ] Bridge call notes and recordings
- [ ] Email threads related to the incident
- [ ] Status page updates and times

### 4. System Logs
- [ ] Application logs around the incident window
- [ ] Infrastructure logs (load balancer, container orchestrator)
- [ ] Database slow query logs and error logs
- [ ] Network/firewall logs if relevant
- [ ] Cloud provider event logs (CloudTrail, Activity Log)

### 5. Customer Reports
- [ ] Support ticket timestamps
- [ ] Social media reports
- [ ] Customer-reported symptoms and timing

## Timeline Template

Record every event with its exact timestamp, source, and type:

| Time (UTC) | Source | Type | Event Description |
|------------|--------|------|-------------------|
| _HH:MM:SS_ | _monitoring/deploy/human/log_ | _trigger/detection/action/decision/resolution_ | _what happened_ |

### Event Types

- **Trigger** — the root cause event (deployment, config change, external failure)
- **Impact Start** — when users began experiencing the issue
- **Detection** — when the team became aware (alert, customer report)
- **Declaration** — when the incident was formally declared
- **Investigation** — diagnostic actions taken
- **Decision** — key decisions made by IC
- **Action** — mitigation or remediation actions executed
- **Mitigation** — when user impact was reduced or eliminated
- **Resolution** — when the incident was fully resolved

## Correlation Techniques

### Clock Synchronization
- Ensure all timestamps are in the same timezone (UTC preferred)
- Account for clock skew between systems (check NTP status)
- Note: Slack timestamps use the sender's timezone by default

### Gap Analysis
After building the initial timeline, look for:
- Gaps longer than 5 minutes during active investigation
- Events without a clear causal connection to adjacent events
- Missing human actions (who decided what and when?)
- Discrepancies between verbal accounts and logged evidence

### Causal Chain Mapping
For each event, ask:
- What caused this event?
- What did this event cause?
- Was this event preventable?
- Was this event detectable earlier?

## Timeline Review Process

1. **Individual accounts** — each responder writes their own timeline from memory
2. **Evidence merge** — combine individual accounts with system evidence
3. **Group review** — walk through the merged timeline as a group
4. **Gap filling** — investigate and resolve discrepancies
5. **Final timeline** — produce the authoritative version for the postmortem

## Counter-Rationalizations

| Shortcut | Counter | Why |
|----------|---------|-----|
| "We can skip some steps for this case" | Adapt the workflow steps, don't skip them | Skipped steps are where incidents and oversights originate |
| "The user seems to already know what to do" | Complete all workflow phases with the user | The workflow catches blind spots that experience alone misses |
| "This is a minor case, full process is overkill" | Scale the process down, don't turn it off | Minor cases become major when unstructured; the process scales, not disappears |
| "I'll fill in the details later" | Complete each section before moving on | Deferred details are forgotten; real-time capture is more accurate |
| "The template output isn't necessary" | Always produce the structured output format | Structured output enables comparison, audit trails, and handoff to other teams |

## Output Format

The final timeline should include:
- Every event with UTC timestamp and source
- Clear marking of trigger, detection, and resolution points
- Duration between key phases (trigger→detection, detection→mitigation, mitigation→resolution)
- Annotations for decisions and their rationale
- Gaps explicitly noted as "no data available" rather than omitted
