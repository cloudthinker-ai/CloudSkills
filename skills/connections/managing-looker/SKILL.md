---
name: managing-looker
description: |
  Looker BI platform management. Covers explore analysis, dashboard review, LookML project management, PDT status monitoring, query performance, user activity, and content validation. Use when analyzing dashboards, investigating query performance, managing LookML projects, or auditing Looker usage.
connection_type: looker
preload: false
---

# Looker Management Skill

Manage and analyze Looker explores, dashboards, LookML projects, and query performance via the Looker API.

## MANDATORY: Discovery-First Pattern

**Always discover projects and models before querying specific explores or dashboards.**

### Phase 1: Discovery

```bash
#!/bin/bash

looker_api() {
    local method="${1:-GET}"
    local endpoint="$2"
    local data="${3:-}"

    if [ -n "$data" ]; then
        curl -s -X "$method" \
            -H "Authorization: token ${LOOKER_API_TOKEN}" \
            -H "Content-Type: application/json" \
            "${LOOKER_BASE_URL}/api/4.0/${endpoint}" \
            -d "$data"
    else
        curl -s -X "$method" \
            -H "Authorization: token ${LOOKER_API_TOKEN}" \
            "${LOOKER_BASE_URL}/api/4.0/${endpoint}"
    fi
}

echo "=== LookML Projects ==="
looker_api GET "projects" | jq -r '
    .[] | "\(.id)\t\(.name)\t\(.git_service_name // "N/A")\t\(if .is_example then "EXAMPLE" else "CUSTOM" end)"
' | column -t

echo ""
echo "=== LookML Models ==="
looker_api GET "lookml_models" | jq -r '
    .[] | "\(.name)\t\(.project_name)\t\(.explores | length) explores"
' | column -t | head -20

echo ""
echo "=== Dashboards (recent) ==="
looker_api GET "dashboards?fields=id,title,folder,view_count&sorts=view_count desc&limit=20" | jq -r '
    .[] | "\(.id)\t\(.title[0:40])\t\(.folder?.name // "?")\t\(.view_count) views"
' | column -t
```

## Core Helper Functions

```bash
#!/bin/bash

looker_api() {
    local method="${1:-GET}"
    local endpoint="$2"
    local data="${3:-}"

    if [ -n "$data" ]; then
        curl -s -X "$method" \
            -H "Authorization: token ${LOOKER_API_TOKEN}" \
            -H "Content-Type: application/json" \
            "${LOOKER_BASE_URL}/api/4.0/${endpoint}" \
            -d "$data"
    else
        curl -s -X "$method" \
            -H "Authorization: token ${LOOKER_API_TOKEN}" \
            "${LOOKER_BASE_URL}/api/4.0/${endpoint}"
    fi
}
```

## Output Rules
- **TOKEN EFFICIENCY**: Target ≤50 lines per output
- Use `fields` query parameter to limit returned fields from Looker API
- Never dump full LookML model definitions — extract key metadata only

## Common Operations

### Explore Analysis

```bash
#!/bin/bash
MODEL="${1:?Model name required}"

echo "=== Explores in Model: $MODEL ==="
looker_api GET "lookml_models/${MODEL}" | jq -r '
    .explores[] | "\(.name)\t\(.label // .name)\t\(.description[0:50] // "no description")"
' | column -t | head -20

echo ""
echo "=== Explore Fields ==="
EXPLORE="${2:-}"
if [ -n "$EXPLORE" ]; then
    looker_api GET "lookml_models/${MODEL}/explores/${EXPLORE}?fields=fields" | jq '{
        dimensions: (.fields.dimensions | length),
        measures: (.fields.measures | length),
        filters: (.fields.filters | length),
        parameters: (.fields.parameters | length)
    }'

    echo ""
    echo "=== Top Dimensions ==="
    looker_api GET "lookml_models/${MODEL}/explores/${EXPLORE}?fields=fields" | jq -r '
        .fields.dimensions[:10][] | "\(.name)\t\(.type)\t\(.label_short // .label)"
    ' | column -t
fi
```

### Dashboard Analysis

