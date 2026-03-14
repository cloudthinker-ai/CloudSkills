---
name: managing-pivotal-tracker
description: |
  Pivotal Tracker project management covering projects, stories, epics, iterations, and velocity analytics. Use when auditing Pivotal Tracker usage, managing stories and epics, analyzing iteration velocity, or reviewing backlog health across Pivotal Tracker projects.
connection_type: pivotal-tracker
preload: false
---

# Managing Pivotal Tracker

Pivotal Tracker project management analysis via the Pivotal Tracker REST API.

## Discovery Phase

```bash
#!/bin/bash
PT_BASE="https://www.pivotaltracker.com/services/v5"

echo "=== Current User ==="
curl -s -H "X-TrackerToken: $PIVOTAL_TOKEN" \
  "$PT_BASE/me" | jq '{id, name, email, initials, kind}'

echo ""
echo "=== Projects ==="
curl -s -H "X-TrackerToken: $PIVOTAL_TOKEN" \
  "$PT_BASE/projects" \
  | jq -r '.[] | "\(.id)\t\(.name[0:30])\t\(.current_velocity)\tvel\t\(.iteration_length) week sprints"' | column -t

echo ""
PROJECT_ID="${1:?Project ID required}"
echo "=== Project Details ==="
curl -s -H "X-TrackerToken: $PIVOTAL_TOKEN" \
  "$PT_BASE/projects/$PROJECT_ID" \
  | jq '{name, point_scale, current_velocity, iteration_length, number_of_done_iterations_to_show, start_date}'

echo ""
echo "=== Memberships ==="
curl -s -H "X-TrackerToken: $PIVOTAL_TOKEN" \
  "$PT_BASE/projects/$PROJECT_ID/memberships" \
  | jq -r '.[] | "\(.person.name)\t\(.role)\t\(.person.email)"' | column -t

echo ""
echo "=== Epics ==="
curl -s -H "X-TrackerToken: $PIVOTAL_TOKEN" \
  "$PT_BASE/projects/$PROJECT_ID/epics" \
  | jq -r '.[] | "\(.id)\t\(.name[0:35])\t\(.label.name // "none")"' | column -t
```

## Analysis Phase

```bash
#!/bin/bash
PT_BASE="https://www.pivotaltracker.com/services/v5"
PROJECT_ID="${1:?Project ID required}"

echo "=== Current Iteration ==="
curl -s -H "X-TrackerToken: $PIVOTAL_TOKEN" \
  "$PT_BASE/projects/$PROJECT_ID/iterations?scope=current" \
  | jq -r '.[0] | "Iteration \(.number): \(.start[0:10]) to \(.finish[0:10])\nStories: \(.stories | length)\nPoints: \([.stories[].estimate // 0] | add)"'

echo ""
echo "=== Current Iteration Stories ==="
curl -s -H "X-TrackerToken: $PIVOTAL_TOKEN" \
  "$PT_BASE/projects/$PROJECT_ID/iterations?scope=current" \
  | jq -r '.[0].stories[] | "\(.id)\t\(.story_type)\t\(.current_state)\t\(.estimate // "-")pts\t\(.name[0:40])"' | column -t

echo ""
echo "=== Backlog Stories ==="
curl -s -H "X-TrackerToken: $PIVOTAL_TOKEN" \
  "$PT_BASE/projects/$PROJECT_ID/stories?with_state=unstarted&limit=15" \
  | jq -r '.[] | "\(.id)\t\(.story_type)\t\(.estimate // "-")pts\t\(.name[0:40])"' | column -t

echo ""
echo "=== Velocity (last 5 iterations) ==="
curl -s -H "X-TrackerToken: $PIVOTAL_TOKEN" \
  "$PT_BASE/projects/$PROJECT_ID/iterations?scope=done&limit=5&offset=-5" \
  | jq -r '.[] | "Iter \(.number)\t\(.start[0:10])\t\([.stories[] | select(.current_state == "accepted") | .estimate // 0] | add) pts accepted"' | column -t

echo ""
echo "=== Blockers ==="
curl -s -H "X-TrackerToken: $PIVOTAL_TOKEN" \
  "$PT_BASE/projects/$PROJECT_ID/stories?filter=has:blockers" \
  | jq -r '.[:10][] | "\(.id)\t\(.name[0:40])\t\(.current_state)"' | column -t
```

## Output Format

```
PIVOTAL TRACKER HEALTH: [project_name]
Velocity:       [current_velocity] pts/iteration
Sprint Length:   [n] weeks
Current Sprint:  Iteration [n]

CURRENT ITERATION
Type         State       Count  Points
feature      accepted    [n]    [n]
bug          started     [n]    -
chore        unstarted   [n]    -

VELOCITY TREND (Last 5)
Iteration    Accepted Points
[n]          [pts]

BACKLOG
Unestimated Stories:  [count]
Total Backlog:        [count] stories
Blocked Stories:      [count]
```
