---
name: capacity-planning-review
enabled: true
description: |
  Use when performing capacity planning review — capacity planning workflow
  covering traffic forecasting, resource utilization analysis, scaling strategy,
  cost projections, and bottleneck identification. Use for quarterly capacity
  reviews, pre-launch planning, or scaling readiness assessments.
required_connections:
  - prefix: datadog
    label: "Datadog (or monitoring platform)"
config_fields:
  - key: service_name
    label: "Service Name"
    required: true
    placeholder: "e.g., api-gateway"
  - key: planning_horizon
    label: "Planning Horizon"
    required: true
    placeholder: "e.g., 6 months, 1 year"
  - key: growth_rate
    label: "Expected Growth Rate"
    required: false
    placeholder: "e.g., 20% MoM, 3x by Q4"
features:
  - SRE
  - CAPACITY
---

# Capacity Planning Review Skill

Perform capacity planning for **{{ service_name }}** over **{{ planning_horizon }}**.

## Workflow

### Step 1 — Current State Assessment

Gather current utilization metrics:

```
CURRENT UTILIZATION SNAPSHOT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Traffic:
  - Current RPS (avg): ___
  - Current RPS (peak): ___
  - Peak-to-average ratio: ___
  - Daily/weekly traffic patterns: [describe]

Compute:
  - Instance type/count: ___
  - CPU utilization (avg/p95): ___% / ___%
  - Memory utilization (avg/p95): ___% / ___%
  - Pod/container count: ___

Data:
  - Database size: ___ GB
  - Database connections (avg/max): ___ / ___
  - Cache hit ratio: ___%
  - Storage growth rate: ___ GB/month

Network:
  - Bandwidth utilization: ___ Mbps
  - Request latency (p50/p95/p99): ___ms / ___ms / ___ms
```

### Step 2 — Traffic Forecasting

```
TRAFFIC PROJECTION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Growth assumption: {{ growth_rate | "historical trend" }}

| Timeframe | Projected RPS (avg) | Projected RPS (peak) | Confidence |
|-----------|--------------------|--------------------|------------|
| Current   | [actual]           | [actual]           | -          |
| +1 month  | [projected]        | [projected]        | HIGH       |
| +3 months | [projected]        | [projected]        | MEDIUM     |
| +6 months | [projected]        | [projected]        | LOW        |
| +12 months| [projected]        | [projected]        | LOW        |

Known traffic events:
- [ ] Seasonal peaks (e.g., Black Friday, end-of-quarter)
- [ ] Planned launches or campaigns
- [ ] Market expansion or new customer onboarding
```

### Step 3 — Resource Projections

```
RESOURCE PROJECTIONS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
| Resource | Current | +3 Months | +6 Months | Limit | Headroom |
|----------|---------|-----------|-----------|-------|----------|
| Compute instances | X | Y | Z | Max | % |
| CPU cores | X | Y | Z | Max | % |
| Memory (GB) | X | Y | Z | Max | % |
| DB connections | X | Y | Z | Max | % |
| DB storage (GB) | X | Y | Z | Max | % |
| Cache memory | X | Y | Z | Max | % |
| Network bandwidth | X | Y | Z | Max | % |
```

### Step 4 — Bottleneck Analysis

Identify the **first constraint** that will be hit:

```
BOTTLENECK RANKING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Database connections — pool exhaustion before compute ceiling
[ ] CPU — compute-bound workload hits capacity
[ ] Memory — OOM kills or swap before CPU ceiling
[ ] Storage — disk fills before other limits
[ ] Network — bandwidth or connection limits
[ ] Rate limits — external API or service limits
[ ] Queue depth — message backlog grows unbounded
[ ] Third-party dependency — external service becomes bottleneck

First bottleneck: [resource] at [projected date]
Mitigation: [scaling action needed]
```

### Step 5 — Scaling Strategy

```
SCALING PLAN
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SHORT-TERM (0-3 months):
[ ] Adjust autoscaling thresholds (current: X%, target: Y%)
[ ] Increase max instance count / replica count
[ ] Optimize hot paths (profiling-driven)
[ ] Cache tuning (increase hit ratio)

MEDIUM-TERM (3-6 months):
[ ] Vertical scaling (larger instance types)
[ ] Database read replicas or sharding
[ ] CDN optimization
[ ] Async processing for non-critical paths

LONG-TERM (6-12 months):
[ ] Architecture changes (decompose monolith, event-driven)
[ ] Multi-region deployment
[ ] Database migration (scale-out solution)
[ ] Cost optimization (reserved instances, spot fleet)
```

### Step 6 — Cost Projection

| Resource | Current Monthly | +3 Months | +6 Months | Notes |
|----------|----------------|-----------|-----------|-------|
| Compute | $X | $Y | $Z | [scaling plan] |
| Database | $X | $Y | $Z | [growth + replicas] |
| Storage | $X | $Y | $Z | [growth rate] |
| Network | $X | $Y | $Z | [egress growth] |
| **Total** | **$X** | **$Y** | **$Z** | |

### Step 7 — Action Items

| Action | Priority | Timeline | Owner | Cost Impact |
|--------|----------|----------|-------|-------------|
| [action] | P1/P2/P3 | [date] | [name] | $X/month |

## Counter-Rationalizations

| Shortcut | Counter | Why |
|----------|---------|-----|
| "We can skip some steps for this case" | Adapt the workflow steps, don't skip them | Skipped steps are where incidents and oversights originate |
| "The user seems to already know what to do" | Complete all workflow phases with the user | The workflow catches blind spots that experience alone misses |
| "This is a minor case, full process is overkill" | Scale the process down, don't turn it off | Minor cases become major when unstructured; the process scales, not disappears |
| "I'll fill in the details later" | Complete each section before moving on | Deferred details are forgotten; real-time capture is more accurate |
| "The template output isn't necessary" | Always produce the structured output format | Structured output enables comparison, audit trails, and handoff to other teams |

## Output Format

Produce a capacity planning report with:
1. **Current state** utilization snapshot with key metrics
2. **Traffic forecast** with growth projections and confidence levels
3. **Resource projections** table with headroom analysis
4. **Bottleneck analysis** identifying first constraint and timeline
5. **Scaling plan** with short/medium/long-term actions
6. **Cost projection** with monthly cost trajectory
