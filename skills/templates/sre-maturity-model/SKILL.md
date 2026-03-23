---
name: sre-maturity-model
enabled: true
description: |
  Use when performing sre maturity model — evaluates an organization's Site
  Reliability Engineering maturity across SLO management, incident response,
  toil reduction, capacity planning, and reliability culture. Produces a
  maturity scorecard and actionable roadmap for advancing reliability
  engineering practices.
required_connections:
  - prefix: monitoring
    label: "Monitoring Platform"
config_fields:
  - key: organization_name
    label: "Organization or Team Name"
    required: true
    placeholder: "e.g., Backend Platform Team"
  - key: service_count
    label: "Number of Production Services"
    required: true
    placeholder: "e.g., 40"
  - key: current_availability
    label: "Current Availability Target"
    required: false
    placeholder: "e.g., 99.9%"
features:
  - DEVOPS
  - SRE
  - RELIABILITY
---

# SRE Maturity Model Assessment

## Phase 1: SLO & Error Budget Management
1. Assess SLO practices
   - [ ] SLIs defined for all critical services
   - [ ] SLOs set based on user expectations and business needs
   - [ ] Error budgets calculated and tracked
   - [ ] Error budget policies defined (what happens when exhausted)
   - [ ] SLO dashboards accessible to all stakeholders
   - [ ] SLOs reviewed and adjusted quarterly
   - [ ] Tiered SLOs (critical vs. non-critical services)
2. Score: 1 (No SLOs) to 5 (Error budget driven development)

### SLO Coverage

| Service Tier | Service Count | SLIs Defined | SLOs Set | Error Budget Tracked | Coverage |
|-------------|--------------|-------------|---------|---------------------|----------|
| Tier 1 (Critical) | | | | | % |
| Tier 2 (Important) | | | | | % |
| Tier 3 (Standard) | | | | | % |

## Phase 2: Incident Management
1. Assess incident management maturity
   - [ ] Incident severity classification defined
   - [ ] On-call rotation with documented escalation paths
   - [ ] Incident response runbooks for common failures
   - [ ] Incident commander role defined and trained
   - [ ] Communication templates (internal and external)
   - [ ] Blameless post-incident reviews conducted
   - [ ] Action items tracked to completion
   - [ ] Incident metrics tracked (MTTD, MTTR, frequency)
2. Score: 1 (Reactive, ad hoc) to 5 (Proactive, systematic)

### Incident Metrics

| Metric | Current | Target | Trend |
|--------|---------|--------|-------|
| MTTD (Mean Time to Detect) | min | min | |
| MTTR (Mean Time to Recover) | min | min | |
| Incidents/month (Sev 1-2) | | < | |
| Post-incident reviews completed | % | 100% | |
| Action items completed on time | % | > 90% | |

## Phase 3: Toil Assessment
1. Evaluate toil levels
   - [ ] Toil defined and identified across teams
   - [ ] Toil measured (% of time on toil vs. engineering)
   - [ ] Toil reduction projects prioritized
   - [ ] Automation built to eliminate recurring toil
   - [ ] Target: < 50% of SRE time on toil
2. Identify top sources of toil

### Toil Inventory

| Toil Source | Frequency | Time/Occurrence | Total Hours/Month | Automatable | Priority |
|-------------|-----------|----------------|------------------|-------------|----------|
|             | /week     | min            |                  | Yes/Partial/No | 1-5    |

## Phase 4: Observability & Monitoring
1. Assess observability maturity
   - [ ] Metrics collection (infrastructure and application)
   - [ ] Structured logging with correlation IDs
   - [ ] Distributed tracing across services
   - [ ] Alerting with low noise (actionable alerts only)
   - [ ] Dashboards for service health and SLO status
   - [ ] Anomaly detection implemented
   - [ ] Synthetic monitoring for user journeys
2. Score: 1 (Minimal monitoring) to 5 (Full observability with AIOps)

## Phase 5: Capacity Planning & Reliability
1. Assess reliability engineering practices
   - [ ] Capacity planning process defined
   - [ ] Load testing performed regularly
   - [ ] Chaos engineering experiments conducted
   - [ ] Disaster recovery tested annually
   - [ ] Multi-region or multi-AZ architecture
   - [ ] Graceful degradation patterns implemented
   - [ ] Dependency management and circuit breakers
2. Score: 1 (No planning) to 5 (Proactive, chaos-tested)

## Phase 6: Culture & Organization
1. Assess SRE organizational maturity
   - [ ] Dedicated SRE team or embedded SRE roles
   - [ ] SRE engagement model defined (embedded, consulting, platform)
   - [ ] Shared ownership of reliability (dev teams participate)
   - [ ] Production readiness reviews for new services
   - [ ] Reliability considered in planning and prioritization
   - [ ] Knowledge sharing (tech talks, documentation, training)
2. Score: 1 (Ops team only) to 5 (Reliability is everyone's responsibility)

### Overall Maturity Scorecard

| Dimension | Score (1-5) | Key Strengths | Priority Gaps |
|-----------|-----------|---------------|---------------|
| SLOs & Error Budgets | | | |
| Incident Management | | | |
| Toil Reduction | | | |
| Observability | | | |
| Capacity & Reliability | | | |
| Culture & Organization | | | |
| **Overall** | **/5** | | |

## Counter-Rationalizations

| Shortcut | Counter | Why |
|----------|---------|-----|
| "We can skip some steps for this case" | Adapt the workflow steps, don't skip them | Skipped steps are where incidents and oversights originate |
| "The user seems to already know what to do" | Complete all workflow phases with the user | The workflow catches blind spots that experience alone misses |
| "This is a minor case, full process is overkill" | Scale the process down, don't turn it off | Minor cases become major when unstructured; the process scales, not disappears |
| "I'll fill in the details later" | Complete each section before moving on | Deferred details are forgotten; real-time capture is more accurate |
| "The template output isn't necessary" | Always produce the structured output format | Structured output enables comparison, audit trails, and handoff to other teams |

## Output Format
- **Maturity Scorecard**: Per-dimension scores with evidence
- **SLO Coverage Report**: Current SLO status across services
- **Toil Inventory**: Top toil sources with automation opportunities
- **Incident Metrics Dashboard**: MTTD, MTTR, frequency trends
- **Improvement Roadmap**: Prioritized initiatives with timeline

## Action Items
- [ ] Define SLIs and SLOs for all critical services
- [ ] Implement error budget tracking and policies
- [ ] Establish blameless post-incident review process
- [ ] Measure and reduce toil below 50%
- [ ] Set up comprehensive observability stack
- [ ] Begin regular chaos engineering experiments
- [ ] Schedule quarterly maturity re-assessment
