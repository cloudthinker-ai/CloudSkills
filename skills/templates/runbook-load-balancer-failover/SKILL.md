---
name: runbook-load-balancer-failover
enabled: true
description: |
  Load balancer failover procedure covering health checks, traffic shift, backend validation, and rollback. Use for planned LB maintenance, active-passive failover, or responding to LB degradation.
required_connections: []
config_fields:
  - key: lb_name
    label: "Load Balancer Name"
    required: true
    placeholder: "e.g., prod-api-alb, nginx-frontend"
  - key: primary_lb
    label: "Primary LB Endpoint"
    required: true
    placeholder: "e.g., alb-primary-1234.us-east-1.elb.amazonaws.com"
  - key: secondary_lb
    label: "Secondary / Standby LB Endpoint"
    required: true
    placeholder: "e.g., alb-secondary-5678.us-west-2.elb.amazonaws.com"
  - key: failover_type
    label: "Failover Type"
    required: false
    placeholder: "e.g., planned maintenance, emergency failover"
features:
  - RUNBOOK
  - NETWORKING
---

# Load Balancer Failover Runbook Skill

Execute LB failover for **{{ lb_name }}** from **{{ primary_lb }}** to **{{ secondary_lb }}**.
Type: **{{ failover_type }}**

## Workflow

### Phase 1 — Pre-Failover Health Check

```
PRE-FAILOVER HEALTH CHECK
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PRIMARY LB STATUS
  Name: {{ lb_name }}
  Endpoint: {{ primary_lb }}
  Current RPS: ___
  Active connections: ___
  Healthy backends: ___ / ___
  SSL certificate expiry: ___

SECONDARY LB STATUS
  Endpoint: {{ secondary_lb }}
  Health check status: ___
  Healthy backends: ___ / ___
  SSL certificate valid: YES / NO
  Last traffic served: ___

BACKEND PARITY CHECK
[ ] Same backend instances registered on both LBs
[ ] Health check configuration identical
[ ] Listener rules / routing rules match
[ ] SSL certificates match on both LBs
[ ] Security groups allow traffic from secondary LB to backends
[ ] Sticky sessions / session persistence configured identically
```

### Phase 2 — Pre-Failover Validation

```
PRE-FAILOVER VALIDATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Test secondary LB with synthetic requests:
    curl -H "Host: {{ lb_name }}" https://{{ secondary_lb }}/health
    Response: ___ (expect 200 OK)
[ ] Verify response content matches primary LB output
[ ] Check latency from secondary LB: ___ ms
[ ] Verify logging and monitoring configured on secondary LB
[ ] Confirm DNS TTL is low enough for quick switchover: ___ seconds
[ ] Notify on-call team and stakeholders of planned failover
[ ] Prepare rollback command / procedure
```

### Phase 3 — Traffic Shift Execution

```
TRAFFIC SHIFT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
GRADUAL SHIFT (recommended for planned failovers):
1. [ ] Route 10% traffic to secondary LB
2. [ ] Monitor for 5 minutes: error rate ___, latency ___
3. [ ] Route 50% traffic to secondary LB
4. [ ] Monitor for 5 minutes: error rate ___, latency ___
5. [ ] Route 100% traffic to secondary LB
6. [ ] Confirm zero traffic on primary LB

IMMEDIATE SHIFT (for emergency failovers):
1. [ ] Update DNS record to point to {{ secondary_lb }}
2. [ ] Update Route53 health check / failover routing (if applicable)
3. [ ] Record switchover timestamp: ___
4. [ ] Verify DNS propagation

TRAFFIC SHIFT METHOD:
[ ] DNS-based (Route53 weighted/failover routing)
[ ] Global LB (CloudFront, Global Accelerator, Cloudflare)
[ ] Manual DNS update
```

### Phase 4 — Post-Failover Backend Validation

```
BACKEND VALIDATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
TRAFFIC FLOW (check at T+5min, T+15min)
[ ] All traffic arriving at secondary LB backends
[ ] No traffic leaking to primary LB
[ ] Request distribution across backends is balanced
[ ] No backend instances marked unhealthy

APPLICATION HEALTH
[ ] Response times within SLA: ___ ms (SLA: ___ ms)
[ ] Error rate: ___% (baseline: ___%)
[ ] All API endpoints responding correctly
[ ] WebSocket / long-lived connections re-established
[ ] No session loss for sticky session workloads

MONITORING
[ ] Metrics flowing from secondary LB
[ ] Access logs being generated
[ ] Alerts configured and firing correctly
[ ] Dashboard updated to show secondary LB metrics
```

### Phase 5 — Rollback Procedure

```
ROLLBACK (if issues detected)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Trigger: error rate > ___%, latency > ___ ms, backend failures

1. [ ] Shift traffic back to primary LB (reverse of Phase 3)
2. [ ] Verify primary LB receiving traffic
3. [ ] Confirm primary LB backends healthy
4. [ ] Monitor application health for 15 minutes
5. [ ] Notify stakeholders of rollback
6. [ ] Document failure reason for investigation
```

### Phase 6 — Cleanup

```
CLEANUP
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Perform maintenance on primary LB (if planned maintenance)
[ ] Verify primary LB ready for failback when needed
[ ] Update monitoring to reflect new active LB
[ ] Update incident response runbooks with new primary
[ ] Document failover duration and any issues
[ ] Close change management ticket
[ ] Schedule failback (if applicable): ___
```

## Output Format

Produce a load balancer failover report with:
1. **Failover summary** (LB name, primary, secondary, type, timestamps)
2. **Pre-failover health** of both load balancers
3. **Traffic shift execution** log with gradual percentages
4. **Backend validation** results (latency, error rate, distribution)
5. **Issues and rollback** details (if any)
6. **Post-failover status** and next steps
