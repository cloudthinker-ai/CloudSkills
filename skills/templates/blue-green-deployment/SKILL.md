---
name: blue-green-deployment
enabled: true
description: |
  Blue-green deployment template covering environment preparation, parallel stack deployment, traffic switching, validation gates, and cleanup. Use for zero-downtime releases with instant rollback capability.
required_connections:
  - prefix: aws
    label: "AWS (or cloud provider)"
config_fields:
  - key: service_name
    label: "Service Name"
    required: true
    placeholder: "e.g., checkout-service"
  - key: version
    label: "New Version"
    required: true
    placeholder: "e.g., v3.2.0"
  - key: active_environment
    label: "Currently Active Environment"
    required: true
    placeholder: "e.g., blue, green"
features:
  - DEPLOYMENT
---

# Blue-Green Deployment Skill

Execute blue-green deployment of **{{ service_name }} {{ version }}**. Currently active: **{{ active_environment }}**.

## Workflow

### Step 1 — Environment Identification

```
ENVIRONMENT MAP
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Active (serving traffic):  {{ active_environment }}
  - Version: [current version]
  - Instances: [count]
  - Target group / endpoint: [identifier]

Inactive (deployment target): [opposite of active]
  - Version: [to be deployed: {{ version }}]
  - Instances: [count]
  - Target group / endpoint: [identifier]
```

### Step 2 — Prepare Inactive Environment

```
ENVIRONMENT PREPARATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Inactive environment infrastructure is running
[ ] Inactive environment matches active environment spec:
    - Same instance types / pod resources
    - Same replica count
    - Same autoscaling configuration
    - Same network configuration
[ ] Database migrations applied (must be backward-compatible)
[ ] Environment variables and secrets updated for {{ version }}
[ ] Feature flags configured for {{ version }}
```

### Step 3 — Deploy to Inactive Environment

```
DEPLOYMENT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Deploy {{ version }} to inactive environment
[ ] Wait for all instances/pods to be healthy
[ ] Health check endpoints returning 200
[ ] Application version endpoint confirms {{ version }}
[ ] All instances registered in target group
```

### Step 4 — Pre-Switch Validation

```
PRE-SWITCH TESTING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Smoke tests pass against inactive environment (direct access)
[ ] Integration tests pass against inactive environment
[ ] Performance baseline captured:
    - P50 latency: ___ms
    - P95 latency: ___ms
    - P99 latency: ___ms
    - Error rate: ___%
[ ] Database connectivity verified
[ ] Downstream dependency connectivity verified
[ ] Log output reviewed for unexpected errors
[ ] Security scan passed (if required)

GO / NO-GO DECISION: ___
Approved by: ___
```

### Step 5 — Traffic Switch

```
TRAFFIC SWITCH
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Notify on-call team of switch
[ ] Record timestamp of switch: ___

Switch method (choose one):
[ ] Load balancer target group swap
[ ] DNS weighted routing (0% -> 100%)
[ ] Service mesh traffic shift
[ ] Kubernetes service selector update

[ ] Execute traffic switch
[ ] Verify traffic arriving at new ({{ version }}) environment
[ ] Verify no traffic on old environment (within TTL window)
```

### Step 6 — Post-Switch Validation

```
POST-SWITCH MONITORING (30 min window)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
T+5min:
[ ] Error rate within baseline (< +1%)
[ ] Latency within baseline (< +20% on P95)
[ ] No new error types in logs
[ ] Key user journeys working

T+15min:
[ ] Error rate stable
[ ] No memory leaks or resource exhaustion
[ ] Downstream services healthy
[ ] No customer complaints

T+30min:
[ ] All metrics stable and within SLO
[ ] Deployment marked as SUCCESSFUL
[ ] Stakeholders notified
```

### Step 7 — Rollback (if needed)

```
ROLLBACK
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Trigger: error rate >5% OR P95 latency >2x baseline for 5 min

[ ] Switch traffic back to {{ active_environment }} (instant)
[ ] Verify traffic on original environment
[ ] Verify error rates return to baseline
[ ] Notify stakeholders of rollback
[ ] Create incident ticket to investigate

Rollback time: ~seconds (just a traffic switch)
```

### Step 8 — Cleanup

```
CLEANUP (after stabilization period, typically 24-48h)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Old environment scaled down or updated to standby
[ ] Old version available for emergency rollback (24h retention)
[ ] Deployment record logged
[ ] Infrastructure-as-code updated to reflect new active environment
[ ] Monitoring updated: new environment is now primary
[ ] Cost optimization: scale down inactive environment
```

## Output Format

Produce a deployment execution report with:
1. **Deployment summary** (service, version, environments, timestamps)
2. **Pre-switch validation** results
3. **Traffic switch** execution log with exact timing
4. **Post-switch metrics** comparison (before vs after)
5. **Final status** (SUCCESS / ROLLED BACK) with next steps
