---
name: performance-degradation-response
enabled: true
description: |
  Response playbook for latency spikes, throughput degradation, and performance incidents. Covers systematic investigation of application, database, infrastructure, and network layers, with decision frameworks for mitigation strategies including scaling, traffic shedding, and targeted optimization.
required_connections:
  - prefix: slack
    label: "Slack (for incident coordination)"
config_fields:
  - key: affected_service
    label: "Affected Service"
    required: true
    placeholder: "e.g., checkout-api, search-service"
  - key: symptom
    label: "Primary Symptom"
    required: true
    placeholder: "e.g., p99 latency increased from 200ms to 5s"
  - key: start_time
    label: "When Degradation Started"
    required: false
    placeholder: "e.g., 2024-01-15 14:30 UTC"
features:
  - INCIDENT
---

# Performance Degradation Response

Service: **{{ affected_service }}** | Symptom: **{{ symptom }}**
Started: **{{ start_time }}**

## Immediate Triage (0-10 min)

### 1. Quantify the Degradation
- [ ] What is the current p50, p95, p99 latency vs. baseline?
- [ ] What is the current error rate vs. baseline?
- [ ] What is the current throughput (RPS) vs. baseline?
- [ ] Is the degradation constant or intermittent?
- [ ] Is it affecting all endpoints or specific ones?
- [ ] Is it affecting all users or a subset?

### 2. Correlate with Changes
- [ ] Any deployments in the last 24 hours?
- [ ] Any config changes?
- [ ] Any traffic pattern changes (organic growth, marketing campaign)?
- [ ] Any dependency issues (check vendor status pages)?
- [ ] Any infrastructure events (cloud provider, network)?

### 3. Quick Win Checks
- [ ] Is a single instance/pod unhealthy (hot spot)?
- [ ] Is autoscaling responding (if applicable)?
- [ ] Is there an obvious resource constraint (CPU, memory, disk, connections)?

## Systematic Investigation

### Layer 1: Application
| Check | How | Finding |
|-------|-----|---------|
| Recent deployments | CI/CD pipeline history | — |
| Hot endpoints | APM top-N by latency | — |
| Error rates by endpoint | APM/metrics | — |
| Thread/goroutine count | Application metrics | — |
| GC pressure | JVM/runtime metrics | — |
| Connection pool utilization | Application metrics | — |
| Cache hit rates | Cache metrics | — |
| Feature flags changed | Feature flag tool | — |

### Layer 2: Database
| Check | How | Finding |
|-------|-----|---------|
| Slow queries | Slow query log / pg_stat_statements | — |
| Connection count | DB metrics | — |
| Lock contention | Lock monitoring | — |
| Replication lag | Replica status | — |
| Table/index bloat | Table statistics | — |
| Disk I/O | Storage metrics | — |
| Query plan changes | EXPLAIN on slow queries | — |

### Layer 3: Infrastructure
| Check | How | Finding |
|-------|-----|---------|
| CPU utilization | Infrastructure metrics | — |
| Memory utilization | Infrastructure metrics | — |
| Disk I/O / IOPS | Storage metrics | — |
| Network throughput | Network metrics | — |
| Container restarts | Kubernetes events | — |
| Node health | Node metrics / events | — |
| Load balancer metrics | LB dashboard | — |

### Layer 4: Network and DNS
| Check | How | Finding |
|-------|-----|---------|
| DNS resolution time | DNS metrics | — |
| TLS handshake time | APM/traces | — |
| Inter-service latency | Service mesh / traces | — |
| Packet loss | Network monitoring | — |
| Bandwidth saturation | Network metrics | — |

### Layer 5: External Dependencies
| Check | How | Finding |
|-------|-----|---------|
| Third-party API latency | APM/traces | — |
| CDN performance | CDN metrics | — |
| DNS provider | DNS monitoring | — |
| Cloud provider issues | Status page | — |

## Mitigation Strategies

### Immediate Mitigations (apply while investigating)

| Strategy | When to Use | Risk |
|----------|------------|------|
| **Scale horizontally** | CPU/memory constrained, traffic spike | Cost, may not help if bottleneck is elsewhere |
| **Rollback deployment** | Degradation correlates with recent deploy | Reverting features |
| **Enable rate limiting** | Traffic spike overwhelming service | Rejecting legitimate traffic |
| **Shed non-critical traffic** | Need to protect core functionality | Feature degradation |
| **Restart instances** | Memory leak or state corruption suspected | Brief downtime per instance |
| **Failover to replica** | Primary database performance issue | Replication lag data loss |
| **Disable expensive features** | Feature flag gated functionality causing load | Feature unavailability |
| **Scale database** | DB connection or CPU bottleneck | Cost, potential brief interruption |

### Decision Framework
```
Is the degradation caused by a recent change?
├── YES → Rollback the change
└── NO → Is it a traffic/load issue?
    ├── YES → Scale horizontally + rate limit if needed
    └── NO → Is it a database issue?
        ├── YES → Address slow queries, scale reads, add caching
        └── NO → Is it an external dependency?
            ├── YES → Activate circuit breakers, enable fallbacks
            └── NO → Deep investigation (profiling, tracing)
```

## Recovery Verification

- [ ] Latency returned to baseline (p50, p95, p99)
- [ ] Error rate returned to baseline
- [ ] Throughput returned to normal
- [ ] No elevated resource utilization
- [ ] Monitoring stable for 30+ minutes
- [ ] Remove any temporary mitigations (rate limits, extra scaling)
