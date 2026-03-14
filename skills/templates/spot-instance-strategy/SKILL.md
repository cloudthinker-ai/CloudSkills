---
name: spot-instance-strategy
enabled: true
description: |
  Designs a spot instance strategy for fault-tolerant and flexible workloads to achieve significant cost savings. Covers workload suitability assessment, instance diversification, interruption handling, capacity management, and hybrid strategies combining spot with on-demand and reserved instances.
required_connections:
  - prefix: cloud-provider
    label: "Cloud Provider"
config_fields:
  - key: cloud_provider
    label: "Cloud Provider"
    required: true
    placeholder: "e.g., AWS, GCP, Azure"
  - key: workload_type
    label: "Primary Workload Type"
    required: true
    placeholder: "e.g., batch processing, CI/CD, web serving, ML training"
  - key: interruption_tolerance
    label: "Interruption Tolerance"
    required: false
    placeholder: "e.g., high (batch), medium (stateless web), low"
features:
  - COST_MANAGEMENT
  - COMPUTE
  - FINOPS
---

# Spot Instance Strategy

## Phase 1: Workload Assessment
1. Evaluate workloads for spot suitability
   - [ ] Fault tolerance (can handle interruptions)
   - [ ] Checkpointing capability
   - [ ] Flexible start/completion times
   - [ ] Stateless or state externalized
   - [ ] Can run on multiple instance types
2. Quantify potential savings per workload

### Spot Suitability Matrix

| Workload | Fault Tolerant | Checkpointable | Flexible Timing | Multi-Instance | Spot Fit |
|----------|---------------|----------------|-----------------|---------------|----------|
|          | [ ]           | [ ]            | [ ]             | [ ]           | High/Med/Low |

## Phase 2: Instance Diversification
1. Identify multiple instance types per workload (minimum 6-10)
2. Spread across multiple availability zones
3. Analyze historical spot pricing and interruption rates
4. Define instance type priority based on price and availability
5. Configure capacity-optimized allocation strategy

### Instance Pool Configuration

| Instance Type | vCPU | Memory | Spot Price (avg) | Interruption Rate | Priority |
|--------------|------|--------|-----------------|-------------------|----------|
|              |      |        |                 | <5% / 5-15% / >15% |        |

## Phase 3: Interruption Handling
1. Implement graceful shutdown handlers (2-minute warning)
2. Set up checkpointing for long-running jobs
3. Configure automatic replacement of interrupted instances
4. Design queue-based architectures for batch workloads
5. Implement health checks and automatic failover

### Interruption Response Plan

| Scenario | Detection | Response | Recovery Time | Data Loss Risk |
|----------|-----------|----------|--------------|----------------|
| Single instance interruption | | | | |
| Multiple simultaneous interruptions | | | | |
| Availability zone capacity event | | | | |

## Phase 4: Hybrid Strategy Design
1. Define baseline capacity on reserved/on-demand instances
2. Configure auto-scaling with spot for burst capacity
3. Set maximum spot percentage per workload
4. Implement fallback to on-demand when spot unavailable
5. Balance cost savings with availability requirements

## Phase 5: Implementation
1. Configure spot fleet or managed instance group
2. Set up monitoring for spot utilization and savings
3. Implement cost tracking per workload
4. Test interruption handling with fault injection
5. Deploy to production with gradual spot percentage increase

## Phase 6: Optimization
1. Monitor actual vs. projected savings weekly
2. Adjust instance type mix based on interruption patterns
3. Refine capacity allocation between spot, reserved, on-demand
4. Review and update maximum bid prices
5. Expand spot usage to newly identified workloads

## Output Format
- **Workload Assessment**: Spot suitability classification per workload
- **Instance Pool Design**: Diversified instance types per workload
- **Architecture Diagram**: Hybrid spot/on-demand/reserved design
- **Interruption Runbook**: Automated and manual response procedures
- **Savings Dashboard**: Weekly tracking of spot savings vs. on-demand

## Action Items
- [ ] Assess all workloads for spot suitability
- [ ] Select and test diversified instance pools
- [ ] Implement interruption handling and checkpointing
- [ ] Deploy spot strategy to non-critical workloads first
- [ ] Monitor and expand to additional workloads
- [ ] Report monthly savings to stakeholders
