---
name: security-audit-checklist
enabled: true
description: |
  Run a structured security audit across IAM, network, encryption, logging, and vulnerability management. Covers identity hygiene, network segmentation, data protection, and audit trail completeness. Use for periodic security reviews or pre-compliance preparation.
required_connections:
  - prefix: aws
    label: "AWS (or cloud provider)"
config_fields:
  - key: environment
    label: "Environment"
    required: true
    placeholder: "e.g., production, staging"
  - key: account_id
    label: "Account / Project ID"
    required: true
    placeholder: "e.g., 123456789012"
  - key: audit_scope
    label: "Audit Scope"
    required: false
    placeholder: "e.g., full, iam-only, network-only"
features:
  - SECURITY
  - COMPLIANCE
---

# Security Audit Checklist Skill

Perform a comprehensive security audit for **{{ environment }}** (Account: **{{ account_id }}**).

## Workflow

### Step 1 — Scope & Context

Establish audit parameters:
1. **Environment**: {{ environment }}
2. **Scope**: {{ audit_scope | "full audit" }}
3. **Date**: [auto-populated]
4. **Previous audit date**: [request from user if available]
5. **Known exceptions**: [document any pre-approved risk acceptances]

### Step 2 — IAM & Identity Review

```
IAM & IDENTITY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Root account has MFA enabled and no access keys
[ ] All human users use SSO/federation (no long-lived credentials)
[ ] Service accounts use roles/instance profiles, not static keys
[ ] IAM policies follow least-privilege principle
[ ] No wildcard (*) actions on sensitive resources
[ ] Unused IAM users/roles removed (inactive >90 days)
[ ] Cross-account access reviewed and justified
[ ] Password policy meets minimum complexity (14+ chars, rotation)
[ ] API key rotation schedule enforced (<90 days)
```

### Step 3 — Network Security Review

```
NETWORK SECURITY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] No security groups allow 0.0.0.0/0 on SSH (22) or RDP (3389)
[ ] Default VPC security groups deny all inbound
[ ] Network segmentation between tiers (web/app/data)
[ ] Private subnets used for databases and internal services
[ ] VPC flow logs enabled on all VPCs
[ ] WAF configured for public-facing endpoints
[ ] NACLs restrict traffic between subnets appropriately
[ ] No public S3 buckets / storage with sensitive data
[ ] VPN or private connectivity for admin access
```

### Step 4 — Encryption & Data Protection

```
ENCRYPTION & DATA PROTECTION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Encryption at rest enabled for all data stores
[ ] Encryption in transit (TLS 1.2+) enforced on all endpoints
[ ] KMS keys use customer-managed keys (not AWS-managed) for sensitive data
[ ] Key rotation enabled (annual minimum)
[ ] Secrets stored in secrets manager (not env vars or code)
[ ] No sensitive data in logs (PII, credentials, tokens)
[ ] Backup encryption enabled
[ ] S3 bucket policies enforce ssl-only access
```

### Step 5 — Logging & Monitoring

```
LOGGING & MONITORING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] CloudTrail enabled in all regions with log file validation
[ ] CloudTrail logs sent to centralized, immutable storage
[ ] GuardDuty / threat detection enabled
[ ] Security alerts configured for: root login, IAM changes, SG changes
[ ] Log retention meets compliance requirements (≥1 year)
[ ] Access logs enabled on load balancers and API gateways
[ ] DNS query logging enabled
[ ] Anomaly detection active on critical metrics
```

### Step 6 — Vulnerability Management

```
VULNERABILITY MANAGEMENT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Container/AMI vulnerability scanning in CI pipeline
[ ] Runtime vulnerability scanning on deployed workloads
[ ] Dependency scanning (SCA) in CI pipeline
[ ] Critical/High CVEs patched within SLA (7/30 days)
[ ] Penetration test conducted within last 12 months
[ ] Security findings tracked in issue tracker with SLA
```

### Step 7 — Risk Scoring & Report

For each section, assign a risk level:

| Section | Items Passed | Items Failed | Risk Level |
|---------|-------------|-------------|------------|
| IAM & Identity | X/Y | Z | LOW/MED/HIGH/CRIT |
| Network Security | X/Y | Z | LOW/MED/HIGH/CRIT |
| Encryption | X/Y | Z | LOW/MED/HIGH/CRIT |
| Logging | X/Y | Z | LOW/MED/HIGH/CRIT |
| Vulnerability Mgmt | X/Y | Z | LOW/MED/HIGH/CRIT |

**Overall Risk**: Highest individual risk level.

## Output Format

Produce a structured audit report with:
1. **Audit header** (environment, account, date, scope, auditor)
2. **Section checklists** with PASS/FAIL/N-A per item and evidence
3. **Risk matrix** with per-section and overall risk scores
4. **Critical findings** listed with remediation priority and owner
5. **Action items** table with severity, owner, and due date
