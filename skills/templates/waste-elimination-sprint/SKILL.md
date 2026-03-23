---
name: waste-elimination-sprint
enabled: true
description: |
  Use when performing waste elimination sprint — runs a focused sprint to
  identify and eliminate cloud resource waste. Covers idle resource detection,
  rightsizing opportunities, orphaned resource cleanup, storage optimization,
  and quick-win cost reductions that can be implemented within days rather than
  weeks.
required_connections:
  - prefix: cloud-provider
    label: "Cloud Provider"
config_fields:
  - key: cloud_provider
    label: "Cloud Provider"
    required: true
    placeholder: "e.g., AWS, GCP, Azure"
  - key: sprint_duration_days
    label: "Sprint Duration (days)"
    required: true
    placeholder: "e.g., 5"
  - key: target_savings_percent
    label: "Target Savings Percentage"
    required: false
    placeholder: "e.g., 20%"
features:
  - COST_MANAGEMENT
  - FINOPS
  - OPTIMIZATION
---

# Waste Elimination Sprint

## Phase 1: Quick Discovery (Day 1)
1. Run automated waste detection
   - [ ] Idle EC2/VM instances (CPU < 5% for 14+ days)
   - [ ] Unattached EBS volumes / persistent disks
   - [ ] Unused Elastic IPs / static IPs
   - [ ] Old snapshots and AMIs (> 90 days)
   - [ ] Idle load balancers (zero connections)
   - [ ] Unused NAT gateways
   - [ ] Empty S3 buckets with no access
   - [ ] Oversized RDS/database instances
   - [ ] Idle ElastiCache/Memorystore clusters
   - [ ] Zombie Lambda functions (no invocations 90+ days)

### Waste Inventory

| Resource | Type | Monthly Cost | Last Active | Owner | Action |
|----------|------|-------------|-------------|-------|--------|
|          |      | $           |             |       | Delete/Resize/Archive |

## Phase 2: Rightsizing Analysis (Day 2)
1. Identify rightsizing opportunities
   - [ ] Compute instances using < 40% CPU average
   - [ ] Databases with < 30% CPU and memory utilization
   - [ ] Over-provisioned storage (< 50% used)
   - [ ] Oversized container resource limits
2. Calculate savings per rightsizing action

### Rightsizing Recommendations

| Resource | Current Size | Recommended Size | Current Cost | New Cost | Monthly Savings |
|----------|-------------|-----------------|-------------|----------|----------------|
|          |             |                 | $           | $        | $              |

## Phase 3: Storage Optimization (Day 3)
1. Review storage tier usage
   - [ ] Move infrequently accessed data to cheaper tiers
   - [ ] Enable intelligent tiering where available
   - [ ] Implement lifecycle policies for object storage
   - [ ] Compress uncompressed data
   - [ ] Delete expired backups and old log archives
2. Calculate storage savings

## Phase 4: Network Cost Reduction (Day 3-4)
1. Identify network waste
   - [ ] Cross-region data transfer that could be local
   - [ ] Cross-AZ traffic that could be reduced
   - [ ] Unused VPN tunnels and Direct Connect
   - [ ] Redundant NAT gateways
2. Optimize data transfer patterns

## Phase 5: Execute Quick Wins (Day 4-5)
1. Delete confirmed unused resources
2. Resize oversized instances and databases
3. Apply storage lifecycle policies
4. Tag resources for ongoing tracking
5. Document all changes made

### Savings Tracker

| Category | Actions Taken | Monthly Savings | Annual Savings |
|----------|--------------|----------------|---------------|
| Idle resources deleted | | $ | $ |
| Rightsized resources | | $ | $ |
| Storage optimized | | $ | $ |
| Network optimized | | $ | $ |
| **Total** | | **$** | **$** |

## Phase 6: Prevent Recurrence
1. Set up alerts for idle resource detection
2. Implement automatic shutdown for dev/test resources
3. Add resource expiry tags for temporary resources
4. Schedule monthly waste detection scans
5. Report savings to leadership

## Counter-Rationalizations

| Shortcut | Counter | Why |
|----------|---------|-----|
| "We can skip some steps for this case" | Adapt the workflow steps, don't skip them | Skipped steps are where incidents and oversights originate |
| "The user seems to already know what to do" | Complete all workflow phases with the user | The workflow catches blind spots that experience alone misses |
| "This is a minor case, full process is overkill" | Scale the process down, don't turn it off | Minor cases become major when unstructured; the process scales, not disappears |
| "I'll fill in the details later" | Complete each section before moving on | Deferred details are forgotten; real-time capture is more accurate |
| "The template output isn't necessary" | Always produce the structured output format | Structured output enables comparison, audit trails, and handoff to other teams |

## Output Format
- **Waste Inventory**: All identified waste with costs and owners
- **Quick Win Actions**: Immediate actions taken with savings
- **Rightsizing Report**: Recommended changes with projected savings
- **Prevention Plan**: Ongoing policies to prevent waste recurrence
- **Sprint Summary**: Total savings achieved and next steps

## Action Items
- [ ] Run automated waste detection across all accounts
- [ ] Contact resource owners to confirm deletion approval
- [ ] Execute resource cleanup and rightsizing
- [ ] Implement storage lifecycle policies
- [ ] Set up recurring waste detection automation
- [ ] Present sprint results and savings to stakeholders
