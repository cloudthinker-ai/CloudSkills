---
name: managing-aws-kinesis
description: |
  AWS Kinesis stream management, shard analysis, consumer lag monitoring, enhanced fan-out configuration, and throughput analysis. You MUST read this skill before executing any Kinesis operations — it contains mandatory two-phase execution, anti-hallucination rules, and safety constraints.
connection_type: aws
preload: false
---

# AWS Kinesis Management Skill

Analyze and manage Kinesis streams with safe, read-only operations.

## MANDATORY: Two-Phase Execution

**You MUST follow this two-phase pattern. Skipping Phase 1 causes hallucinated stream/consumer names.**

### Phase 1: Discovery (ALWAYS run first)

```bash
#!/bin/bash

# 1. List streams
aws kinesis list-streams --output json | jq -r '.StreamNames[]'

# 2. Describe stream
aws kinesis describe-stream-summary --stream-name "$STREAM_NAME" --output json

# 3. List shards
aws kinesis list-shards --stream-name "$STREAM_NAME" --output json | jq '.Shards[] | {ShardId, HashKeyRange, SequenceNumberRange}'

# 4. List stream consumers (enhanced fan-out)
aws kinesis list-stream-consumers --stream-arn "$STREAM_ARN" --output json

# 5. Describe stream consumer
aws kinesis describe-stream-consumer --stream-arn "$STREAM_ARN" --consumer-name "$CONSUMER_NAME" --output json 2>/dev/null
```

**Phase 1 outputs:**
- Stream names and ARNs
- Shard count and configuration
- Registered consumers (enhanced fan-out)

### Phase 2: Analysis (only after Phase 1)

Only reference stream names, shard IDs, and consumer names confirmed in Phase 1.

## Shell Script Patterns

### Helper Function

```bash
#!/bin/bash

# Core Kinesis helper — always use this
kinesis_cmd() {
    aws kinesis "$@" --output json
}

# CloudWatch metric for Kinesis
kinesis_metric() {
    local stream="$1" metric="$2" stat="${3:-Sum}" period="${4:-300}"
    aws cloudwatch get-metric-statistics \
        --namespace AWS/Kinesis \
        --metric-name "$metric" \
        --dimensions Name=StreamName,Value="$stream" \
        --start-time "$(date -u -v-1H +%Y-%m-%dT%H:%M:%S 2>/dev/null || date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S)" \
        --end-time "$(date -u +%Y-%m-%dT%H:%M:%S)" \
        --period "$period" \
        --statistics "$stat" \
        --output json
}
```

## Anti-Hallucination Rules

- **NEVER reference a stream** without confirming via `list-streams`
- **NEVER reference shard IDs** without confirming via `list-shards`
- **NEVER assume consumer names** — always list stream consumers
- **NEVER guess shard count** — always describe the stream
- **NEVER assume on-demand vs provisioned** — check stream mode

## Safety Rules

- **READ-ONLY ONLY**: Use only describe-*, list-*, CloudWatch get-metric-statistics
- **FORBIDDEN**: create-stream, delete-stream, put-record, merge-shards, split-shard without explicit user request
- **NEVER get records from production streams** without explicit user request
- **Use CloudWatch metrics** for throughput analysis, not get-records

## Common Operations

### Stream Overview

```bash
#!/bin/bash
echo "=== Kinesis Streams ==="
for STREAM in $(aws kinesis list-streams --output json | jq -r '.StreamNames[]'); do
    SUMMARY=$(kinesis_cmd describe-stream-summary --stream-name "$STREAM" | jq '.StreamDescriptionSummary')
    echo "$STREAM:"
    echo "  Status: $(echo $SUMMARY | jq -r '.StreamStatus')"
    echo "  Shards: $(echo $SUMMARY | jq -r '.OpenShardCount')"
    echo "  Mode: $(echo $SUMMARY | jq -r '.StreamModeDetails.StreamMode')"
    echo "  Consumers: $(echo $SUMMARY | jq -r '.ConsumerCount')"
    echo "  Retention: $(echo $SUMMARY | jq -r '.RetentionPeriodHours')h"
done
```

