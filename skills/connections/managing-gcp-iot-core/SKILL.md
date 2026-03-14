---
name: managing-gcp-iot-core
description: |
  Google Cloud IoT platform management using Pub/Sub, Cloud Functions, and device management patterns that replaced the deprecated IoT Core. Covers device telemetry via Pub/Sub, command delivery, device state management, and monitoring through Cloud Monitoring.
connection_type: gcp-iot-core
preload: false
---

# GCP IoT Management Skill

Monitor and manage GCP IoT infrastructure (post-IoT Core migration patterns).

## MANDATORY: Discovery-First Pattern

**GCP IoT Core was deprecated August 2023. Discover the current Pub/Sub and device management setup.**

### Phase 1: Discovery

```bash
#!/bin/bash
PROJECT="${GCP_PROJECT_ID}"

echo "=== Note: GCP IoT Core Deprecated ==="
echo "IoT Core retired Aug 2023. Checking Pub/Sub-based IoT patterns."

echo ""
echo "=== Pub/Sub Topics (IoT related) ==="
gcloud pubsub topics list --project="$PROJECT" \
  --filter="name:iot OR name:telemetry OR name:device OR name:sensor" \
  --format="table(name.basename(), messageRetentionDuration)"

echo ""
echo "=== Pub/Sub Subscriptions ==="
gcloud pubsub subscriptions list --project="$PROJECT" \
  --filter="name:iot OR name:telemetry OR name:device OR name:sensor" \
  --format="table(name.basename(), topic.basename(), ackDeadlineSeconds, messageRetentionDuration)"

echo ""
echo "=== Cloud Functions (IoT handlers) ==="
gcloud functions list --project="$PROJECT" \
  --filter="name:iot OR name:device OR name:telemetry" \
  --format="table(name, status, runtime, trigger)" 2>/dev/null || \
gcloud functions list --project="$PROJECT" --gen2 \
  --filter="name:iot OR name:device OR name:telemetry" \
  --format="table(name, state, buildConfig.runtime)" 2>/dev/null

echo ""
echo "=== Firestore/Datastore Collections (device state) ==="
echo "Check Firestore for device registry collections manually"

echo ""
echo "=== MQTT Broker (if using third-party) ==="
echo "Check for Cloud Run or GKE services running MQTT brokers:"
gcloud run services list --project="$PROJECT" \
  --filter="metadata.name:mqtt OR metadata.name:broker" \
  --format="table(metadata.name, status.url, status.conditions[0].status)" 2>/dev/null
```

**Phase 1 outputs:** Pub/Sub topics, subscriptions, Cloud Functions, device state stores

### Phase 2: Analysis

```bash
#!/bin/bash
echo "=== Pub/Sub Message Volume (24h) ==="
for topic in $(gcloud pubsub topics list --project="$PROJECT" --filter="name:iot OR name:telemetry OR name:device" --format="value(name.basename())" 2>/dev/null); do
  gcloud monitoring time-series list --project="$PROJECT" \
    --filter="metric.type=\"pubsub.googleapis.com/topic/send_message_operation_count\" AND resource.labels.topic_id=\"$topic\"" \
    --interval-start-time="$(date -u -v-1d +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d '1 day ago' +%Y-%m-%dT%H:%M:%SZ)" \
    --format="value(points[0].value.int64Value)" 2>/dev/null | \
    xargs -I{} echo "$topic: {} messages"
done

echo ""
echo "=== Subscription Backlog ==="
for sub in $(gcloud pubsub subscriptions list --project="$PROJECT" --filter="name:iot OR name:device" --format="value(name.basename())" 2>/dev/null); do
  backlog=$(gcloud monitoring time-series list --project="$PROJECT" \
    --filter="metric.type=\"pubsub.googleapis.com/subscription/num_undelivered_messages\" AND resource.labels.subscription_id=\"$sub\"" \
    --format="value(points[0].value.int64Value)" 2>/dev/null)
  echo "$sub: ${backlog:-0} undelivered messages"
done

echo ""
echo "=== Cloud Function Errors (24h) ==="
gcloud logging read "resource.type=cloud_function AND severity>=ERROR AND timestamp>=\"$(date -u -v-1d +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d '1 day ago' +%Y-%m-%dT%H:%M:%SZ)\"" \
  --project="$PROJECT" --limit=10 --format="table(timestamp, resource.labels.function_name, textPayload)" 2>/dev/null || echo "Check Cloud Logging for function errors"
```

## Output Format

```
GCP IOT STATUS
==============
Project: {project_id}
Note: IoT Core deprecated - using Pub/Sub patterns
Telemetry Topics: {count}
Subscriptions: {count} (backlog: {total_undelivered})
24h Messages: {count}
IoT Functions: {count} ({errors} errors)
Issues: {list_of_warnings}
```

## Common Pitfalls

- **IoT Core deprecated**: Migrated to Pub/Sub + custom MQTT broker patterns
- **MQTT alternatives**: Use EMQX, HiveMQ, or Mosquitto on GKE/Cloud Run
- **Device auth**: Use JWT tokens with Pub/Sub service accounts — no built-in device registry
- **Message ordering**: Pub/Sub does not guarantee order — use ordering keys if needed
