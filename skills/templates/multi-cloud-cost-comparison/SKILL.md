---
name: multi-cloud-cost-comparison
enabled: true
description: |
  Provides a structured framework for comparing costs across multiple cloud providers for equivalent workloads. Covers service-level price comparison, TCO analysis, hidden cost identification, discount program evaluation, and recommendation generation for optimal cloud placement.
required_connections:
  - prefix: cloud-billing
    label: "Cloud Billing Accounts"
config_fields:
  - key: providers_to_compare
    label: "Cloud Providers to Compare"
    required: true
    placeholder: "e.g., AWS, GCP, Azure"
  - key: workload_description
    label: "Primary Workload Description"
    required: true
    placeholder: "e.g., web application with 10k daily active users"
  - key: comparison_period
    label: "Cost Comparison Period"
    required: false
    placeholder: "e.g., 1 year, 3 years"
features:
  - COST_MANAGEMENT
  - FINOPS
  - MULTI_CLOUD
---

# Multi-Cloud Cost Comparison

## Phase 1: Workload Definition
1. Define workload requirements
   - [ ] Compute (vCPUs, memory, GPU)
   - [ ] Storage (block, object, file, volume)
   - [ ] Database (type, size, IOPS, replicas)
   - [ ] Networking (egress, load balancing, CDN)
   - [ ] Managed services (containers, serverless, ML)
2. Document performance requirements (latency, throughput)
3. Specify availability requirements (SLA, multi-region)
4. Identify compliance and data residency constraints

## Phase 2: Service Mapping

### Equivalent Service Comparison

| Capability | AWS | GCP | Azure | Notes |
|-----------|-----|-----|-------|-------|
| Compute | EC2 | Compute Engine | VMs | |
| Kubernetes | EKS | GKE | AKS | |
| Serverless | Lambda | Cloud Functions | Functions | |
| Object Storage | S3 | Cloud Storage | Blob Storage | |
| Relational DB | RDS | Cloud SQL | SQL Database | |
| NoSQL DB | DynamoDB | Firestore | Cosmos DB | |
| Cache | ElastiCache | Memorystore | Cache for Redis | |
| CDN | CloudFront | Cloud CDN | Front Door | |
| Load Balancer | ALB/NLB | Cloud LB | App Gateway | |

## Phase 3: Cost Calculation

### Per-Service Cost Comparison

| Service | Spec | AWS ($/mo) | GCP ($/mo) | Azure ($/mo) | Cheapest |
|---------|------|-----------|-----------|-------------|----------|
| Compute | | | | | |
| Storage | | | | | |
| Database | | | | | |
| Networking | | | | | |
| Other managed | | | | | |
| **Total** | | **$** | **$** | **$** | |

1. Calculate on-demand pricing for each provider
2. Apply available discounts (RI, CUD, Savings Plans)
3. Include data transfer and egress costs
4. Account for support plan costs
5. Factor in free tier benefits where applicable

## Phase 4: Hidden Cost Analysis
1. Identify costs often missed in comparisons
   - [ ] Data egress between regions and to internet
   - [ ] API call charges
   - [ ] Logging and monitoring costs
   - [ ] Cross-AZ data transfer
   - [ ] IP address charges
   - [ ] License surcharges (Windows, enterprise DB)
2. Calculate operational costs (staffing, training, tooling)
3. Factor in migration costs if switching providers

## Phase 5: TCO Analysis

### Total Cost of Ownership (3-Year)

| Category | AWS | GCP | Azure |
|----------|-----|-----|-------|
| Infrastructure | $ | $ | $ |
| Discounts (RI/CUD) | -$ | -$ | -$ |
| Data transfer | $ | $ | $ |
| Support | $ | $ | $ |
| Operational (staff/tools) | $ | $ | $ |
| Migration cost | $ | $ | $ |
| **3-Year TCO** | **$** | **$** | **$** |

## Phase 6: Recommendation
1. Rank providers by total cost for the workload
2. Identify optimal provider per service category
3. Evaluate multi-cloud strategy if beneficial
4. Consider non-cost factors (features, ecosystem, expertise)
5. Generate final recommendation with justification

## Output Format
- **Service Mapping Table**: Equivalent services across providers
- **Cost Comparison Spreadsheet**: Detailed line-item pricing
- **TCO Analysis**: 3-year total cost including hidden costs
- **Recommendation Report**: Provider ranking with justification
- **Sensitivity Analysis**: How costs change with scaling

## Action Items
- [ ] Define workload requirements and specifications
- [ ] Collect current pricing for all service equivalents
- [ ] Calculate costs with applicable discount programs
- [ ] Identify and quantify hidden costs
- [ ] Complete TCO analysis
- [ ] Present recommendation to stakeholders
