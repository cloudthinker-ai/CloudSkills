---
name: cis-benchmark-aws
enabled: true
description: |
  CIS Benchmark assessment for AWS covering identity and access management, logging, monitoring, networking, and storage controls. Based on CIS AWS Foundations Benchmark v3.0. Use for security baseline validation or hardening projects.
required_connections:
  - prefix: aws
    label: "AWS"
config_fields:
  - key: account_id
    label: "AWS Account ID"
    required: true
    placeholder: "e.g., 123456789012"
  - key: account_alias
    label: "Account Alias / Name"
    required: true
    placeholder: "e.g., prod-main"
  - key: regions
    label: "Regions in Scope"
    required: false
    placeholder: "e.g., us-east-1, eu-west-1"
features:
  - SECURITY
  - COMPLIANCE
  - AWS
---

# CIS Benchmark for AWS Skill

Run CIS AWS Foundations Benchmark v3.0 assessment for account **{{ account_alias }}** ({{ account_id }}).

## Workflow

### Step 1 — Assessment Scope

1. **Account**: {{ account_id }} ({{ account_alias }})
2. **Regions**: {{ regions | "all active regions" }}
3. **Benchmark version**: CIS AWS Foundations Benchmark v3.0
4. **Assessment date**: [auto-populated]

### Step 2 — Section 1: Identity and Access Management

```
1. IAM
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] 1.1  — Maintain current contact details
[ ] 1.2  — Ensure security contact information is registered
[ ] 1.3  — Ensure security questions are registered (root account)
[ ] 1.4  — No root account access key exists
[ ] 1.5  — MFA enabled on root account
[ ] 1.6  — Hardware MFA on root account
[ ] 1.7  — Eliminate root usage for daily tasks
[ ] 1.8  — Minimum password length ≥14 characters
[ ] 1.9  — Password reuse prevention (≥24 passwords)
[ ] 1.10 — MFA enabled for all IAM users with console access
[ ] 1.11 — No access keys created during initial user setup
[ ] 1.12 — Credentials unused for ≥45 days are disabled
[ ] 1.13 — Only one active access key per IAM user
[ ] 1.14 — Access keys rotated every ≤90 days
[ ] 1.15 — No IAM user has inline policies
[ ] 1.16 — No full "*:*" admin privileges in IAM policies
[ ] 1.17 — IAM users are members of groups (not standalone)
[ ] 1.18 — IAM instance roles used for EC2 (not access keys)
[ ] 1.19 — Expired SSL/TLS certificates removed from IAM
[ ] 1.20 — IAM Access Analyzer enabled in all regions
```

### Step 3 — Section 2: Logging

```
2. LOGGING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] 2.1  — CloudTrail enabled in all regions
[ ] 2.2  — CloudTrail log file validation enabled
[ ] 2.3  — CloudTrail S3 bucket not publicly accessible
[ ] 2.4  — CloudTrail integrated with CloudWatch Logs
[ ] 2.5  — AWS Config enabled in all regions
[ ] 2.6  — S3 bucket logging enabled on CloudTrail bucket
[ ] 2.7  — CloudTrail logs encrypted with KMS CMK
[ ] 2.8  — KMS key rotation enabled for CloudTrail encryption
[ ] 2.9  — VPC flow logging enabled in all VPCs
[ ] 2.10 — Object-level logging for read events on S3 (CloudTrail)
[ ] 2.11 — Object-level logging for write events on S3 (CloudTrail)
```

### Step 4 — Section 3: Monitoring

```
3. MONITORING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] 3.1  — Alarm for unauthorized API calls
[ ] 3.2  — Alarm for console sign-in without MFA
[ ] 3.3  — Alarm for root account usage
[ ] 3.4  — Alarm for IAM policy changes
[ ] 3.5  — Alarm for CloudTrail config changes
[ ] 3.6  — Alarm for console auth failures
[ ] 3.7  — Alarm for disabling/deleting CMKs
[ ] 3.8  — Alarm for S3 bucket policy changes
[ ] 3.9  — Alarm for AWS Config changes
[ ] 3.10 — Alarm for security group changes
[ ] 3.11 — Alarm for NACL changes
[ ] 3.12 — Alarm for network gateway changes
[ ] 3.13 — Alarm for route table changes
[ ] 3.14 — Alarm for VPC changes
```

### Step 5 — Section 4: Networking

```
4. NETWORKING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] 4.1  — No security groups allow ingress 0.0.0.0/0 to port 22
[ ] 4.2  — No security groups allow ingress 0.0.0.0/0 to port 3389
[ ] 4.3  — Default security group restricts all traffic
[ ] 4.4  — VPC peering least-access routing
```

### Step 6 — Section 5: Storage

```
5. STORAGE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] 5.1  — EBS volume encryption enabled by default
[ ] 5.2  — S3 bucket-level public access blocked (Block Public Access)
[ ] 5.3  — S3 buckets use SSE or KMS encryption
[ ] 5.4  — RDS instances have encryption at rest enabled
```

### Step 7 — Scoring & Report

| CIS Section | Controls Passed | Controls Failed | Score |
|-------------|----------------|-----------------|-------|
| 1. IAM | X/20 | Y | Z% |
| 2. Logging | X/11 | Y | Z% |
| 3. Monitoring | X/14 | Y | Z% |
| 4. Networking | X/4 | Y | Z% |
| 5. Storage | X/4 | Y | Z% |
| **Overall** | **X/53** | **Y** | **Z%** |

## Output Format

Produce a CIS Benchmark report with:
1. **Assessment header** (account, regions, benchmark version, date)
2. **Per-section checklists** with PASS/FAIL and evidence per control
3. **Score summary** table with per-section and overall percentage
4. **Critical findings** (Level 1 failures) with remediation steps
5. **Remediation runbook** with AWS CLI commands for each failed control
