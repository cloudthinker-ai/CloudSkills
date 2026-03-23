---
name: reliability-scorecard
enabled: true
description: |
  Use when performing reliability scorecard — produces a comprehensive
  reliability scorecard for a service or system, evaluating it across multiple
  dimensions including availability, latency, durability, and operational
  readiness. Use this template to establish a baseline, track improvements over
  time, and benchmark services against organizational standards.
required_connections:
  - prefix: monitoring
    label: "Monitoring Platform"
  - prefix: incident-mgmt
    label: "Incident Management Tool"
config_fields:
  - key: service_name
    label: "Service Name"
    required: true
    placeholder: "e.g., payment-gateway"
  - key: tier
    label: "Service Tier"
    required: true
    placeholder: "e.g., Tier 1 (Critical)"
  - key: scoring_period
    label: "Scoring Period"
    required: true
    placeholder: "e.g., Q1 2026"
features:
  - RELIABILITY
  - SCORECARD
  - SRE_OPS
---

# Reliability Scorecard

## Phase 1: Data Collection

Gather metrics for each reliability dimension across the scoring period.

- [ ] Availability: Uptime percentage and total downtime minutes
- [ ] Latency: p50, p95, p99 response times
- [ ] Error rate: Percentage of failed requests
- [ ] Durability: Data loss events (count and severity)
- [ ] Incident count: Total incidents by severity (SEV1-SEV4)
- [ ] MTTR: Mean time to recovery per severity level
- [ ] MTTD: Mean time to detection per severity level
- [ ] Change failure rate: Percentage of deployments causing incidents

## Phase 2: Scoring

Rate each dimension on a 1-5 scale.

| Dimension | Score (1-5) | Target | Actual Metric | Notes |
|-----------|-------------|--------|---------------|-------|
| Availability | | 99.9% | | |
| Latency (p99) | | <200ms | | |
| Error Rate | | <0.1% | | |
| Durability | | Zero loss | | |
| MTTD | | <5 min | | |
| MTTR | | <30 min | | |
| Change Failure Rate | | <5% | | |
| On-call Burden | | <2 pages/week | | |
| Documentation | | Current | | |
| Disaster Recovery | | Tested | | |

**Scoring Guide:**

| Score | Meaning |
|-------|---------|
| 5 | Exceeds target consistently. Industry-leading. |
| 4 | Meets target. Minor gaps only. |
| 3 | Approaching target. Known improvement areas. |
| 2 | Below target. Active remediation needed. |
| 1 | Significantly below target. Immediate action required. |

## Phase 3: Gap Analysis

For each dimension scoring 3 or below:

1. - [ ] Identify root causes for underperformance
2. - [ ] List specific improvement initiatives
3. - [ ] Estimate effort and timeline for each initiative
4. - [ ] Assign owners

## Phase 4: Comparison

- [ ] Compare to previous scoring period
- [ ] Identify dimensions with improving/declining trends
- [ ] Benchmark against other services of the same tier

## Counter-Rationalizations

| Shortcut | Counter | Why |
|----------|---------|-----|
| "We can skip some steps for this case" | Adapt the workflow steps, don't skip them | Skipped steps are where incidents and oversights originate |
| "The user seems to already know what to do" | Complete all workflow phases with the user | The workflow catches blind spots that experience alone misses |
| "This is a minor case, full process is overkill" | Scale the process down, don't turn it off | Minor cases become major when unstructured; the process scales, not disappears |
| "I'll fill in the details later" | Complete each section before moving on | Deferred details are forgotten; real-time capture is more accurate |
| "The template output isn't necessary" | Always produce the structured output format | Structured output enables comparison, audit trails, and handoff to other teams |

## Output Format

### Scorecard Summary

- **Service:** ___
- **Tier:** ___
- **Period:** ___
- **Overall Score:** ___ / 50
- **Grade:** A (45-50) / B (38-44) / C (30-37) / D (20-29) / F (<20)

### Trend

| Dimension | Previous | Current | Delta |
|-----------|----------|---------|-------|
|           |          |         |       |

### Action Items

- [ ] Address all dimensions scoring 1-2 within 30 days
- [ ] Create improvement plans for dimensions scoring 3
- [ ] Share scorecard with service owners and stakeholders
- [ ] Schedule next scorecard review for end of next period
