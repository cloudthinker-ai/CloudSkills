---
name: managing-preset-io
description: |
  Use when working with Preset Io — preset.io (managed Apache Superset)
  management — monitor workspaces, dashboards, charts, datasets, and database
  connections. Use when reviewing dashboard health, inspecting query
  performance, auditing access controls, or checking data freshness.
connection_type: preset-io
preload: false
---

# Managing Preset.io

Manage and monitor Preset.io (managed Superset) — dashboards, charts, datasets, and database connections.

## Discovery Phase

```bash
#!/bin/bash

PRESET_API="https://api.app.preset.io/v1"
AUTH="Authorization: Bearer $PRESET_API_TOKEN"

echo "=== Teams ==="
curl -s -H "$AUTH" "$PRESET_API/teams" \
  | jq -r '.payload[] | [.name, .id] | @tsv' | column -t | head -5

echo ""
echo "=== Workspaces ==="
curl -s -H "$AUTH" "$PRESET_API/teams/$PRESET_TEAM_ID/workspaces" \
  | jq -r '.payload[] | [.id, .title, .hostname, .region] | @tsv' | column -t | head -10

WORKSPACE_API="https://$PRESET_WORKSPACE_HOST/api/v1"
WORKSPACE_AUTH="Authorization: Bearer $PRESET_WORKSPACE_TOKEN"

echo ""
echo "=== Databases ==="
curl -s -H "$WORKSPACE_AUTH" "$WORKSPACE_API/database/" \
  | jq -r '.result[] | [.id, .database_name, .backend, .allow_run_async] | @tsv' | column -t | head -10

echo ""
echo "=== Dashboards ==="
curl -s -H "$WORKSPACE_AUTH" "$WORKSPACE_API/dashboard/?page_size=15" \
  | jq -r '.result[] | [.id, .dashboard_title, .changed_on_utc, .published] | @tsv' | column -t
```

## Analysis Phase

```bash
#!/bin/bash

WORKSPACE_API="https://$PRESET_WORKSPACE_HOST/api/v1"
AUTH="Authorization: Bearer $PRESET_WORKSPACE_TOKEN"

echo "=== Datasets ==="
curl -s -H "$AUTH" "$WORKSPACE_API/dataset/?page_size=15" \
  | jq -r '.result[] | [.id, .table_name, .schema, .database.database_name, .changed_on_utc] | @tsv' | column -t

echo ""
echo "=== Charts ==="
curl -s -H "$AUTH" "$WORKSPACE_API/chart/?page_size=15" \
  | jq -r '.result[] | [.id, .slice_name, .viz_type, .changed_on_utc] | @tsv' | column -t

echo ""
echo "=== Recent Query Logs ==="
curl -s -H "$AUTH" "$WORKSPACE_API/query/?page_size=10" \
  | jq -r '.result[] | [.status, .database.database_name, .rows, .elapsed_time // 0, .changed_on] | @tsv' | column -t

echo ""
echo "=== Failed Queries ==="
curl -s -H "$AUTH" "$WORKSPACE_API/query/?page_size=10&filters=[{\"col\":\"status\",\"opr\":\"eq\",\"value\":\"failed\"}]" \
  | jq -r '.result[] | [.database.database_name, .error_message[:60], .changed_on] | @tsv' | column -t

echo ""
echo "=== Database Health ==="
for DB_ID in $(curl -s -H "$AUTH" "$WORKSPACE_API/database/" | jq -r '.result[:5][].id'); do
  DB_NAME=$(curl -s -H "$AUTH" "$WORKSPACE_API/database/$DB_ID" | jq -r '.result.database_name')
  STATUS=$(curl -s -H "$AUTH" "$WORKSPACE_API/database/$DB_ID/test_connection" | jq -r '.message // "connected"')
  echo "$DB_NAME: $STATUS"
done
```

## Output Format

```
WORKSPACES
ID       Title            Hostname         Region
<id>     <ws-title>       <hostname>       <region>

DASHBOARDS
ID       Title            Updated          Published
<id>     <dash-title>     <timestamp>      true

DATASETS
ID       Table            Schema    Database         Updated
<id>     <table-name>     <schema>  <db-name>        <timestamp>

FAILED QUERIES
Database         Error                    Time
<db-name>        <message>                <timestamp>
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

