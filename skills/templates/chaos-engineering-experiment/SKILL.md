---
name: chaos-engineering-experiment
enabled: true
description: |
  Use when performing chaos engineering experiment — chaos engineering
  experiment template covering hypothesis definition, blast radius containment,
  experiment execution, observation, and learning. Supports Chaos Monkey,
  Litmus, Gremlin, and manual fault injection. Use for resilience validation and
  failure mode discovery.
required_connections:
  - prefix: datadog
    label: "Datadog (or monitoring platform)"
config_fields:
  - key: target_system
    label: "Target System"
    required: true
    placeholder: "e.g., order-service"
  - key: failure_type
    label: "Failure Type"
    required: true
    placeholder: "e.g., pod-kill, network-latency, cpu-stress, az-failure"
  - key: environment
    label: "Environment"
    required: true
    placeholder: "e.g., staging, production"
features:
  - SRE
  - CHAOS
---

# Chaos Engineering Experiment Skill

Design and execute a chaos experiment on **{{ target_system }}** with failure type **{{ failure_type }}** in **{{ environment }}**.

## Workflow

### Step 1 — Experiment Design

```
EXPERIMENT CARD
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Target: {{ target_system }}
Failure type: {{ failure_type }}
Environment: {{ environment }}
Date: [auto-populated]
Experiment owner: [name]

HYPOTHESIS
"We believe that when [{{ failure_type }}] affects [{{ target_system }}],
the system will [expected behavior] because [reasoning].
User impact will be [none / degraded / partial outage] lasting [duration]."

STEADY STATE DEFINITION
The following metrics define "normal" for {{ target_system }}:
  - Error rate: < ___%
  - P95 latency: < ___ms
  - Throughput: > ___ rps
  - Availability: > ___%
  - [Custom metric]: [threshold]
```

### Step 2 — Blast Radius & Safety

```
BLAST RADIUS CONTAINMENT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SCOPE LIMITS
[ ] Affected components: [list only what will be impacted]
[ ] Unaffected components: [confirm isolation]
[ ] Maximum duration: ___ minutes
[ ] Maximum percentage of instances affected: ___%
[ ] Customer impact expected: NONE / MINIMAL / MODERATE

SAFETY CONTROLS
[ ] Kill switch ready (abort experiment instantly)
[ ] Automatic rollback configured (time-based or metric-based)
[ ] Monitoring alerts will fire if blast radius exceeds plan
[ ] On-call engineer aware and standing by
[ ] Customer-facing incident process ready (if production)

ABORT CRITERIA
[ ] Error rate exceeds ___% for > ___ minutes
[ ] P95 latency exceeds ___ms for > ___ minutes
[ ] Downstream services degraded beyond acceptable
[ ] Data loss or corruption detected
[ ] Customer complaints received
```

### Step 3 — Pre-Experiment Baseline

```
BASELINE CAPTURE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Capture 15 minutes of steady state before injection:

[ ] Error rate: ___%
[ ] P50 latency: ___ms
[ ] P95 latency: ___ms
[ ] P99 latency: ___ms
[ ] Throughput: ___ rps
[ ] CPU utilization: ___%
[ ] Memory utilization: ___%
[ ] Active instances/pods: ___
[ ] [Custom metric]: ___

All metrics within steady state definition: YES / NO
```

### Step 4 — Fault Injection

```
FAULT INJECTION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Injection method: [Chaos Monkey / Litmus / Gremlin / tc / kill / manual]

Common fault types:
  Pod/instance termination:
    [ ] Kill X% of pods/instances simultaneously

  Network faults:
    [ ] Add ___ms latency to [target]
    [ ] Drop ___% of packets to [target]
    [ ] Partition [component-A] from [component-B]

  Resource stress:
    [ ] CPU stress to ___% on [target]
    [ ] Memory pressure to ___% on [target]
    [ ] Disk fill to ___% on [target]

  Dependency failure:
    [ ] Block traffic to [database / cache / API]
    [ ] Return errors from [dependency] at ___% rate

  Infrastructure:
    [ ] Simulate AZ failure
    [ ] Revoke IAM permissions
    [ ] Expire certificates

INJECTION START TIME: ___
PLANNED DURATION: ___ minutes
```

### Step 5 — Observation

```
OBSERVATION LOG
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[T+0]   Fault injected: [description]
[T+Xm]  Observed: [metric change, alert fired, behavior]
[T+Xm]  System response: [autoscaling, circuit breaker, failover]
[T+Xm]  Recovery: [how system recovered, time to recover]

KEY OBSERVATIONS:
[ ] Did alerts fire? Which ones? How quickly?
[ ] Did autoscaling/self-healing engage?
[ ] Did circuit breakers trip?
[ ] Did failover work correctly?
[ ] Was the user experience impacted?
[ ] How long until steady state restored?
```

### Step 6 — Results & Analysis

```
EXPERIMENT RESULTS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
HYPOTHESIS RESULT: CONFIRMED / DISPROVED / PARTIALLY CONFIRMED

| Metric | Baseline | During Experiment | Recovery Time |
|--------|----------|-------------------|---------------|
| Error rate | ___% | ___% | ___ min |
| P95 latency | ___ms | ___ms | ___ min |
| Throughput | ___ rps | ___ rps | ___ min |
| Availability | ___% | ___% | ___ min |

FINDINGS:
1. [What worked well — resilience mechanisms that functioned]
2. [What failed — unexpected behaviors or gaps]
3. [Surprises — things the team did not predict]

IMPROVEMENTS NEEDED:
| Finding | Action | Priority | Owner |
|---------|--------|----------|-------|
| [gap] | [fix] | P1/P2/P3 | [name] |
```

### Step 7 — Follow-Up

```
NEXT STEPS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Share results with team
[ ] File action items for improvements
[ ] Schedule follow-up experiment after fixes
[ ] Add to chaos experiment catalog
[ ] Update runbooks based on findings
[ ] Consider automating this experiment for continuous validation
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

Produce a chaos experiment report with:
1. **Experiment card** (hypothesis, target, failure type, blast radius)
2. **Baseline vs experiment metrics** comparison table
3. **Observation timeline** with key events
4. **Hypothesis result** (confirmed/disproved) with evidence
5. **Action items** for resilience improvements
