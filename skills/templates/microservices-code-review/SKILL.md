---
name: microservices-code-review
enabled: true
description: |
  Distributed systems code review template covering service resilience, API contract compliance, observability instrumentation, data consistency patterns, and inter-service communication. Provides a systematic review framework for microservices changes including circuit breakers, retries, idempotency, and distributed tracing.
required_connections:
  - prefix: github
    label: "GitHub"
config_fields:
  - key: repository
    label: "Repository"
    required: true
    placeholder: "e.g., org/order-service"
  - key: pr_number
    label: "PR Number"
    required: true
    placeholder: "e.g., 1234"
  - key: service_name
    label: "Service Name"
    required: true
    placeholder: "e.g., order-service"
features:
  - CODE_REVIEW
---

# Microservices Code Review Skill

Review PR **#{{ pr_number }}** in **{{ repository }}** for service **{{ service_name }}**.

## Workflow

### Phase 1 — Resilience Patterns

```
RESILIENCE CHECK
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Circuit breakers:
    [ ] External service calls wrapped with circuit breaker
    [ ] Fallback behavior defined
    [ ] Circuit breaker thresholds configured
    [ ] Half-open state tested
[ ] Retries:
    [ ] Retry logic with exponential backoff
    [ ] Maximum retry count bounded
    [ ] Jitter added to prevent thundering herd
    [ ] Non-idempotent operations not retried
[ ] Timeouts:
    [ ] All external calls have timeouts
    [ ] Timeout values appropriate (not too long)
    [ ] Cascading timeout budgets considered
[ ] Bulkheads:
    [ ] Thread pools / connection pools isolated per dependency
    [ ] Resource limits prevent cascade failures
```

### Phase 2 — API Contracts

```
CONTRACT COMPLIANCE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Contract changes:
    [ ] API schema changes backward-compatible
    [ ] Consumer-driven contract tests pass
    [ ] Schema registry updated (Avro, Protobuf)
    [ ] Event schema versioned
[ ] Communication patterns:
    [ ] Sync vs async chosen appropriately
    [ ] Message format documented
    [ ] Dead letter queue configured for failed messages
    [ ] Idempotency keys for message processing
```

### Phase 3 — Observability

```
OBSERVABILITY CHECK
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Distributed tracing:
    [ ] Trace context propagated across service calls
    [ ] Spans created for significant operations
    [ ] Trace IDs in log entries
[ ] Metrics:
    [ ] RED metrics (Rate, Errors, Duration) instrumented
    [ ] Custom business metrics where relevant
    [ ] SLI metrics aligned with SLOs
[ ] Logging:
    [ ] Structured logging format (JSON)
    [ ] Correlation IDs in all log entries
    [ ] Appropriate log levels (no INFO spam)
    [ ] Sensitive data not logged
[ ] Health checks:
    [ ] Liveness probe endpoint
    [ ] Readiness probe endpoint
    [ ] Dependency health reported
```

### Phase 4 — Data Consistency

```
DATA PATTERNS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Consistency:
    [ ] Saga pattern used for distributed transactions
    [ ] Compensating transactions defined for rollback
    [ ] Eventual consistency acceptable for use case
    [ ] Idempotent operations for at-least-once delivery
[ ] Data ownership:
    [ ] Service owns its data (no shared database)
    [ ] Data access via APIs (not direct DB queries)
    [ ] Event sourcing / CQRS used correctly (if applicable)
```

## Output Format

Produce a microservices review report with:
1. **Resilience assessment** (fault tolerance score)
2. **Contract compatibility** (breaking changes detected)
3. **Observability coverage** (tracing, metrics, logging gaps)
4. **Data consistency** risks
5. **Deployment safety** recommendations
