---
name: cost-optimization-report
enabled: true
description: |
  Use when performing cost optimization report — generate a comprehensive cloud
  cost optimization report by analyzing spending patterns, identifying waste,
  and recommending savings opportunities across AWS, GCP, or Azure. Covers idle
  resource detection, rightsizing, reserved instance/commitment analysis, and
  prioritized savings recommendations.
required_connections:
  - prefix: aws
    label: "AWS"
config_fields:
  - key: cloud_provider
    label: "Cloud Provider"
    required: true
    placeholder: "e.g., aws, gcp, azure"
  - key: time_period
    label: "Analysis Period"
    required: false
    placeholder: "e.g., last 30 days, last quarter"
  - key: cost_threshold
    label: "Minimum Monthly Waste Threshold ($)"
    required: false
    placeholder: "e.g., 100"
  - key: focus_areas
    label: "Focus Areas (optional)"
    required: false
    placeholder: "e.g., compute, storage, network, database"
features:
  - COST
---

# Cloud Cost Optimization Report Skill

Generate a structured cost optimization report for **{{ cloud_provider | uppercase }}** covering **{{ time_period | "last 30 days" }}**.

## Workflow

### Step 1 — Establish Cost Baseline

Gather current spending data:

1. **Total monthly spend** — current month vs prior 3 months
2. **Cost breakdown by service** — top 10 services by spend
3. **Cost by team/account/project** — identify top-spending business units
4. **Month-over-month trend** — is spend growing, stable, or declining?
5. **Budget vs actuals** — are budgets being exceeded?

**Expected output from this step:**
```
COST BASELINE — {{ cloud_provider | uppercase }}
Period: {{ time_period }}

Total Spend: $X,XXX/month
MoM Change: +/-X%
Top Services:
  1. [Service]: $X,XXX (XX%)
  2. [Service]: $X,XXX (XX%)
  ...
```

### Step 2 — Idle & Unused Resource Detection

For each service category, identify resources with zero or near-zero utilization:

**Compute:**
- Stopped/terminated EC2/GCE/VMs still incurring storage costs
- EC2 instances with CPU < 5% over 14 days
- Auto Scaling Groups at minimum capacity 24/7 (no scaling events)

**Storage:**
- Unattached EBS volumes / Persistent Disks
- Snapshots older than 90 days without recent access
- S3 buckets with no GET requests in 30 days (excluding logging buckets)
- Empty storage containers / buckets

**Networking:**
- Elastic IPs not associated with running instances
- Idle NAT Gateways (< 100MB/day transfer)
- Unused Load Balancers (0 healthy targets or 0 requests)
- Unattached Elastic Network Interfaces

**Database:**
- RDS/Cloud SQL instances with CPU < 2% and zero connections for 7 days
- Read replicas with zero replica lag and zero queries

**Other:**
- Unused Elastic Container Registries with images > 1 year old
- CloudFormation stacks in ROLLBACK state
- Forgotten development environments running in production accounts

**Threshold for waste reporting:** ${{ cost_threshold | "50" }}/month minimum

### Step 3 — Rightsizing Analysis

Identify over-provisioned resources:

**Compute Rightsizing:**
```
For each compute instance with metrics:
- Average CPU over 14 days < 20% → downsize
- Average memory over 14 days < 30% → downsize
- Max CPU burst < 50% → no need for burstable exclusion
- Calculate estimated savings from downsizing
```

**Database Rightsizing:**
```
For each database instance:
- Average CPU < 15% → eligible for smaller instance class
- FreeableMemory average > 75% of allocated → memory over-provisioned
- IOPS average < 30% of provisioned → IOPS over-provisioned (if io1/io2)
```

### Step 4 — Commitment / Reserved Capacity Analysis

Evaluate savings from longer-term commitments:

1. **On-Demand vs Reserved Instance coverage**
   - What % of compute is on-demand vs reserved?
   - Which on-demand instances are running 24/7 (RI candidates)?
   - Reserved Instance utilization — are purchased RIs being used?

2. **Savings Plan analysis**
   - What is current Savings Plan coverage?
   - Recommended Savings Plan commitment amount

3. **Commitment recommendation:**
   - Stable workloads running > 80% of time → 1-year reserved/committed
   - Very stable workloads → 3-year for maximum savings
   - Variable workloads → on-demand or spot-eligible

### Step 5 — Spot / Preemptible Opportunities

Identify workloads that can run on spot/preemptible instances:

- Batch processing jobs
- CI/CD build agents
- Dev/test environments
- Stateless application tier (with proper interruption handling)
- ML training workloads

**Estimated savings:** 60-80% vs on-demand pricing

### Step 6 — Data Transfer & Network Costs

Analyze network spend:

- Cross-region data transfer costs
- NAT Gateway usage vs VPC endpoints (S3, DynamoDB)
- CloudFront vs direct S3 serving for public assets
- VPC endpoint usage opportunities (eliminate NAT for AWS service traffic)

### Step 7 — Anomaly Detection

Identify unusual cost spikes:

- Services with >20% MoM increase without corresponding business growth
- New services with unexpected costs (developer experiments left running)
- Data transfer spikes (potential data exfiltration or misconfigured logging)
- Unexpected region usage

### Step 8 — Prioritized Recommendations

Rank all findings by impact and implementation effort:

```
SAVINGS RECOMMENDATIONS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

QUICK WINS (implement this week) — Low risk, immediate savings
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
1. [Resource]: [Description]
   Monthly savings: $X,XXX | Risk: Low | Effort: Hours
   Action: [specific command or step]

2. [Resource]: [Description]
   Monthly savings: $XXX | Risk: Low | Effort: Minutes
   Action: [specific command or step]

MEDIUM TERM (implement this month) — Some coordination needed
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
3. Rightsizing [service]: [X] instances downsize from [type] to [type]
   Monthly savings: $X,XXX | Risk: Medium | Effort: Days
   Action: [specific steps with validation approach]

4. Reserved Instances: Purchase [X] RIs for [service]
   Monthly savings: $X,XXX | Risk: Low | Effort: Hours (approval needed)
   Action: [purchase via console/API]

STRATEGIC (this quarter) — Requires architectural changes
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
5. [Architectural change]: [description]
   Monthly savings: $X,XXX | Risk: High | Effort: Weeks
   Action: [high-level steps and considerations]
```

### Step 9 — Executive Summary

Produce a one-page summary:

```
COST OPTIMIZATION REPORT — {{ cloud_provider | uppercase }}
Generated: [date]
Period: {{ time_period }}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

CURRENT STATE
• Monthly Spend: $X,XXX
• MoM Trend: [+/-X%]
• Top Cost Driver: [service]

SAVINGS IDENTIFIED
• Quick Wins: $X,XXX/month (implement in <1 week)
• Medium Term: $X,XXX/month (implement in <1 month)
• Strategic: $X,XXX/month (implement in <1 quarter)
• Total Potential: $XX,XXX/month (XX% reduction)

TOP 3 RECOMMENDATIONS
1. [action]: $X,XXX/month
2. [action]: $X,XXX/month
3. [action]: $X,XXX/month

NEXT STEPS
• [Owner]: [Action] by [Date]
• [Owner]: [Action] by [Date]
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

Produce a structured report with:
1. **Cost baseline** with trends
2. **Waste inventory** (idle/unused resources with monthly cost)
3. **Rightsizing candidates** with specific recommendations
4. **Commitment opportunities** with ROI calculations
5. **Prioritized action plan** sorted by savings impact
6. **Executive summary** for leadership sharing
