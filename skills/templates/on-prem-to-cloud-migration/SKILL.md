---
name: on-prem-to-cloud-migration
enabled: true
description: |
  Use when performing on prem to cloud migration — provides a comprehensive
  framework for migrating on-premises infrastructure to a cloud provider. Covers
  workload assessment, network connectivity, data migration, security posture
  translation, and phased cutover planning with minimal downtime targets.
required_connections:
  - prefix: cloud-provider
    label: "Target Cloud Provider"
config_fields:
  - key: target_cloud
    label: "Target Cloud Provider"
    required: true
    placeholder: "e.g., AWS, GCP, Azure"
  - key: datacenter_location
    label: "Current Datacenter Location"
    required: true
    placeholder: "e.g., US-East, Frankfurt"
  - key: downtime_tolerance
    label: "Maximum Acceptable Downtime"
    required: false
    placeholder: "e.g., 4 hours"
features:
  - CLOUD_MIGRATION
  - INFRASTRUCTURE
---

# On-Premises to Cloud Migration Plan

## Phase 1: Assessment & Discovery
1. Inventory all on-premises assets
   - [ ] Physical servers and specifications
   - [ ] Virtual machines and hypervisor details
   - [ ] Storage systems (SAN, NAS, local)
   - [ ] Network topology and firewall rules
   - [ ] Databases and data volumes
   - [ ] Applications and their dependencies
2. Classify workloads by migration complexity
3. Identify licensing constraints (OS, database, middleware)
4. Measure current performance baselines

### Workload Classification Matrix

| Workload | Complexity | Data Volume | Downtime Tolerance | Migration Wave |
|----------|------------|-------------|-------------------|----------------|
|          | Low/Med/High | GB/TB    | Minutes/Hours/Days | 1/2/3/4       |

## Phase 2: Network & Connectivity
1. Design hybrid connectivity (VPN / Direct Connect / ExpressRoute)
2. Plan IP address scheme for cloud environment
3. Configure DNS resolution between on-prem and cloud
4. Set up firewall rules and security groups
5. Test bandwidth and latency between environments

## Phase 3: Security & Compliance
1. Map on-prem security controls to cloud equivalents
2. Configure identity federation (AD/LDAP to cloud IAM)
3. Set up encryption for data in transit and at rest
4. Plan certificate migration or renewal
5. Validate compliance requirements are met in cloud

## Phase 4: Pilot Migration
1. Select a low-risk, low-dependency workload
2. Execute migration using chosen method (rehost/replatform)
3. Validate functionality and performance
4. Document lessons learned
5. Refine migration playbook

## Phase 5: Production Migration Waves
1. Execute migrations in planned waves
2. Run parallel environments during transition
3. Validate data integrity after each wave
4. Update DNS and routing progressively
5. Monitor performance and error rates closely

## Phase 6: Decommission & Optimize
1. Verify all workloads running successfully in cloud
2. Right-size cloud resources based on actual usage
3. Implement cloud-native monitoring and alerting
4. Decommission on-premises hardware
5. Update disaster recovery and backup procedures

## Counter-Rationalizations

| Shortcut | Counter | Why |
|----------|---------|-----|
| "We can skip some steps for this case" | Adapt the workflow steps, don't skip them | Skipped steps are where incidents and oversights originate |
| "The user seems to already know what to do" | Complete all workflow phases with the user | The workflow catches blind spots that experience alone misses |
| "This is a minor case, full process is overkill" | Scale the process down, don't turn it off | Minor cases become major when unstructured; the process scales, not disappears |
| "I'll fill in the details later" | Complete each section before moving on | Deferred details are forgotten; real-time capture is more accurate |
| "The template output isn't necessary" | Always produce the structured output format | Structured output enables comparison, audit trails, and handoff to other teams |

## Output Format
- **Asset Inventory**: Complete list of on-prem resources with cloud targets
- **Migration Wave Plan**: Grouped workloads with timelines per wave
- **Network Architecture**: Hybrid connectivity diagram
- **Runbook per Wave**: Step-by-step migration and rollback procedures
- **Post-Migration Report**: Performance comparison and optimization recommendations

## Action Items
- [ ] Complete on-premises asset discovery
- [ ] Establish hybrid network connectivity
- [ ] Execute pilot migration and gather learnings
- [ ] Get change approval board sign-off for production waves
- [ ] Monitor each wave for 72 hours before proceeding
- [ ] Schedule datacenter decommission after final stabilization
