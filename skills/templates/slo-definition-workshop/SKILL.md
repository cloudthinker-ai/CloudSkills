---
name: slo-definition-workshop
enabled: true
description: |
  Use when performing slo definition workshop — sLO definition workflow covering
  SLI selection, target setting, error budget policy, alerting strategy, and
  stakeholder alignment. Use when establishing SLOs for a new service, revising
  existing targets, or implementing an SRE practice.
required_connections:
  - prefix: datadog
    label: "Datadog (or monitoring platform)"
config_fields:
  - key: service_name
    label: "Service Name"
    required: true
    placeholder: "e.g., checkout-api"
  - key: service_tier
    label: "Service Tier"
    required: true
    placeholder: "e.g., tier-1 (critical), tier-2 (important), tier-3 (internal)"
  - key: stakeholders
    label: "Stakeholders"
    required: false
    placeholder: "e.g., product-team, platform-team, leadership"
features:
  - SRE
  - OBSERVABILITY
---

# SLO Definition Workshop Skill

Define SLOs for **{{ service_name }}** ({{ service_tier }}).

## Workflow

### Step 1 — Service Context

Gather context about the service:

```
SERVICE PROFILE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Service: {{ service_name }}
Tier: {{ service_tier }}
Stakeholders: {{ stakeholders | "TBD" }}

User journeys this service supports:
1. [journey] — [criticality: critical/important/nice-to-have]
2. [journey] — [criticality]
3. [journey] — [criticality]

Current state:
  - Existing SLOs: YES / NO
  - Historical availability (last 30 days): ___%
  - Historical P95 latency (last 30 days): ___ms
  - Incident frequency (last 90 days): ___
```

### Step 2 — SLI Selection

Choose the right SLIs for each user journey:

```
SLI CANDIDATES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
AVAILABILITY SLI
  Definition: Proportion of valid requests served successfully
  Formula: (successful requests) / (total valid requests) * 100
  What counts as "successful": HTTP 2xx, 3xx (exclude 4xx from denominator)
  What counts as "valid": All requests excluding health checks
  [ ] SELECTED — YES / NO

LATENCY SLI
  Definition: Proportion of requests faster than threshold
  Formula: (requests < threshold) / (total requests) * 100
  Threshold: ___ms (P50) / ___ms (P95) / ___ms (P99)
  Measurement point: [server-side / client-side / edge]
  [ ] SELECTED — YES / NO

CORRECTNESS SLI (if applicable)
  Definition: Proportion of requests returning correct results
  Formula: (correct responses) / (total responses) * 100
  How "correct" is defined: [validation method]
  [ ] SELECTED — YES / NO

FRESHNESS SLI (for data pipelines)
  Definition: Proportion of data updated within threshold
  Formula: (records updated within X min) / (total records) * 100
  Freshness threshold: ___ minutes
  [ ] SELECTED — YES / NO

THROUGHPUT SLI (if applicable)
  Definition: Proportion of time throughput is above minimum
  Formula: (minutes above threshold) / (total minutes) * 100
  Minimum throughput: ___ rps
  [ ] SELECTED — YES / NO
```

### Step 3 — SLO Target Setting

```
SLO TARGETS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
| SLI | Target | Window | Rationale |
|-----|--------|--------|-----------|
| Availability | ___% | 30 days rolling | [why this target] |
| Latency (P95) | ___% < ___ms | 30 days rolling | [why this target] |
| Latency (P99) | ___% < ___ms | 30 days rolling | [why this target] |
| [Other SLI] | ___% | 30 days rolling | [why this target] |

GUIDANCE BY TIER:
  Tier 1 (critical): 99.9% availability (43 min/month budget)
  Tier 2 (important): 99.5% availability (3.6 hrs/month budget)
  Tier 3 (internal): 99.0% availability (7.2 hrs/month budget)

IMPORTANT: SLO should be achievable but aspirational.
  - Too aggressive: constant alert fatigue, team burnout
  - Too lenient: users experience poor reliability before SLO violation
  - Rule of thumb: set slightly above historical performance
```

### Step 4 — Error Budget Policy

```
ERROR BUDGET POLICY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
30-day error budget for {{ service_name }}:

| SLO Target | Budget (minutes/month) | Budget (requests/month*) |
|-----------|----------------------|------------------------|
| 99.99% | 4.3 min | 0.01% of requests |
| 99.9% | 43.2 min | 0.1% of requests |
| 99.5% | 216 min (3.6 hrs) | 0.5% of requests |
| 99.0% | 432 min (7.2 hrs) | 1.0% of requests |

BUDGET STATES AND ACTIONS:
  Budget > 50% remaining:
    [ ] Normal development velocity
    [ ] Feature work prioritized
    [ ] Experimentation encouraged

  Budget 20-50% remaining:
    [ ] Increased caution with risky changes
    [ ] Reliability improvements prioritized alongside features
    [ ] Review recent incidents for patterns

  Budget < 20% remaining:
    [ ] Feature freeze for this service
    [ ] All engineering effort on reliability
    [ ] Incident review required for every budget-consuming event

  Budget exhausted (0%):
    [ ] Full feature freeze
    [ ] Mandatory reliability sprint
    [ ] Executive review of service health
    [ ] Postmortem required before resuming feature work

BUDGET RESET: Monthly rolling window
```

### Step 5 — Alerting Strategy

```
SLO-BASED ALERTING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Multi-window, multi-burn-rate alerting:

FAST BURN (page immediately):
  - Window: 5 min
  - Burn rate: 14.4x (exhausts 30-day budget in 2 days)
  - Action: PAGE on-call

SLOW BURN (ticket within hours):
  - Window: 6 hours
  - Burn rate: 6x (exhausts budget in 5 days)
  - Action: PAGE on-call during business hours

STEADY BURN (ticket):
  - Window: 3 days
  - Burn rate: 1x (on track to exhaust budget)
  - Action: CREATE TICKET, review in next sprint

[ ] Alerts configured in monitoring platform
[ ] Alert routing configured (PagerDuty / OpsGenie)
[ ] Runbook linked to each alert
```

### Step 6 — Documentation & Alignment

```
SLO DOCUMENT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] SLO document published (wiki / repo)
[ ] Stakeholders reviewed and approved targets
[ ] Dashboard created showing SLO status and error budget
[ ] Error budget policy agreed upon with product team
[ ] Review cadence set: [monthly / quarterly]
[ ] First review date: [date]
```

## Counter-Rationalizations

| Shortcut | Counter | Why |
|----------|---------|-----|
| "We can skip some steps for this case" | Adapt the workflow steps, don't skip them | Skipped steps are where incidents and oversights originate |
| "The user seems to already know what to do" | Complete all workflow phases with the user | The workflow catches blind spots that experience alone misses |
| "This is a minor case, full process is overkill" | Scale the process down, don't turn it off | Minor cases become major when unstructured; the process scales, not disappears |
| "I'll fill in the details later" | Complete each section before moving on | Deferred details are forgotten; real-time capture is more accurate |
| "The template output isn't necessary" | Always produce the structured output format | Structured output enables comparison, audit trails, and handoff to other teams |

## Output Format

Produce an SLO definition document with:
1. **Service context** (name, tier, user journeys)
2. **SLI definitions** with measurement methodology
3. **SLO targets** with rationale
4. **Error budget** calculations and policy
5. **Alerting configuration** with burn-rate thresholds
6. **Stakeholder sign-off** tracker
