---
name: managing-lightdash
description: |
  Lightdash BI management — monitor projects, dashboards, saved charts, spaces, and dbt model exploration. Use when reviewing dashboard health, inspecting chart queries, auditing project configuration, or checking scheduler status.
connection_type: lightdash
preload: false
---

# Managing Lightdash

Manage and monitor Lightdash BI — projects, dashboards, charts, spaces, and schedulers.

## Discovery Phase

```bash
#!/bin/bash

LIGHTDASH_API="$LIGHTDASH_URL/api/v1"
AUTH="Authorization: ApiKey $LIGHTDASH_API_KEY"

echo "=== Organization ==="
curl -s -H "$AUTH" "$LIGHTDASH_API/org" \
  | jq '.results | {name: .name, organizationUuid: .organizationUuid}'

echo ""
echo "=== Projects ==="
curl -s -H "$AUTH" "$LIGHTDASH_API/org/projects" \
  | jq -r '.results[] | [.projectUuid, .name, .type] | @tsv' | column -t | head -10

echo ""
echo "=== Spaces ==="
curl -s -H "$AUTH" "$LIGHTDASH_API/projects/$LIGHTDASH_PROJECT_UUID/spaces" \
  | jq -r '.results[] | [.uuid, .name, .isPrivate, .dashboardCount, .chartCount] | @tsv' | column -t | head -10

echo ""
echo "=== Dashboards ==="
curl -s -H "$AUTH" "$LIGHTDASH_API/projects/$LIGHTDASH_PROJECT_UUID/dashboards" \
  | jq -r '.results[] | [.uuid, .name, .spaceName, .updatedAt] | @tsv' | column -t | head -15
```

## Analysis Phase

```bash
#!/bin/bash

LIGHTDASH_API="$LIGHTDASH_URL/api/v1"
AUTH="Authorization: ApiKey $LIGHTDASH_API_KEY"

echo "=== Saved Charts ==="
curl -s -H "$AUTH" "$LIGHTDASH_API/projects/$LIGHTDASH_PROJECT_UUID/charts" \
  | jq -r '.results[] | [.uuid, .name, .chartType, .spaceName, .updatedAt] | @tsv' | column -t | head -15

echo ""
echo "=== Scheduler Jobs ==="
curl -s -H "$AUTH" "$LIGHTDASH_API/schedulers/jobs" \
  | jq -r '.results[:10][] | [.jobId, .jobType, .status, .createdAt] | @tsv' | column -t

echo ""
echo "=== Scheduler Logs (Recent) ==="
curl -s -H "$AUTH" "$LIGHTDASH_API/schedulers/logs?limit=10" \
  | jq -r '.results[] | [.schedulerUuid, .status, .createdAt, .details[:50] // ""] | @tsv' | column -t

echo ""
echo "=== dbt Explores (Models) ==="
curl -s -H "$AUTH" "$LIGHTDASH_API/projects/$LIGHTDASH_PROJECT_UUID/explores" \
  | jq -r '.results[] | [.name, .label, .tags // []] | @tsv' | column -t | head -15

echo ""
echo "=== Project Members ==="
curl -s -H "$AUTH" "$LIGHTDASH_API/projects/$LIGHTDASH_PROJECT_UUID/access" \
  | jq -r '.results[] | [.userUuid, .email, .role] | @tsv' | column -t | head -10
```

## Output Format

```
PROJECTS
UUID     Name             Type
<uuid>   <project-name>   <type>

DASHBOARDS
UUID     Name             Space           Updated
<uuid>   <dash-name>      <space-name>    <timestamp>

SAVED CHARTS
UUID     Name             Type        Space           Updated
<uuid>   <chart-name>     <type>      <space-name>    <timestamp>

SCHEDULER STATUS
Job ID   Type       Status      Created
<id>     <type>     <status>    <timestamp>

EXPLORES
Name             Label            Tags
<explore-name>   <label>          <tags>
```
