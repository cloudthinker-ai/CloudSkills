# Kafka CLI Tools Reference

Complete reference for Apache Kafka CLI tools. Source: [Confluent Kafka Tools Documentation](https://docs.confluent.io/kafka/operations-tools/kafka-tools.html)

---

## Cluster Management

### kafka-broker-api-versions.sh

Retrieve broker version information and supported API versions.

```bash
# List all API versions supported by broker
kafka-broker-api-versions.sh --bootstrap-server $KAFKA_BOOTSTRAP

# With authentication
kafka-broker-api-versions.sh --bootstrap-server $KAFKA_BOOTSTRAP \
  --command-config client.properties
```

### kafka-cluster.sh

Retrieve cluster ID or manage broker registration.

```bash
# Get cluster ID
kafka-cluster.sh cluster-id --bootstrap-server $KAFKA_BOOTSTRAP

# List endpoints (KRaft)
kafka-cluster.sh list-endpoints --bootstrap-controller $KAFKA_CONTROLLER

# Unregister a broker (KRaft)
kafka-cluster.sh unregister --bootstrap-server $KAFKA_BOOTSTRAP --id 1
```

### kafka-metadata-quorum.sh (KRaft only)

Query metadata quorum status.

```bash
# Describe quorum status
kafka-metadata-quorum.sh --bootstrap-server $KAFKA_BOOTSTRAP describe --status

# Show replication status of all voters and observers
kafka-metadata-quorum.sh --bootstrap-server $KAFKA_BOOTSTRAP describe --replication
```

### kafka-features.sh

Manage feature flags at runtime.

```bash
# List current feature flags
kafka-features.sh describe --bootstrap-server $KAFKA_BOOTSTRAP

# Upgrade a feature
kafka-features.sh upgrade --bootstrap-server $KAFKA_BOOTSTRAP \
  --feature metadata.version=20

# Downgrade a feature
kafka-features.sh downgrade --bootstrap-server $KAFKA_BOOTSTRAP \
  --feature metadata.version=18
```

### kafka-storage.sh (KRaft only)

Manage storage directories for KRaft mode.

```bash
# Generate cluster UUID
kafka-storage.sh random-uuid

# Format storage directories
kafka-storage.sh format --config server.properties \
  --cluster-id $CLUSTER_UUID --release-version 3.8

# Show storage info
kafka-storage.sh info --config server.properties
```

---

## Topic & Partition Management

### kafka-topics.sh

Create, delete, describe, or modify topics.

```bash
# List all topics
kafka-topics.sh --bootstrap-server $KAFKA_BOOTSTRAP --list

# Describe a specific topic
kafka-topics.sh --bootstrap-server $KAFKA_BOOTSTRAP --describe --topic my_topic

# Describe all topics with under-replicated partitions
kafka-topics.sh --bootstrap-server $KAFKA_BOOTSTRAP --describe \
  --under-replicated-partitions

# Describe unavailable partitions
kafka-topics.sh --bootstrap-server $KAFKA_BOOTSTRAP --describe \
  --unavailable-partitions

# Create a topic (WRITE operation)
kafka-topics.sh --bootstrap-server $KAFKA_BOOTSTRAP --create \
  --topic my_topic --partitions 12 --replication-factor 3

# Alter partition count (WRITE - cannot reduce)
kafka-topics.sh --bootstrap-server $KAFKA_BOOTSTRAP --alter \
  --topic my_topic --partitions 24

# Delete a topic (DESTRUCTIVE)
kafka-topics.sh --bootstrap-server $KAFKA_BOOTSTRAP --delete --topic my_topic
```

### kafka-get-offsets.sh

Retrieve topic-partition offsets.

```bash
# Get latest offsets for all partitions
kafka-get-offsets.sh --bootstrap-server $KAFKA_BOOTSTRAP --topic my_topic

# Get earliest offsets
kafka-get-offsets.sh --bootstrap-server $KAFKA_BOOTSTRAP --topic my_topic \
  --time earliest

# Get offsets at specific timestamp (milliseconds)
kafka-get-offsets.sh --bootstrap-server $KAFKA_BOOTSTRAP --topic my_topic \
  --time 1709222400000

# Get offsets for specific partitions
kafka-get-offsets.sh --bootstrap-server $KAFKA_BOOTSTRAP \
  --topic-partitions my_topic:0,1,2
```

### kafka-log-dirs.sh

List replicas and disk usage per log directory.

```bash
# Describe all log dirs on all brokers
kafka-log-dirs.sh --bootstrap-server $KAFKA_BOOTSTRAP --describe

# Filter by specific brokers
kafka-log-dirs.sh --bootstrap-server $KAFKA_BOOTSTRAP --describe \
  --broker-list 0,1,2

# Filter by specific topics
kafka-log-dirs.sh --bootstrap-server $KAFKA_BOOTSTRAP --describe \
  --topic-list my_topic,other_topic
```

### kafka-leader-election.sh

Trigger leader election for partitions.

```bash
# Preferred leader election for all topic-partitions
kafka-leader-election.sh --bootstrap-server $KAFKA_BOOTSTRAP \
  --election-type PREFERRED --all-topic-partitions

# Unclean election for specific partition (RISK: data loss)
kafka-leader-election.sh --bootstrap-server $KAFKA_BOOTSTRAP \
  --election-type UNCLEAN --topic my_topic --partition 0
```

### kafka-reassign-partitions.sh

Move partitions between brokers.

```bash
# Generate reassignment plan
kafka-reassign-partitions.sh --bootstrap-server $KAFKA_BOOTSTRAP \
  --generate --topics-to-move-json-file topics.json \
  --broker-list 0,1,2

# Execute reassignment (WRITE operation, use --throttle)
kafka-reassign-partitions.sh --bootstrap-server $KAFKA_BOOTSTRAP \
  --execute --reassignment-json-file reassignment.json \
  --throttle 50000000

# Verify reassignment progress
kafka-reassign-partitions.sh --bootstrap-server $KAFKA_BOOTSTRAP \
  --verify --reassignment-json-file reassignment.json

# List active reassignments
kafka-reassign-partitions.sh --bootstrap-server $KAFKA_BOOTSTRAP --list

# Cancel reassignment
kafka-reassign-partitions.sh --bootstrap-server $KAFKA_BOOTSTRAP \
  --cancel --reassignment-json-file reassignment.json
```

### kafka-delete-records.sh

Delete records up to specified offset (DESTRUCTIVE).

```bash
# Delete records using JSON offset file
kafka-delete-records.sh --bootstrap-server $KAFKA_BOOTSTRAP \
  --offset-json-file offsets.json

# offsets.json format:
# {"partitions": [{"topic": "my_topic", "partition": 0, "offset": 1000}]}
```

---

## Configuration Management

### kafka-configs.sh

Describe and alter configuration for topics, brokers, clients, users, and IPs.

```bash
# Describe topic configuration
kafka-configs.sh --bootstrap-server $KAFKA_BOOTSTRAP \
  --entity-type topics --entity-name my_topic --describe

# Describe broker defaults
kafka-configs.sh --bootstrap-server $KAFKA_BOOTSTRAP \
  --entity-type brokers --entity-default --describe

# Describe specific broker configuration
kafka-configs.sh --bootstrap-server $KAFKA_BOOTSTRAP \
  --entity-type brokers --entity-name 0 --describe

# Describe client quotas
kafka-configs.sh --bootstrap-server $KAFKA_BOOTSTRAP \
  --entity-type clients --entity-default --describe

# Describe user quotas
kafka-configs.sh --bootstrap-server $KAFKA_BOOTSTRAP \
  --entity-type users --entity-name my_user --describe

# Alter topic config (WRITE operation)
kafka-configs.sh --bootstrap-server $KAFKA_BOOTSTRAP \
  --entity-type topics --entity-name my_topic \
  --alter --add-config retention.ms=604800000

# Delete topic config override (WRITE operation)
kafka-configs.sh --bootstrap-server $KAFKA_BOOTSTRAP \
  --entity-type topics --entity-name my_topic \
  --alter --delete-config retention.ms
```

---

## Consumer Group Management

### kafka-consumer-groups.sh

List, describe, and manage consumer groups.

```bash
# List all consumer groups
kafka-consumer-groups.sh --bootstrap-server $KAFKA_BOOTSTRAP --list

# Describe group (members, offsets, lag)
kafka-consumer-groups.sh --bootstrap-server $KAFKA_BOOTSTRAP \
  --describe --group my_group

# Describe group with verbose member info
kafka-consumer-groups.sh --bootstrap-server $KAFKA_BOOTSTRAP \
  --describe --group my_group --members --verbose

# Describe group state
kafka-consumer-groups.sh --bootstrap-server $KAFKA_BOOTSTRAP \
  --describe --group my_group --state

# List all groups with state
kafka-consumer-groups.sh --bootstrap-server $KAFKA_BOOTSTRAP \
  --list --state

# Reset offsets to earliest (dry-run first!)
kafka-consumer-groups.sh --bootstrap-server $KAFKA_BOOTSTRAP \
  --group my_group --topic my_topic --reset-offsets --to-earliest --dry-run

# Reset offsets to latest (WRITE operation)
kafka-consumer-groups.sh --bootstrap-server $KAFKA_BOOTSTRAP \
  --group my_group --topic my_topic --reset-offsets --to-latest --execute

# Reset offsets to specific timestamp
kafka-consumer-groups.sh --bootstrap-server $KAFKA_BOOTSTRAP \
  --group my_group --topic my_topic --reset-offsets \
  --to-datetime 2026-03-01T00:00:00.000 --dry-run

# Reset offsets by shift (negative = backwards)
kafka-consumer-groups.sh --bootstrap-server $KAFKA_BOOTSTRAP \
  --group my_group --topic my_topic --reset-offsets \
  --shift-by -100 --dry-run

# Delete a consumer group (DESTRUCTIVE — group must be inactive)
kafka-consumer-groups.sh --bootstrap-server $KAFKA_BOOTSTRAP \
  --delete --group my_group
```

---

## Transaction Management

### kafka-transactions.sh

List and manage transactions.

```bash
# List active transactions
kafka-transactions.sh --bootstrap-server $KAFKA_BOOTSTRAP list

# Describe a specific transaction
kafka-transactions.sh --bootstrap-server $KAFKA_BOOTSTRAP \
  describe --transactional-id my_txn_id

# Describe producers on a topic-partition
kafka-transactions.sh --bootstrap-server $KAFKA_BOOTSTRAP \
  describe-producers --topic my_topic --partition 0

# Find hanging transactions (transactions open > 30 min)
kafka-transactions.sh --bootstrap-server $KAFKA_BOOTSTRAP find-hanging

# Abort a hanging transaction (WRITE operation)
kafka-transactions.sh --bootstrap-server $KAFKA_BOOTSTRAP \
  abort --topic my_topic --partition 0 --start-offset 1000
```

---

## Client Metrics

### kafka-client-metrics.sh

Manage client metrics subscriptions.

```bash
# List all metrics subscriptions
kafka-client-metrics.sh --bootstrap-server $KAFKA_BOOTSTRAP --list

# Describe a metrics subscription
kafka-client-metrics.sh --bootstrap-server $KAFKA_BOOTSTRAP \
  --describe --name my_subscription

# Create/alter a subscription (WRITE)
kafka-client-metrics.sh --bootstrap-server $KAFKA_BOOTSTRAP \
  --alter --name my_subscription \
  --metrics org.apache.kafka.producer \
  --interval 60000
```

---

## Replication & Verification

### kafka-replica-verification.sh

Verify replica data consistency.

```bash
# Verify replicas for all topics matching pattern
kafka-replica-verification.sh --broker-list $KAFKA_BOOTSTRAP \
  --topics-include "my_topic.*" --time -1 --fetch-size 1048576
```

### connect-mirror-maker.sh (MM2)

Cross-cluster replication using Kafka Connect framework.

```bash
# Start MirrorMaker 2 with properties file
connect-mirror-maker.sh mm2.properties

# Start with specific cluster pair
connect-mirror-maker.sh mm2.properties --clusters source,target
```

---

## Console Tools (Testing/Debugging)

### kafka-console-consumer.sh

Read messages from a topic (use for debugging only in production).

```bash
# Consume from beginning
kafka-console-consumer.sh --bootstrap-server $KAFKA_BOOTSTRAP \
  --topic my_topic --from-beginning --max-messages 10

# Consume with key printing
kafka-console-consumer.sh --bootstrap-server $KAFKA_BOOTSTRAP \
  --topic my_topic --property print.key=true --property print.timestamp=true

# Consume with specific consumer group
kafka-console-consumer.sh --bootstrap-server $KAFKA_BOOTSTRAP \
  --topic my_topic --group debug_consumer

# Consume specific partition
kafka-console-consumer.sh --bootstrap-server $KAFKA_BOOTSTRAP \
  --topic my_topic --partition 0 --offset 1000 --max-messages 5
```

### kafka-console-producer.sh

Publish messages to a topic (WRITE operation).

```bash
# Produce with key separator
kafka-console-producer.sh --bootstrap-server $KAFKA_BOOTSTRAP \
  --topic my_topic --property parse.key=true --property key.separator=:

# Produce with acks=all
kafka-console-producer.sh --bootstrap-server $KAFKA_BOOTSTRAP \
  --topic my_topic --producer-property acks=all
```

---

## Important Configuration Properties

### Topic-Level Configs

| Property | Default | Description |
|----------|---------|-------------|
| `retention.ms` | 604800000 (7d) | How long to retain messages |
| `retention.bytes` | -1 (unlimited) | Max bytes retained per partition |
| `cleanup.policy` | delete | `delete` or `compact` or `delete,compact` |
| `segment.bytes` | 1073741824 (1GB) | Size of a single log segment |
| `min.insync.replicas` | 1 | Min ISR count for acks=all writes |
| `max.message.bytes` | 1048588 (~1MB) | Max message size |
| `compression.type` | producer | `none`, `gzip`, `snappy`, `lz4`, `zstd` |
| `message.timestamp.type` | CreateTime | `CreateTime` or `LogAppendTime` |

### Broker-Level Configs

| Property | Default | Description |
|----------|---------|-------------|
| `num.partitions` | 1 | Default partitions for new topics |
| `default.replication.factor` | 1 | Default RF for new topics |
| `log.retention.hours` | 168 (7d) | Default retention hours |
| `log.segment.bytes` | 1073741824 | Default segment size |
| `auto.create.topics.enable` | true | Auto-create topics on produce/consume |
| `unclean.leader.election.enable` | false | Allow non-ISR leader election |
| `min.insync.replicas` | 1 | Default min ISR |
