---
name: managing-power-bi
description: |
  Power BI service management — monitor workspaces, datasets, reports, refresh schedules, and capacity utilization. Use when inspecting dashboard health, debugging refresh failures, auditing workspace permissions, or reviewing dataset configurations.
connection_type: power-bi
preload: false
---

# Managing Power BI

Manage and monitor Power BI service — workspaces, datasets, reports, refreshes, and capacity.

## Discovery Phase

```bash
#!/bin/bash

PBI_API="https://api.powerbi.com/v1.0/myorg"
AUTH="Authorization: Bearer $POWER_BI_ACCESS_TOKEN"

echo "=== Workspaces ==="
curl -s -H "$AUTH" "$PBI_API/groups" \
  | jq -r '.value[] | [.id, .name, .type, .state] | @tsv' | column -t | head -15

echo ""
echo "=== Datasets ==="
curl -s -H "$AUTH" "$PBI_API/datasets" \
  | jq -r '.value[] | [.id, .name, .configuredBy, .isRefreshable] | @tsv' | column -t | head -15

echo ""
echo "=== Reports ==="
curl -s -H "$AUTH" "$PBI_API/reports" \
  | jq -r '.value[] | [.id, .name, .datasetId, .reportType] | @tsv' | column -t | head -15

echo ""
echo "=== Dashboards ==="
curl -s -H "$AUTH" "$PBI_API/dashboards" \
  | jq -r '.value[] | [.id, .displayName, .isReadOnly] | @tsv' | column -t | head -10
```

## Analysis Phase

```bash
#!/bin/bash

PBI_API="https://api.powerbi.com/v1.0/myorg"
AUTH="Authorization: Bearer $POWER_BI_ACCESS_TOKEN"

echo "=== Dataset Refresh History ==="
for DS_ID in $(curl -s -H "$AUTH" "$PBI_API/datasets" | jq -r '.value[:5][].id'); do
  DS_NAME=$(curl -s -H "$AUTH" "$PBI_API/datasets/$DS_ID" | jq -r '.name')
  echo "--- $DS_NAME ---"
  curl -s -H "$AUTH" "$PBI_API/datasets/$DS_ID/refreshes?\$top=3" \
    | jq -r '.value[] | [.status, .startTime, .endTime, .serviceExceptionJson // ""] | @tsv' | column -t
done

echo ""
echo "=== Failed Refreshes ==="
for DS_ID in $(curl -s -H "$AUTH" "$PBI_API/datasets" | jq -r '.value[].id'); do
  curl -s -H "$AUTH" "$PBI_API/datasets/$DS_ID/refreshes?\$top=1" \
    | jq -r --arg id "$DS_ID" '.value[] | select(.status=="Failed") | [$id, .startTime, .serviceExceptionJson[:80]] | @tsv'
done | column -t | head -10

echo ""
echo "=== Refresh Schedules ==="
for DS_ID in $(curl -s -H "$AUTH" "$PBI_API/datasets" | jq -r '.value[:5][].id'); do
  DS_NAME=$(curl -s -H "$AUTH" "$PBI_API/datasets/$DS_ID" | jq -r '.name')
  SCHEDULE=$(curl -s -H "$AUTH" "$PBI_API/datasets/$DS_ID/refreshSchedule" | jq -c '{enabled: .enabled, frequency: .days, times: .times}' 2>/dev/null)
  echo "$DS_NAME: $SCHEDULE"
done

echo ""
echo "=== Workspace Users ==="
curl -s -H "$AUTH" "$PBI_API/groups/$POWER_BI_WORKSPACE_ID/users" \
  | jq -r '.value[] | [.emailAddress, .groupUserAccessRight, .principalType] | @tsv' | column -t | head -10
```

## Output Format

```
WORKSPACES
ID       Name              Type       State
<id>     <workspace-name>  <type>     <state>

DATASETS
ID       Name              Owner          Refreshable
<id>     <dataset-name>    <configured>   true

REFRESH HISTORY
Dataset          Status      Start              End
<dataset-name>   Completed   <timestamp>        <timestamp>

FAILED REFRESHES
Dataset ID       Start              Error
<id>             <timestamp>        <message>
```
