---
name: cascading-failure-response
enabled: true
description: |
  Use when performing cascading failure response — response playbook for
  cascading and correlated failures across multiple services. Covers
  identification of the originating failure, blast radius mapping, circuit
  breaker activation, load shedding strategies, service isolation, dependency
  graph analysis, and coordinated multi-team recovery procedures.
required_connections:
  - prefix: slack
    label: "Slack (for multi-team coordination)"
config_fields:
  - key: initial_failure
    label: "Initial/Suspected Failure Point"
    required: true
    placeholder: "e.g., auth-service timeout causing downstream failures"
  - key: affected_services
    label: "Affected Services (known so far)"
    required: true
    placeholder: "e.g., auth-service, user-api, checkout, dashboard"
  - key: severity
    label: "Severity"
    required: true
    placeholder: "e.g., SEV1"
features:
  - INCIDENT
---

# Cascading Failure Response

Initial Failure: **{{ initial_failure }}**
Affected Services: **{{ affected_services }}**
Severity: **{{ severity }}**

## Why Cascading Failures Are Different

Cascading failures require a fundamentally different approach than single-service incidents:
- Multiple teams must coordinate simultaneously
- Fixing downstream symptoms without addressing the root cause wastes effort
- Standard mitigation (restart, scale up) can make cascading failures WORSE
- The blast radius may still be expanding while you investigate

## Phase 1 — Stabilize (0-15 min)

**Goal:** Stop the cascade from spreading further. Do NOT try to fix the root cause yet.

### Immediate Actions
- [ ] **Identify the dependency graph** — which services depend on what
- [ ] **Activate circuit breakers** — stop failing calls from propagating
- [ ] **Enable load shedding** — reject low-priority traffic to protect core paths
- [ ] **Isolate the failing service** — prevent it from consuming resources of healthy services
- [ ] **Disable retry storms** — retries on failing services amplify the cascade

### Anti-Patterns During Cascading Failures
| DO NOT | WHY |
|--------|-----|
| Restart all instances simultaneously | Thundering herd on recovery |
| Scale up aggressively | May overwhelm downstream dependencies |
| Enable retries | Amplifies load on already-failing services |
| Focus on downstream symptoms | Must find the originating failure first |
| Let each team fix independently | Uncoordinated recovery causes oscillation |

## Phase 2 — Map the Blast Radius (15-30 min)

### Service Impact Matrix

| Service | Status | Depends On | Depended On By | Circuit Breaker | Notes |
|---------|--------|-----------|----------------|-----------------|-------|
| _service_ | _healthy/degraded/down_ | _services_ | _services_ | _active/inactive/N/A_ | — |

### Identify the Root Service
Work backwards through the dependency chain:
1. Which service failed FIRST? (check alert timestamps)
2. Which services have NO failing upstream dependencies?
3. Of those, which one is currently unhealthy?

**Root service identified:** _______________

### Blast Radius Visualization
```
[Root Failure] ──→ [Service A] ──→ [Service C] ──→ [Service E]
                        │
                        └──→ [Service D]
                ──→ [Service B] ──→ [Service F]
```

## Phase 3 — Coordinated Recovery

### Recovery Order
Recover services in dependency order — upstream first, downstream after.

| Priority | Service | Action | Owner | Status |
|----------|---------|--------|-------|--------|
| 1 | _root service_ | _fix/restart/rollback_ | _team_ | — |
| 2 | _direct dependent_ | _wait for upstream + verify_ | _team_ | — |
| 3 | _indirect dependent_ | _wait + clear backlogs_ | _team_ | — |

### Controlled Recovery Protocol
1. Fix the root service first
2. Verify root service is healthy (metrics at baseline for 5+ minutes)
3. Gradually re-enable traffic to direct dependents (start at 10%)
4. Monitor for re-cascading at each step
5. Increase traffic incrementally (10% → 25% → 50% → 100%)
6. Repeat for each layer of the dependency chain

### Queue/Backlog Management
- [ ] Identify message queues with backlogs from the outage
- [ ] Determine if backlog should be processed or purged
- [ ] If processing: rate-limit consumers to avoid re-overwhelming services
- [ ] Monitor queue depth during recovery

## Phase 4 — Verification

- [ ] All services reporting healthy
- [ ] Error rates at baseline across all affected services
- [ ] Latency at baseline across all affected services
- [ ] No queue backlogs growing
- [ ] Circuit breakers returned to closed state
- [ ] Load shedding disabled
- [ ] Monitoring stable for 30+ minutes

## Post-Incident Focus Areas

### Resilience Improvements
- [ ] Review circuit breaker configurations (thresholds, timeouts)
- [ ] Implement bulkhead patterns to isolate failures
- [ ] Add graceful degradation for non-critical dependencies
- [ ] Review retry policies (exponential backoff, jitter, limits)
- [ ] Implement load shedding at service boundaries
- [ ] Add dependency health checks to readiness probes
- [ ] Review timeout configurations across the service mesh

### Monitoring Improvements
- [ ] Add cascading failure detection alerts
- [ ] Create service dependency dashboard
- [ ] Add circuit breaker state monitoring
- [ ] Implement distributed tracing for cross-service debugging

## Counter-Rationalizations

| Shortcut | Counter | Why |
|----------|---------|-----|
| "We can skip some steps for this case" | Adapt the workflow steps, don't skip them | Skipped steps are where incidents and oversights originate |
| "The user seems to already know what to do" | Complete all workflow phases with the user | The workflow catches blind spots that experience alone misses |
| "This is a minor case, full process is overkill" | Scale the process down, don't turn it off | Minor cases become major when unstructured; the process scales, not disappears |
| "I'll fill in the details later" | Complete each section before moving on | Deferred details are forgotten; real-time capture is more accurate |
| "The template output isn't necessary" | Always produce the structured output format | Structured output enables comparison, audit trails, and handoff to other teams |

