---
name: devops-maturity-assessment
enabled: true
description: |
  Use when performing devops maturity assessment — assesses an organization's
  DevOps maturity across key dimensions including culture, automation,
  measurement, and sharing (CALMS). Produces a current maturity score,
  identifies improvement areas, and generates a prioritized roadmap for
  advancing DevOps practices.
required_connections:
  - prefix: project-management
    label: "Project Management Tool"
config_fields:
  - key: organization_name
    label: "Organization or Team Name"
    required: true
    placeholder: "e.g., Platform Engineering Team"
  - key: team_size
    label: "Engineering Team Size"
    required: true
    placeholder: "e.g., 50 engineers across 8 teams"
  - key: current_deployment_frequency
    label: "Current Deployment Frequency"
    required: false
    placeholder: "e.g., weekly, daily, multiple per day"
features:
  - DEVOPS
  - MATURITY
  - ASSESSMENT
---

# DevOps Maturity Assessment

## Phase 1: DORA Metrics Baseline
1. Measure the four key DORA metrics
   - [ ] Deployment Frequency: How often code deploys to production
   - [ ] Lead Time for Changes: Time from commit to production
   - [ ] Change Failure Rate: Percentage of deployments causing incidents
   - [ ] Mean Time to Recovery: Time to restore service after incident

### DORA Metrics Scorecard

| Metric | Current Value | Elite | High | Medium | Low | Rating |
|--------|-------------|-------|------|--------|-----|--------|
| Deployment Frequency | | On-demand (multi/day) | Daily-weekly | Monthly | < Monthly | |
| Lead Time | | < 1 hour | 1 day - 1 week | 1-6 months | > 6 months | |
| Change Failure Rate | | 0-15% | 16-30% | 31-45% | > 45% | |
| MTTR | | < 1 hour | < 1 day | 1 day - 1 week | > 1 week | |

## Phase 2: Culture Assessment
1. Evaluate DevOps culture dimensions
   - [ ] Collaboration between Dev and Ops (shared goals, no silos)
   - [ ] Blameless post-incident culture
   - [ ] Experimentation encouraged (fail fast, learn fast)
   - [ ] Knowledge sharing practices (docs, demos, guilds)
   - [ ] Shared on-call responsibility
   - [ ] Psychological safety for raising concerns
2. Score: 1 (Ad Hoc) to 5 (Optimized)

## Phase 3: Automation Assessment
1. Evaluate automation maturity
   - [ ] Source control (branching strategy, code review)
   - [ ] Build automation (CI pipeline, build times)
   - [ ] Test automation (unit, integration, e2e coverage)
   - [ ] Deployment automation (CD pipeline, rollback)
   - [ ] Infrastructure as Code (IaC coverage, drift detection)
   - [ ] Configuration management (secrets, feature flags)
   - [ ] Database schema automation
   - [ ] Security scanning automation (SAST, DAST, SCA)
2. Score: 1 (Manual) to 5 (Fully Automated)

### Automation Maturity Matrix

| Capability | Level 1 (Manual) | Level 2 (Scripted) | Level 3 (Automated) | Level 4 (Self-Service) | Level 5 (Autonomous) | Current |
|-----------|-----------------|-------------------|--------------------|-----------------------|---------------------|---------|
| Build | Manual | Scripts | CI pipeline | Self-service | Auto-optimizing | |
| Test | Manual | Some unit tests | CI testing | Full coverage | Continuous testing | |
| Deploy | Manual | Scripted | CD pipeline | Self-service deploy | Auto-deploy | |
| Infrastructure | Manual | Scripts | IaC partial | Full IaC | GitOps | |
| Security | Manual | Ad hoc scans | CI scanning | Shift-left | Continuous | |

## Phase 4: Measurement & Monitoring
1. Evaluate observability maturity
   - [ ] Application performance monitoring (APM)
   - [ ] Infrastructure monitoring
   - [ ] Log aggregation and analysis
   - [ ] Distributed tracing
   - [ ] SLOs and error budgets defined
   - [ ] Business metrics dashboards
   - [ ] Alerting quality (signal vs. noise)
2. Score: 1 (Reactive) to 5 (Predictive)

## Phase 5: Process & Governance
1. Evaluate process maturity
   - [ ] Change management (lightweight vs. heavy)
   - [ ] Incident management process
   - [ ] Capacity planning
   - [ ] Release management
   - [ ] Technical debt management
   - [ ] Compliance automation
2. Score: 1 (Ad Hoc) to 5 (Optimized)

### Overall Maturity Summary

| Dimension | Score (1-5) | Key Strengths | Key Gaps |
|-----------|-----------|---------------|----------|
| Culture | | | |
| Automation | | | |
| Measurement | | | |
| Sharing/Learning | | | |
| Process | | | |
| **Overall** | **/5** | | |

## Phase 6: Improvement Roadmap
1. Prioritize improvements by impact and effort
2. Define quick wins (< 1 month)
3. Define medium-term initiatives (1-3 months)
4. Define strategic improvements (3-6 months)
5. Assign ownership and success metrics

### Improvement Roadmap

| Priority | Initiative | Dimension | Current | Target | Effort | Timeline | Owner |
|----------|-----------|-----------|---------|--------|--------|----------|-------|
| 1 | | | | | Low/Med/High | | |

## Counter-Rationalizations

| Shortcut | Counter | Why |
|----------|---------|-----|
| "We can skip some steps for this case" | Adapt the workflow steps, don't skip them | Skipped steps are where incidents and oversights originate |
| "The user seems to already know what to do" | Complete all workflow phases with the user | The workflow catches blind spots that experience alone misses |
| "This is a minor case, full process is overkill" | Scale the process down, don't turn it off | Minor cases become major when unstructured; the process scales, not disappears |
| "I'll fill in the details later" | Complete each section before moving on | Deferred details are forgotten; real-time capture is more accurate |
| "The template output isn't necessary" | Always produce the structured output format | Structured output enables comparison, audit trails, and handoff to other teams |

## Output Format
- **DORA Metrics Report**: Current metrics with industry comparison
- **Maturity Scorecard**: Per-dimension scores with evidence
- **Gap Analysis**: Prioritized list of improvement areas
- **Improvement Roadmap**: Phased plan with timelines and owners
- **Executive Summary**: One-page overview for leadership

## Action Items
- [ ] Collect DORA metrics data
- [ ] Conduct team surveys and interviews
- [ ] Score all maturity dimensions
- [ ] Identify and prioritize improvement areas
- [ ] Develop phased improvement roadmap
- [ ] Present findings and roadmap to leadership
- [ ] Schedule quarterly re-assessment
