---
name: managing-airbyte
description: |
  Airbyte data integration platform management. Covers connection status monitoring, sync job tracking, source and destination health, schema change detection, workspace management, and connector upgrades. Use when checking sync status, investigating job failures, managing Airbyte connections, or auditing data pipeline configurations.
connection_type: airbyte
preload: false
---

# Airbyte Management Skill

Manage and monitor Airbyte connections, sync jobs, and data pipeline health via the Airbyte API.

## MANDATORY: Discovery-First Pattern

**Always list workspaces and connections before querying specific jobs or sources.**

### Phase 1: Discovery

```bash
#!/bin/bash

airbyte_api() {
    local method="${1:-POST}"
    local endpoint="$2"
    local data="${3:-{}}"

    curl -s -X "$method" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer ${AIRBYTE_API_TOKEN}" \
        "${AIRBYTE_API_URL}/api/v1/${endpoint}" \
        -d "$data"
}

echo "=== Workspaces ==="
airbyte_api POST "workspaces/list" | jq -r '
    .workspaces[] | "\(.workspaceId)\t\(.name)\t\(.slug)"
' | column -t

echo ""
echo "=== Connections Summary ==="
airbyte_api POST "connections/list" "{\"workspaceId\": \"${AIRBYTE_WORKSPACE_ID}\"}" | jq -r '
    .connections[] | "\(.connectionId[0:8])\t\(.name)\t\(.status)\t\(.scheduleType // "manual")"
' | column -t | head -30

echo ""
echo "=== Source/Destination Count ==="
SOURCES=$(airbyte_api POST "sources/list" "{\"workspaceId\": \"${AIRBYTE_WORKSPACE_ID}\"}" | jq '.sources | length')
DESTS=$(airbyte_api POST "destinations/list" "{\"workspaceId\": \"${AIRBYTE_WORKSPACE_ID}\"}" | jq '.destinations | length')
echo "Sources: $SOURCES | Destinations: $DESTS"
```

## Core Helper Functions

```bash
#!/bin/bash

airbyte_api() {
    local method="${1:-POST}"
    local endpoint="$2"
    local data="${3:-{}}"

    curl -s -X "$method" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer ${AIRBYTE_API_TOKEN}" \
        "${AIRBYTE_API_URL}/api/v1/${endpoint}" \
        -d "$data"
}
```

## Output Rules
- **TOKEN EFFICIENCY**: Target ≤50 lines per output
- Airbyte API is mostly POST-based even for reads — always use POST with JSON body
- Never dump full catalog — extract stream names and sync modes only

## Common Operations

### Connection Health Dashboard

```bash
#!/bin/bash
echo "=== Connection Status Overview ==="
airbyte_api POST "connections/list" "{\"workspaceId\": \"${AIRBYTE_WORKSPACE_ID}\"}" | jq '
    .connections | {
        total: length,
        active: [.[] | select(.status == "active")] | length,
        inactive: [.[] | select(.status == "inactive")] | length,
        deprecated: [.[] | select(.status == "deprecated")] | length
    }'

echo ""
echo "=== Recent Job Failures ==="
airbyte_api POST "connections/list" "{\"workspaceId\": \"${AIRBYTE_WORKSPACE_ID}\"}" | jq -r '
    .connections[] | .connectionId
' | head -20 | while read cid; do
    airbyte_api POST "jobs/list" "{\"configTypes\": [\"sync\"], \"configId\": \"${cid}\", \"pagination\": {\"pageSize\": 1}}" | jq -r '
        .jobs[]? | select(.job.status == "failed") |
        "\(.job.configId[0:8])\t\(.job.status)\t\(.job.createdAt | todate)\t\(.attempts[-1].failureSummary?.failures[0]?.externalMessage[0:60] // "unknown")"
    '
done | column -t | head -15
```

### Sync Job Details

```bash
#!/bin/bash
CONNECTION_ID="${1:?Connection ID required}"

echo "=== Connection Details ==="
airbyte_api POST "connections/get" "{\"connectionId\": \"${CONNECTION_ID}\"}" | jq '{
    name: .name,
    status: .status,
    schedule: .scheduleType,
    namespace: .namespaceFormat,
    prefix: .prefix,
    streams: (.syncCatalog.streams | length)
}'

echo ""
echo "=== Recent Sync Jobs ==="
airbyte_api POST "jobs/list" "{\"configTypes\": [\"sync\"], \"configId\": \"${CONNECTION_ID}\", \"pagination\": {\"pageSize\": 10}}" | jq -r '
    .jobs[] | "\(.job.id)\t\(.job.status)\t\(.job.createdAt | todate)\t\(.job.updatedAt | todate)"
' | column -t

echo ""
echo "=== Last Sync Stats ==="
airbyte_api POST "jobs/list" "{\"configTypes\": [\"sync\"], \"configId\": \"${CONNECTION_ID}\", \"pagination\": {\"pageSize\": 1}}" | jq '
    .jobs[0].attempts[-1].attempt | {
        status: .status,
        records_synced: .totalStats.recordsEmitted,
        bytes_synced: .totalStats.bytesEmitted,
        records_committed: .totalStats.recordsCommitted
    }'
```

