---
name: managing-activemq
description: |
  ActiveMQ broker health, destination management, advisory topic monitoring, network connector status, and message flow analysis. You MUST read this skill before executing any ActiveMQ operations — it contains mandatory two-phase execution, anti-hallucination rules, and safety constraints.
connection_type: activemq
preload: false
---

# ActiveMQ Management Skill

Analyze and manage ActiveMQ brokers with safe, read-only operations.

## MANDATORY: Two-Phase Execution

**You MUST follow this two-phase pattern. Skipping Phase 1 causes hallucinated queue/topic names.**

### Phase 1: Discovery (ALWAYS run first)

```bash
#!/bin/bash

# 1. Broker info (Jolokia/REST API)
curl -s -u "$AMQ_USER:$AMQ_PASSWORD" \
    "http://$AMQ_HOST:8161/api/jolokia/read/org.apache.activemq:type=Broker,brokerName=*"

# 2. List queues
curl -s -u "$AMQ_USER:$AMQ_PASSWORD" \
    "http://$AMQ_HOST:8161/api/jolokia/read/org.apache.activemq:type=Broker,brokerName=localhost/Queues"

# 3. List topics
curl -s -u "$AMQ_USER:$AMQ_PASSWORD" \
    "http://$AMQ_HOST:8161/api/jolokia/read/org.apache.activemq:type=Broker,brokerName=localhost/Topics"

# For ActiveMQ Artemis (newer):
# 4. List queues (Artemis)
curl -s -u "$AMQ_USER:$AMQ_PASSWORD" \
    "http://$AMQ_HOST:8161/console/jolokia/read/org.apache.activemq.artemis:broker=\"*\",component=addresses"

# 5. Queue stats
curl -s -u "$AMQ_USER:$AMQ_PASSWORD" \
    "http://$AMQ_HOST:8161/api/jolokia/read/org.apache.activemq:type=Broker,brokerName=localhost,destinationType=Queue,destinationName=my_queue"
```

**Phase 1 outputs:**
- Broker name and version
- Queue and topic list with message counts
- Consumer and producer counts

### Phase 2: Analysis (only after Phase 1)

Only reference queues, topics, and destinations confirmed in Phase 1.

## Shell Script Patterns

### Helper Function

```bash
#!/bin/bash

# Jolokia API helper — always use this
amq_jolokia() {
    local mbean="$1"
    curl -s -u "${AMQ_USER:-admin}:${AMQ_PASSWORD:-admin}" \
        "http://${AMQ_HOST:-localhost}:8161/api/jolokia/read/$mbean"
}

# Jolokia exec helper (for operations)
amq_exec() {
    local mbean="$1" operation="$2"
    curl -s -u "${AMQ_USER:-admin}:${AMQ_PASSWORD:-admin}" \
        -X POST -H "Content-Type: application/json" \
        -d "{\"type\":\"exec\",\"mbean\":\"$mbean\",\"operation\":\"$operation\"}" \
        "http://${AMQ_HOST:-localhost}:8161/api/jolokia/"
}

# ActiveMQ Web Console API
amq_api() {
    local endpoint="$1"
    curl -s -u "${AMQ_USER:-admin}:${AMQ_PASSWORD:-admin}" \
        "http://${AMQ_HOST:-localhost}:8161/api/$endpoint"
}
```

## Anti-Hallucination Rules

- **NEVER reference a queue or topic** without confirming via Jolokia API or web console
- **NEVER assume broker name** — always query broker info first
- **NEVER guess destination names** — always list destinations
- **NEVER assume Classic vs Artemis** — check broker type first
- **NEVER assume network connector names** — list them from broker config

## Safety Rules

- **READ-ONLY ONLY**: Use only Jolokia read operations, web console GET endpoints
- **FORBIDDEN**: purge, removeQueue, removeTopic, sendMessage without explicit user request
- **NEVER browse messages** on high-volume production queues — it can cause memory issues
- **Use Jolokia read** for metrics, not message browsing

## Common Operations

### Broker Health Overview

```bash
#!/bin/bash
echo "=== Broker Info ==="
amq_jolokia "org.apache.activemq:type=Broker,brokerName=localhost" | jq '.value | {BrokerId, BrokerName, BrokerVersion, Uptime, MemoryLimit, StoreLimit, TempLimit, MemoryPercentUsage, StorePercentUsage, TempPercentUsage}'

echo ""
echo "=== Queue Summary ==="
amq_jolokia "org.apache.activemq:type=Broker,brokerName=localhost" | jq '.value.Queues | length | tostring + " queues"'

echo ""
echo "=== Topic Summary ==="
amq_jolokia "org.apache.activemq:type=Broker,brokerName=localhost" | jq '.value.Topics | length | tostring + " topics"'

echo ""
echo "=== Health ==="
amq_jolokia "org.apache.activemq:type=Health,brokerName=localhost" 2>/dev/null | jq '.value'
```

### Destination Management

```bash
#!/bin/bash
echo "=== Queue Details ==="
for QUEUE in $(amq_jolokia "org.apache.activemq:type=Broker,brokerName=localhost" | jq -r '.value.Queues[].objectName' 2>/dev/null); do
    amq_jolokia "$QUEUE" | jq '.value | {Name, QueueSize, EnqueueCount, DequeueCount, ConsumerCount, ProducerCount, MemoryPercentUsage, InFlightCount}'
done

echo ""
echo "=== Topics with Subscribers ==="
for TOPIC in $(amq_jolokia "org.apache.activemq:type=Broker,brokerName=localhost" | jq -r '.value.Topics[].objectName' 2>/dev/null); do
    amq_jolokia "$TOPIC" | jq '.value | select(.ConsumerCount > 0) | {Name, ConsumerCount, EnqueueCount, DequeueCount}'
done
```

### Network Connector Status

```bash
#!/bin/bash
echo "=== Network Connectors ==="
amq_jolokia "org.apache.activemq:type=Broker,brokerName=localhost,connector=networkConnectors,networkConnectorName=*" | jq '.value | to_entries[] | {name: .key, active: .value.Started, duplex: .value.Duplex}' 2>/dev/null || echo "No network connectors configured"

echo ""
echo "=== Transport Connectors ==="
amq_jolokia "org.apache.activemq:type=Broker,brokerName=localhost,connector=clientConnectors,connectorName=*" | jq '.value' 2>/dev/null
```

### Advisory Topics

```bash
#!/bin/bash
echo "=== Advisory Topics ==="
amq_jolokia "org.apache.activemq:type=Broker,brokerName=localhost" | jq '[.value.Topics[].objectName | select(contains("Advisory"))]' 2>/dev/null

echo ""
echo "=== Connection Count ==="
amq_jolokia "org.apache.activemq:type=Broker,brokerName=localhost" | jq '.value | {CurrentConnectionsCount, TotalConnectionsCount, TotalConsumerCount, TotalProducerCount, TotalMessageCount}'
```

## Common Pitfalls

- **Store limit**: When store usage hits 100%, producers are blocked — monitor StorePercentUsage
- **Memory limit**: Memory usage exceeding threshold triggers flow control
- **DLQ accumulation**: Failed messages go to ActiveMQ.DLQ — monitor its size
- **Slow consumers**: Slow consumers on topics cause memory buildup — check advisory topics
- **Network bridge lag**: Network connectors between brokers can have replication lag
- **Classic vs Artemis API**: ActiveMQ Classic and Artemis have different JMX/Jolokia endpoints