```bash
#!/bin/bash
DASHBOARD_ID="${1:?Dashboard ID required}"

echo "=== Dashboard Details ==="
looker_api GET "dashboards/${DASHBOARD_ID}" | jq '{
    id: .id,
    title: .title,
    folder: .folder?.name,
    elements: (.dashboard_elements | length),
    filters: (.dashboard_filters | length),
    view_count: .view_count,
    last_viewed_at: .last_viewed_at
}'

echo ""
echo "=== Dashboard Elements ==="
looker_api GET "dashboards/${DASHBOARD_ID}" | jq -r '
    .dashboard_elements[] | "\(.id)\t\(.type)\t\(.title // "untitled")\t\(.look_id // .query_id // "?")"
' | column -t | head -20

echo ""
echo "=== Dashboard Filters ==="
looker_api GET "dashboards/${DASHBOARD_ID}" | jq -r '
    .dashboard_filters[] | "\(.name)\t\(.type)\t\(.default_value // "none")\t\(.model)\t\(.explore)"
' | column -t
```

### PDT Status Monitoring

```bash
#!/bin/bash
echo "=== PDT Builds ==="
looker_api GET "derived_table/graph/model" 2>/dev/null | jq -r '
    to_entries[] | "\(.key)\t\(.value.status // "?")\t\(.value.last_build_started_at[0:16] // "never")"
' | column -t | head -20

echo ""
echo "=== Running PDT Builds ==="
looker_api GET "running_queries?fields=id,status,source,model,explore,created_at" | jq -r '
    .[] | select(.source == "pdt") |
    "\(.id)\t\(.status)\t\(.model)\t\(.explore)\t\(.created_at[0:16])"
' | column -t

echo ""
echo "=== PDT Connection Status ==="
looker_api GET "connections" | jq -r '
    .[] | "\(.name)\t\(.pdt_enabled)\t\(.dialect_name)\t\(.host // "?")"
' | column -t | head -10
```

### Query Performance

```bash
#!/bin/bash
echo "=== Slow Running Queries ==="
looker_api GET "running_queries?fields=id,user,query,runtime,status,source,created_at&limit=20" | jq -r '
    .[] | select(.runtime > 30) |
    "\(.id)\t\(.runtime | floor)s\t\(.status)\t\(.source)\t\(.user?.display_name // "system")"
' | column -t | head -15

echo ""
echo "=== Query History (by model) ==="
looker_api GET "query_tasks?fields=id,status,result_source,runtime" 2>/dev/null | jq '
    group_by(.result_source) | map({source: .[0].result_source, count: length, avg_runtime: ([.[].runtime] | add / length | floor)}) |
    .[] | "\(.source)\t\(.count) queries\tavg \(.avg_runtime)s"
' -r 2>/dev/null

echo ""
echo "=== Kill Long-Running Query ==="
echo "Use: looker_api DELETE 'running_queries/{query_task_id}'"
```

### LookML Project Validation

```bash
#!/bin/bash
PROJECT="${1:?Project name required}"

echo "=== LookML Validation ==="
looker_api POST "projects/${PROJECT}/lookml_validation" | jq '{
    stale_content: .stale_content,
    errors: [.errors[] | {severity: .severity, kind: .kind, message: .message[0:80]}] | length,
    warnings: [.warnings[]? | .message[0:60]] | length
}'

echo ""
echo "=== Validation Errors ==="
looker_api GET "projects/${PROJECT}/lookml_validation" | jq -r '
    .errors[:10][] | "\(.severity)\t\(.kind)\t\(.message[0:80])"
' | column -t

echo ""
echo "=== Git Status ==="
looker_api GET "projects/${PROJECT}/git/branch" | jq '{
    branch: .name,
    ref: .ref,
    is_production: .is_production,
    ahead: .ahead_count,
    behind: .behind_count
}'
```

## Common Pitfalls

- **API versions**: Looker API 4.0 is current — older instances may only support 3.1 — check `/api/4.0/versions`
- **Token auth**: API tokens expire — if getting 401, re-authenticate via `POST /api/4.0/login` with client credentials
- **PDT builds**: PDTs build on schedule or trigger — stale PDTs mean stale dashboard data but no visible error
- **Content validation**: LookML validation errors don't prevent deployment in dev mode — production deploy may break
- **Explore permissions**: Users may not see all explores — API results depend on the authenticating user's permissions
- **Folder structure**: Dashboards live in folders with access controls — personal folders are per-user
- **Dashboard vs Look**: Dashboards contain multiple elements; Looks are single saved queries — they have different APIs
- **Query caching**: Looker caches query results — stale data may be from cache, not a query failure
- **Model sets**: Permissions are tied to model sets — a user may access some models but not others
