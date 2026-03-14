---
name: multi-region-deployment
enabled: true
description: |
  Multi-region deployment template covering region selection, data replication strategy, traffic routing, failover configuration, consistency models, and operational procedures. Use for expanding to new regions, designing active-active architectures, or implementing global redundancy.
required_connections:
  - prefix: aws
    label: "AWS (or cloud provider)"
config_fields:
  - key: service_name
    label: "Service Name"
    required: true
    placeholder: "e.g., global-api"
  - key: primary_region
    label: "Primary Region"
    required: true
    placeholder: "e.g., us-east-1"
  - key: secondary_regions
    label: "Secondary Region(s)"
    required: true
    placeholder: "e.g., eu-west-1, ap-southeast-1"
  - key: topology
    label: "Topology"
    required: true
    placeholder: "e.g., active-active, active-passive"
features:
  - ARCHITECTURE
  - DEPLOYMENT
  - DISASTER_RECOVERY
---

# Multi-Region Deployment Skill

Plan multi-region deployment for **{{ service_name }}** across **{{ primary_region }}** and **{{ secondary_regions }}** ({{ topology }}).

## Workflow

### Step 1 — Region Strategy

```
REGION ARCHITECTURE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Service: {{ service_name }}
Topology: {{ topology }}
Primary: {{ primary_region }}
Secondary: {{ secondary_regions }}

TOPOLOGY DECISION:
  Active-Active:
    - All regions serve production traffic simultaneously
    - Requires conflict resolution for writes
    - Lowest latency for global users
    - Highest complexity and cost

  Active-Passive:
    - Primary handles all traffic, secondary is standby
    - Simpler data consistency model
    - Higher latency for remote users
    - Lower cost, used primarily for DR

Selected: {{ topology }}
Justification: [why this topology was chosen]
```

### Step 2 — Data Replication Strategy

```
DATA REPLICATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
DATABASE:
[ ] Replication type: [synchronous / asynchronous / semi-sync]
[ ] Replication technology: [Aurora Global DB / DynamoDB Global Tables / CockroachDB / custom]
[ ] Consistency model: [strong / eventual / causal]
[ ] Conflict resolution: [last-writer-wins / region-primary / application-level]
[ ] Expected replication lag: ___ms
[ ] Maximum acceptable lag: ___ms
[ ] Replication monitoring configured

CACHE:
[ ] Cache strategy: [local per-region / replicated / independent]
[ ] Cache invalidation: [event-driven / TTL / hybrid]
[ ] Cache warm-up procedure for new regions

OBJECT STORAGE:
[ ] S3 cross-region replication configured
[ ] Replication scope: [full bucket / prefix-filtered]
[ ] Versioning enabled

MESSAGING / EVENTS:
[ ] Event replication: [Kafka MirrorMaker / SNS fan-out / EventBridge]
[ ] Event ordering guarantees: [per-partition / none]
[ ] Deduplication strategy for cross-region events
```

### Step 3 — Traffic Routing

```
TRAFFIC ROUTING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
ROUTING METHOD:
[ ] GeoDNS (Route53 geolocation / latency-based routing)
[ ] Global load balancer (CloudFront, Global Accelerator)
[ ] Anycast DNS
[ ] Application-level routing

ROUTING RULES:
| User Region | Target Region | Fallback Region |
|------------|---------------|-----------------|
| North America | {{ primary_region }} | [fallback] |
| Europe | [region] | [fallback] |
| Asia Pacific | [region] | [fallback] |
| Default | {{ primary_region }} | [fallback] |

HEALTH CHECKS:
[ ] Health check endpoint per region
[ ] Health check interval: ___ seconds
[ ] Failure threshold: ___ consecutive failures
[ ] Automatic failover on health check failure
[ ] Failover DNS TTL: ___ seconds
```

### Step 4 — Deployment Pipeline

```
MULTI-REGION CI/CD
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
DEPLOYMENT STRATEGY:
[ ] Sequential: deploy to primary, validate, then secondary regions
[ ] Parallel: deploy to all regions simultaneously
[ ] Canary per region: canary in each region before full rollout

DEPLOYMENT ORDER:
1. [ ] {{ primary_region }} (canary -> full)
2. [ ] [secondary region 1] (canary -> full)
3. [ ] [secondary region 2] (canary -> full)

PER-REGION VALIDATION:
[ ] Health checks passing in region
[ ] Latency within SLO for region
[ ] Data replication healthy
[ ] No cross-region errors

ROLLBACK:
[ ] Per-region rollback capability (independent versions temporarily)
[ ] Global rollback procedure
[ ] Database migration rollback across regions
```

### Step 5 — Failover Configuration

```
FAILOVER PROCEDURES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
AUTOMATIC FAILOVER:
[ ] Health check-based DNS failover configured
[ ] Failover triggers defined:
    - Region unreachable for > ___ seconds
    - Error rate > ___% for > ___ minutes
    - Latency > ___ms sustained for > ___ minutes
[ ] Automatic database promotion in secondary region
[ ] Automatic traffic rerouting

MANUAL FAILOVER:
[ ] Runbook for manual failover documented
[ ] DNS override procedure
[ ] Database promotion procedure
[ ] Application configuration switch

FAILBACK:
[ ] Data reconciliation procedure after failback
[ ] Traffic gradual shift back to primary
[ ] Verify data consistency across regions
[ ] Reset secondary to standby mode

TESTING:
[ ] Failover tested quarterly
[ ] Last test date: ___
[ ] Next test date: ___
```

### Step 6 — Operational Considerations

```
OPERATIONS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
MONITORING:
[ ] Per-region dashboards
[ ] Cross-region replication lag monitoring
[ ] Per-region SLO tracking
[ ] Global aggregate metrics
[ ] Region comparison dashboards (spot regional issues)

ON-CALL:
[ ] Follow-the-sun on-call rotation (if applicable)
[ ] Runbooks cover multi-region scenarios
[ ] Incident response includes region isolation as mitigation

COST:
[ ] Per-region cost breakdown
[ ] Data transfer costs between regions estimated: $___/month
[ ] Cross-region replication costs: $___/month
[ ] Total multi-region premium over single-region: ___% / $___/month

COMPLIANCE:
[ ] Data residency requirements met per region
[ ] GDPR: EU data stays in EU region
[ ] Data sovereignty: [other regional requirements]
```

### Step 7 — Readiness Checklist

```
MULTI-REGION READINESS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Infrastructure deployed in all regions
[ ] Data replication configured and healthy
[ ] Traffic routing with failover tested
[ ] Deployment pipeline supports multi-region
[ ] Monitoring covers all regions
[ ] Failover procedure documented and tested
[ ] On-call team trained on multi-region procedures
[ ] Cost model reviewed and approved
[ ] Compliance requirements verified per region
[ ] Load testing completed in each region
```

## Output Format

Produce a multi-region deployment plan with:
1. **Architecture overview** (topology, regions, data flow)
2. **Data replication** strategy with consistency model
3. **Traffic routing** rules and failover configuration
4. **Deployment pipeline** design with per-region validation
5. **Operational runbooks** for failover, failback, and monitoring
6. **Cost analysis** for multi-region premium
