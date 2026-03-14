---
name: managing-rabbitmq
description: |
  RabbitMQ queue management, exchange bindings, connection health, shovel and federation status, and cluster monitoring. You MUST read this skill before executing any RabbitMQ operations — it contains mandatory two-phase execution, anti-hallucination rules, and safety constraints.
connection_type: rabbitmq
preload: false
---

# RabbitMQ Management Skill

Analyze and manage RabbitMQ clusters with safe, read-only operations.

## MANDATORY: Two-Phase Execution

**You MUST follow this two-phase pattern. Skipping Phase 1 causes hallucinated queue/exchange names.**

### Phase 1: Discovery (ALWAYS run first)

```bash
#!/bin/bash

# 1. Cluster overview
rabbitmqctl cluster_status

# 2. List vhosts
rabbitmqctl list_vhosts

# 3. List queues
rabbitmqctl list_queues -p "$VHOST" name messages consumers state

# 4. List exchanges
rabbitmqctl list_exchanges -p "$VHOST" name type durable auto_delete

# 5. List bindings
rabbitmqctl list_bindings -p "$VHOST" source_name destination_name routing_key
```

**Phase 1 outputs:**
- Cluster nodes and their status
- Vhosts, queues, exchanges, and bindings
- Queue message counts and consumer counts

### Phase 2: Analysis (only after Phase 1)

Only reference vhosts, queues, exchanges, and bindings confirmed in Phase 1.

## Shell Script Patterns

### Helper Function

```bash
#!/bin/bash

# Core rabbitmqctl helper — always use this
rmq_cmd() {
    rabbitmqctl "$@"
}

# Management API helper
rmq_api() {
    local endpoint="$1"
    curl -s -u "${RMQ_USER:-guest}:${RMQ_PASSWORD:-guest}" \
        "http://${RMQ_HOST:-localhost}:15672/api/$endpoint"
}
```

## Anti-Hallucination Rules

- **NEVER reference a queue** without confirming via `list_queues` or API
- **NEVER reference an exchange** without confirming via `list_exchanges`
- **NEVER assume vhost names** — always list vhosts first
- **NEVER guess binding routing keys** — always list bindings
- **NEVER assume node names** — check cluster_status first

## Safety Rules

- **READ-ONLY ONLY**: Use only list_*, status, cluster_status, Management API GET endpoints
- **FORBIDDEN**: delete_queue, purge_queue, stop_app, reset, forget_cluster_node without explicit user request
- **NEVER purge queues** without explicit user request
- **Use Management API** (GET only) for detailed metrics

## Common Operations

### Cluster Health Overview

```bash
#!/bin/bash
echo "=== Cluster Status ==="
rmq_cmd cluster_status

echo ""
echo "=== Node Health ==="
rmq_api "nodes" | jq '.[] | {name, running, mem_used: (.mem_used/1024/1024|round|tostring + "MB"), fd_used, proc_used, disk_free: (.disk_free/1024/1024/1024|.*100|round/100|tostring + "GB"), uptime}'

echo ""
echo "=== Overview ==="
rmq_api "overview" | jq '{rabbitmq_version, erlang_version, cluster_name, queue_totals, object_totals, message_stats}'
```

### Queue Analysis

```bash
#!/bin/bash
VHOST="${1:-%2F}"

echo "=== Queues ==="
rmq_api "queues/$VHOST" | jq '.[] | {name, state, messages, consumers, memory: (.memory/1024/1024|.*10|round/10|tostring + "MB"), message_stats: {publish_rate: .message_stats.publish_details.rate, deliver_rate: .message_stats.deliver_details.rate}}'

echo ""
echo "=== Queues with No Consumers ==="
rmq_api "queues/$VHOST" | jq '[.[] | select(.consumers == 0 and .messages > 0)] | .[] | {name, messages, memory: (.memory/1024|round|tostring + "KB")}'

echo ""
echo "=== Queues with High Message Count ==="
rmq_api "queues/$VHOST" | jq '[.[] | select(.messages > 1000)] | sort_by(-.messages) | .[] | {name, messages, consumers, state}'
```

### Exchange & Binding Analysis

```bash
#!/bin/bash
VHOST="${1:-%2F}"

echo "=== Exchanges ==="
rmq_api "exchanges/$VHOST" | jq '.[] | select(.name != "") | {name, type, durable, auto_delete}'

echo ""
echo "=== Bindings ==="
rmq_api "bindings/$VHOST" | jq '.[] | {source, destination, destination_type, routing_key, properties_key}'
```

### Connection & Channel Health

```bash
#!/bin/bash
echo "=== Connections ==="
rmq_api "connections" | jq '.[] | {name: .name, state, user, vhost, channels, recv_oct_details: .recv_oct_details.rate, send_oct_details: .send_oct_details.rate}'

echo ""
echo "=== Channels ==="
rmq_api "channels" | jq '.[0:20] | .[] | {name: .name, state, consumer_count, messages_unacknowledged, prefetch_count}'

echo ""
echo "=== Shovel Status ==="
rmq_api "shovels" | jq '.[] | {name: .name, state, src_uri: .value.src_uri, dest_uri: .value.dest_uri}' 2>/dev/null

echo ""
echo "=== Federation Status ==="
rmq_api "federation-links" | jq '.[] | {exchange, upstream, status, type}' 2>/dev/null
```

## Common Pitfalls

- **Unacked messages**: High unacked count means consumers are slow or stuck — check prefetch settings
- **Memory alarms**: Memory watermark triggers flow control, blocking publishers
- **Disk alarms**: Low disk space triggers flow control — check disk_free
- **Queue mirroring deprecated**: Classic queue mirroring is deprecated — use quorum queues instead
- **Idle connections**: Too many idle connections waste file descriptors — check connection limits
- **Message TTL**: Messages can expire silently — check queue TTL and per-message TTL settings
