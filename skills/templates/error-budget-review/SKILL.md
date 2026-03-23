---
name: error-budget-review
enabled: true
description: |
  Use when performing error budget review — guides teams through a structured
  review of their error budget consumption against defined SLOs. This template
  helps SRE teams assess reliability performance, identify budget burn patterns,
  and make data-driven decisions about feature velocity versus reliability
  investment.
required_connections:
  - prefix: monitoring
    label: "Monitoring Platform"
  - prefix: slo-tracker
    label: "SLO Tracking Tool"
config_fields:
  - key: service_name
    label: "Service Name"
    required: true
    placeholder: "e.g., checkout-api"
  - key: review_window
    label: "Review Window"
    required: true
    placeholder: "e.g., 30 days"
  - key: slo_target
    label: "SLO Target (%)"
    required: true
    placeholder: "e.g., 99.9"
features:
  - SLO_MANAGEMENT
  - ERROR_BUDGET
  - SRE_OPS
---

# Error Budget Review

## Phase 1: Budget Status Assessment

Gather current error budget data for the review window.

1. Record SLO and error budget status:
   - [ ] Current SLO target: ___%
   - [ ] Error budget total (minutes of allowed downtime): ___
   - [ ] Error budget consumed: ___%
   - [ ] Error budget remaining: ___%
   - [ ] Days remaining in the window: ___

2. Burn rate analysis:
   - [ ] Current burn rate (budget consumed per day): ___
   - [ ] Projected budget at end of window: ___%
   - [ ] Is the current burn rate sustainable? Y/N

## Phase 2: Incident and Degradation Review

Catalog events that consumed error budget.

| Date | Event Description | Duration (min) | Budget Consumed (%) | Root Cause Category | Preventable? |
|------|-------------------|----------------|---------------------|---------------------|--------------|
|      |                   |                |                     |                     |              |

**Root Cause Categories:** Infrastructure, Deployment, Dependency, Configuration, Capacity, Unknown

## Phase 3: Budget Burn Decision Matrix

| Budget Status | Action |
|---------------|--------|
| >50% remaining | Continue normal feature velocity. No restrictions. |
| 25-50% remaining | Increase review rigor. Require rollback plans for all deployments. |
| 10-25% remaining | Reduce deployment frequency. Prioritize reliability work. |
| <10% remaining | Feature freeze. All engineering effort on reliability. |
| Exhausted | Full freeze. Escalate to leadership. Conduct postmortem on budget exhaustion. |

## Phase 4: Trend Analysis

- [ ] Compare budget consumption to previous 3 review windows
- [ ] Identify recurring root cause categories
- [ ] Assess whether SLO targets are appropriately set
- [ ] Evaluate if measurement methodology is accurate

## Phase 5: Recommendations

1. For each top budget consumer:
   - [ ] Define preventive action
   - [ ] Assign owner
   - [ ] Set target completion date
   - [ ] Define expected budget impact

## Counter-Rationalizations

| Shortcut | Counter | Why |
|----------|---------|-----|
| "We can skip some steps for this case" | Adapt the workflow steps, don't skip them | Skipped steps are where incidents and oversights originate |
| "The user seems to already know what to do" | Complete all workflow phases with the user | The workflow catches blind spots that experience alone misses |
| "This is a minor case, full process is overkill" | Scale the process down, don't turn it off | Minor cases become major when unstructured; the process scales, not disappears |
| "I'll fill in the details later" | Complete each section before moving on | Deferred details are forgotten; real-time capture is more accurate |
| "The template output isn't necessary" | Always produce the structured output format | Structured output enables comparison, audit trails, and handoff to other teams |

## Output Format

### Summary

- **SLO:** ___% over ___ day window
- **Error budget status:** ___% consumed / ___% remaining
- **Burn rate assessment:** Sustainable / At Risk / Critical
- **Top budget consumer:** ___ (___% of total consumption)

### Action Items

- [ ] Update SLO documentation if targets are being adjusted
- [ ] File reliability improvement tickets for top 3 budget consumers
- [ ] Communicate budget status to stakeholders
- [ ] Schedule follow-up review in ___ days
