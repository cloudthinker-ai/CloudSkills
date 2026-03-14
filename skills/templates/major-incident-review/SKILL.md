---
name: major-incident-review
enabled: true
description: |
  Guides teams through a structured, blameless review of major incidents, covering timeline reconstruction, root cause analysis, contributing factors, and corrective actions. This template ensures incidents become learning opportunities that drive systemic improvements rather than finger-pointing exercises.
required_connections:
  - prefix: incident-management
    label: "Incident Management Platform"
  - prefix: monitoring
    label: "Monitoring Platform"
  - prefix: ticketing
    label: "Ticketing System"
config_fields:
  - key: incident_id
    label: "Incident ID"
    required: true
    placeholder: "e.g., INC-2026-0042"
  - key: incident_date
    label: "Incident Date"
    required: true
    placeholder: "e.g., 2026-03-10"
  - key: severity
    label: "Severity Level"
    required: true
    placeholder: "e.g., SEV1, P0"
features:
  - INCIDENT_REVIEW
  - POSTMORTEM
  - SRE_OPS
---

# Major Incident Review

## Phase 1: Incident Summary

Provide a concise overview of the incident.

- [ ] Incident ID: ___
- [ ] Date/Time (UTC): ___ to ___
- [ ] Duration: ___
- [ ] Severity: ___
- [ ] Services affected: ___
- [ ] Customer impact: ___
- [ ] Revenue impact (if known): ___
- [ ] SLA impact: ___
- [ ] Incident commander: ___

**One-sentence summary:** ___

## Phase 2: Timeline Reconstruction

Build a detailed, factual timeline using logs, metrics, and chat records.

| Time (UTC) | Event | Source |
|------------|-------|--------|
|            | First anomaly detected | Monitoring |
|            | Alert fired | Alerting system |
|            | Engineer paged | On-call system |
|            | Investigation started | Chat logs |
|            | Root cause identified | |
|            | Mitigation applied | |
|            | Service restored | |
|            | Incident closed | |

- [ ] All timestamps verified against system logs
- [ ] Detection time: ___ (time from first anomaly to alert)
- [ ] Response time: ___ (time from alert to engineer engaged)
- [ ] Mitigation time: ___ (time from engaged to impact resolved)

## Phase 3: Root Cause Analysis

**What happened (proximate cause):** ___

**Why it happened (root cause):** ___

**Contributing factors:**

| Factor | Category | Preventable |
|--------|----------|:-----------:|
|        | Code / Config / Process / Human / External | Y/N |

**Five Whys Analysis:**

1. Why did ___? Because ___
2. Why did ___? Because ___
3. Why did ___? Because ___
4. Why did ___? Because ___
5. Why did ___? Because ___

## Phase 4: What Went Well / What Needs Improvement

**What went well:**

1.
2.
3.

**What needs improvement:**

1.
2.
3.

**Where we got lucky:**

1.
2.

## Phase 5: Corrective Actions

| Action | Type | Priority | Owner | Due Date | Tracking Ticket |
|--------|------|:--------:|-------|----------|-----------------|
|        | Prevent / Detect / Mitigate | P0/P1/P2 | | | |

**Action Types:**

- **Prevent:** Stop this class of incident from happening
- **Detect:** Catch it faster next time
- **Mitigate:** Reduce impact when it does happen

- [ ] Each action has a clear owner and due date
- [ ] Actions address root cause, not just symptoms
- [ ] At least one action improves detection time

## Output Format

### Summary

- **Incident:** ___
- **Severity:** ___
- **Duration:** ___
- **Root cause:** ___
- **Customer impact:** ___
- **Corrective actions:** ___ total (___ P0, ___ P1, ___ P2)

### Action Items

- [ ] Publish incident review to engineering wiki
- [ ] Create tracking tickets for all corrective actions
- [ ] Present review at next engineering all-hands or SRE sync
- [ ] Schedule 30-day follow-up to verify corrective actions are complete
- [ ] Update monitoring and alerting based on detection gaps
- [ ] Update runbooks with lessons learned
