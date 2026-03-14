---
name: api-latency-investigation
enabled: true
description: |
  Provides a systematic investigation framework for diagnosing and resolving API latency issues. Covers distributed tracing analysis, bottleneck identification across the request path, database query impact, external dependency latency, and optimization recommendations with expected impact.
required_connections:
  - prefix: apm
    label: "APM / Tracing Platform"
  - prefix: monitoring
    label: "Monitoring Platform"
config_fields:
  - key: api_endpoint
    label: "Affected API Endpoint(s)"
    required: true
    placeholder: "e.g., GET /api/v1/orders, POST /api/v1/checkout"
  - key: current_latency
    label: "Current P95 Latency"
    required: true
    placeholder: "e.g., 2500ms"
  - key: target_latency
    label: "Target P95 Latency"
    required: false
    placeholder: "e.g., 500ms"
features:
  - PERFORMANCE
  - API
  - INVESTIGATION
---

# API Latency Investigation

## Phase 1: Symptom Characterization
1. Define the latency problem precisely
   - [ ] Which endpoints are affected?
   - [ ] When did latency increase? (gradual or sudden)
   - [ ] Is it constant or intermittent?
   - [ ] Does it correlate with traffic volume?
   - [ ] Which percentiles are affected? (P50, P95, P99)
   - [ ] Are specific users, regions, or clients affected?
2. Collect current latency metrics
3. Compare against historical baseline
4. Check for recent deployments or infrastructure changes

### Latency Profile

| Endpoint | P50 (current) | P50 (baseline) | P95 (current) | P95 (baseline) | P99 (current) |
|----------|-------------|---------------|-------------|---------------|-------------|
|          | ms          | ms            | ms          | ms            | ms          |

## Phase 2: Request Path Analysis
1. Trace the full request path
   - [ ] Client / CDN / Load Balancer
   - [ ] API Gateway / Reverse Proxy
   - [ ] Application server processing
   - [ ] Database queries
   - [ ] Cache lookups (hit/miss)
   - [ ] External API calls
   - [ ] Message queue operations
   - [ ] Response serialization
2. Measure time spent at each component using distributed tracing
3. Identify the component consuming most time

### Latency Breakdown

| Component | Avg Time (ms) | % of Total | Variance | Bottleneck |
|-----------|-------------|-----------|----------|------------|
| Network/LB | | % | Low/High | [ ] |
| API Gateway | | % | | [ ] |
| App processing | | % | | [ ] |
| Database | | % | | [ ] |
| Cache | | % | | [ ] |
| External APIs | | % | | [ ] |
| Serialization | | % | | [ ] |
| **Total** | | **100%** | | |

## Phase 3: Bottleneck Deep Dive
1. For database bottlenecks:
   - [ ] Review slow queries and execution plans
   - [ ] Check for missing indexes
   - [ ] Analyze connection pool utilization
   - [ ] Check for lock contention
2. For application bottlenecks:
   - [ ] Profile CPU hotspots
   - [ ] Check for memory pressure / GC pauses
   - [ ] Review thread/goroutine blocking
   - [ ] Check for synchronous operations that should be async
3. For external dependency bottlenecks:
   - [ ] Measure dependency response times
   - [ ] Check for timeout configurations
   - [ ] Evaluate circuit breaker behavior
   - [ ] Consider caching dependency responses
4. For network bottlenecks:
   - [ ] Check DNS resolution times
   - [ ] Verify TLS handshake performance
   - [ ] Measure cross-AZ/region latency
   - [ ] Review connection reuse and keep-alive settings

## Phase 4: Root Cause Identification
1. Correlate latency with system metrics
2. Check for resource saturation (CPU, memory, connections, IOPS)
3. Review application logs for errors and warnings
4. Identify any cascade effects from downstream services
5. Document confirmed root cause(s)

### Root Cause Analysis

| Root Cause | Evidence | Impact on Latency | Fix Complexity | Priority |
|-----------|----------|-------------------|---------------|----------|
|           |          | +ms              | Low/Med/High  | 1-5      |

## Phase 5: Optimization Implementation
1. Implement fixes in priority order
   - [ ] Database query optimization and indexing
   - [ ] Caching layer (application cache, Redis, CDN)
   - [ ] Connection pooling tuning
   - [ ] Async processing for non-critical paths
   - [ ] Payload size reduction
   - [ ] Batch/bulk API operations
   - [ ] Circuit breakers for external dependencies
2. Test each fix and measure latency impact
3. Verify no regressions introduced

## Phase 6: Validation & Monitoring
1. Compare post-fix latency against baseline
2. Validate across all affected percentiles
3. Run load test at peak traffic levels
4. Set up latency alerting and SLO monitoring
5. Document findings for future reference

## Output Format
- **Latency Profile**: Current vs. baseline by percentile
- **Request Path Breakdown**: Time per component analysis
- **Root Cause Report**: Confirmed causes with evidence
- **Optimization Results**: Before/after latency measurements
- **Monitoring Setup**: Alerts and dashboards for ongoing tracking

## Action Items
- [ ] Characterize the latency problem with precise metrics
- [ ] Trace request path and identify bottleneck components
- [ ] Deep dive into top bottleneck(s)
- [ ] Implement optimizations in priority order
- [ ] Validate latency improvement against targets
- [ ] Set up ongoing latency monitoring and alerting
