---
name: managing-rudderstack
description: |
  RudderStack CDP management — monitor sources, destinations, event delivery, transformations, and pipeline health. Use when debugging event routing, inspecting transformation logic, auditing data flows, or reviewing connection status.
connection_type: rudderstack
preload: false
---

# Managing RudderStack

Manage and monitor RudderStack customer data platform — sources, destinations, transformations, and event delivery.

## Discovery Phase

```bash
#!/bin/bash

RUDDER_API="https://api.rudderstack.com/v2"
AUTH="Authorization: Bearer $RUDDERSTACK_ACCESS_TOKEN"

echo "=== Sources ==="
curl -s -H "$AUTH" "$RUDDER_API/sources" \
  | jq -r '.sources[] | [.id, .name, .type, .enabled] | @tsv' | column -t | head -15

echo ""
echo "=== Destinations ==="
curl -s -H "$AUTH" "$RUDDER_API/destinations" \
  | jq -r '.destinations[] | [.id, .name, .type, .enabled] | @tsv' | column -t | head -15

echo ""
echo "=== Connections ==="
curl -s -H "$AUTH" "$RUDDER_API/connections" \
  | jq -r '.connections[] | [.sourceId, .destinationId, .enabled] | @tsv' | column -t | head -10

echo ""
echo "=== Transformations ==="
curl -s -H "$AUTH" "$RUDDER_API/transformations" \
  | jq -r '.transformations[] | [.id, .name, .updatedAt] | @tsv' | column -t | head -10
```

## Analysis Phase

```bash
#!/bin/bash

RUDDER_API="https://api.rudderstack.com/v2"
AUTH="Authorization: Bearer $RUDDERSTACK_ACCESS_TOKEN"

echo "=== Event Delivery Status ==="
curl -s -H "$AUTH" "$RUDDER_API/destinations/$RUDDERSTACK_DEST_ID/jobs/status" \
  | jq -r '.statuses[] | [.state, .count, .lastJobAt] | @tsv' | column -t | head -10

echo ""
echo "=== Failed Events ==="
curl -s -H "$AUTH" "$RUDDER_API/destinations/$RUDDERSTACK_DEST_ID/jobs/failed" \
  | jq -r '.jobs[:10][] | [.jobId, .errorCode, .errorMessage[:60], .createdAt] | @tsv' | column -t

echo ""
echo "=== Source Event Volume ==="
curl -s -H "$AUTH" "$RUDDER_API/sources/$RUDDERSTACK_SOURCE_ID/stats" \
  | jq '{totalEvents: .totalEvents, successRate: .successRate, failedEvents: .failedEvents}'

echo ""
echo "=== Live Events (recent) ==="
curl -s -H "$AUTH" "$RUDDER_API/sources/$RUDDERSTACK_SOURCE_ID/liveEvents?limit=5" \
  | jq -r '.events[] | [.type, .event, .timestamp] | @tsv' | column -t
```

## Output Format

```
SOURCES
ID           Name             Type          Enabled
<id>         <source-name>    <type>        true

DESTINATIONS
ID           Name             Type          Enabled
<id>         <dest-name>      <type>        true

DELIVERY STATUS
State        Count    Last Job
succeeded    <n>      <timestamp>
failed       <n>      <timestamp>

FAILED EVENTS
Job ID       Error Code   Message
<id>         <code>       <message>
```
