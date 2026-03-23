---
name: finops-maturity-assessment
enabled: true
description: |
  Use when performing finops maturity assessment — finOps maturity review
  covering crawl/walk/run phases across cost visibility, optimization,
  governance, and organizational alignment. Based on the FinOps Foundation
  framework. Use for establishing FinOps practice, benchmarking maturity, or
  planning capability improvements.
required_connections:
  - prefix: aws
    label: "AWS (or cloud provider billing)"
config_fields:
  - key: organization
    label: "Organization Name"
    required: true
    placeholder: "e.g., Acme Corp"
  - key: monthly_cloud_spend
    label: "Monthly Cloud Spend"
    required: true
    placeholder: "e.g., $500K, $2M"
  - key: cloud_providers
    label: "Cloud Providers"
    required: false
    placeholder: "e.g., AWS, GCP, Azure"
features:
  - FINOPS
  - COST
---

# FinOps Maturity Assessment Skill

Assess FinOps maturity for **{{ organization }}** with **{{ monthly_cloud_spend }}** monthly cloud spend.

## Workflow

### Step 1 — Current State Overview

```
FINOPS OVERVIEW
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Organization: {{ organization }}
Monthly spend: {{ monthly_cloud_spend }}
Cloud providers: {{ cloud_providers | "TBD" }}
YoY spend growth: ___%
Engineering headcount: ___
Cost per engineer: $___/month

Current FinOps team:
  [ ] Dedicated FinOps role: YES / NO
  [ ] FinOps tools in use: [list]
  [ ] Executive sponsor: YES / NO
  [ ] Cost allocation tags: PARTIAL / FULL / NONE
```

### Step 2 — Capability 1: Cost Visibility

```
COST VISIBILITY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
CRAWL:
[ ] Cloud billing data accessible to finance team
[ ] Monthly cost reports generated
[ ] Total spend tracked at account/project level
[ ] Basic cost breakdown by service type

WALK:
[ ] Cost allocation tags on >80% of resources
[ ] Costs allocated to teams/products/business units
[ ] Shared costs distributed using fair allocation model
[ ] Unit cost metrics defined (cost per transaction, per user, per GB)
[ ] Cost anomaly detection configured
[ ] Daily cost reporting available

RUN:
[ ] Real-time cost dashboards accessible to all engineers
[ ] Showback/chargeback model implemented
[ ] Cost forecasting with <10% accuracy
[ ] Unit economics tracked and trending
[ ] Cost data integrated into CI/CD (cost of change)
[ ] Multi-cloud cost normalization

CURRENT PHASE: CRAWL / WALK / RUN
```

### Step 3 — Capability 2: Cost Optimization

```
COST OPTIMIZATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
CRAWL:
[ ] Identify unused resources (unattached EBS, idle instances)
[ ] Right-size over-provisioned instances (basic analysis)
[ ] Shut down non-production resources outside business hours
[ ] Delete old snapshots and unused storage

WALK:
[ ] Reserved Instances / Savings Plans cover >60% of steady-state
[ ] Spot instances used for fault-tolerant workloads
[ ] Autoscaling configured and tuned for major services
[ ] Storage lifecycle policies (S3 tiers, archive)
[ ] Database optimization (reserved, Aurora serverless, read replicas)
[ ] Regular optimization reviews (monthly)

RUN:
[ ] RI/SP coverage >80% with automated purchasing
[ ] Continuous right-sizing with automated recommendations
[ ] Architectural optimization (serverless, containers, managed services)
[ ] Workload scheduling (batch jobs on spot, off-peak processing)
[ ] Data transfer optimization (same-region, VPC endpoints)
[ ] Waste elimination automated (auto-cleanup, TTL resources)

CURRENT PHASE: CRAWL / WALK / RUN
ESTIMATED SAVINGS OPPORTUNITY: $___/month (___% of spend)
```

### Step 4 — Capability 3: Cost Governance

