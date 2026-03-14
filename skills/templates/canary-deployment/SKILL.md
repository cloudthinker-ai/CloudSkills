---
name: canary-deployment
enabled: true
description: |
  Canary deployment template covering traffic percentage ramp-up, metrics gates at each stage, automated promotion criteria, and rollback triggers. Use for gradual, risk-controlled production releases with real traffic validation.
required_connections:
  - prefix: datadog
    label: "Datadog (or monitoring platform)"
config_fields:
  - key: service_name
    label: "Service Name"
    required: true
    placeholder: "e.g., recommendation-engine"
  - key: version
    label: "Canary Version"
    required: true
    placeholder: "e.g., v2.1.0"
  - key: baseline_version
    label: "Baseline (Current) Version"
    required: true
    placeholder: "e.g., v2.0.3"
features:
  - DEPLOYMENT
---

# Canary Deployment Skill

Execute canary deployment of **{{ service_name }} {{ version }}** against baseline **{{ baseline_version }}**.

## Workflow

### Step 1 — Canary Configuration

```
CANARY SETUP
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Service: {{ service_name }}
Canary version: {{ version }}
Baseline version: {{ baseline_version }}

Traffic ramp schedule:
  Stage 1:  1% canary  (10 min bake)
  Stage 2:  5% canary  (15 min bake)
  Stage 3: 25% canary  (30 min bake)
  Stage 4: 50% canary  (30 min bake)
  Stage 5: 100% canary (promotion)

Rollback trigger (any stage):
  - Error rate: canary > baseline + 1%
  - P95 latency: canary > baseline * 1.5
  - P99 latency: canary > baseline * 2.0
  - Custom metric threshold breach
```

### Step 2 — Pre-Canary Checks

```
PRE-CANARY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Baseline metrics captured:
    - Error rate: ___%
    - P50 latency: ___ms
    - P95 latency: ___ms
    - P99 latency: ___ms
    - Throughput: ___ rps
[ ] Canary version deployed (0% traffic)
[ ] Canary pods/instances healthy
[ ] Canary version verified (version endpoint)
[ ] Monitoring dashboard with canary vs baseline comparison ready
[ ] Alerting configured for canary metrics
[ ] Traffic splitting mechanism configured (service mesh / LB / ingress)
```

### Step 3 — Stage 1: 1% Traffic (Smoke Test)

```
STAGE 1 — 1% TRAFFIC (10 min bake)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Route 1% traffic to canary
[ ] Start time: ___

Metrics gate (at T+10min):
  [ ] Error rate:   canary ___% vs baseline ___% — PASS/FAIL
  [ ] P95 latency:  canary ___ms vs baseline ___ms — PASS/FAIL
  [ ] P99 latency:  canary ___ms vs baseline ___ms — PASS/FAIL
  [ ] No new error types in canary logs
  [ ] No panics, OOMs, or crashes

Decision: PROMOTE / ROLLBACK
```

### Step 4 — Stage 2: 5% Traffic

```
STAGE 2 — 5% TRAFFIC (15 min bake)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Route 5% traffic to canary
[ ] Start time: ___

Metrics gate (at T+15min):
  [ ] Error rate:   canary ___% vs baseline ___% — PASS/FAIL
  [ ] P95 latency:  canary ___ms vs baseline ___ms — PASS/FAIL
  [ ] P99 latency:  canary ___ms vs baseline ___ms — PASS/FAIL
  [ ] Memory usage stable (no leak pattern)
  [ ] CPU usage proportional to traffic share

Decision: PROMOTE / ROLLBACK
```

### Step 5 — Stage 3: 25% Traffic

```
STAGE 3 — 25% TRAFFIC (30 min bake)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Route 25% traffic to canary
[ ] Start time: ___

Metrics gate (at T+30min):
  [ ] Error rate:   canary ___% vs baseline ___% — PASS/FAIL
  [ ] P95 latency:  canary ___ms vs baseline ___ms — PASS/FAIL
  [ ] P99 latency:  canary ___ms vs baseline ___ms — PASS/FAIL
  [ ] Business metrics normal (conversion, success rates)
  [ ] Dependency health unaffected
  [ ] No customer-reported issues

Decision: PROMOTE / ROLLBACK
```

### Step 6 — Stage 4: 50% Traffic

```
STAGE 4 — 50% TRAFFIC (30 min bake)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Route 50% traffic to canary
[ ] Start time: ___

Metrics gate (at T+30min):
  [ ] Error rate:   canary ___% vs baseline ___% — PASS/FAIL
  [ ] P95 latency:  canary ___ms vs baseline ___ms — PASS/FAIL
  [ ] P99 latency:  canary ___ms vs baseline ___ms — PASS/FAIL
  [ ] Autoscaling behaving correctly under load
  [ ] All downstream dependencies stable
  [ ] No data consistency issues

Decision: PROMOTE TO 100% / ROLLBACK
```

### Step 7 — Stage 5: Full Promotion

```
PROMOTION — 100% TRAFFIC
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Route 100% traffic to {{ version }}
[ ] Scale down baseline ({{ baseline_version }}) instances
[ ] Update deployment to {{ version }} as new baseline
[ ] Monitor for 30 minutes post-promotion
[ ] Confirm all metrics stable at full traffic
[ ] Deployment marked as SUCCESSFUL
[ ] Stakeholders notified
```

### Rollback Procedure

```
ROLLBACK (any stage)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Route 100% traffic back to baseline ({{ baseline_version }})
[ ] Scale down canary instances
[ ] Verify baseline metrics return to normal
[ ] Create issue to investigate canary failure
[ ] Document: stage failed, metrics at failure, root cause hypothesis
```

## Output Format

Produce a canary deployment report with:
1. **Canary configuration** (versions, ramp schedule, thresholds)
2. **Per-stage metrics** comparison (canary vs baseline)
3. **Promotion/rollback decision** at each stage with reasoning
4. **Final status** (PROMOTED / ROLLED BACK at stage X)
5. **Metrics summary** chart showing canary vs baseline over time
