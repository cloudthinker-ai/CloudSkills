---
name: business-continuity-plan
enabled: true
description: |
  Template for developing and validating business continuity plans for critical services. Covers business impact analysis, recovery strategy definition, team roles and communication plans, failover procedures, testing schedules, and plan maintenance to ensure operational resilience during disruptions.
required_connections:
  - prefix: pagerduty
    label: "PagerDuty (or alerting tool)"
config_fields:
  - key: service_name
    label: "Service/Business Unit"
    required: true
    placeholder: "e.g., payment-processing, customer-support"
  - key: criticality
    label: "Business Criticality"
    required: true
    placeholder: "e.g., Tier 1 (critical), Tier 2 (important), Tier 3 (standard)"
  - key: max_downtime
    label: "Maximum Tolerable Downtime"
    required: true
    placeholder: "e.g., 4 hours, 24 hours"
features:
  - COMPLIANCE
  - BUSINESS_CONTINUITY
---

# Business Continuity Plan Skill

Develop BCP for **{{ service_name }}** ({{ criticality }}, max downtime: **{{ max_downtime }}**).

## Workflow

### Phase 1 — Business Impact Analysis

```
BUSINESS IMPACT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Service: {{ service_name }}
[ ] Criticality: {{ criticality }}
[ ] Maximum tolerable downtime: {{ max_downtime }}
[ ] Revenue impact per hour of downtime: $___
[ ] Customers affected by outage: ___
[ ] Regulatory impact of downtime: ___
[ ] Reputational impact: [ ] LOW  [ ] MEDIUM  [ ] HIGH

DEPENDENCY MAP
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Upstream dependencies:
    - ___: criticality: ___ | SLA: ___
    - ___: criticality: ___ | SLA: ___
[ ] Downstream dependents:
    - ___: impact if unavailable: ___
    - ___: impact if unavailable: ___
[ ] Third-party dependencies:
    - ___: SLA: ___ | alternative: ___
    - ___: SLA: ___ | alternative: ___
```

### Phase 2 — Recovery Objectives

```
RECOVERY TARGETS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Recovery Time Objective (RTO): ___
Recovery Point Objective (RPO): ___
Minimum Business Continuity Objective (MBCO): ___

RECOVERY TIERS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Tier | Recovery Time | Functions Restored
1    | 0 - 1 hour   | ___
2    | 1 - 4 hours  | ___
3    | 4 - 24 hours | ___
4    | 24 - 72 hours| ___
```

### Phase 3 — Recovery Strategies

```
STRATEGY PER SCENARIO
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Scenario                  | Strategy              | RTO    | Cost
Single server failure     | Auto-scaling/failover | ___    | ___
AZ failure                | Multi-AZ deployment   | ___    | ___
Region failure            | Multi-region failover | ___    | ___
Cloud provider outage     | Multi-cloud / manual  | ___    | ___
Cyber attack              | Isolation + restore   | ___    | ___
Data corruption           | Point-in-time restore | ___    | ___
Key personnel unavailable | Cross-training        | ___    | ___
Third-party outage        | Alternative provider  | ___    | ___
```

### Phase 4 — Team and Communication

```
INCIDENT TEAM
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Role                  | Primary       | Backup        | Contact
Incident Commander    | ___           | ___           | ___
Technical Lead        | ___           | ___           | ___
Communications Lead   | ___           | ___           | ___
Business Stakeholder  | ___           | ___           | ___
Vendor Liaison        | ___           | ___           | ___

COMMUNICATION PLAN
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Audience            | Channel       | Frequency    | Owner
Internal team       | Slack/Teams   | Real-time    | ___
Leadership          | Email/call    | Every ___ hr | ___
Customers           | Status page   | Every ___ hr | ___
Regulators          | Email         | As required  | ___
Media               | PR statement  | As needed    | ___
```

### Phase 5 — Testing and Maintenance

```
BCP TESTING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Test schedule:
    - Tabletop exercise: ___ (quarterly)
    - Functional test: ___ (semi-annual)
    - Full simulation: ___ (annual)
[ ] Last test date: ___
[ ] Last test result: [ ] PASS  [ ] PARTIAL  [ ] FAIL
[ ] Issues from last test:
    - ___
    - ___
[ ] Plan last updated: ___
[ ] Next review date: ___
[ ] Plan version: ___
[ ] Distribution list updated: [ ] YES
```

## Output Format

Produce a business continuity plan with:
1. **Business impact analysis** (criticality, dependencies, financial impact)
2. **Recovery objectives** (RTO, RPO, recovery tiers)
3. **Recovery strategies** (per scenario with costs)
4. **Team and communication** (roles, contacts, communication channels)
5. **Testing schedule** (exercises planned, last test results, improvements)
