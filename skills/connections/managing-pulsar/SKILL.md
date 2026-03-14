---
name: managing-pulsar
description: |
  Apache Pulsar tenant management, namespace policies, topic statistics, subscription lag, and cluster health. You MUST read this skill before executing any Pulsar operations — it contains mandatory two-phase execution, anti-hallucination rules, and safety constraints.
connection_type: pulsar
preload: false
---

# Apache Pulsar Management Skill

Analyze and manage Pulsar clusters with safe, read-only operations.

## MANDATORY: Two-Phase Execution

**You MUST follow this two-phase pattern. Skipping Phase 1 causes hallucinated tenant/topic names.**

### Phase 1: Discovery (ALWAYS run first)

```bash
#!/bin/bash

# 1. List clusters
pulsar-admin clusters list

# 2. List tenants
pulsar-admin tenants list

# 3. List namespaces in a tenant
pulsar-admin namespaces list my-tenant

# 4. List topics in a namespace
pulsar-admin topics list my-tenant/my-namespace

# 5. Get topic stats
pulsar-admin topics stats persistent://my-tenant/my-namespace/my-topic
```

**Phase 1 outputs:**
- Clusters, tenants, and namespaces
- Topics with partition info
- Subscriptions and consumer details

### Phase 2: Analysis (only after Phase 1)

Only reference tenants, namespaces, topics, and subscriptions confirmed in Phase 1.

## Shell Script Patterns

### Helper Function

```bash
#!/bin/bash

# Core Pulsar admin helper — always use this
pulsar_admin() {
    pulsar-admin --admin-url "${PULSAR_ADMIN_URL:-http://localhost:8080}" "$@"
}

# Pulsar REST API helper
pulsar_api() {
    local endpoint="$1"
    curl -s "http://${PULSAR_HOST:-localhost}:8080/admin/v2/$endpoint"
}
```

## Anti-Hallucination Rules

- **NEVER reference a tenant** without confirming via `tenants list`
- **NEVER reference a namespace** without confirming via `namespaces list`
- **NEVER reference topic names** without confirming via `topics list`
- **NEVER assume subscription names** — always check topic stats
- **NEVER guess partition count** — check partitioned-topic stats

## Safety Rules

- **READ-ONLY ONLY**: Use only list, stats, get-*, lookup commands
- **FORBIDDEN**: create, delete, unload, offload, update, terminate without explicit user request
- **NEVER consume from production topics** for analysis
- **Use admin API** for metrics, not direct consumption

## Common Operations

### Cluster Health Overview

```bash
#!/bin/bash
echo "=== Clusters ==="
pulsar_admin clusters list

echo ""
echo "=== Brokers ==="
pulsar_admin brokers list $(pulsar_admin clusters list | head -1)

echo ""
echo "=== Broker Health ==="
pulsar_api "brokers/health" || echo "Health endpoint not available"

echo ""
echo "=== Tenants ==="
for TENANT in $(pulsar_admin tenants list); do
    echo "$TENANT: $(pulsar_admin namespaces list $TENANT | wc -l) namespaces"
done
```

### Topic Statistics

```bash
#!/bin/bash
TOPIC="${1:-persistent://my-tenant/my-namespace/my-topic}"

echo "=== Topic Stats ==="
pulsar_admin topics stats "$TOPIC" | jq '{msgRateIn, msgThroughputIn, msgRateOut, msgThroughputOut, storageSize, backlogSize, publishers: (.publishers | length), subscriptions: (.subscriptions | keys)}'

echo ""
echo "=== Subscription Details ==="
pulsar_admin topics stats "$TOPIC" | jq '.subscriptions | to_entries[] | {name: .key, msgBacklog: .value.msgBacklog, msgRateOut: .value.msgRateOut, consumers: (.value.consumers | length), type: .value.type}'

echo ""
echo "=== Internal Stats ==="
pulsar_admin topics stats-internal "$TOPIC" | jq '{numberOfEntries, totalSize, currentLedgerEntries, currentLedgerSize, lastConfirmedEntry}'
```

### Namespace Analysis

```bash
#!/bin/bash
TENANT="${1:-my-tenant}"
NAMESPACE="${2:-my-namespace}"

echo "=== Namespace Policies ==="
pulsar_admin namespaces policies "$TENANT/$NAMESPACE" | jq '{retention_policies, backlog_quota_map, message_ttl_in_seconds, max_producers_per_topic, max_consumers_per_topic, replication_clusters}'

echo ""
echo "=== Topics in Namespace ==="
pulsar_admin topics list "$TENANT/$NAMESPACE"

echo ""
echo "=== Namespace Bundle Stats ==="
pulsar_admin namespaces bundles "$TENANT/$NAMESPACE" 2>/dev/null
```

### Subscription Lag Analysis

```bash
#!/bin/bash
TENANT="${1:-my-tenant}"
NAMESPACE="${2:-my-namespace}"

echo "=== Backlog by Topic ==="
for TOPIC in $(pulsar_admin topics list "$TENANT/$NAMESPACE"); do
    STATS=$(pulsar_admin topics stats "$TOPIC" 2>/dev/null)
    BACKLOG=$(echo "$STATS" | jq '.backlogSize // 0')
    [ "$BACKLOG" != "0" ] && echo "$TOPIC: backlog=$BACKLOG"
done

echo ""
echo "=== Subscription Backlogs ==="
for TOPIC in $(pulsar_admin topics list "$TENANT/$NAMESPACE"); do
    pulsar_admin topics stats "$TOPIC" 2>/dev/null | jq --arg topic "$TOPIC" '.subscriptions | to_entries[] | select(.value.msgBacklog > 0) | {topic: $topic, subscription: .key, msgBacklog: .value.msgBacklog}'
done
```

## Common Pitfalls

- **Backlog accumulation**: Unacked messages build up backlog — monitor subscription backlog size
- **Topic unloading**: Unloading topics disrupts consumers — do not unload production topics for analysis
- **Namespace bundles**: Bundle splitting affects topic distribution — check bundle ownership
- **Geo-replication lag**: Cross-cluster replication has inherent lag — monitor replication metrics
- **Schema evolution**: Incompatible schema changes break consumers — check schema compatibility mode
- **Tiered storage**: Offloaded data has higher read latency — check offload thresholds
