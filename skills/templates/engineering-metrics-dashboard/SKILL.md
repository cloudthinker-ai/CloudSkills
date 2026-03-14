---
name: engineering-metrics-dashboard
enabled: true
description: |
  Defines and structures an engineering metrics dashboard covering DORA metrics, quality indicators, operational health, and team productivity. This template helps engineering leaders select meaningful metrics, set targets, and build dashboards that drive data-informed decisions without encouraging metric gaming.
required_connections:
  - prefix: ci-cd
    label: "CI/CD Platform"
  - prefix: monitoring
    label: "Monitoring Platform"
  - prefix: ticketing
    label: "Ticketing System"
config_fields:
  - key: org_name
    label: "Organization / Team Name"
    required: true
    placeholder: "e.g., Engineering Division"
  - key: reporting_cadence
    label: "Reporting Cadence"
    required: true
    placeholder: "e.g., Weekly, Bi-weekly, Monthly"
features:
  - ENGINEERING_METRICS
  - DORA
  - OBSERVABILITY
---

# Engineering Metrics Dashboard

## Phase 1: DORA Metrics

Track the four key metrics from the DORA research program.

| Metric | Current | Target | Elite Benchmark |
|--------|---------|--------|-----------------|
| Deployment Frequency | ___ / week | | Multiple per day |
| Lead Time for Changes | ___ hours | | Less than 1 hour |
| Change Failure Rate | ___% | | 0-15% |
| Mean Time to Recovery | ___ hours | | Less than 1 hour |

**Data Sources:**

- [ ] Deployment frequency: source = ___
- [ ] Lead time: measured from ___ to ___
- [ ] Change failure rate: definition of failure = ___
- [ ] MTTR: measured from ___ to ___

## Phase 2: Quality Metrics

| Metric | Current | Target | Trend |
|--------|---------|--------|-------|
| Bug escape rate (bugs found in prod) | | | |
| Test coverage (%) | | | |
| P1/P2 incidents per month | | | |
| Tech debt ratio (% of sprint on debt) | | | |
| Code review turnaround time | | | |
| Build success rate (%) | | | |

## Phase 3: Operational Health

| Metric | Current | Target | Trend |
|--------|---------|--------|-------|
| Service availability (%) | | | |
| P50 / P99 latency | | | |
| Error rate (%) | | | |
| On-call pages per week | | | |
| Toil percentage (%) | | | |
| Infrastructure cost per request | | | |

## Phase 4: Team Productivity

| Metric | Current | Target | Trend |
|--------|---------|--------|-------|
| Cycle time (commit to production) | | | |
| PR merge time (avg) | | | |
| Sprint velocity (rolling avg) | | | |
| Work in progress (avg items) | | | |
| Planned vs unplanned work ratio | | | |
| Developer experience score (survey) | | | |

## Phase 5: Dashboard Design

- [ ] Select visualization tool: ___
- [ ] Define refresh frequency: ___
- [ ] Set up automated data collection pipelines
- [ ] Configure alerting for metrics that breach thresholds
- [ ] Ensure metrics are visible to the entire engineering org
- [ ] Add context annotations (deploys, incidents, re-orgs)

**Anti-Gaming Guidelines:**

- [ ] Use metrics for learning, not punishment
- [ ] Always pair efficiency metrics with quality metrics
- [ ] Review metric definitions quarterly
- [ ] Include qualitative feedback alongside quantitative data

## Output Format

### Summary

- **Organization:** ___
- **Reporting cadence:** ___
- **DORA performance level:** Elite / High / Medium / Low
- **Top improving metric:** ___
- **Metric needing attention:** ___

### Action Items

- [ ] Set up automated data collection for all metrics
- [ ] Build dashboard in selected visualization tool
- [ ] Establish baseline measurements for first reporting period
- [ ] Schedule recurring review meetings
- [ ] Communicate metric goals and anti-gaming guidelines to teams
- [ ] Review and refine metrics after first quarter
