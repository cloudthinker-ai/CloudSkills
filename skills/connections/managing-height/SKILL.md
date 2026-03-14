---
name: managing-height
description: |
  Height.app project management covering tasks, lists, workspaces, and team activity analytics. Use when auditing Height workspace usage, managing tasks and lists, analyzing team workload, or reviewing project progress across a Height workspace.
connection_type: height
preload: false
---

# Managing Height

Height workspace management and analytics via the Height REST API.

## Discovery Phase

```bash
#!/bin/bash
HEIGHT_BASE="https://api.height.app"

echo "=== Workspace Info ==="
curl -s -H "Authorization: api-key $HEIGHT_API_KEY" \
  "$HEIGHT_BASE/workspace" | jq '{id, name, url}'

echo ""
echo "=== Lists ==="
curl -s -H "Authorization: api-key $HEIGHT_API_KEY" \
  "$HEIGHT_BASE/lists" \
  | jq -r '.list[] | "\(.id)\t\(.name[0:30])\t\(.type)\t\(.archivedAt // "active")"' | column -t

echo ""
echo "=== Users ==="
curl -s -H "Authorization: api-key $HEIGHT_API_KEY" \
  "$HEIGHT_BASE/users" \
  | jq -r '.list[] | "\(.id)\t\(.username)\t\(.email)\t\(.state)"' | column -t

echo ""
echo "=== Field Templates ==="
curl -s -H "Authorization: api-key $HEIGHT_API_KEY" \
  "$HEIGHT_BASE/fieldTemplates" \
  | jq -r '.list[]? | "\(.id)\t\(.name)\t\(.type)"' | column -t | head -15
```

## Analysis Phase

```bash
#!/bin/bash
HEIGHT_BASE="https://api.height.app"
LIST_ID="${1:?List ID required}"

echo "=== List Tasks ==="
curl -s -H "Authorization: api-key $HEIGHT_API_KEY" \
  "$HEIGHT_BASE/lists/$LIST_ID/tasks" \
  | jq -r '.list[] | "\(.index)\t\(.name[0:40])\t\(.status)\t\(.assigneesIds | length) assignees"' | column -t | head -25

echo ""
echo "=== Task Status Distribution ==="
curl -s -H "Authorization: api-key $HEIGHT_API_KEY" \
  "$HEIGHT_BASE/lists/$LIST_ID/tasks" \
  | jq '[.list[].status] | group_by(.) | map({status: .[0], count: length}) | sort_by(-.count)[]'

echo ""
echo "=== Unassigned Tasks ==="
curl -s -H "Authorization: api-key $HEIGHT_API_KEY" \
  "$HEIGHT_BASE/lists/$LIST_ID/tasks" \
  | jq '[.list[] | select(.assigneesIds | length == 0)] | {unassigned: length, tasks: [.[:5][] | {name: .name[0:40], status}]}'

echo ""
echo "=== Recent Activity ==="
curl -s -H "Authorization: api-key $HEIGHT_API_KEY" \
  "$HEIGHT_BASE/activities?listId=$LIST_ID" \
  | jq -r '.list[:10][] | "\(.createdAt[0:16])\t\(.type)\t\(.user.username // "system")"' | column -t
```

## Output Format

```
HEIGHT WORKSPACE HEALTH
Workspace:     [name]
Total Lists:   [count] ([active] active)
Total Users:   [count]

LIST HEALTH: [list_name]
Total Tasks:   [count]
Unassigned:    [count]

STATUS DISTRIBUTION
Status         Count   Pct
backLog        [n]     [pct]%
inProgress     [n]     [pct]%
done           [n]     [pct]%
```
