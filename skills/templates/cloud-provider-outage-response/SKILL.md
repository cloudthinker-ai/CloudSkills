---
name: cloud-provider-outage-response
enabled: true
description: |
  Use when performing cloud provider outage response — response playbook for
  regional or service-level outages from major cloud providers (AWS, GCP,
  Azure). Covers impact assessment, multi-region failover procedures, customer
  communication during provider outages, SLA credit documentation, and
  architectural resilience improvements to reduce dependency on single cloud
  regions or services.
required_connections:
  - prefix: slack
    label: "Slack (for incident coordination)"
config_fields:
  - key: cloud_provider
    label: "Cloud Provider"
    required: true
    placeholder: "e.g., AWS, GCP, Azure"
  - key: affected_region
    label: "Affected Region"
    required: true
    placeholder: "e.g., us-east-1, europe-west1, eastus"
  - key: affected_services
    label: "Affected Cloud Services"
    required: false
    placeholder: "e.g., EC2, S3, RDS, Lambda"
features:
  - INCIDENT
---

# Cloud Provider Outage Response

Provider: **{{ cloud_provider }}** | Region: **{{ affected_region }}**
Affected Services: **{{ affected_services }}**

## Status Page URLs

| Provider | Status Page | Health Dashboard |
|----------|------------|-----------------|
| AWS | https://health.aws.amazon.com | AWS Personal Health Dashboard |
| GCP | https://status.cloud.google.com | GCP Dashboard in Console |
| Azure | https://status.azure.com | Azure Service Health |

## Phase 1 — Confirm and Assess (0-15 min)

### Confirm Provider Outage
- [ ] Check provider status page (may lag behind actual issues)
- [ ] Check AWS Health Dashboard / GCP Service Health / Azure Service Health
- [ ] Check community reports (Twitter/X, Hacker News, Downdetector)
- [ ] Verify from our own monitoring (distinguish our issue vs. provider issue)
- [ ] Check if the outage is regional or global

### Assess Our Impact
- [ ] Which of our services are in {{ affected_region }}?
- [ ] Which cloud services do we depend on that are affected?
- [ ] Do we have multi-region redundancy?
- [ ] What is the customer-facing impact?
- [ ] Are there any data durability concerns?

### Service Dependency Map

| Our Service | Cloud Dependency | Region | Multi-Region? | Failover Ready? |
|-------------|-----------------|--------|---------------|-----------------|
| _service_ | _EC2/RDS/S3/etc._ | {{ affected_region }} | _yes/no_ | _yes/no_ |

## Phase 2 — Failover Decision (15-30 min)

### Failover Decision Matrix

| Condition | Action |
|-----------|--------|
| Multi-region active-active deployed | Traffic should auto-failover; verify |
| Multi-region active-passive with tested failover | Initiate failover to secondary region |
| Single-region with cold standby | Assess if outage duration justifies cold start |
| Single-region, no DR | Wait for provider recovery; communicate to customers |
| Provider ETA < 30 minutes | Usually better to wait than failover |
| Provider ETA unknown or > 1 hour | Initiate failover if possible |

### Failover Execution (if proceeding)

#### DNS-Based Failover
```bash
# Update DNS to point to healthy region
# Route53 health checks should auto-failover
# Manual override if needed:
aws route53 change-resource-record-sets --hosted-zone-id ZONE_ID \
  --change-batch '{"Changes":[{"Action":"UPSERT","ResourceRecordSet":{"Name":"api.example.com","Type":"A","TTL":60,"ResourceRecords":[{"Value":"HEALTHY_REGION_IP"}]}}]}'
```

#### Load Balancer Failover
- [ ] Remove unhealthy region from global load balancer
- [ ] Verify traffic routing to healthy region(s)
- [ ] Monitor healthy region for capacity (can it handle full load?)

#### Database Failover
- [ ] Promote read replica in healthy region to primary (if applicable)
- [ ] Update application connection strings
- [ ] Accept potential data loss based on replication lag
- [ ] Document the replication lag at time of failover

### Capacity Verification
When failing over, the healthy region must handle increased load:
- [ ] Check current capacity utilization in healthy region
- [ ] Pre-scale compute resources if needed
- [ ] Verify database can handle doubled connection count
- [ ] Check rate limits and quotas in healthy region
- [ ] Monitor for capacity-related failures during failover

## Phase 3 — During the Outage

### Monitoring
- [ ] Set up dedicated monitoring for provider status updates
- [ ] Monitor healthy region(s) for stability under increased load
- [ ] Track customer-reported issues
- [ ] Document all timeline events for post-incident review

### Customer Communication
```
We are currently experiencing service disruption due to an infrastructure
issue at our cloud provider ({{ cloud_provider }}) affecting the
{{ affected_region }} region.

Impact: [describe customer-facing impact]
Status: [Our team is actively working on failover / We are monitoring
         the provider's recovery efforts]
Next update: [time]

You can track the provider's status at: [status page URL]
```

### What NOT to Do
- Do NOT assume the provider will recover quickly (plan for hours)
- Do NOT make changes to the affected region (API calls may fail/timeout)
- Do NOT restart services in the affected region (may make recovery harder)
- Do NOT blame the provider publicly (factual statements only)

## Phase 4 — Recovery

### When Provider Recovers
- [ ] Verify provider announces recovery on status page
- [ ] Test our services in the recovered region (do not trust blindly)
- [ ] Check data integrity in the recovered region
- [ ] Reconcile any data divergence between regions

### Failback Procedure (if we failed over)
1. Verify recovered region is stable (wait 30+ minutes)
2. Sync data from active region back to recovered region
3. Gradually shift traffic back (10% → 25% → 50% → 100%)
4. Monitor for issues at each step
5. Restore original multi-region configuration
6. Verify all systems nominal

### Data Reconciliation
- [ ] Check for data written to both regions during split
- [ ] Resolve any conflicts (last-write-wins, manual review, etc.)
- [ ] Verify database replication is healthy and caught up
- [ ] Check message queues for unprocessed items
- [ ] Verify cache consistency

## Phase 5 — Post-Outage

### SLA Credit Documentation
- [ ] Record exact start and end time of outage
- [ ] Document affected services and regions
- [ ] Calculate downtime percentage for SLA claim
- [ ] File SLA credit request with provider (within required timeframe)
- [ ] Track credit request to resolution

### Architectural Review
- [ ] Were we adequately multi-region? If not, plan remediation
- [ ] Did failover work as expected?
- [ ] What was our recovery time vs. target?
- [ ] Do we need additional regions or providers?
- [ ] Should we adopt multi-cloud for critical services?
- [ ] Review and update disaster recovery plan

## Counter-Rationalizations

| Shortcut | Counter | Why |
|----------|---------|-----|
| "We can skip some steps for this case" | Adapt the workflow steps, don't skip them | Skipped steps are where incidents and oversights originate |
| "The user seems to already know what to do" | Complete all workflow phases with the user | The workflow catches blind spots that experience alone misses |
| "This is a minor case, full process is overkill" | Scale the process down, don't turn it off | Minor cases become major when unstructured; the process scales, not disappears |
| "I'll fill in the details later" | Complete each section before moving on | Deferred details are forgotten; real-time capture is more accurate |
| "The template output isn't necessary" | Always produce the structured output format | Structured output enables comparison, audit trails, and handoff to other teams |

