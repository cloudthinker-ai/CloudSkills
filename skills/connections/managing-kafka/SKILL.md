---
name: managing-kafka
description: |
  Apache Kafka topic management, consumer group monitoring, partition analysis, broker health, and lag monitoring. You MUST read this skill before executing any Kafka operations — it contains mandatory two-phase execution, anti-hallucination rules, and safety constraints.
connection_type: kafka
preload: false
---

# Kafka Management Skill

Analyze and manage Kafka clusters with safe, read-only operations.

## MANDATORY: Two-Phase Execution

**You MUST follow this two-phase pattern. Skipping Phase 1 causes hallucinated topic/group names.**

### Phase 1: Discovery (ALWAYS run first)

```bash
#!/bin/bash

# 1. List brokers
kafka-broker-api-versions.sh --bootstrap-server "$KAFKA_BOOTSTRAP" 2>/dev/null | head -5

# 2. List topics
kafka-topics.sh --bootstrap-server "$KAFKA_BOOTSTRAP" --list

# 3. Describe a topic (never assume partition count)
kafka-topics.sh --bootstrap-server "$KAFKA_BOOTSTRAP" --describe --topic my_topic

# 4. List consumer groups
kafka-consumer-groups.sh --bootstrap-server "$KAFKA_BOOTSTRAP" --list

# 5. Describe consumer group
kafka-consumer-groups.sh --bootstrap-server "$KAFKA_BOOTSTRAP" --describe --group my_group
```

**Phase 1 outputs:**
- Broker list and IDs
- Topics with partition counts and replication factors
- Consumer groups with lag information

### Phase 2: Analysis (only after Phase 1)

Only reference topics, partitions, and consumer groups confirmed in Phase 1.

## Shell Script Patterns

### Helper Function

```bash
#!/bin/bash

# Core Kafka CLI helper — always use this
kafka_cmd() {
    local tool="$1"; shift
    "kafka-${tool}.sh" --bootstrap-server "${KAFKA_BOOTSTRAP:-localhost:9092}" "$@"
}

# Kafka topic describe
kafka_topic() {
    kafka_cmd topics --describe --topic "$1"
}

# Kafka consumer group describe
kafka_group() {
    kafka_cmd consumer-groups --describe --group "$1"
}
```

## Anti-Hallucination Rules

- **NEVER reference a topic** without confirming via `kafka-topics.sh --list`
- **NEVER reference a consumer group** without confirming via `kafka-consumer-groups.sh --list`
- **NEVER assume partition count** — always describe the topic first
- **NEVER guess broker IDs** — always check cluster metadata
- **NEVER assume replication factor** — always verify from topic description

## Safety Rules

- **READ-ONLY ONLY**: Use only --list, --describe, kafka-consumer-groups.sh --describe, kafka-log-dirs.sh --describe
- **FORBIDDEN**: --create, --delete, --alter, kafka-console-producer, --reset-offsets --execute without explicit user request
- **NEVER consume from production topics** without explicit user request — use --describe only
- **Use `--dry-run`** with reset-offsets before executing

## Common Operations

### Broker Health Overview

```bash
#!/bin/bash
echo "=== Cluster Metadata ==="
kafka_cmd metadata --snapshot /dev/null 2>/dev/null || \
kafka_cmd topics --describe | head -1

echo ""
echo "=== Topics Overview ==="
kafka_cmd topics --list | while read TOPIC; do
    INFO=$(kafka_cmd topics --describe --topic "$TOPIC" 2>/dev/null | head -1)
    echo "$INFO"
done

echo ""
echo "=== Log Dirs (disk usage per broker) ==="
kafka-log-dirs.sh --bootstrap-server "$KAFKA_BOOTSTRAP" --describe | jq -r '.brokers[] | "\(.broker)\t\(.logDirs[].partitions | length) partitions\t\(.logDirs[].partitions | map(.size) | add // 0 | . / 1024 / 1024 | floor)MB"' 2>/dev/null
```

### Consumer Group Lag Monitoring

```bash
#!/bin/bash
echo "=== All Consumer Groups ==="
kafka_cmd consumer-groups --list

echo ""
echo "=== Consumer Group Details ==="
for GROUP in $(kafka_cmd consumer-groups --list); do
    echo "--- $GROUP ---"
    kafka_cmd consumer-groups --describe --group "$GROUP" 2>/dev/null | tail -n +2
done

echo ""
echo "=== Groups with Lag ==="
for GROUP in $(kafka_cmd consumer-groups --list); do
    LAG=$(kafka_cmd consumer-groups --describe --group "$GROUP" 2>/dev/null | awk 'NR>1 {sum += $6} END {print sum+0}')
    [ "$LAG" -gt 0 ] 2>/dev/null && echo "$GROUP: $LAG total lag"
done
```

### Topic Partition Analysis

```bash
#!/bin/bash
TOPIC="${1:-my_topic}"

echo "=== Topic Description ==="
kafka_topic "$TOPIC"

echo ""
echo "=== Partition Offsets ==="
kafka-get-offsets.sh --bootstrap-server "$KAFKA_BOOTSTRAP" --topic "$TOPIC" 2>/dev/null || \
kafka_cmd consumer-groups --describe --group __consumer_offsets 2>/dev/null

echo ""
echo "=== Under-replicated Partitions ==="
kafka_cmd topics --describe --under-replicated-partitions

echo ""
echo "=== Unavailable Partitions ==="
kafka_cmd topics --describe --unavailable-partitions
```

### Topic Configuration Analysis

```bash
#!/bin/bash
TOPIC="${1:-my_topic}"

echo "=== Topic Config ==="
kafka-configs.sh --bootstrap-server "$KAFKA_BOOTSTRAP" --entity-type topics --entity-name "$TOPIC" --describe

echo ""
echo "=== Broker Config (dynamic) ==="
kafka-configs.sh --bootstrap-server "$KAFKA_BOOTSTRAP" --entity-type brokers --entity-default --describe

echo ""
echo "=== Retention Settings ==="
kafka-configs.sh --bootstrap-server "$KAFKA_BOOTSTRAP" --entity-type topics --entity-name "$TOPIC" --describe | grep -E "retention|cleanup|segment"
```

## Common Pitfalls

- **Consumer lag vs latency**: High offset lag may be acceptable if consumers process in batches
- **Under-replicated partitions**: URPs indicate broker issues — investigate immediately
- **Partition count changes**: Increasing partitions breaks key-based ordering — plan carefully
- **Replication factor**: RF=1 means no fault tolerance — production should be RF >= 3
- **Log compaction**: Compacted topics retain latest key — do not confuse with retention-based deletion
- **Consumer group rebalancing**: Frequent rebalances cause lag spikes — check for unstable consumers
- **ISR shrink**: In-sync replica set shrinking means followers cannot keep up
