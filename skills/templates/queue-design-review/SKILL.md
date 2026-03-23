---
name: queue-design-review
enabled: true
description: |
  Use when performing queue design review — reviews the design of message queue
  and event streaming architectures, covering queue topology, consumer design,
  ordering guarantees, dead letter handling, and capacity planning. This
  template helps teams design reliable asynchronous processing systems and avoid
  common messaging pitfalls.
required_connections:
  - prefix: messaging
    label: "Messaging Platform"
  - prefix: monitoring
    label: "Monitoring Platform"
config_fields:
  - key: system_name
    label: "System Name"
    required: true
    placeholder: "e.g., Order Processing Pipeline"
  - key: queue_technology
    label: "Queue Technology"
    required: true
    placeholder: "e.g., Kafka, SQS, RabbitMQ, Pub/Sub"
features:
  - QUEUE_DESIGN
  - MESSAGING
  - ARCHITECTURE
---

# Queue Design Review

## Phase 1: Requirements Assessment

Define messaging requirements.

- [ ] Message throughput (messages/second): ___
- [ ] Message size (average/max): ___
- [ ] Ordering requirement: None / Partition / Global
- [ ] Delivery guarantee: At-most-once / At-least-once / Exactly-once
- [ ] Latency requirement (end-to-end): ___
- [ ] Retention period: ___
- [ ] Replay capability required: Y/N

## Phase 2: Topology Review

Document the queue/topic architecture.

| Queue/Topic | Producers | Consumers | Partitions | Consumer Groups | DLQ |
|------------|-----------|-----------|------------|-----------------|-----|
|            |           |           |            |                 | Y/N |

**Message Schema:**

| Queue/Topic | Message Type | Schema Version | Schema Registry | Backward Compatible |
|------------|-------------|----------------|-----------------|-------------------|
|            |             |                | Y/N             | Y/N               |

## Phase 3: Producer Design Review

- [ ] Idempotent publishing configured
- [ ] Retry logic with backoff for publish failures
- [ ] Message serialization format defined (JSON, Avro, Protobuf)
- [ ] Partition key strategy defined (if applicable)
- [ ] Message size validation before publish
- [ ] Correlation ID / trace ID included in messages
- [ ] Publish confirmation / acknowledgment handling

## Phase 4: Consumer Design Review

- [ ] Idempotent message processing (safe to reprocess)
- [ ] Graceful shutdown (finish in-flight messages)
- [ ] Concurrency model (single-threaded, thread pool, event loop)
- [ ] Error handling strategy:
  - [ ] Transient errors: retry with backoff
  - [ ] Permanent errors: route to DLQ
  - [ ] Poison messages: detect and isolate
- [ ] Consumer lag monitoring
- [ ] Offset/acknowledgment management (auto vs manual commit)
- [ ] Maximum processing time per message: ___
- [ ] Visibility timeout / ack deadline configured appropriately

**Dead Letter Queue Design:**

- [ ] DLQ exists for each queue/topic
- [ ] DLQ monitoring and alerting configured
- [ ] DLQ processing / replay procedure documented
- [ ] DLQ retention policy defined
- [ ] Maximum retry count before DLQ: ___

## Phase 5: Reliability and Scaling

**Failure Scenarios:**

| Scenario | Expected Behavior | Tested |
|----------|-------------------|--------|
| Consumer crashes mid-processing | Message redelivered after timeout | Y/N |
| Producer cannot reach broker | Retry with backoff, alert if persistent | Y/N |
| Broker node failure | Failover to replica | Y/N |
| Consumer lag exceeds threshold | Auto-scale consumers or alert | Y/N |
| DLQ fills up | Alert, do not block main queue | Y/N |

**Scaling:**

- [ ] Consumer auto-scaling configured: Y/N
- [ ] Max consumers bounded by partition count (Kafka) or concurrency limit
- [ ] Backpressure mechanism defined
- [ ] Capacity planning for peak load: ___ x normal throughput

## Counter-Rationalizations

| Shortcut | Counter | Why |
|----------|---------|-----|
| "We can skip some steps for this case" | Adapt the workflow steps, don't skip them | Skipped steps are where incidents and oversights originate |
| "The user seems to already know what to do" | Complete all workflow phases with the user | The workflow catches blind spots that experience alone misses |
| "This is a minor case, full process is overkill" | Scale the process down, don't turn it off | Minor cases become major when unstructured; the process scales, not disappears |
| "I'll fill in the details later" | Complete each section before moving on | Deferred details are forgotten; real-time capture is more accurate |
| "The template output isn't necessary" | Always produce the structured output format | Structured output enables comparison, audit trails, and handoff to other teams |

## Output Format

### Summary

- **System:** ___
- **Technology:** ___
- **Queues/topics:** ___
- **Delivery guarantee:** ___
- **Peak throughput:** ___
- **Issues found:** ___

### Action Items

- [ ] Fix consumer idempotency gaps
- [ ] Configure DLQ for queues missing one
- [ ] Set up consumer lag monitoring and alerting
- [ ] Document message schemas in schema registry
- [ ] Test all failure scenarios
- [ ] Establish capacity planning baseline