### Source and Destination Health

```bash
#!/bin/bash
echo "=== Sources ==="
airbyte_api POST "sources/list" "{\"workspaceId\": \"${AIRBYTE_WORKSPACE_ID}\"}" | jq -r '
    .sources[] | "\(.sourceId[0:8])\t\(.sourceName)\t\(.name)\t\(.connectionConfiguration | keys | join(","))"
' | column -t | head -20

echo ""
echo "=== Destinations ==="
airbyte_api POST "destinations/list" "{\"workspaceId\": \"${AIRBYTE_WORKSPACE_ID}\"}" | jq -r '
    .destinations[] | "\(.destinationId[0:8])\t\(.destinationName)\t\(.name)"
' | column -t | head -10

echo ""
echo "=== Source Health Check ==="
SOURCE_ID="${1:-}"
if [ -n "$SOURCE_ID" ]; then
    airbyte_api POST "sources/check_connection" "{\"sourceId\": \"${SOURCE_ID}\"}" | jq '{
        status: .status,
        message: .message
    }'
fi
```

### Schema Change Detection

```bash
#!/bin/bash
CONNECTION_ID="${1:?Connection ID required}"

echo "=== Configured Streams ==="
airbyte_api POST "connections/get" "{\"connectionId\": \"${CONNECTION_ID}\"}" | jq -r '
    .syncCatalog.streams[] |
    "\(.stream.name)\t\(.config.syncMode)\t\(.config.destinationSyncMode)\t\(.stream.jsonSchema.properties | keys | length) cols"
' | column -t | head -20

echo ""
echo "=== Discover Source Schema (fresh) ==="
SOURCE_ID=$(airbyte_api POST "connections/get" "{\"connectionId\": \"${CONNECTION_ID}\"}" | jq -r '.sourceId')
airbyte_api POST "sources/discover_schema" "{\"sourceId\": \"${SOURCE_ID}\"}" | jq -r '
    .catalog.streams[] | "\(.stream.name)\t\(.stream.jsonSchema.properties | keys | length) cols\t\(.stream.supportedSyncModes | join(","))"
' | column -t | head -20
```

### Trigger and Manage Syncs

```bash
#!/bin/bash
CONNECTION_ID="${1:?Connection ID required}"
ACTION="${2:-status}"

case "$ACTION" in
    trigger)
        echo "=== Triggering Sync ==="
        airbyte_api POST "connections/sync" "{\"connectionId\": \"${CONNECTION_ID}\"}" | jq '{
            job_id: .job.id,
            status: .job.status,
            config_type: .job.configType
        }'
        ;;
    reset)
        echo "=== Triggering Reset ==="
        airbyte_api POST "connections/reset" "{\"connectionId\": \"${CONNECTION_ID}\"}" | jq '{
            job_id: .job.id,
            status: .job.status
        }'
        ;;
    status)
        echo "=== Current Status ==="
        airbyte_api POST "connections/get" "{\"connectionId\": \"${CONNECTION_ID}\"}" | jq '{
            name: .name, status: .status, schedule: .scheduleType
        }'
        ;;
esac
```

## Common Pitfalls

- **POST for reads**: Airbyte API uses POST for list/get operations — do not use GET for these endpoints
- **Workspace scope**: All queries require `workspaceId` — always discover workspaces first
- **Connection vs Connector**: A "connection" links a source to a destination; a "connector" is the source/destination type definition
- **Schema discovery**: `discover_schema` can be slow (minutes) for large databases — it queries the actual source
- **Sync modes**: `full_refresh` re-syncs everything; `incremental` only new/changed — wrong mode causes data loss or duplication
- **Destination sync modes**: `overwrite` replaces data; `append` adds rows; `append_dedup` upserts — verify before changing
- **Reset impact**: `connections/reset` deletes all data in destination and re-syncs — use with extreme caution
- **Job attempts**: A single job may have multiple attempts on failure — check `attempts[-1]` for latest
- **Normalization**: If enabled, Airbyte runs normalization after sync — failures may occur in normalization, not sync
