---
name: infrastructure-code-review
enabled: true
description: |
  Use when performing infrastructure code review — infrastructure-as-Code review
  template for Terraform, CloudFormation, Pulumi, and other IaC tools. Covers
  security hardening, cost impact analysis, blast radius assessment, state
  management safety, and drift detection to ensure infrastructure changes are
  safe, secure, and cost-effective.
required_connections:
  - prefix: github
    label: "GitHub"
config_fields:
  - key: repository
    label: "Repository"
    required: true
    placeholder: "e.g., org/infrastructure"
  - key: pr_number
    label: "PR Number"
    required: true
    placeholder: "e.g., 1234"
  - key: iac_tool
    label: "IaC Tool"
    required: true
    placeholder: "e.g., Terraform, CloudFormation, Pulumi"
features:
  - CODE_REVIEW
---

# Infrastructure Code Review Skill

Review IaC PR **#{{ pr_number }}** in **{{ repository }}** using **{{ iac_tool }}**.

## Workflow

### Phase 1 — Security Review

```
SECURITY CHECK
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Network security:
    [ ] No 0.0.0.0/0 ingress rules (unless justified)
    [ ] Security groups follow least-privilege
    [ ] Private subnets used for internal services
    [ ] VPC flow logs enabled
[ ] IAM/Access:
    [ ] IAM policies follow least-privilege
    [ ] No wildcard (*) permissions
    [ ] No hardcoded credentials
    [ ] Service accounts use specific roles
[ ] Encryption:
    [ ] Encryption at rest enabled (EBS, S3, RDS)
    [ ] Encryption in transit enforced (TLS)
    [ ] KMS keys managed properly
    [ ] No public S3 buckets (unless intended)
[ ] Compliance:
    [ ] Resources tagged per organizational policy
    [ ] Logging enabled (CloudTrail, audit logs)
    [ ] Backup policies configured
```

### Phase 2 — Blast Radius

```
BLAST RADIUS ASSESSMENT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Resources being destroyed: ___
[ ] Resources being replaced: ___
[ ] Resources being modified in-place: ___
[ ] Cross-environment impact: YES / NO
[ ] Data loss risk: YES / NO
[ ] Downtime expected: YES / NO
[ ] Plan output reviewed: YES / NO
[ ] Lifecycle rules (prevent_destroy) on critical resources: YES / NO
```

### Phase 3 — Cost Impact

```
COST ANALYSIS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] New resources cost estimate: $___/month
[ ] Instance sizing appropriate: YES / NO
[ ] Reserved/spot instances considered: YES / NO
[ ] Auto-scaling configured with limits: YES / NO
[ ] Storage tier appropriate: YES / NO
[ ] Data transfer costs considered: YES / NO
[ ] Cost alerts/budgets configured: YES / NO
```

### Phase 4 — State and Operations

```
STATE MANAGEMENT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] State file location secure: YES / NO
[ ] State locking enabled: YES / NO
[ ] State import needed for existing resources: YES / NO
[ ] Module versioning used: YES / NO
[ ] Provider version pinned: YES / NO
[ ] Deployment order dependencies correct: YES / NO
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

Produce an infrastructure review report with:
1. **Security findings** (critical / high / medium / low)
2. **Blast radius assessment** (safe / moderate / dangerous)
3. **Cost impact estimate** (monthly delta)
4. **Deployment recommendations** (apply directly / phased / maintenance window)
5. **Required remediations** before approval