### Shard Analysis

```bash
#!/bin/bash
STREAM="${1:-my-stream}"

echo "=== Shards ==="
kinesis_cmd list-shards --stream-name "$STREAM" | jq '.Shards[] | {ShardId, ParentShardId: .ParentShardId, HashKeyRange: "\(.HashKeyRange.StartingHashKey[0:10])...\(.HashKeyRange.EndingHashKey[0:10])"}'

echo ""
echo "=== Write Throughput per Shard ==="
kinesis_metric "$STREAM" "IncomingRecords" "Sum" 60 | jq -r '.Datapoints | sort_by(.Timestamp) | .[-5:][] | "\(.Timestamp)\t\(.Sum) records"'

echo ""
echo "=== Read Throughput ==="
kinesis_metric "$STREAM" "GetRecords.Records" "Sum" 60 | jq -r '.Datapoints | sort_by(.Timestamp) | .[-5:][] | "\(.Timestamp)\t\(.Sum) records"'
```

### Consumer Lag Analysis

```bash
#!/bin/bash
STREAM="${1:-my-stream}"

echo "=== Iterator Age (lag) ==="
kinesis_metric "$STREAM" "GetRecords.IteratorAgeMilliseconds" "Maximum" 60 | jq -r '.Datapoints | sort_by(.Timestamp) | .[-5:][] | "\(.Timestamp)\t\(.Maximum)ms"'

echo ""
echo "=== Read Provisioned Throughput Exceeded ==="
kinesis_metric "$STREAM" "ReadProvisionedThroughputExceeded" "Sum" 300 | jq -r '.Datapoints | sort_by(.Timestamp) | .[] | select(.Sum > 0) | "\(.Timestamp)\t\(.Sum)"'

echo ""
echo "=== Write Provisioned Throughput Exceeded ==="
kinesis_metric "$STREAM" "WriteProvisionedThroughputExceeded" "Sum" 300 | jq -r '.Datapoints | sort_by(.Timestamp) | .[] | select(.Sum > 0) | "\(.Timestamp)\t\(.Sum)"'

echo ""
echo "=== Enhanced Fan-out Consumers ==="
STREAM_ARN=$(kinesis_cmd describe-stream-summary --stream-name "$STREAM" | jq -r '.StreamDescriptionSummary.StreamARN')
kinesis_cmd list-stream-consumers --stream-arn "$STREAM_ARN" | jq '.Consumers[] | {ConsumerName, ConsumerStatus, ConsumerCreationTimestamp}'
```

### Throughput Analysis

```bash
#!/bin/bash
STREAM="${1:-my-stream}"

echo "=== Incoming Bytes ==="
kinesis_metric "$STREAM" "IncomingBytes" "Sum" 60 | jq -r '.Datapoints | sort_by(.Timestamp) | .[-5:][] | "\(.Timestamp)\t\(.Sum / 1024 | round)KB"'

echo ""
echo "=== Outgoing Bytes ==="
kinesis_metric "$STREAM" "GetRecords.Bytes" "Sum" 60 | jq -r '.Datapoints | sort_by(.Timestamp) | .[-5:][] | "\(.Timestamp)\t\(.Sum / 1024 | round)KB"'

echo ""
echo "=== Put Latency ==="
kinesis_metric "$STREAM" "PutRecord.Latency" "Average" 60 | jq -r '.Datapoints | sort_by(.Timestamp) | .[-5:][] | "\(.Timestamp)\t\(.Average)ms"'
```

## Common Pitfalls

- **Shard limits**: Each shard supports 1MB/s write and 2MB/s read — exceeding causes throttling
- **Hot shards**: Skewed partition keys cause hot shards — check per-shard metrics
- **Iterator age**: High iterator age means consumers are falling behind — investigate consumer health
- **Enhanced fan-out cost**: Each registered consumer adds cost — use shared throughput when possible
- **Resharding lag**: Shard splitting/merging creates parent-child relationships — consumers must handle this
- **Retention period**: Default 24h, max 8760h (365 days) — data beyond retention is lost permanently
