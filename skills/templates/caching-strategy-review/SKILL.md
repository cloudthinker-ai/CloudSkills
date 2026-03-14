---
name: caching-strategy-review
enabled: true
description: |
  Reviews and designs caching strategies for services, evaluating cache placement, invalidation approaches, consistency trade-offs, and capacity planning. This template helps teams make informed decisions about what to cache, where to cache it, and how to handle cache lifecycle management.
required_connections:
  - prefix: monitoring
    label: "Monitoring Platform"
config_fields:
  - key: service_name
    label: "Service Name"
    required: true
    placeholder: "e.g., product-catalog-api"
  - key: cache_technology
    label: "Cache Technology"
    required: false
    placeholder: "e.g., Redis, Memcached, CDN"
features:
  - CACHING
  - PERFORMANCE
  - ARCHITECTURE
---

# Caching Strategy Review

## Phase 1: Current State Assessment

Document the existing caching setup (or lack thereof).

- [ ] Current cache technology: ___
- [ ] Cache hit ratio: ___%
- [ ] Cache miss latency (p99): ___
- [ ] Cache hit latency (p99): ___
- [ ] Origin latency without cache (p99): ___
- [ ] Cache size (current usage): ___
- [ ] Eviction rate: ___
- [ ] Cache-related incidents in last 90 days: ___

## Phase 2: Cache Candidacy Analysis

Evaluate which data should be cached.

| Data | Read Frequency | Write Frequency | Read:Write Ratio | Staleness Tolerance | Size per Entry | Cache Candidate |
|------|---------------|-----------------|------------------|--------------------|----|-----------------|
|      | High/Med/Low  | High/Med/Low    |                  | Seconds/Minutes/Hours | | Y/N |

**Decision Matrix — Cache Candidacy:**

| Criteria | Strong Candidate | Weak Candidate |
|----------|-----------------|----------------|
| Read:Write ratio | >10:1 | <2:1 |
| Staleness tolerance | Minutes to hours | Real-time required |
| Computation cost | Expensive queries or aggregations | Simple key lookups |
| Data size | Fits in memory budget | Too large for cache tier |
| Access pattern | Hot subset, power law distribution | Uniform random access |

## Phase 3: Cache Architecture Design

**Cache Placement:**

- [ ] Client-side cache (browser, mobile)
- [ ] CDN / edge cache
- [ ] API gateway cache
- [ ] Application-level cache (in-process)
- [ ] Distributed cache (Redis, Memcached)
- [ ] Database query cache

**Cache Strategy Selection:**

| Pattern | When to Use | Trade-offs |
|---------|------------|------------|
| Cache-aside (lazy loading) | General purpose, read-heavy | Cache miss penalty, potential stale data |
| Write-through | Need strong consistency | Write latency increase |
| Write-behind | Write-heavy, eventual consistency OK | Complexity, data loss risk |
| Read-through | Simplify application code | Cache dependency for all reads |
| Refresh-ahead | Predictable access patterns | Wasted refreshes for unused data |

- [ ] Selected strategy: ___
- [ ] Justification: ___

## Phase 4: Invalidation Strategy

- [ ] TTL-based expiration: ___ seconds
- [ ] Event-based invalidation (on write/update)
- [ ] Version-based invalidation (cache key includes version)
- [ ] Manual invalidation capability
- [ ] Cache warming strategy for cold starts

**Consistency Analysis:**

- [ ] Maximum acceptable staleness: ___
- [ ] Thundering herd protection (lock/collapse duplicate requests)
- [ ] Cache stampede prevention (jittered TTLs)
- [ ] Negative caching (cache misses to prevent repeated lookups)

## Phase 5: Capacity and Resilience

- [ ] Memory budget: ___
- [ ] Eviction policy: LRU / LFU / TTL / Random
- [ ] Cache cluster sizing (nodes, replicas)
- [ ] Failure mode: Graceful degradation to origin
- [ ] Circuit breaker on cache failures
- [ ] Cache is not a single point of failure
- [ ] Monitoring and alerting on hit ratio, latency, evictions

## Output Format

### Summary

- **Service:** ___
- **Cache technology:** ___
- **Strategy:** ___
- **Expected hit ratio:** ___%
- **Expected latency improvement:** ___
- **Memory budget:** ___

### Action Items

- [ ] Implement selected caching strategy
- [ ] Configure TTL and invalidation rules
- [ ] Set up monitoring dashboards for cache metrics
- [ ] Add alerts for hit ratio drops and high eviction rates
- [ ] Load test with cache enabled and disabled
- [ ] Document cache warming procedure
- [ ] Plan for cache failure scenarios
