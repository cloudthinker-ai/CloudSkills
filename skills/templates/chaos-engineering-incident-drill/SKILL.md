---
name: chaos-engineering-incident-drill
enabled: true
description: |
  Use when performing chaos engineering incident drill — planned failure
  injection exercise framework with observation checklists, hypothesis
  definition, blast radius controls, rollback procedures, and post-drill
  analysis. Guides teams through designing, executing, and learning from
  controlled chaos experiments to validate incident response readiness and
  system resilience.
required_connections:
  - prefix: slack
    label: "Slack (for drill coordination)"
config_fields:
  - key: drill_name
    label: "Drill Name"
    required: true
    placeholder: "e.g., Database failover drill"
  - key: target_service
    label: "Target Service/System"
    required: true
    placeholder: "e.g., payment-api, Redis cluster"
  - key: drill_date
    label: "Scheduled Date"
    required: true
    placeholder: "e.g., 2024-02-15 14:00 UTC"
  - key: environment
    label: "Target Environment"
    required: false
    placeholder: "e.g., staging, production-canary"
features:
  - INCIDENT
---

# Chaos Engineering Incident Drill

Drill: **{{ drill_name }}**
Target: **{{ target_service }}** | Environment: **{{ environment }}**
Scheduled: **{{ drill_date }}**

## Pre-Drill Planning

### Hypothesis
Define what you expect to happen:

> **Hypothesis:** When [failure injection], we expect [expected behavior]. The system should [recover/failover/degrade gracefully] within [time threshold] and monitoring should detect the issue within [detection threshold].

### Blast Radius Controls
- [ ] Drill is scoped to a single service / availability zone / percentage of traffic
- [ ] Kill switch is prepared and tested (how to stop the experiment instantly)
- [ ] Affected downstream services identified and owners notified
- [ ] Customer impact assessment completed (expected: none / minimal / controlled)
- [ ] Rollback procedure documented and ready

### Prerequisites Checklist
- [ ] Stakeholders notified (engineering, SRE, support, management)
- [ ] On-call team aware and standing by
- [ ] Monitoring dashboards open and shared
- [ ] Baseline metrics captured (latency, error rate, throughput)
- [ ] Experiment tooling tested (Chaos Monkey, Litmus, Gremlin, etc.)
- [ ] Incident channel created for drill coordination
- [ ] No conflicting deployments or maintenance windows
- [ ] Runbooks for the target service reviewed

### Abort Criteria
Stop the experiment immediately if:
- [ ] Customer impact exceeds expected threshold
- [ ] Error rates exceed ___% for more than ___ minutes
- [ ] Cascading failures detected beyond target blast radius
- [ ] Recovery does not begin within ___ minutes
- [ ] A real incident is declared during the drill

## Experiment Design

### Failure Injection Scenarios

| Scenario | Injection Method | Expected Behavior | Duration |
|----------|-----------------|-------------------|----------|
| _e.g., Kill primary DB_ | _terminate instance_ | _failover to replica_ | _5 min_ |
| _e.g., Network partition_ | _block traffic on port_ | _circuit breaker activates_ | _3 min_ |
| _e.g., CPU saturation_ | _stress-ng 100% CPU_ | _autoscaling triggers_ | _10 min_ |

### Observation Points

| What to Observe | Dashboard/Tool | Baseline Value | Threshold |
|----------------|---------------|---------------|-----------|
| Error rate | _Grafana/Datadog_ | _< 0.1%_ | _> 1%_ |
| Latency p99 | _APM tool_ | _200ms_ | _> 2000ms_ |
| Alert firing | _PagerDuty_ | _none_ | _within 5 min_ |
| Auto-recovery | _K8s/ASG_ | _N/A_ | _within 10 min_ |

## Drill Execution

### Phase 1: Baseline (T-10 min)
- [ ] Capture baseline metrics screenshot
- [ ] Confirm all monitoring is green
- [ ] Announce drill start in incident channel
- [ ] Confirm kill switch operator is ready

### Phase 2: Injection (T=0)
- [ ] Execute failure injection
- [ ] Start timer
- [ ] Begin observation log

### Phase 3: Observation (T+0 to T+N)

**Observation Log:**

| Time | Observation | Expected? | Notes |
|------|-------------|-----------|-------|
| T+0 | _injection executed_ | _yes_ | — |
| T+1m | _what happened_ | _yes/no_ | — |
| T+5m | _what happened_ | _yes/no_ | — |

### Phase 4: Recovery (after injection ends or abort)
- [ ] Stop failure injection / activate kill switch
- [ ] Monitor recovery metrics
- [ ] Record time to recovery
- [ ] Verify service returns to baseline

### Phase 5: Wrap-Up
- [ ] Announce drill complete in incident channel
- [ ] Capture post-drill metrics screenshot

## Post-Drill Analysis

### Results Summary

| Aspect | Expected | Actual | Pass/Fail |
|--------|----------|--------|-----------|
| Detection time | _X min_ | _Y min_ | _pass/fail_ |
| Alert fired correctly | _yes_ | _yes/no_ | _pass/fail_ |
| Auto-recovery worked | _yes_ | _yes/no_ | _pass/fail_ |
| Recovery time | _X min_ | _Y min_ | _pass/fail_ |
| Customer impact | _none_ | _none/minimal_ | _pass/fail_ |
| Blast radius contained | _yes_ | _yes/no_ | _pass/fail_ |

### Hypothesis Validation
- **Confirmed / Partially Confirmed / Refuted**
- Key findings: ___

### Findings and Action Items

| Finding | Severity | Action Item | Owner | Ticket |
|---------|----------|-------------|-------|--------|
| _finding_ | _high/med/low_ | _action_ | _name_ | _link_ |

### Recommendations for Next Drill
- Suggested next experiment: ___
- Environment upgrade needed: ___
- Tooling improvements: ___

## Counter-Rationalizations

| Shortcut | Counter | Why |
|----------|---------|-----|
| "We can skip some steps for this case" | Adapt the workflow steps, don't skip them | Skipped steps are where incidents and oversights originate |
| "The user seems to already know what to do" | Complete all workflow phases with the user | The workflow catches blind spots that experience alone misses |
| "This is a minor case, full process is overkill" | Scale the process down, don't turn it off | Minor cases become major when unstructured; the process scales, not disappears |
| "I'll fill in the details later" | Complete each section before moving on | Deferred details are forgotten; real-time capture is more accurate |
| "The template output isn't necessary" | Always produce the structured output format | Structured output enables comparison, audit trails, and handoff to other teams |

