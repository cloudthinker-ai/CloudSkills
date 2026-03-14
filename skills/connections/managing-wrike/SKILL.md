---
name: managing-wrike
description: |
  Wrike project management covering folders, projects, tasks, timelog entries, and workflow analytics. Use when auditing Wrike usage, managing tasks and projects, analyzing time tracking, or reviewing workflow health across a Wrike workspace.
connection_type: wrike
preload: false
---

# Managing Wrike

Wrike project management analysis via the Wrike REST API.

## Discovery Phase

```bash
#!/bin/bash
WRIKE_BASE="https://www.wrike.com/api/v4"

echo "=== Current User ==="
curl -s -H "Authorization: Bearer $WRIKE_TOKEN" \
  "$WRIKE_BASE/contacts?me=true" \
  | jq '.data[0] | {id, firstName, lastName, type, profiles}'

echo ""
echo "=== Account Info ==="
curl -s -H "Authorization: Bearer $WRIKE_TOKEN" \
  "$WRIKE_BASE/account" \
  | jq '.data[0] | {id, name, subscription: .subscription.type}'

echo ""
echo "=== Folders & Projects ==="
curl -s -H "Authorization: Bearer $WRIKE_TOKEN" \
  "$WRIKE_BASE/folders?project=true&fields=[\"briefDescription\"]" \
  | jq -r '.data[] | "\(.id)\t\(.title[0:30])\t\(.project.status // "folder")\t\(.scope)"' | column -t | head -25

echo ""
echo "=== Workflows ==="
curl -s -H "Authorization: Bearer $WRIKE_TOKEN" \
  "$WRIKE_BASE/workflows" \
  | jq -r '.data[] | "\(.id)\t\(.name)\tstates: \([.customStatuses[] | .name] | join(", "))"'

echo ""
echo "=== Custom Fields ==="
curl -s -H "Authorization: Bearer $WRIKE_TOKEN" \
  "$WRIKE_BASE/customfields?fields=[\"type\"]" \
  | jq -r '.data[:10][] | "\(.id)\t\(.title[0:25])\t\(.type)"' | column -t
```

## Analysis Phase

```bash
#!/bin/bash
WRIKE_BASE="https://www.wrike.com/api/v4"
FOLDER_ID="${1:?Folder/Project ID required}"

echo "=== Tasks in Project ==="
curl -s -H "Authorization: Bearer $WRIKE_TOKEN" \
  "$WRIKE_BASE/folders/$FOLDER_ID/tasks?fields=[\"responsibleIds\",\"customStatusId\"]&pageSize=25" \
  | jq -r '.data[] | "\(.id)\t\(.title[0:40])\t\(.status)\t\(.importance)\t\(.responsibleIds | length) assignees"' | column -t

echo ""
echo "=== Task Status Distribution ==="
curl -s -H "Authorization: Bearer $WRIKE_TOKEN" \
  "$WRIKE_BASE/folders/$FOLDER_ID/tasks?fields=[\"customStatusId\"]&pageSize=100" \
  | jq '[.data[].status] | group_by(.) | map({status: .[0], count: length}) | sort_by(-.count)[]'

echo ""
echo "=== Overdue Tasks ==="
curl -s -H "Authorization: Bearer $WRIKE_TOKEN" \
  "$WRIKE_BASE/folders/$FOLDER_ID/tasks?status=Active&dueDate={\"end\":\"$(date +%Y-%m-%d)\"}&pageSize=10" \
  | jq -r '.data[]? | "\(.title[0:40])\tdue=\(.dates.due // "none")\t\(.importance)"' | column -t

echo ""
echo "=== Time Logs (last 7 days) ==="
FROM=$(date -v-7d +%Y-%m-%dT00:00:00Z 2>/dev/null || date -u -d "-7 days" +%Y-%m-%dT00:00:00Z)
curl -s -H "Authorization: Bearer $WRIKE_TOKEN" \
  "$WRIKE_BASE/folders/$FOLDER_ID/timelogs?trackedDate={\"start\":\"$FROM\"}" \
  | jq -r '.data[]? | "\(.trackedDate)\t\(.hours)h\t\(.comment[0:30] // "no comment")"' | column -t
```

## Output Format

```
WRIKE PROJECT HEALTH: [project_name]
Status:         [status]
Total Tasks:    [count]
Overdue Tasks:  [count]

TASK STATUS DISTRIBUTION
Status           Count   Pct
Active           [n]     [pct]%
Completed        [n]     [pct]%
Deferred         [n]     [pct]%

TIME TRACKING (Last 7 Days)
Total Hours:     [h]
Contributors:    [count]

OVERDUE TASKS
Task                 Due Date    Priority
[title]              [date]      [importance]
```
