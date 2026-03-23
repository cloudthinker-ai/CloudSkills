---
name: reserved-instance-planning
enabled: true
description: |
  Use when performing reserved instance planning — analyzes current cloud
  compute usage patterns to recommend optimal reserved instance or savings plan
  purchases. Covers utilization analysis, commitment term selection, payment
  option comparison, coverage gap identification, and ongoing reservation
  management.
required_connections:
  - prefix: cloud-billing
    label: "Cloud Billing Account"
config_fields:
  - key: cloud_provider
    label: "Cloud Provider"
    required: true
    placeholder: "e.g., AWS, GCP, Azure"
  - key: analysis_period_days
    label: "Usage Analysis Period (days)"
    required: true
    placeholder: "e.g., 90"
  - key: commitment_budget
    label: "Annual Commitment Budget"
    required: false
    placeholder: "e.g., $500,000"
features:
  - COST_MANAGEMENT
  - FINOPS
  - COMPUTE
---

# Reserved Instance Planning

## Phase 1: Usage Analysis
1. Collect compute usage data for the analysis period
   - [ ] Instance types and sizes
   - [ ] Utilization patterns (steady-state vs. burst)
   - [ ] Regional distribution
   - [ ] Operating system and tenancy
   - [ ] Hours running per month per instance type
2. Identify steady-state baseline workloads
3. Separate predictable from variable workloads
4. Calculate current on-demand spend by instance family

### Usage Pattern Classification

| Instance Family | Region | Avg Utilization | Pattern | RI Candidate |
|----------------|--------|-----------------|---------|-------------|
|                |        | %               | Steady/Burst/Scheduled | Yes/No |

## Phase 2: Commitment Options Analysis

### Payment Option Comparison

| Option | Upfront Cost | Monthly Cost | Total Cost (1yr) | Total Cost (3yr) | Savings vs On-Demand |
|--------|-------------|-------------|-----------------|-----------------|---------------------|
| On-Demand | $0 | | | | 0% |
| No Upfront RI | $0 | | | | ~% |
| Partial Upfront RI | | | | | ~% |
| All Upfront RI | | $0 | | | ~% |
| Savings Plan (Compute) | | | | | ~% |
| Savings Plan (Instance) | | | | | ~% |

1. Compare reserved instances vs. savings plans
2. Evaluate 1-year vs. 3-year commitment terms
3. Assess flexibility needs (instance size, region, family)
4. Calculate break-even points for each option

## Phase 3: Coverage Recommendation
1. Calculate optimal reservation coverage (typically 70-80% of steady-state)
2. Recommend specific reservations by instance family and region
3. Identify coverage gaps to fill with savings plans
4. Plan remaining variable workloads for on-demand or spot
5. Project annual savings from recommendations

### Recommended Purchases

| Priority | Type | Instance Family | Region | Quantity | Term | Payment | Monthly Savings |
|----------|------|----------------|--------|----------|------|---------|----------------|
| 1        |      |                |        |          |      |         |                |

## Phase 4: Purchase Execution
1. Get budget approval for commitment purchases
2. Execute purchases in priority order
3. Verify reservations apply to target instances
4. Set up utilization monitoring for new reservations
5. Document all purchases and expiration dates

## Phase 5: Ongoing Management
1. Monitor reservation utilization weekly
2. Identify underutilized or unused reservations
3. Plan exchanges or modifications for mismatched reservations
4. Queue renewal analysis 90 days before expiration
5. Review coverage quarterly and adjust strategy

## Counter-Rationalizations

| Shortcut | Counter | Why |
|----------|---------|-----|
| "We can skip some steps for this case" | Adapt the workflow steps, don't skip them | Skipped steps are where incidents and oversights originate |
| "The user seems to already know what to do" | Complete all workflow phases with the user | The workflow catches blind spots that experience alone misses |
| "This is a minor case, full process is overkill" | Scale the process down, don't turn it off | Minor cases become major when unstructured; the process scales, not disappears |
| "I'll fill in the details later" | Complete each section before moving on | Deferred details are forgotten; real-time capture is more accurate |
| "The template output isn't necessary" | Always produce the structured output format | Structured output enables comparison, audit trails, and handoff to other teams |

## Output Format
- **Usage Analysis Report**: Instance utilization patterns and classification
- **Savings Projection**: Cost comparison of commitment options
- **Purchase Recommendations**: Prioritized list with projected savings
- **Reservation Inventory**: All active commitments with expiration dates
- **Quarterly Review Template**: Coverage and utilization tracking

## Action Items
- [ ] Pull usage data for the analysis period
- [ ] Classify workloads by usage pattern
- [ ] Calculate savings projections for each option
- [ ] Get budget approval for recommended purchases
- [ ] Execute reservation purchases
- [ ] Set up ongoing utilization monitoring
- [ ] Schedule quarterly reservation review
