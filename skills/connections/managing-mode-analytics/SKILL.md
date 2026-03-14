---
name: managing-mode-analytics
description: |
  Mode Analytics management — monitor workspaces, reports, queries, data sources, and scheduled runs. Use when reviewing report health, inspecting query performance, auditing data connections, or checking scheduled report delivery.
connection_type: mode-analytics
preload: false
---

# Managing Mode Analytics

Manage and monitor Mode Analytics — reports, queries, data sources, and scheduled runs.

## Discovery Phase

```bash
#!/bin/bash

MODE_API="https://app.mode.com/api"
AUTH="-u $MODE_API_TOKEN:$MODE_API_SECRET"

echo "=== Workspace Info ==="
curl -s $AUTH "$MODE_API/$MODE_WORKSPACE" \
  | jq '{name: .name, username: .username, plan: .plan}'

echo ""
echo "=== Data Sources ==="
curl -s $AUTH "$MODE_API/$MODE_WORKSPACE/data_sources" \
  | jq -r '._embedded.data_sources[] | [.id, .name, .adapter, .has_expensive_schema_warning] | @tsv' | column -t | head -10

echo ""
echo "=== Spaces ==="
curl -s $AUTH "$MODE_API/$MODE_WORKSPACE/spaces" \
  | jq -r '._embedded.spaces[] | [.token, .name, .space_type, .restricted] | @tsv' | column -t | head -10

echo ""
echo "=== Recent Reports ==="
curl -s $AUTH "$MODE_API/$MODE_WORKSPACE/reports?order=desc&order_by=updated_at&limit=15" \
  | jq -r '._embedded.reports[] | [.token, .name, .updated_at, .last_run_state] | @tsv' | column -t
```

## Analysis Phase

```bash
#!/bin/bash

MODE_API="https://app.mode.com/api"
AUTH="-u $MODE_API_TOKEN:$MODE_API_SECRET"

echo "=== Report Run History ==="
curl -s $AUTH "$MODE_API/$MODE_WORKSPACE/reports/$MODE_REPORT_TOKEN/runs?limit=10" \
  | jq -r '._embedded.report_runs[] | [.token, .state, .created_at, .completed_at] | @tsv' | column -t

echo ""
echo "=== Failed Runs (Recent) ==="
curl -s $AUTH "$MODE_API/$MODE_WORKSPACE/report_runs?filter=failed&limit=10" \
  | jq -r '._embedded.report_runs[] | [.report_token, .state, .created_at, .error_message[:60]] | @tsv' | column -t

echo ""
echo "=== Scheduled Reports ==="
curl -s $AUTH "$MODE_API/$MODE_WORKSPACE/report_schedules" \
  | jq -r '._embedded.report_schedules[] | [.report_token, .cron, .paused, .last_run_at] | @tsv' | column -t | head -10

echo ""
echo "=== Data Source Health ==="
for DS_ID in $(curl -s $AUTH "$MODE_API/$MODE_WORKSPACE/data_sources" | jq -r '._embedded.data_sources[:5][].id'); do
  DS_NAME=$(curl -s $AUTH "$MODE_API/$MODE_WORKSPACE/data_sources/$DS_ID" | jq -r '.name')
  STATUS=$(curl -s $AUTH "$MODE_API/$MODE_WORKSPACE/data_sources/$DS_ID/status" | jq -r '.status // "unknown"')
  echo "$DS_NAME: $STATUS"
done

echo ""
echo "=== Query Performance (last run) ==="
curl -s $AUTH "$MODE_API/$MODE_WORKSPACE/reports/$MODE_REPORT_TOKEN/runs/latest/queries" \
  | jq -r '._embedded.queries[] | [.name, .state, .raw_rows, (.total_time_in_seconds | tostring) + "s"] | @tsv' | column -t
```

## Output Format

```
WORKSPACE
Name:       <workspace-name>
Plan:       <plan>

DATA SOURCES
ID       Name             Adapter      Warning
<id>     <ds-name>        <adapter>    <bool>

SCHEDULED REPORTS
Report           Cron          Paused   Last Run
<report-token>   <cron>        false    <timestamp>

FAILED RUNS
Report           State    Created         Error
<report-token>   failed   <timestamp>     <message>

QUERY PERFORMANCE
Query Name       State      Rows     Duration
<query-name>     completed  <n>      <seconds>s
```