```
COST GOVERNANCE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
CRAWL:
[ ] Budget set at organizational level
[ ] Billing alerts for total spend threshold
[ ] Cloud access limited to authorized personnel
[ ] Basic tagging policy defined

WALK:
[ ] Per-team/project budgets established
[ ] Budget vs actual reviewed monthly
[ ] Tagging compliance enforced (>90%)
[ ] New resource provisioning has cost estimate
[ ] Cost approval process for large expenditures (>$X/month)
[ ] Quarterly FinOps review with leadership

RUN:
[ ] Automated budget enforcement (alerts + actions)
[ ] Policy-as-code for cost guardrails
[ ] Architecture reviews include cost impact analysis
[ ] Service catalogs with pre-approved, cost-efficient patterns
[ ] Procurement optimization (EDP, committed use discounts)
[ ] FinOps KPIs in engineering performance metrics

CURRENT PHASE: CRAWL / WALK / RUN
```

### Step 5 — Capability 4: Organizational Alignment

```
ORGANIZATIONAL ALIGNMENT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
CRAWL:
[ ] Finance and engineering aware of cloud costs
[ ] Basic cost awareness training available
[ ] At least one person accountable for cloud costs

WALK:
[ ] Engineers can see cost impact of their services
[ ] Team leads review their team's cloud spend monthly
[ ] FinOps community of practice established
[ ] Cost optimization part of sprint planning
[ ] Cost included in architecture decision records

RUN:
[ ] Cost efficiency is a first-class engineering metric
[ ] Teams have cost targets and report against them
[ ] FinOps embedded in product/engineering culture
[ ] Cost-aware development practices in engineering handbook
[ ] FinOps certifications across finance and engineering
[ ] Continuous improvement feedback loops

CURRENT PHASE: CRAWL / WALK / RUN
```

### Step 6 — Maturity Scorecard

```
MATURITY SCORECARD
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
| Capability | Phase | Score (1-5) | Target Phase |
|-----------|-------|-------------|-------------|
| Cost Visibility | CRAWL/WALK/RUN | ___/5 | [target] |
| Cost Optimization | CRAWL/WALK/RUN | ___/5 | [target] |
| Cost Governance | CRAWL/WALK/RUN | ___/5 | [target] |
| Org Alignment | CRAWL/WALK/RUN | ___/5 | [target] |
| **Overall** | **___** | **___/5** | **___** |

Scoring: 1=Not started, 2=Crawl, 3=Walk, 4=Run, 5=Advanced Run
```

### Step 7 — Improvement Roadmap

| Priority | Initiative | Phase Target | Effort | Savings Potential | Timeline |
|----------|-----------|-------------|--------|------------------|----------|
| P1 | [initiative] | CRAWL->WALK | [weeks] | $___/month | [quarter] |
| P2 | [initiative] | CRAWL->WALK | [weeks] | $___/month | [quarter] |
| P3 | [initiative] | WALK->RUN | [weeks] | $___/month | [quarter] |

## Counter-Rationalizations

| Shortcut | Counter | Why |
|----------|---------|-----|
| "We can skip some steps for this case" | Adapt the workflow steps, don't skip them | Skipped steps are where incidents and oversights originate |
| "The user seems to already know what to do" | Complete all workflow phases with the user | The workflow catches blind spots that experience alone misses |
| "This is a minor case, full process is overkill" | Scale the process down, don't turn it off | Minor cases become major when unstructured; the process scales, not disappears |
| "I'll fill in the details later" | Complete each section before moving on | Deferred details are forgotten; real-time capture is more accurate |
| "The template output isn't necessary" | Always produce the structured output format | Structured output enables comparison, audit trails, and handoff to other teams |

## Output Format

Produce a FinOps maturity report with:
1. **Current state** overview with spend metrics
2. **Capability assessments** per FinOps domain (crawl/walk/run)
3. **Maturity scorecard** with current and target phases
4. **Savings opportunities** with estimated dollar impact
5. **Improvement roadmap** with prioritized initiatives
