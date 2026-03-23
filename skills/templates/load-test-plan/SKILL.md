---
name: load-test-plan
enabled: true
description: |
  Use when performing load test plan — load testing plan template covering test
  scenario design, baseline capture, execution configuration, results analysis,
  and reporting. Supports k6, Locust, Gatling, and JMeter approaches. Use for
  capacity validation, performance regression testing, or pre-launch load
  testing.
required_connections:
  - prefix: datadog
    label: "Datadog (or monitoring platform)"
config_fields:
  - key: service_name
    label: "Service / Endpoint Under Test"
    required: true
    placeholder: "e.g., api.example.com/v2/orders"
  - key: target_rps
    label: "Target RPS (Requests Per Second)"
    required: true
    placeholder: "e.g., 5000"
  - key: test_duration
    label: "Test Duration"
    required: false
    placeholder: "e.g., 30 minutes"
features:
  - SRE
  - PERFORMANCE
---

# Load Test Plan Skill

Design and execute load testing for **{{ service_name }}** targeting **{{ target_rps }} RPS**.

## Workflow

### Step 1 — Test Objectives

Define what this load test will validate:

```
TEST OBJECTIVES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Target: {{ service_name }}
Target RPS: {{ target_rps }}
Duration: {{ test_duration | "30 minutes" }}

Goals:
[ ] Validate service handles {{ target_rps }} RPS within SLO
[ ] Identify performance bottlenecks before they hit production
[ ] Establish performance baseline for regression detection
[ ] Determine maximum throughput before degradation
[ ] Validate autoscaling behavior under load

Success criteria:
  - P95 latency: < ___ms
  - P99 latency: < ___ms
  - Error rate: < ___%
  - Throughput: ≥ {{ target_rps }} RPS sustained
```

### Step 2 — Test Scenarios

```
SCENARIO DESIGN
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Scenario 1 — Baseline (current production traffic)
  - RPS: [current production average]
  - Duration: 10 minutes
  - Purpose: Capture baseline metrics

Scenario 2 — Target Load
  - RPS: {{ target_rps }}
  - Duration: {{ test_duration | "30 minutes" }}
  - Ramp-up: 5 minutes linear ramp
  - Purpose: Validate target capacity

Scenario 3 — Peak Load (2x target)
  - RPS: [2x {{ target_rps }}]
  - Duration: 15 minutes
  - Purpose: Find breaking point and validate graceful degradation

Scenario 4 — Stress Test (ramp to failure)
  - RPS: Ramp from {{ target_rps }} to max, +10% every 2 minutes
  - Purpose: Determine absolute maximum throughput

Scenario 5 — Soak Test (optional)
  - RPS: {{ target_rps }}
  - Duration: 2-4 hours
  - Purpose: Detect memory leaks, connection pool exhaustion
```

### Step 3 — Test Configuration

```
REQUEST PROFILE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
| Endpoint | Method | Weight | Payload |
|----------|--------|--------|---------|
| [path] | GET | 60% | - |
| [path] | POST | 25% | [size] |
| [path] | PUT | 10% | [size] |
| [path] | DELETE | 5% | - |

Test data:
[ ] Test user accounts provisioned
[ ] Test data seeded in database
[ ] Authentication tokens pre-generated
[ ] Request payloads prepared (realistic size/complexity)

Environment:
[ ] Test environment isolated from production
[ ] Test environment matches production spec (or scaled proportionally)
[ ] Load generators provisioned in same region as target
[ ] Monitoring dashboards configured
```

### Step 4 — Pre-Test Checklist

```
PRE-TEST
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Stakeholders notified of test window
[ ] Target service team aware and monitoring
[ ] Baseline metrics captured (before test)
[ ] Rate limiters adjusted or bypassed for test traffic
[ ] Autoscaling verified (or fixed replica count for controlled test)
[ ] Test script dry-run successful (low RPS sanity check)
[ ] Kill switch ready to stop test immediately
[ ] Database capacity sufficient for test data volume
```

### Step 5 — Execution & Monitoring

```
DURING TEST — MONITOR
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Service metrics:
[ ] Request rate (actual vs target)
[ ] Error rate (by status code: 4xx, 5xx)
[ ] Latency (P50, P95, P99)
[ ] Throughput (successful requests/sec)

Infrastructure metrics:
[ ] CPU utilization (per instance and aggregate)
[ ] Memory utilization
[ ] Network I/O
[ ] Disk I/O (if applicable)

Dependency metrics:
[ ] Database query time and connection pool usage
[ ] Cache hit ratio and latency
[ ] External API response time
[ ] Message queue depth (if applicable)

ABORT CRITERIA:
[ ] Error rate > 10% for > 2 minutes
[ ] Service becomes unresponsive
[ ] Downstream services impacted
[ ] Data corruption detected
```

### Step 6 — Results Analysis

```
RESULTS TEMPLATE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
| Metric | Baseline | Target Load | Peak Load | SLO | Status |
|--------|----------|------------|-----------|-----|--------|
| RPS achieved | ___ | ___ | ___ | {{ target_rps }} | PASS/FAIL |
| P50 latency | ___ms | ___ms | ___ms | ___ms | PASS/FAIL |
| P95 latency | ___ms | ___ms | ___ms | ___ms | PASS/FAIL |
| P99 latency | ___ms | ___ms | ___ms | ___ms | PASS/FAIL |
| Error rate | ___% | ___% | ___% | ___% | PASS/FAIL |
| Max CPU | ___% | ___% | ___% | 80% | PASS/FAIL |
| Max memory | ___% | ___% | ___% | 80% | PASS/FAIL |

Breaking point: ___ RPS (where error rate > 1% or P95 > SLO)
Headroom: ___% above target RPS before degradation
```

### Step 7 — Recommendations

Produce actionable recommendations:
1. **Bottlenecks identified**: [resource, threshold, impact]
2. **Optimization opportunities**: [specific tuning recommendations]
3. **Scaling recommendations**: [infrastructure changes needed]
4. **Retest needed**: [YES/NO, with specific scenarios]

## Counter-Rationalizations

| Shortcut | Counter | Why |
|----------|---------|-----|
| "We can skip some steps for this case" | Adapt the workflow steps, don't skip them | Skipped steps are where incidents and oversights originate |
| "The user seems to already know what to do" | Complete all workflow phases with the user | The workflow catches blind spots that experience alone misses |
| "This is a minor case, full process is overkill" | Scale the process down, don't turn it off | Minor cases become major when unstructured; the process scales, not disappears |
| "I'll fill in the details later" | Complete each section before moving on | Deferred details are forgotten; real-time capture is more accurate |
| "The template output isn't necessary" | Always produce the structured output format | Structured output enables comparison, audit trails, and handoff to other teams |

## Output Format

Produce a load test report with:
1. **Test configuration** (scenarios, endpoints, traffic profile)
2. **Results table** with metrics per scenario vs SLO
3. **Bottleneck analysis** with graphs/data showing saturation points
4. **Recommendations** prioritized by impact
5. **Comparison** with previous test runs (if available)
