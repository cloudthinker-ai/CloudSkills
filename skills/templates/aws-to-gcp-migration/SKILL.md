---
name: aws-to-gcp-migration
enabled: true
description: |
  Use when performing aws to gcp migration — guides a structured migration from
  AWS to Google Cloud Platform, covering service mapping, data transfer
  strategies, IAM reconfiguration, networking changes, and validation testing.
  Produces a phased migration plan with rollback procedures and cost projections
  for the target environment.
required_connections:
  - prefix: aws
    label: "AWS Account"
  - prefix: gcp
    label: "GCP Project"
config_fields:
  - key: source_aws_account_id
    label: "Source AWS Account ID"
    required: true
    placeholder: "e.g., 123456789012"
  - key: target_gcp_project
    label: "Target GCP Project ID"
    required: true
    placeholder: "e.g., my-project-prod"
  - key: migration_timeline
    label: "Target Migration Timeline"
    required: false
    placeholder: "e.g., 6 months"
features:
  - CLOUD_MIGRATION
  - MULTI_CLOUD
---

# AWS to GCP Migration Plan

Guides a structured migration from AWS account **{{ source_aws_account_id }}** to GCP project **{{ target_gcp_project }}** with a target timeline of **{{ migration_timeline }}**.

## Workflow

### Step 1 — Discovery & Assessment
1. Inventory all AWS services currently in use
2. Map each AWS service to its GCP equivalent:
   - [ ] EC2 → Compute Engine
   - [ ] S3 → Cloud Storage
   - [ ] RDS → Cloud SQL / AlloyDB
   - [ ] Lambda → Cloud Functions / Cloud Run
   - [ ] DynamoDB → Firestore / Bigtable
   - [ ] SQS/SNS → Pub/Sub
   - [ ] EKS → GKE
   - [ ] CloudFront → Cloud CDN
   - [ ] Route 53 → Cloud DNS
   - [ ] IAM → Cloud IAM
3. Document dependencies between services
4. Identify services with no direct GCP equivalent and plan alternatives

### Step 2 — Architecture Design
1. Design target GCP architecture
2. Plan networking topology (VPC, subnets, firewall rules)
3. Map IAM roles and policies to GCP IAM
4. Design data migration strategy per data store
5. Plan DNS cutover strategy

#### Decision Matrix: Migration Approach per Workload

| Workload | Rehost | Replatform | Refactor | Retire |
|----------|--------|------------|----------|--------|
| Compute  | [ ]    | [ ]        | [ ]      | [ ]    |
| Database | [ ]    | [ ]        | [ ]      | [ ]    |
| Storage  | [ ]    | [ ]        | [ ]      | [ ]    |
| Network  | [ ]    | [ ]        | [ ]      | [ ]    |

### Step 3 — Foundation Setup
1. Configure GCP organization and project hierarchy
2. Set up networking (Shared VPC, Cloud Interconnect if needed)
3. Configure IAM and security policies
4. Set up monitoring with Cloud Monitoring and Cloud Logging
5. Establish CI/CD pipelines for GCP deployments

### Step 4 — Migration Execution
1. Migrate data stores (use Transfer Service, Database Migration Service)
2. Deploy compute workloads to GCP
3. Configure load balancers and traffic management
4. Run parallel environments for validation
5. Execute DNS cutover with gradual traffic shifting

### Step 5 — Validation & Optimization
1. Run integration and performance tests on GCP
2. Validate data integrity post-migration
3. Compare cost baseline between AWS and GCP
4. Optimize resource sizing and committed use discounts
5. Decommission AWS resources after stabilization period

## Counter-Rationalizations

| Shortcut | Counter | Why |
|----------|---------|-----|
| "We can skip some steps for this case" | Adapt the workflow steps, don't skip them | Skipped steps are where incidents and oversights originate |
| "The user seems to already know what to do" | Complete all workflow phases with the user | The workflow catches blind spots that experience alone misses |
| "This is a minor case, full process is overkill" | Scale the process down, don't turn it off | Minor cases become major when unstructured; the process scales, not disappears |
| "I'll fill in the details later" | Complete each section before moving on | Deferred details are forgotten; real-time capture is more accurate |
| "The template output isn't necessary" | Always produce the structured output format | Structured output enables comparison, audit trails, and handoff to other teams |

## Output Format
- **Migration Inventory Spreadsheet**: Service-by-service mapping with migration method
- **Architecture Diagram**: Target GCP architecture with networking
- **Migration Runbook**: Step-by-step execution guide per workload
- **Rollback Plan**: Procedures to revert each migration phase
- **Cost Comparison**: Pre- and post-migration cost analysis
