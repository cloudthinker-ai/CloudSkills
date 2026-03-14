---
name: managing-segment
description: |
  Segment CDP management — monitor sources, destinations, event delivery, tracking plans, and data quality. Use when inspecting event flow, debugging destination failures, auditing tracking plan violations, or reviewing workspace configuration.
connection_type: segment
preload: false
---

# Managing Segment

Manage and monitor Segment customer data platform — sources, destinations, tracking plans, and event delivery.

## Discovery Phase

```bash
#!/bin/bash

SEGMENT_API="https://api.segmentapis.com"
AUTH="Authorization: Bearer $SEGMENT_API_TOKEN"

echo "=== Workspace Info ==="
curl -s -H "$AUTH" "$SEGMENT_API/v1/workspace" \
  | jq '{name: .data.workspace.name, id: .data.workspace.id}'

echo ""
echo "=== Sources ==="
curl -s -H "$AUTH" "$SEGMENT_API/v1/sources" \
  | jq -r '.data.sources[] | [.id, .name, .catalogId, .writeKeys[0]] | @tsv' | column -t | head -15

echo ""
echo "=== Destinations ==="
curl -s -H "$AUTH" "$SEGMENT_API/v1/destinations" \
  | jq -r '.data.destinations[] | [.id, .name, .enabled, .sourceId] | @tsv' | column -t | head -15

echo ""
echo "=== Tracking Plans ==="
curl -s -H "$AUTH" "$SEGMENT_API/v1/tracking-plans" \
  | jq -r '.data.trackingPlans[] | [.name, .id, .updatedAt] | @tsv' | column -t | head -10
```

## Analysis Phase

```bash
#!/bin/bash

SEGMENT_API="https://api.segmentapis.com"
AUTH="Authorization: Bearer $SEGMENT_API_TOKEN"

echo "=== Delivery Metrics (per destination) ==="
for DEST_ID in $(curl -s -H "$AUTH" "$SEGMENT_API/v1/destinations" | jq -r '.data.destinations[:5][].id'); do
  DEST_NAME=$(curl -s -H "$AUTH" "$SEGMENT_API/v1/destinations/$DEST_ID" | jq -r '.data.destination.name')
  echo "--- $DEST_NAME ---"
  curl -s -H "$AUTH" "$SEGMENT_API/v1/destinations/$DEST_ID/delivery-metrics" \
    | jq '{delivered: .data.metrics.delivered, failed: .data.metrics.failed, retried: .data.metrics.retried}' 2>/dev/null
done

echo ""
echo "=== Tracking Plan Violations ==="
curl -s -H "$AUTH" "$SEGMENT_API/v1/tracking-plans/$SEGMENT_TRACKING_PLAN_ID/violations" \
  | jq -r '.data.violations[:10][] | [.eventName, .type, .count] | @tsv' | column -t

echo ""
echo "=== Source Event Volume ==="
curl -s -H "$AUTH" "$SEGMENT_API/v1/sources/$SEGMENT_SOURCE_ID/event-volume" \
  | jq -r '.data.dailyVolumes[:7][] | [.date, .total] | @tsv' | column -t
```

## Output Format

```
WORKSPACE
Name:       <workspace-name>

SOURCES
ID           Name             Catalog
<id>         <source-name>    <catalog-id>

DESTINATIONS
ID           Name             Enabled  Source
<id>         <dest-name>      true     <source-id>

DELIVERY METRICS
Destination      Delivered   Failed   Retried
<dest-name>      <n>         <n>      <n>

TRACKING PLAN VIOLATIONS
Event Name       Type          Count
<event>          <violation>   <n>
```
