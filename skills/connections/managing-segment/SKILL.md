---
name: managing-segment
description: |
  Use when working with Segment — segment CDP management — monitor sources,
  destinations, event delivery, tracking plans, and data quality. Use when
  inspecting event flow, debugging destination failures, auditing tracking plan
  violations, or reviewing workspace configuration.
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

## Anti-Hallucination Rules

1. **NEVER assume resource names** — always discover via CLI/API in Phase 1 before referencing in Phase 2.
2. **NEVER fabricate metric names or dimensions** — verify against the service documentation or `--help` output.
3. **NEVER mix CLI commands between service versions** — confirm which version/API you are targeting.
4. **ALWAYS use the discovery → verify → analyze chain** — every resource referenced must have been discovered first.
5. **ALWAYS handle empty results gracefully** — an empty response is valid data, not an error to retry.

## Counter-Rationalizations

| Shortcut | Counter | Why |
|----------|---------|-----|
| "I'll skip discovery and check known resources" | Always run Phase 1 discovery first | Resource names change, new resources appear — assumed names cause errors |
| "The user only asked for a quick check" | Follow the full discovery → analysis flow | Quick checks miss critical issues; structured analysis catches silent failures |
| "Default configuration is probably fine" | Audit configuration explicitly | Defaults often leave logging, security, and optimization features disabled |
| "Metrics aren't needed for this" | Always check relevant metrics when available | API/CLI responses show current state; metrics reveal trends and intermittent issues |
| "I don't have access to that" | Try the command and report the actual error | Assumed permission failures prevent useful investigation; actual errors are informative |

