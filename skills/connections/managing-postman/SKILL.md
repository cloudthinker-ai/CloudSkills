---
name: managing-postman
description: |
  Postman workspace management - collection and request management, environment variable configuration, monitor run analysis, and API documentation generation. Use when managing API testing workflows, analyzing test results, or maintaining API documentation in Postman.
connection_type: postman
preload: false
---

# Postman Management Skill

Manage Postman collections, environments, monitors, and API documentation via the Postman API.

## Core Helper Functions

```bash
#!/bin/bash

# Postman API
POSTMAN_API="https://api.getpostman.com"
POSTMAN_KEY="${POSTMAN_API_KEY:-}"

# Postman API wrapper
postman_api() {
    local method="${1:-GET}"
    local endpoint="$2"
    shift 2
    curl -s -X "$method" "${POSTMAN_API}${endpoint}" \
        -H "X-Api-Key: ${POSTMAN_KEY}" \
        -H "Content-Type: application/json" "$@" | jq '.'
}
```

## MANDATORY: Discovery-First Pattern

**Always inspect the workspace and collections before performing operations.**

### Phase 1: Discovery

```bash
#!/bin/bash

echo "=== Workspaces ==="
postman_api GET "/workspaces" | jq '[.workspaces[] | {id, name, type, visibility}]'

echo ""
echo "=== Collections ==="
postman_api GET "/collections" | jq '[.collections[] | {id, name, owner, updated_at: .updatedAt}] | sort_by(.name)'

echo ""
echo "=== Environments ==="
postman_api GET "/environments" | jq '[.environments[] | {id, name, owner, updated_at: .updatedAt}]'

echo ""
echo "=== Monitors ==="
postman_api GET "/monitors" | jq '[.monitors[] | {id, name, schedule, lastRun: .lastRun.status}]'
```

## Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- Always extract relevant fields from API responses
- Never dump full collection definitions -- summarize structure

## Common Operations

### Collection Management

```bash
#!/bin/bash
COLLECTION_ID="${1:?Collection ID required}"

echo "=== Collection Overview ==="
postman_api GET "/collections/${COLLECTION_ID}" | jq '{
    name: .collection.info.name,
    description: .collection.info.description,
    schema: .collection.info.schema,
    total_items: [.collection.item[] | .. | .request? // empty] | length,
    folders: [.collection.item[] | select(.item) | .name],
    variables: [.collection.variable // [] | .[] | {key, value: (if .type == "secret" then "***" else .value end)}]
}'

echo ""
echo "=== Request Summary ==="
postman_api GET "/collections/${COLLECTION_ID}" | jq '[.collection.item[] | {
    folder: .name,
    requests: [(.item // [])[] | {name, method: .request.method, url: (.request.url.raw // (.request.url | if type == "string" then . else .raw end))}]
}]'

echo ""
echo "=== Auth Configuration ==="
postman_api GET "/collections/${COLLECTION_ID}" | jq '.collection.auth // "No collection-level auth"'
```

### Environment Variable Management

```bash
#!/bin/bash
ENV_ID="${1:?Environment ID required}"

echo "=== Environment Variables ==="
postman_api GET "/environments/${ENV_ID}" | jq '{
    name: .environment.name,
    variables: [.environment.values[] | {
        key,
        value: (if .type == "secret" then "***REDACTED***" else .value end),
        enabled,
        type: (.type // "default")
    }]
}'

echo ""
echo "=== All Environments Comparison ==="
for env in $(postman_api GET "/environments" | jq -r '.environments[].id'); do
    name=$(postman_api GET "/environments/${env}" | jq -r '.environment.name')
    vars=$(postman_api GET "/environments/${env}" | jq '[.environment.values[] | .key]')
    echo "${name}: ${vars}"
done
```

### Monitor Run Analysis

```bash
#!/bin/bash
MONITOR_ID="${1:?Monitor ID required}"

echo "=== Monitor Details ==="
postman_api GET "/monitors/${MONITOR_ID}" | jq '{
    name: .monitor.name,
    collection: .monitor.collectionUid,
    environment: .monitor.environmentUid,
    schedule: .monitor.schedule,
    last_run: .monitor.lastRun,
    notifications: .monitor.notifications
}'

echo ""
echo "=== Recent Runs ==="
postman_api GET "/monitors/${MONITOR_ID}" | jq '{
    last_run_status: .monitor.lastRun.status,
    last_run_started: .monitor.lastRun.startedAt,
    stats: .monitor.lastRun.stats
}'

echo ""
echo "=== All Monitor Health ==="
postman_api GET "/monitors" | jq '[.monitors[] | {
    name,
    status: .lastRun.status,
    finished_at: .lastRun.finishedAt
}] | sort_by(.status)'
```

### API Documentation

```bash
#!/bin/bash

echo "=== Published APIs ==="
postman_api GET "/apis" | jq '[.apis[] | {id, name, summary, created_by: .createdBy, updated_at: .updatedAt}]'

echo ""
echo "=== API Versions ==="
API_ID="${1:-}"
if [ -n "$API_ID" ]; then
    postman_api GET "/apis/${API_ID}/versions" | jq '[.versions[] | {id, name, releaseNotes}]'

    echo ""
    echo "=== API Schemas ==="
    for ver in $(postman_api GET "/apis/${API_ID}/versions" | jq -r '.versions[].id' | head -5); do
        postman_api GET "/apis/${API_ID}/versions/${ver}/schemas" | jq '[.schemas[] | {id, type, language}]'
    done
fi

echo ""
echo "=== Collection Documentation Links ==="
postman_api GET "/collections" | jq '[.collections[] | {name, id, docs_url: "https://documenter.getpostman.com/view/\(.owner)/\(.id)"}]'
```

## Safety Rules
- **Read-only by default**: Only use GET requests for discovery and inspection
- **Never delete** collections or environments without explicit user confirmation
- **Never expose** secret-type environment variables -- always redact them
- **Never overwrite** environment variables without confirming current values first
- **Fork before editing**: Suggest forking collections before making structural changes

## Common Pitfalls
- **API key rate limits**: Postman API has rate limits (60 requests/minute for free tier); batch requests
- **Collection UIDs vs IDs**: The API uses UIDs (owner-id format), not the short display IDs
- **Environment scope**: Environments are workspace-scoped; the same name in different workspaces are different environments
- **Monitor timezone**: Monitor schedules use UTC; confirm timezone when interpreting run times
- **Variable precedence**: Global < environment < collection < data variables; overlapping keys cause confusion
