---
name: event-driven-architecture-review
enabled: true
description: |
  Template for reviewing event-driven architecture designs and implementations. Covers event schema validation, producer/consumer mapping, ordering guarantees, idempotency patterns, dead letter handling, schema evolution strategy, and observability to ensure reliable event-driven systems.
required_connections:
  - prefix: aws
    label: "AWS (or cloud provider)"
config_fields:
  - key: system_name
    label: "System Name"
    required: true
    placeholder: "e.g., order-processing-pipeline"
  - key: event_platform
    label: "Event Platform"
    required: true
    placeholder: "e.g., Kafka, EventBridge, SNS/SQS, RabbitMQ"
features:
  - ENGINEERING
  - ARCHITECTURE
---

# Event-Driven Architecture Review Skill

Review event-driven architecture for **{{ system_name }}** on **{{ event_platform }}**.

## Workflow

### Phase 1 — Event Inventory

```
EVENT CATALOG
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Total event types: ___
[ ] Event map:
    Event Name          | Producer     | Consumer(s)  | Volume/day
    ____________________|______________|______________|___________
                        |              |              |
                        |              |              |
                        |              |              |

[ ] Event schema registry: [ ] YES  [ ] NO
[ ] Schema format: [ ] Avro  [ ] JSON Schema  [ ] Protobuf  [ ] None
[ ] Event naming convention: ___
```

### Phase 2 — Event Design Review

```
EVENT SCHEMA QUALITY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Events contain:
    [ ] Unique event ID
    [ ] Event type/name
    [ ] Timestamp (ISO 8601)
    [ ] Source/producer identifier
    [ ] Correlation/trace ID
    [ ] Schema version
[ ] Events are self-contained (no need to fetch additional data)
[ ] Events represent facts (past tense: OrderPlaced, not PlaceOrder)
[ ] Event payload size within limits (avg: ___KB, max: ___KB)
[ ] No PII in events (or encrypted if required)

SCHEMA EVOLUTION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Backward compatibility enforced
[ ] Forward compatibility considered
[ ] Schema versioning strategy:
    [ ] Full compatibility
    [ ] Backward only
    [ ] None (breaking changes allowed)
[ ] Schema validation on publish: [ ] YES  [ ] NO
```

### Phase 3 — Reliability Patterns

```
RELIABILITY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Delivery guarantees:
[ ] At-least-once delivery implemented
[ ] Consumer idempotency:
    - Idempotency key strategy: ___
    - Deduplication window: ___
[ ] Ordering guarantees:
    - Partition/ordering key: ___
    - Per-key ordering: [ ] GUARANTEED  [ ] BEST EFFORT
[ ] Dead letter queue (DLQ) configured:
    - DLQ destination: ___
    - DLQ alert threshold: ___
    - DLQ reprocessing procedure: [ ] DOCUMENTED

ERROR HANDLING MATRIX
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Error Type           | Strategy        | Max Retries | Backoff
Transient (network)  | Retry           | ___         | ___
Validation error     | DLQ             | 0           | N/A
Poison message       | DLQ + alert     | ___         | ___
Consumer crash       | Rebalance       | N/A         | N/A
```

### Phase 4 — Performance and Scalability

```
PERFORMANCE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Throughput:
    - Current: ___ events/sec
    - Peak: ___ events/sec
    - Target capacity: ___ events/sec
[ ] Latency (end-to-end, publish to consume):
    - P50: ___ms
    - P95: ___ms
    - P99: ___ms
[ ] Consumer lag:
    - Current lag: ___ events
    - Lag alert threshold: ___ events
[ ] Partitions/shards: ___
[ ] Consumer group instances: ___
[ ] Backpressure handling: ___
```

### Phase 5 — Observability

```
OBSERVABILITY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Distributed tracing across events:
    - Trace ID propagation: [ ] YES
    - End-to-end trace visualization: [ ] YES
[ ] Metrics collected:
    [ ] Publish rate per event type
    [ ] Consumer processing rate
    [ ] Consumer lag per partition
    [ ] Error rate per consumer
    [ ] DLQ depth
[ ] Alerting configured:
    [ ] Consumer lag exceeds threshold
    [ ] DLQ messages accumulating
    [ ] Publisher failures
    [ ] Consumer group rebalances
[ ] Event flow visualization/documentation: [ ] YES  [ ] NO
```

## Output Format

Produce an event-driven architecture review report with:
1. **Architecture overview** (event catalog, producers, consumers)
2. **Design quality** (schema quality, naming, evolution strategy)
3. **Reliability assessment** (delivery guarantees, error handling, DLQ)
4. **Performance profile** (throughput, latency, scalability headroom)
5. **Recommendations** (improvements ranked by impact and effort)
