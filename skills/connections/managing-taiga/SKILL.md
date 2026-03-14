---
name: managing-taiga
description: |
  Taiga agile project management covering projects, user stories, tasks, sprints, epics, and kanban boards. Use when auditing Taiga project health, managing sprints and user stories, analyzing velocity, or reviewing backlog status across Taiga projects.
connection_type: taiga
preload: false
---

# Managing Taiga

Taiga agile project management analysis via the Taiga REST API.

## Discovery Phase

```bash
#!/bin/bash
TAIGA_BASE="${TAIGA_URL:-https://api.taiga.io}/api/v1"

echo "=== Current User ==="
curl -s -H "Authorization: Bearer $TAIGA_TOKEN" \
  "$TAIGA_BASE/users/me" | jq '{id, username, full_name, email}'

echo ""
echo "=== Projects ==="
curl -s -H "Authorization: Bearer $TAIGA_TOKEN" \
  "$TAIGA_BASE/projects?member=$(curl -s -H "Authorization: Bearer $TAIGA_TOKEN" "$TAIGA_BASE/users/me" | jq -r '.id')&order_by=-modified_date" \
  | jq -r '.[] | "\(.id)\t\(.name[0:30])\t\(.is_private)\tstories=\(.total_story_points // 0)"' | column -t | head -20

echo ""
echo "=== Project Details ==="
PROJECT_ID="${1:?Project ID required}"
curl -s -H "Authorization: Bearer $TAIGA_TOKEN" \
  "$TAIGA_BASE/projects/$PROJECT_ID" \
  | jq '{name, description: .description[0:80], members: .members | length, is_backlog_activated, is_kanban_activated, total_story_points}'

echo ""
echo "=== Milestones (Sprints) ==="
curl -s -H "Authorization: Bearer $TAIGA_TOKEN" \
  "$TAIGA_BASE/milestones?project=$PROJECT_ID" \
  | jq -r '.[] | "\(.id)\t\(.name[0:25])\t\(.estimated_start)\t\(.estimated_finish)\tclosed=\(.closed)"' | column -t
```

## Analysis Phase

```bash
#!/bin/bash
TAIGA_BASE="${TAIGA_URL:-https://api.taiga.io}/api/v1"
PROJECT_ID="${1:?Project ID required}"

echo "=== User Stories by Status ==="
curl -s -H "Authorization: Bearer $TAIGA_TOKEN" \
  "$TAIGA_BASE/userstories?project=$PROJECT_ID" \
  | jq '[.[].status_extra_info.name] | group_by(.) | map({status: .[0], count: length}) | sort_by(-.count)[]'

echo ""
echo "=== Open Sprint Issues ==="
SPRINT_ID=$(curl -s -H "Authorization: Bearer $TAIGA_TOKEN" \
  "$TAIGA_BASE/milestones?project=$PROJECT_ID&closed=false" | jq -r '.[0].id // empty')
if [ -n "$SPRINT_ID" ]; then
  curl -s -H "Authorization: Bearer $TAIGA_TOKEN" \
    "$TAIGA_BASE/userstories?milestone=$SPRINT_ID" \
    | jq -r '.[] | "#\(.ref)\t\(.subject[0:40])\t\(.status_extra_info.name)\tpts=\(.total_points // 0)"' | column -t
fi

echo ""
echo "=== Backlog (unassigned to sprint) ==="
curl -s -H "Authorization: Bearer $TAIGA_TOKEN" \
  "$TAIGA_BASE/userstories?project=$PROJECT_ID&milestone=null&status__is_closed=false" \
  | jq '{backlog_stories: length, total_points: [.[].total_points // 0] | add}'

echo ""
echo "=== Sprint Velocity ==="
curl -s -H "Authorization: Bearer $TAIGA_TOKEN" \
  "$TAIGA_BASE/milestones?project=$PROJECT_ID&closed=true&order_by=-estimated_finish" \
  | jq -r '.[:5][] | "\(.name[0:25])\t\(.closed_points // 0)/\(.total_points // 0) pts\t\(.estimated_start) - \(.estimated_finish)"' | column -t
```

## Output Format

```
TAIGA PROJECT HEALTH: [project_name]
Total Stories:     [count]
Backlog Size:      [count] stories ([n] pts)
Active Sprint:     [name]
Members:           [count]

STATUS DISTRIBUTION
Status           Stories  Points
New              [n]      [n]
In Progress      [n]      [n]
Done             [n]      [n]

SPRINT VELOCITY (Last 5)
Sprint           Completed  Total   Velocity
[name]           [n]pts     [n]pts  [pct]%
```
