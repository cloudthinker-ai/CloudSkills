---
name: managing-shortcut-pm
description: |
  Shortcut (formerly Clubhouse) project management covering stories, epics, iterations, workflows, and team analytics. Use when auditing Shortcut usage, managing stories and epics, analyzing iteration velocity, or reviewing workflow health across a Shortcut workspace.
connection_type: shortcut
preload: false
---

# Managing Shortcut

Shortcut project management analysis and operations via the Shortcut REST API.

## Discovery Phase

```bash
#!/bin/bash
SC_BASE="https://api.app.shortcut.com/api/v3"

echo "=== Current Member ==="
curl -s -H "Shortcut-Token: $SHORTCUT_TOKEN" \
  "$SC_BASE/member" | jq '{id, profile: {name: .profile.name, email: .profile.email_address}}'

echo ""
echo "=== Workflows ==="
curl -s -H "Shortcut-Token: $SHORTCUT_TOKEN" \
  "$SC_BASE/workflows" \
  | jq -r '.[] | "\(.id)\t\(.name)\tstates: \([.states[].name] | join(" -> "))"'

echo ""
echo "=== Projects ==="
curl -s -H "Shortcut-Token: $SHORTCUT_TOKEN" \
  "$SC_BASE/projects" \
  | jq -r '.[] | "\(.id)\t\(.name[0:30])\t\(.num_stories) stories\t\(if .archived then "archived" else "active" end)"' | column -t

echo ""
echo "=== Epics (active) ==="
curl -s -H "Shortcut-Token: $SHORTCUT_TOKEN" \
  "$SC_BASE/epics" \
  | jq -r '.[] | select(.archived == false) | "\(.id)\t\(.name[0:35])\t\(.state)\tstories=\(.stats.num_stories_total)"' \
  | column -t | head -20

echo ""
echo "=== Current Iteration ==="
curl -s -H "Shortcut-Token: $SHORTCUT_TOKEN" \
  "$SC_BASE/iterations" \
  | jq -r '.[] | select(.status == "started") | "\(.id)\t\(.name)\t\(.start_date)\t\(.end_date)\tstories=\(.stats.num_stories_total)"'
```

## Analysis Phase

```bash
#!/bin/bash
SC_BASE="https://api.app.shortcut.com/api/v3"

echo "=== Story Search ==="
curl -s -H "Shortcut-Token: $SHORTCUT_TOKEN" \
  -H "Content-Type: application/json" \
  -X POST "$SC_BASE/search/stories" \
  -d '{"query": "state:\"In Progress\"", "page_size": 20}' \
  | jq -r '.data[] | "sc-\(.id)\t\(.name[0:40])\t\(.story_type)\t\(.owners | map(.profile.name) | join(",") // "unassigned")"' | column -t

echo ""
echo "=== Iteration Velocity ==="
curl -s -H "Shortcut-Token: $SHORTCUT_TOKEN" \
  "$SC_BASE/iterations" \
  | jq -r '[.[] | select(.status == "done")] | sort_by(-.end_date)[:5][] | "\(.name[0:25])\t\(.stats.num_stories_done)/\(.stats.num_stories_total) stories\t\(.stats.num_points_done // 0)/\(.stats.num_points_total // 0) pts"' | column -t

echo ""
echo "=== Unestimated Stories ==="
curl -s -H "Shortcut-Token: $SHORTCUT_TOKEN" \
  -H "Content-Type: application/json" \
  -X POST "$SC_BASE/search/stories" \
  -d '{"query": "!is:done !is:archived estimate:none", "page_size": 5}' \
  | jq '{unestimated_count: (.total // (.data | length))}'

echo ""
echo "=== Label Distribution ==="
curl -s -H "Shortcut-Token: $SHORTCUT_TOKEN" \
  "$SC_BASE/labels" \
  | jq -r '.[] | select(.stats.num_stories_total > 0) | "\(.name)\t\(.stats.num_stories_total) stories\t\(.stats.num_stories_in_progress // 0) in progress"' | sort -t$'\t' -k2 -rn | column -t | head -15
```

## Output Format

```
SHORTCUT WORKSPACE HEALTH
User:            [name] ([email])
Projects:        [count] ([active] active)
Epics:           [count] ([active] active)
Current Sprint:  [name] ([start] - [end])

WORKFLOW STATUS
State            Stories  Points
To Do            [n]      [n]
In Progress      [n]      [n]
Done             [n]      [n]

ITERATION VELOCITY (Last 5)
Iteration        Stories Done  Points Done
[name]           [n]/[total]   [n]/[total]
```
