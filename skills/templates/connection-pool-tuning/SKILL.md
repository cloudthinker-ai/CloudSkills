---
name: connection-pool-tuning
enabled: true
description: |
  Use when performing connection pool tuning — guides the analysis and
  optimization of connection pools for databases, HTTP clients, and message
  brokers. Covers pool sizing calculations, timeout configuration, leak
  detection, monitoring setup, and performance validation to eliminate
  connection-related bottlenecks.
required_connections:
  - prefix: monitoring
    label: "Monitoring Platform"
config_fields:
  - key: pool_type
    label: "Connection Pool Type"
    required: true
    placeholder: "e.g., database (HikariCP, pgbouncer), HTTP client, Redis"
  - key: current_pool_size
    label: "Current Pool Size"
    required: true
    placeholder: "e.g., max=50, min=10"
  - key: symptom
    label: "Primary Symptom"
    required: false
    placeholder: "e.g., connection timeout, pool exhaustion, high latency"
features:
  - PERFORMANCE
  - DATABASE
  - OPTIMIZATION
---

# Connection Pool Tuning

## Phase 1: Current State Assessment
1. Collect connection pool metrics
   - [ ] Active connections (average and peak)
   - [ ] Idle connections
   - [ ] Pending connection requests (queue depth)
   - [ ] Connection wait time (P50, P95, P99)
   - [ ] Connection creation rate
   - [ ] Connection lifetime and usage patterns
   - [ ] Connection timeout/error rate
   - [ ] Pool utilization percentage
2. Map connection consumers (application instances, threads)
3. Identify connection target capacity limits

### Pool Metrics Baseline

| Metric | Current | Healthy Range | Status |
|--------|---------|---------------|--------|
| Max pool size | | | |
| Active (avg) | | < 70% of max | |
| Active (peak) | | < 90% of max | |
| Idle (avg) | | > min pool | |
| Wait time P50 | ms | < 5ms | |
| Wait time P95 | ms | < 50ms | |
| Timeout rate | /hr | 0 | |
| Creation rate | /min | Low | |

## Phase 2: Pool Sizing Analysis
1. Calculate optimal pool size
   - Database pools: `pool_size = (core_count * 2) + effective_spindle_count`
   - For cloud databases: consider max connections limit and instance count
   - HTTP client pools: based on downstream service capacity
   - Formula: `max_pool = ceil(peak_concurrent_requests * avg_request_hold_time / 1000)`
2. Account for multiple application instances
   - Total connections = pool_size_per_instance * instance_count
   - Must not exceed target's max_connections
3. Determine min pool size (handle baseline without creation overhead)

### Pool Sizing Calculation

| Factor | Value | Notes |
|--------|-------|-------|
| Peak concurrent requests | /s | From traffic data |
| Avg connection hold time | ms | From profiling |
| Application instances | | Current count |
| Target max connections | | Database/service limit |
| Calculated pool per instance | | Formula result |
| Recommended max pool | | With safety margin |
| Recommended min pool | | Baseline connections |

## Phase 3: Timeout Configuration
1. Configure connection timeouts
   - [ ] Connection acquisition timeout (how long to wait for pool connection)
   - [ ] Connection creation timeout (how long to establish new connection)
   - [ ] Idle timeout (when to close idle connections)
   - [ ] Max lifetime (maximum age before forced recycling)
   - [ ] Validation timeout (health check query timeout)
   - [ ] Socket/read/write timeout on the connection itself
2. Set timeouts based on SLA requirements

### Timeout Configuration

| Timeout | Current | Recommended | Rationale |
|---------|---------|-------------|-----------|
| Acquisition | ms | ms | Fail fast for user-facing |
| Creation | ms | ms | Network + auth overhead |
| Idle | min | min | Release unused resources |
| Max lifetime | min | min | Prevent stale connections |
| Validation | ms | ms | Quick health check |
| Socket read | ms | ms | Query timeout |

## Phase 4: Connection Leak Detection
1. Check for connection leaks
   - [ ] Connections borrowed but never returned
   - [ ] Transactions not committed/rolled back
   - [ ] Connections held across long operations
   - [ ] Connections not returned in error paths
2. Enable leak detection logging
3. Set leak detection threshold (connection held > N seconds)
4. Review application code for proper try-with-resources / using patterns

### Leak Detection Checklist

| Pattern | Risk | Detected | Fix |
|---------|------|----------|-----|
| Missing close in catch/finally | High | [ ] | try-with-resources |
| Connection passed across methods | Medium | [ ] | Scoped usage |
| Long-held transactions | Medium | [ ] | Reduce scope |
| Background task holding connection | High | [ ] | Separate pool |

## Phase 5: Advanced Configuration
1. Configure pool behavior
   - [ ] Connection validation strategy (on borrow, on return, periodic)
   - [ ] Eviction policy for idle connections
   - [ ] Fair scheduling (FIFO) vs. LIFO connection reuse
   - [ ] Separate pools for different workloads (OLTP vs. reporting)
   - [ ] Read replica pool configuration
2. Configure connection pool for failover scenarios
3. Set up pool warm-up on application start

## Phase 6: Monitoring & Alerting
1. Set up pool monitoring dashboards
2. Configure alerts
   - [ ] Pool utilization > 80% - warning
   - [ ] Pool utilization > 95% - critical
   - [ ] Connection wait time P95 > threshold
   - [ ] Connection timeout rate > 0
   - [ ] Connection creation errors
3. Validate changes under load test
4. Document final configuration

## Counter-Rationalizations

| Shortcut | Counter | Why |
|----------|---------|-----|
| "We can skip some steps for this case" | Adapt the workflow steps, don't skip them | Skipped steps are where incidents and oversights originate |
| "The user seems to already know what to do" | Complete all workflow phases with the user | The workflow catches blind spots that experience alone misses |
| "This is a minor case, full process is overkill" | Scale the process down, don't turn it off | Minor cases become major when unstructured; the process scales, not disappears |
| "I'll fill in the details later" | Complete each section before moving on | Deferred details are forgotten; real-time capture is more accurate |
| "The template output isn't necessary" | Always produce the structured output format | Structured output enables comparison, audit trails, and handoff to other teams |

## Output Format
- **Pool Assessment**: Current metrics and health status
- **Sizing Recommendation**: Calculated optimal pool configuration
- **Timeout Configuration**: All timeout values with rationale
- **Leak Analysis**: Detection results and code fixes
- **Monitoring Dashboard**: Pool health metrics and alerts

## Action Items
- [ ] Collect current pool metrics and baseline
- [ ] Calculate optimal pool size for workload
- [ ] Configure appropriate timeouts
- [ ] Enable and review leak detection
- [ ] Apply configuration changes (staging first)
- [ ] Validate under load test
- [ ] Set up ongoing pool monitoring and alerts
