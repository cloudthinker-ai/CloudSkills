---
name: managing-polytomic
description: |
  Use when working with Polytomic — polytomic data integration management —
  monitor connections, syncs, models, bulk syncs, and execution health. Use when
  debugging sync failures, inspecting data mappings, auditing connection status,
  or reviewing sync run performance.
connection_type: polytomic
preload: false
---

# Managing Polytomic

Manage and monitor Polytomic data integration — connections, syncs, models, and execution health.

## Discovery Phase

```bash
#!/bin/bash

POLYTOMIC_API="https://app.polytomic.com/api"
AUTH="Authorization: Bearer $POLYTOMIC_API_KEY"

echo "=== Connections ==="
curl -s -H "$AUTH" "$POLYTOMIC_API/connections" \
  | jq -r '.data[] | [.id, .name, .type, .status] | @tsv' | column -t | head -10

echo ""
echo "=== Models ==="
curl -s -H "$AUTH" "$POLYTOMIC_API/models" \
  | jq -r '.data[] | [.id, .name, .connection_id, .type] | @tsv' | column -t | head -15

echo ""
echo "=== Syncs ==="
curl -s -H "$AUTH" "$POLYTOMIC_API/syncs" \
  | jq -r '.data[] | [.id, .name, .mode, .active, .schedule.frequency] | @tsv' | column -t | head -15

echo ""
echo "=== Bulk Syncs ==="
curl -s -H "$AUTH" "$POLYTOMIC_API/bulk/syncs" \
  | jq -r '.data[] | [.id, .name, .source_connection_id, .dest_connection_id, .active] | @tsv' | column -t | head -10
```

## Analysis Phase

```bash
#!/bin/bash

POLYTOMIC_API="https://app.polytomic.com/api"
AUTH="Authorization: Bearer $POLYTOMIC_API_KEY"

echo "=== Recent Sync Executions ==="
curl -s -H "$AUTH" "$POLYTOMIC_API/syncs/$POLYTOMIC_SYNC_ID/executions?limit=10" \
  | jq -r '.data[] | [.id, .status, .records_processed, .records_failed, .started_at, .completed_at] | @tsv' | column -t

echo ""
echo "=== Failed Executions ==="
curl -s -H "$AUTH" "$POLYTOMIC_API/syncs/executions?status=failed&limit=10" \
  | jq -r '.data[] | [.id, .sync_id, .started_at, .error[:60]] | @tsv' | column -t

echo ""
echo "=== Connection Health ==="
for CONN_ID in $(curl -s -H "$AUTH" "$POLYTOMIC_API/connections" | jq -r '.data[:5][].id'); do
  CONN_NAME=$(curl -s -H "$AUTH" "$POLYTOMIC_API/connections/$CONN_ID" | jq -r '.data.name')
  STATUS=$(curl -s -H "$AUTH" "$POLYTOMIC_API/connections/$CONN_ID" | jq -r '.data.status')
  echo "$CONN_NAME: $STATUS"
done

echo ""
echo "=== Sync Field Mappings ==="
curl -s -H "$AUTH" "$POLYTOMIC_API/syncs/$POLYTOMIC_SYNC_ID" \
  | jq -r '.data.fields[] | [.source.field, .target.field, .sync_mode] | @tsv' | column -t | head -10

echo ""
echo "=== Bulk Sync Status ==="
curl -s -H "$AUTH" "$POLYTOMIC_API/bulk/syncs/$POLYTOMIC_BULK_SYNC_ID/executions?limit=5" \
  | jq -r '.data[] | [.id, .status, .started_at, .completed_at] | @tsv' | column -t
```

## Output Format

```
CONNECTIONS
ID       Name             Type       Status
<id>     <conn-name>      <type>     <status>

SYNCS
ID       Name             Mode       Active   Frequency
<id>     <sync-name>      <mode>     true     <freq>

SYNC EXECUTIONS
ID       Status      Processed  Failed   Started         Completed
<id>     completed   <n>        <n>      <timestamp>     <timestamp>

FAILED EXECUTIONS
ID       Sync ID  Started         Error
<id>     <sid>    <timestamp>     <message>
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

