---
name: managing-youtrack
description: |
  JetBrains YouTrack issue tracking covering projects, issues, agile boards, sprints, and workflow analytics. Use when auditing YouTrack usage, managing issues and agile boards, analyzing sprint progress, or reviewing project health across a YouTrack instance.
connection_type: youtrack
preload: false
---

# Managing YouTrack

YouTrack issue tracking and agile management via the YouTrack REST API.

## Discovery Phase

```bash
#!/bin/bash
YT_BASE="${YOUTRACK_URL}/api"

echo "=== Current User ==="
curl -s -H "Authorization: Bearer $YOUTRACK_TOKEN" \
  "$YT_BASE/users/me?fields=id,login,name,email" | jq '.'

echo ""
echo "=== Projects ==="
curl -s -H "Authorization: Bearer $YOUTRACK_TOKEN" \
  "$YT_BASE/admin/projects?fields=id,shortName,name,archived,leader(name)&\$top=25" \
  | jq -r '.[] | "\(.shortName)\t\(.name[0:30])\t\(.leader.name // "none")\t\(if .archived then "archived" else "active" end)"' | column -t

echo ""
echo "=== Agile Boards ==="
curl -s -H "Authorization: Bearer $YOUTRACK_TOKEN" \
  "$YT_BASE/agiles?fields=id,name,projects(shortName),sprints(name,start,finish,isDefault)&\$top=10" \
  | jq -r '.[] | "\(.id)\t\(.name[0:30])\tprojects=\([.projects[].shortName] | join(","))"' | column -t

echo ""
echo "=== Saved Searches ==="
curl -s -H "Authorization: Bearer $YOUTRACK_TOKEN" \
  "$YT_BASE/savedQueries?fields=id,name,query&\$top=10" \
  | jq -r '.[] | "\(.name[0:30])\t\(.query)"' | column -t
```

## Analysis Phase

```bash
#!/bin/bash
YT_BASE="${YOUTRACK_URL}/api"
PROJECT="${1:?Project short name required}"

echo "=== Issue Counts by State ==="
for STATE in "Open" "In Progress" "Fixed" "Verified"; do
  COUNT=$(curl -s -H "Authorization: Bearer $YOUTRACK_TOKEN" \
    "$YT_BASE/issues?query=project:$PROJECT+State:+{$STATE}&fields=id&\$top=1" \
    -w "\n%{http_code}" | head -1 | jq '. | length')
  echo -e "$STATE\t$COUNT"
done | column -t

echo ""
echo "=== Recent Issues ==="
curl -s -H "Authorization: Bearer $YOUTRACK_TOKEN" \
  "$YT_BASE/issues?query=project:$PROJECT+sort+by:updated+desc&fields=idReadable,summary,customFields(name,value(name))&\$top=15" \
  | jq -r '.[] | "\(.idReadable)\t\(.summary[0:40])\t\([.customFields[] | select(.name == "State") | .value.name] | first // "unknown")"' | column -t

echo ""
echo "=== Unresolved by Priority ==="
curl -s -H "Authorization: Bearer $YOUTRACK_TOKEN" \
  "$YT_BASE/issues?query=project:$PROJECT+%23Unresolved+sort+by:Priority&fields=idReadable,summary,customFields(name,value(name))&\$top=20" \
  | jq -r '.[] | "\(.idReadable)\t\([.customFields[] | select(.name == "Priority") | .value.name] | first // "normal")\t\(.summary[0:45])"' | column -t

echo ""
echo "=== Sprint Progress ==="
AGILE_ID=$(curl -s -H "Authorization: Bearer $YOUTRACK_TOKEN" \
  "$YT_BASE/agiles?fields=id,name,projects(shortName)&\$top=10" \
  | jq -r ".[] | select(.projects | any(.shortName == \"$PROJECT\")) | .id" | head -1)
if [ -n "$AGILE_ID" ]; then
  curl -s -H "Authorization: Bearer $YOUTRACK_TOKEN" \
    "$YT_BASE/agiles/$AGILE_ID/sprints?fields=name,start,finish,isDefault,resolved,unresolvedIssuesCount&\$top=5" \
    | jq -r '.[] | "\(.name[0:25])\t\(.start[0:10] // "N/A")\tunresolved=\(.unresolvedIssuesCount // "N/A")"' | column -t
fi
```

## Output Format

```
YOUTRACK PROJECT HEALTH: [PROJECT]
Total Issues:      [count]
Unresolved:        [count]
Active Sprints:    [count]

STATE DISTRIBUTION
State            Count
Open             [n]
In Progress      [n]
Fixed            [n]

PRIORITY BREAKDOWN (Unresolved)
Priority         Count
Critical         [n]
Major            [n]
Normal           [n]

SPRINT PROGRESS
Sprint           Unresolved  Period
[name]           [n]         [start] - [finish]
```
