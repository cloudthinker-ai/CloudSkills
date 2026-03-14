---
name: runbook-cache-flush
enabled: true
description: |
  Cache flush and warm procedure covering impact assessment, flush execution, and warming strategy. Use when cache data is stale, after schema changes, or when cache corruption is suspected.
required_connections: []
config_fields:
  - key: cache_service
    label: "Cache Service"
    required: true
    placeholder: "e.g., Redis production cluster, Memcached"
  - key: cache_endpoint
    label: "Cache Endpoint"
    required: true
    placeholder: "e.g., redis-prod.internal:6379"
  - key: flush_scope
    label: "Flush Scope"
    required: true
    placeholder: "e.g., full flush, specific key pattern user:*"
  - key: reason
    label: "Reason for Flush"
    required: false
    placeholder: "e.g., stale data after migration, cache poisoning"
features:
  - RUNBOOK
  - DATABASE
---

# Cache Flush and Warm Runbook Skill

Execute cache flush for **{{ cache_service }}** at **{{ cache_endpoint }}**.
Scope: **{{ flush_scope }}** | Reason: **{{ reason }}**

## Workflow

### Phase 1 — Impact Assessment

```
IMPACT ASSESSMENT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
CACHE PROFILE
  Service: {{ cache_service }}
  Endpoint: {{ cache_endpoint }}
  Flush scope: {{ flush_scope }}
  Current memory usage: ___ MB / ___ MB total
  Key count: ___
  Hit ratio (current): ___%

DOWNSTREAM IMPACT
[ ] Identify services dependent on this cache
[ ] Estimate cache-miss penalty (latency increase): ___ ms
[ ] Estimate origin load increase: ___x multiplier
[ ] Check origin (database/API) can handle thundering herd
[ ] Estimate time to rebuild cache organically: ___ minutes

RISK ASSESSMENT
[ ] Can origin handle 100% cache-miss traffic? YES / NO
[ ] Is there a read-through cache pattern in place? YES / NO
[ ] Will flush cause user-visible latency increase? YES / NO
[ ] Is there a risk of cache stampede? YES / NO
```

### Phase 2 — Pre-Flush Preparation

```
PREPARATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Notify dependent service owners
[ ] Scale up origin (database / API) if needed
    - Current capacity: ___
    - Target capacity: ___
[ ] Enable rate limiting on cache-miss path (if available)
[ ] Configure circuit breaker thresholds (if available)
[ ] Take cache snapshot / RDB backup (if full flush)
[ ] Open monitoring dashboards:
    - Cache hit/miss ratio
    - Origin service latency and error rate
    - Application response times
[ ] Confirm maintenance window with stakeholders
```

### Phase 3 — Flush Execution

```
FLUSH EXECUTION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
TARGETED FLUSH (preferred — specific keys/patterns):
1. [ ] Identify keys to flush: {{ flush_scope }}
2. [ ] Count keys matching pattern: ___
3. [ ] Delete keys using SCAN + DEL (never use KEYS in production)
4. [ ] Verify target keys removed
5. [ ] Confirm non-target keys intact

FULL FLUSH (use only when necessary):
1. [ ] Final confirmation: full flush approved by ___
2. [ ] Execute FLUSHDB or FLUSHALL
3. [ ] Record flush timestamp: ___
4. [ ] Verify memory freed: ___ MB

POST-FLUSH METRICS
  Key count after flush: ___
  Memory after flush: ___ MB
  Timestamp: ___
```

### Phase 4 — Cache Warming Strategy

```
CACHE WARMING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
WARMING APPROACH (select one):
[ ] Passive warming — let read-through rebuild cache naturally
[ ] Active warming — run warming script to pre-populate hot keys
[ ] Hybrid — warm critical keys actively, let others rebuild passively

ACTIVE WARMING STEPS (if selected):
1. [ ] Identify hot keys from previous access patterns
2. [ ] Run warming script / job:
    - Target key count: ___
    - Batch size: ___
    - Rate limit: ___ keys/second
3. [ ] Monitor warming progress: ___% complete
4. [ ] Verify warmed data correctness (spot-check samples)

WARMING PROGRESS
  Hit ratio target: > ___%
  Current hit ratio: ___%
  Estimated time to target: ___ minutes
```

### Phase 5 — Post-Flush Validation

```
POST-FLUSH VALIDATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
CACHE HEALTH (check at T+5min, T+15min, T+1h)
[ ] Cache hit ratio recovering: ___% -> ___% -> ___%
[ ] Memory utilization trending back to normal
[ ] No eviction pressure (if memory-limited)
[ ] Connection count stable

APPLICATION HEALTH
[ ] Response times returning to baseline
[ ] Error rate at or below pre-flush level
[ ] No timeout errors from cache layer
[ ] Origin load decreasing as cache warms

ORIGIN HEALTH
[ ] Database CPU / connections returning to normal
[ ] API backend latency returning to normal
[ ] No connection pool exhaustion events
```

### Phase 6 — Cleanup

```
CLEANUP
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Scale down origin if it was scaled up
[ ] Remove temporary rate limits or circuit breaker overrides
[ ] Confirm cache hit ratio at steady state: ___%
[ ] Notify stakeholders of completion
[ ] Document flush results and lessons learned
[ ] Update cache TTL policies if stale data was the root cause
```

## Output Format

Produce a cache flush execution report with:
1. **Flush summary** (service, scope, reason, timestamps)
2. **Impact assessment** results and risk mitigations applied
3. **Flush execution** confirmation with before/after metrics
4. **Warming progress** tracking and hit ratio recovery curve
5. **Validation results** (application and origin health)
