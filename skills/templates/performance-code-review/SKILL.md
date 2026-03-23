---
name: performance-code-review
enabled: true
description: |
  Use when performing performance code review — performance-focused code review
  template covering N+1 query detection, memory leak identification, caching
  strategy evaluation, algorithmic complexity analysis, and resource utilization
  review. Provides a systematic framework for identifying performance
  bottlenecks and regressions before they impact production systems.
required_connections:
  - prefix: github
    label: "GitHub"
config_fields:
  - key: repository
    label: "Repository"
    required: true
    placeholder: "e.g., org/backend-service"
  - key: pr_number
    label: "PR Number"
    required: true
    placeholder: "e.g., 1234"
  - key: performance_sla
    label: "Performance SLA"
    required: false
    placeholder: "e.g., p99 < 200ms"
features:
  - CODE_REVIEW
---

# Performance Code Review Skill

Performance review of PR **#{{ pr_number }}** in **{{ repository }}** against SLA **{{ performance_sla }}**.

## Workflow

### Phase 1 — Database and Query Performance

```
DATABASE PERFORMANCE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] N+1 queries:
    [ ] No loops issuing individual queries
    [ ] Eager loading / joins used for related data
    [ ] Batch operations for bulk inserts/updates
[ ] Query optimization:
    [ ] Queries use appropriate indexes
    [ ] No SELECT * (only needed columns)
    [ ] EXPLAIN plan reviewed for complex queries
    [ ] Pagination for large result sets
    [ ] No full table scans on large tables
[ ] Connection management:
    [ ] Connection pooling configured
    [ ] Connections properly released
    [ ] No connection leaks in error paths
```

### Phase 2 — Memory and Resource Management

```
MEMORY REVIEW
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Memory leaks:
    [ ] Event listeners removed on cleanup
    [ ] Subscriptions unsubscribed
    [ ] Large objects released after use
    [ ] Circular references avoided
[ ] Resource management:
    [ ] File handles closed properly
    [ ] Streams consumed and closed
    [ ] Buffers bounded in size
    [ ] Temporary files cleaned up
[ ] Data structures:
    [ ] Appropriate data structure chosen (map vs list vs set)
    [ ] Collections pre-sized when size is known
    [ ] No unbounded collection growth
```

### Phase 3 — Algorithmic Complexity

```
COMPLEXITY REVIEW
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Time complexity:
    [ ] No O(n^2) or worse in hot paths
    [ ] Nested loops reviewed for optimization
    [ ] String concatenation in loops uses builder/buffer
[ ] Space complexity:
    [ ] No unnecessary data copies
    [ ] Streaming used for large data processing
    [ ] Lazy evaluation where appropriate
[ ] Caching:
    [ ] Expensive computations cached
    [ ] Cache invalidation strategy defined
    [ ] Cache TTL appropriate for data freshness
    [ ] Cache size bounded
```

### Phase 4 — Concurrency and I/O

```
CONCURRENCY REVIEW
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Async operations:
    [ ] I/O operations are non-blocking
    [ ] Async/await used correctly (no fire-and-forget)
    [ ] Parallel execution for independent operations
    [ ] Concurrency limits for external calls
[ ] Thread safety:
    [ ] Shared state properly synchronized
    [ ] No race conditions
    [ ] Lock granularity appropriate
[ ] Network calls:
    [ ] Timeouts configured for all external calls
    [ ] Retry logic with exponential backoff
    [ ] Circuit breakers for downstream dependencies
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

Produce a performance review report with:
1. **Performance risk summary** (high / medium / low impact findings)
2. **Estimated performance impact** per finding
3. **Benchmark recommendations** where applicable
4. **Specific optimization suggestions** with code examples
5. **Load testing recommendations** for validation
