---
name: cloud-commitment-calculator
enabled: true
description: |
  Calculates the optimal mix of reserved instances, savings plans, and committed use discounts based on historical usage data. Produces a purchase plan that maximizes savings while maintaining flexibility for workload changes, including break-even analysis and risk assessment.
required_connections:
  - prefix: cloud-billing
    label: "Cloud Billing Account"
config_fields:
  - key: cloud_provider
    label: "Cloud Provider"
    required: true
    placeholder: "e.g., AWS, GCP, Azure"
  - key: analysis_months
    label: "Months of Historical Data to Analyze"
    required: true
    placeholder: "e.g., 6"
  - key: risk_tolerance
    label: "Risk Tolerance for Commitments"
    required: false
    placeholder: "e.g., conservative, moderate, aggressive"
features:
  - COST_MANAGEMENT
  - FINOPS
---

# Cloud Commitment Calculator

## Phase 1: Historical Usage Analysis
1. Collect usage data for the analysis period
   - [ ] Compute hours by instance family, region, OS
   - [ ] Database instance hours by engine and size
   - [ ] Storage volume by tier
   - [ ] Data transfer volumes
2. Identify usage trends (growing, stable, declining)
3. Calculate minimum baseline usage (P10 percentile)
4. Determine steady-state usage (P50 percentile)
5. Map seasonal or cyclical patterns

### Usage Baseline Summary

| Resource Type | P10 (Minimum) | P50 (Steady) | P90 (Peak) | Trend |
|--------------|---------------|-------------|------------|-------|
| Compute      |               |             |            | +/-/= |
| Database     |               |             |            | +/-/= |
| Storage      |               |             |            | +/-/= |

## Phase 2: Commitment Options Modeling

### Coverage Scenarios

| Scenario | Coverage Target | Commitment Spend | On-Demand Remainder | Total Cost | Savings |
|----------|----------------|-----------------|--------------------|-----------| --------|
| Conservative | P10 baseline | $ | $ | $ | % |
| Moderate | P25-P50 | $ | $ | $ | % |
| Aggressive | P50-P75 | $ | $ | $ | % |

1. Model conservative coverage (commit only to minimum baseline)
2. Model moderate coverage (commit to steady-state)
3. Model aggressive coverage (commit to higher percentile)
4. Calculate risk of underutilization for each scenario
5. Factor in growth projections

## Phase 3: Break-Even Analysis
1. Calculate break-even utilization for each commitment type
2. Determine months to break-even for upfront payments
3. Assess penalty for early termination or modification
4. Model worst-case scenario (workload disappears)
5. Compare flexibility of different commitment types

### Break-Even Table

| Commitment Type | Term | Upfront | Break-Even Utilization | Break-Even Month | Flexibility |
|----------------|------|---------|----------------------|------------------|-------------|
| RI - No Upfront | 1yr | $0 | % | Month | Low |
| RI - Partial | 1yr | $ | % | Month | Low |
| RI - All Upfront | 1yr | $ | % | Month | Low |
| Savings Plan | 1yr | $ | % | Month | Medium |
| CUD | 1yr | $ | % | Month | Low |

## Phase 4: Optimal Purchase Plan
1. Generate recommended purchase list
2. Phase purchases over time to reduce risk
3. Stagger expiration dates for renewal flexibility
4. Allocate budget across commitment types
5. Reserve portion of budget for on-demand flexibility

### Recommended Purchases

| Priority | Type | Details | Term | Monthly Commit | Annual Savings | Purchase Date |
|----------|------|---------|------|---------------|---------------|---------------|
| 1 | | | | $ | $ | |

## Phase 5: Ongoing Monitoring
1. Track commitment utilization weekly
2. Compare actual savings vs. projected
3. Flag commitments below utilization threshold
4. Queue renewal analysis 90 days before expiration
5. Adjust strategy based on usage trend changes

## Output Format
- **Usage Analysis**: Historical patterns and baseline calculations
- **Scenario Comparison**: Side-by-side of coverage strategies
- **Purchase Plan**: Prioritized commitment purchases with dates
- **Break-Even Report**: Risk analysis per commitment
- **Monitoring Dashboard**: Utilization and savings tracking

## Action Items
- [ ] Extract historical usage data
- [ ] Calculate usage baselines and trends
- [ ] Model commitment scenarios
- [ ] Select strategy aligned with risk tolerance
- [ ] Get budget approval for purchase plan
- [ ] Execute purchases in phased schedule
- [ ] Set up utilization monitoring and alerts
