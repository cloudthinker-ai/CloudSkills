---
name: managing-rudderstack
description: |
  Use when working with Rudderstack — rudderStack CDP management — monitor
  sources, destinations, event delivery, transformations, and pipeline health.
  Use when debugging event routing, inspecting transformation logic, auditing
  data flows, or reviewing connection status.
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

