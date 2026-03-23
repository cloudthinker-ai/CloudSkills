---
name: runbook-scaling-event
enabled: true
description: |
  Use when performing runbook scaling event — application scaling procedure
  covering trigger assessment, scale execution, and monitoring. Use for manual
  scaling in response to traffic spikes, planned events, or autoscaling
  failures.
required_connections: []
config_fields:
  - key: service_name
    label: "Service Name"
    required: true
    placeholder: "e.g., api-gateway, checkout-service"
  - key: scaling_trigger
    label: "Scaling Trigger"
    required: true
    placeholder: "e.g., traffic spike, planned event, CPU > 80%"
  - key: current_capacity
    label: "Current Capacity"
    required: true
    placeholder: "e.g., 4 replicas, 2x c5.xlarge"
  - key: target_capacity
    label: "Target Capacity"
    required: true
    placeholder: "e.g., 12 replicas, 6x c5.xlarge"
features:
  - RUNBOOK
  - SRE
---

# Application Scaling Runbook Skill

Scale **{{ service_name }}** from **{{ current_capacity }}** to **{{ target_capacity }}**.
Trigger: **{{ scaling_trigger }}**

## Workflow

### Phase 1 — Trigger Assessment

```
TRIGGER ASSESSMENT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SCALING REASON
  Service: {{ service_name }}
  Trigger: {{ scaling_trigger }}
  Urgency: [IMMEDIATE / PLANNED / PROACTIVE]

CURRENT METRICS
  Requests per second: ___
  CPU utilization (avg/p95): ___% / ___%
  Memory utilization (avg/p95): ___% / ___%
  Response latency (p50/p95/p99): ___ms / ___ms / ___ms
  Error rate: ___%
  Queue depth (if applicable): ___
  Active connections: ___

CAPACITY ANALYSIS
  Current: {{ current_capacity }}
  Target: {{ target_capacity }}
  Scale factor: ___x
  Estimated headroom after scaling: ___%

AUTOSCALER STATUS
[ ] Is autoscaler enabled? YES / NO
[ ] Autoscaler current status: [scaling / steady / disabled]
[ ] Why is manual scaling needed?
    [ ] Autoscaler too slow for traffic ramp
    [ ] Autoscaler at max limit
    [ ] Autoscaler misconfigured
    [ ] Proactive scaling for known event
```

### Phase 2 — Pre-Scale Checks

```
PRE-SCALE CHECKS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
RESOURCE AVAILABILITY
[ ] Sufficient compute quota for target capacity
[ ] Sufficient IP addresses in subnet(s)
[ ] Container image available and pullable
[ ] Node capacity available (K8s) or instances launchable (EC2/VM)
[ ] Load balancer can handle additional backends

DEPENDENCY CHECK
[ ] Database connection pool can handle additional instances
    Current pool: ___ / ___ max
    After scaling: ___ / ___ max
[ ] Cache capacity sufficient for additional load
[ ] Downstream services can handle increased throughput
[ ] Rate limits on external APIs will not be exceeded
[ ] Shared resources (file locks, queues) can handle concurrency

COST ESTIMATE
  Additional cost: $___/hour ($___/month if sustained)
  Budget approval: [not needed / approved / pending]
```

### Phase 3 — Scale Execution

```
SCALE EXECUTION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
KUBERNETES:
[ ] Update replica count: kubectl scale deployment {{ service_name }} --replicas=___
[ ] Or update HPA limits: max replicas = ___
[ ] Watch rollout: kubectl rollout status deployment/{{ service_name }}

EC2 / VM AUTO SCALING:
[ ] Update ASG desired capacity: ___
[ ] Update ASG max capacity (if needed): ___
[ ] Verify launch template / configuration is current

SERVERLESS:
[ ] Update provisioned concurrency: ___
[ ] Update reserved concurrency: ___

EXECUTION LOG
  Scale initiated at: ___
  New instances/pods started: ___
  All instances healthy at: ___
  Time to full scale: ___ minutes
```

### Phase 4 — Post-Scale Monitoring

```
POST-SCALE MONITORING (check at T+5min, T+15min, T+1h)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
CAPACITY VALIDATION
[ ] All new instances/pods in Ready state
[ ] New instances passing health checks
[ ] Load balanced evenly across all instances
[ ] No pending pods / failed launches

PERFORMANCE METRICS (compare to pre-scale)
  Metric          Before    After     Target
  ─────────────── ───────── ───────── ─────────
  RPS             ___       ___       ___
  CPU (avg)       ___%      ___%      < 70%
  Memory (avg)    ___%      ___%      < 80%
  Latency (p95)   ___ms     ___ms     < ___ms
  Error rate      ___%      ___%      < 1%

DEPENDENCY HEALTH
[ ] Database connections stable (not approaching pool limit)
[ ] Cache hit ratio maintained
[ ] Downstream services not overwhelmed
[ ] No increased error rates from dependencies
```

### Phase 5 — Scale-Down Plan

```
SCALE-DOWN PLAN
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SCALE-DOWN CRITERIA
  Scale down when:
  [ ] Traffic returns below ___ RPS for > ___ minutes
  [ ] CPU utilization < ___% for > ___ minutes
  [ ] Planned event has concluded
  [ ] Autoscaler can manage remaining load

SCALE-DOWN PROCEDURE
[ ] Reduce capacity gradually (not all at once)
[ ] Step 1: reduce to ___x (50% reduction)
[ ] Monitor for 15 minutes
[ ] Step 2: reduce to target steady-state: ___
[ ] Verify performance remains within SLA
[ ] Re-enable autoscaler (if was overridden)

ESTIMATED SCALE-DOWN TIME: ___
```

### Phase 6 — Documentation

```
DOCUMENTATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Log scaling event:
    Service: {{ service_name }}
    From: {{ current_capacity }} -> To: {{ target_capacity }}
    Trigger: {{ scaling_trigger }}
    Duration at elevated scale: ___
    Cost impact: $___
[ ] Update autoscaler configuration if limits were insufficient
[ ] Create ticket to improve autoscaling (if manual was needed)
[ ] Update capacity planning with observed traffic patterns
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

Produce a scaling event report with:
1. **Scaling summary** (service, trigger, from/to capacity)
2. **Pre-scale assessment** (metrics, dependencies, cost)
3. **Execution log** with timing and instance health
4. **Post-scale metrics** comparison (before vs. after)
5. **Scale-down plan** with criteria and schedule
6. **Recommendations** for autoscaler improvements
