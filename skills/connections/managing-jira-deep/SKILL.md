---
name: managing-jira-deep
description: |
  Deep Jira project management covering projects, boards, sprints, issue analytics, velocity tracking, and workflow health. Use when performing deep audits of Jira usage, analyzing sprint velocity, reviewing backlog health, assessing workflow bottlenecks, or generating project health reports across a Jira instance.
connection_type: atlassian
preload: false
---

# Managing Jira (Deep)

Deep Jira project management analysis covering sprint health, velocity, and workflow bottlenecks via the Jira REST API.

## Discovery Phase

```bash
#!/bin/bash
JIRA_BASE="$JIRA_URL/rest/api/3"
AGILE_BASE="$JIRA_URL/rest/agile/1.0"

echo "=== Current User ==="
curl -s -H "Authorization: Bearer $ATLASSIAN_TOKEN" \
  "$JIRA_BASE/myself" | jq '{accountId, displayName, emailAddress}'

echo ""
echo "=== Projects ==="
curl -s -H "Authorization: Bearer $ATLASSIAN_TOKEN" \
  "$JIRA_BASE/project?maxResults=30" \
  | jq -r '.[] | "\(.key)\t\(.name[0:30])\t\(.projectTypeKey)\t\(.lead.displayName // "none")"' | column -t

echo ""
echo "=== Boards ==="
curl -s -H "Authorization: Bearer $ATLASSIAN_TOKEN" \
  "$AGILE_BASE/board?maxResults=20" \
  | jq -r '.values[] | "\(.id)\t\(.name[0:30])\t\(.type)\t\(.location.projectKey // "N/A")"' | column -t

echo ""
echo "=== Active Sprints ==="
for BOARD_ID in $(curl -s -H "Authorization: Bearer $ATLASSIAN_TOKEN" \
  "$AGILE_BASE/board?maxResults=10" | jq -r '.values[].id'); do
  curl -s -H "Authorization: Bearer $ATLASSIAN_TOKEN" \
    "$AGILE_BASE/board/$BOARD_ID/sprint?state=active" \
    | jq -r '.values[]? | "\(.id)\t\(.name[0:30])\t\(.startDate[0:10])\t\(.endDate[0:10])"'
done | column -t
```

## Analysis Phase

```bash
#!/bin/bash
JIRA_BASE="$JIRA_URL/rest/api/3"
AGILE_BASE="$JIRA_URL/rest/agile/1.0"
PROJECT_KEY="${1:?Project key required}"

echo "=== Issue Status Distribution ==="
curl -s -H "Authorization: Bearer $ATLASSIAN_TOKEN" \
  "$JIRA_BASE/search?jql=project=$PROJECT_KEY&maxResults=0&groupBy=status" \
  -G --data-urlencode "jql=project = \"$PROJECT_KEY\"" | jq '.total'

for STATUS in "To Do" "In Progress" "In Review" "Done"; do
  COUNT=$(curl -s -H "Authorization: Bearer $ATLASSIAN_TOKEN" \
    "$JIRA_BASE/search?maxResults=0" \
    -G --data-urlencode "jql=project = \"$PROJECT_KEY\" AND status = \"$STATUS\"" | jq '.total')
  echo -e "$STATUS\t$COUNT issues"
done | column -t

echo ""
echo "=== Unassigned Issues ==="
curl -s -H "Authorization: Bearer $ATLASSIAN_TOKEN" \
  "$JIRA_BASE/search?maxResults=0" \
  -G --data-urlencode "jql=project = \"$PROJECT_KEY\" AND assignee IS EMPTY AND status != Done" \
  | jq '{unassigned_open_issues: .total}'

echo ""
echo "=== Sprint Velocity (last 3 closed sprints) ==="
BOARD_ID=$(curl -s -H "Authorization: Bearer $ATLASSIAN_TOKEN" \
  "$AGILE_BASE/board?projectKeyOrId=$PROJECT_KEY&maxResults=1" | jq -r '.values[0].id')
curl -s -H "Authorization: Bearer $ATLASSIAN_TOKEN" \
  "$AGILE_BASE/board/$BOARD_ID/sprint?state=closed&maxResults=3" \
  | jq -r '.values[]? | "\(.name[0:25])\t\(.startDate[0:10])\t\(.endDate[0:10])\tcompleteDate=\(.completeDate[0:10])"' | column -t

echo ""
echo "=== Overdue Issues ==="
curl -s -H "Authorization: Bearer $ATLASSIAN_TOKEN" \
  "$JIRA_BASE/search?maxResults=10" \
  -G --data-urlencode "jql=project = \"$PROJECT_KEY\" AND duedate < now() AND status != Done ORDER BY duedate ASC" \
  | jq -r '.issues[]? | "\(.key)\t\(.fields.summary[0:40])\tdue=\(.fields.duedate)\t\(.fields.assignee.displayName // "unassigned")"' | column -t
```

## Output Format

```
JIRA DEEP HEALTH: [PROJECT_KEY]
Total Issues:      [count]
Open Issues:       [count]
Unassigned Open:   [count]
Overdue:           [count]

STATUS DISTRIBUTION
Status           Count    Pct
To Do            [n]      [pct]%
In Progress      [n]      [pct]%
Done             [n]      [pct]%

SPRINT VELOCITY (Last 3)
Sprint               Completed  Committed  Velocity
[name]               [n]pts     [n]pts     [pct]%

BOTTLENECKS
Avg Days in Review:  [n]
Blocked Issues:      [count]
```
