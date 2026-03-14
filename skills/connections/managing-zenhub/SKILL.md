---
name: managing-zenhub
description: |
  ZenHub project management covering workspaces, boards, epics, sprints, and velocity analytics layered on GitHub Issues. Use when auditing ZenHub usage, analyzing board pipelines, reviewing sprint progress, or assessing team velocity across ZenHub workspaces.
connection_type: zenhub
preload: false
---

# Managing ZenHub

ZenHub project management analysis via the ZenHub REST and GraphQL APIs.

## Discovery Phase

```bash
#!/bin/bash
ZENHUB_BASE="https://api.zenhub.com"
ZENHUB_GQL="https://api.zenhub.com/public/graphql"

echo "=== Current User ==="
curl -s -H "Authorization: Bearer $ZENHUB_TOKEN" \
  -H "Content-Type: application/json" \
  -X POST "$ZENHUB_GQL" \
  -d '{"query": "{ viewer { id login } }"}' | jq '.data.viewer'

echo ""
echo "=== Workspaces ==="
curl -s -H "Authorization: Bearer $ZENHUB_TOKEN" \
  -H "Content-Type: application/json" \
  -X POST "$ZENHUB_GQL" \
  -d '{"query": "{ viewer { searchWorkspaces(query: \"\") { nodes { id name description } } } }"}' \
  | jq -r '.data.viewer.searchWorkspaces.nodes[] | "\(.id)\t\(.name[0:30])\t\(.description[0:40] // "")"' | column -t

echo ""
REPO_ID="${1:?GitHub Repo ID required}"
echo "=== Board Pipelines ==="
curl -s -H "X-Authentication-Token: $ZENHUB_TOKEN" \
  "$ZENHUB_BASE/p1/repositories/$REPO_ID/board" \
  | jq -r '.pipelines[] | "\(.id)\t\(.name)\t\(.issues | length) issues"' | column -t

echo ""
echo "=== Epics ==="
curl -s -H "X-Authentication-Token: $ZENHUB_TOKEN" \
  "$ZENHUB_BASE/p1/repositories/$REPO_ID/epics" \
  | jq -r '.epic_issues[] | "\(.issue_number)\t\(.repo_id)"' | head -15
```

## Analysis Phase

```bash
#!/bin/bash
ZENHUB_BASE="https://api.zenhub.com"
REPO_ID="${1:?GitHub Repo ID required}"

echo "=== Pipeline Distribution ==="
curl -s -H "X-Authentication-Token: $ZENHUB_TOKEN" \
  "$ZENHUB_BASE/p1/repositories/$REPO_ID/board" \
  | jq -r '.pipelines[] | "\(.name)\t\(.issues | length) issues\t\([.issues[].estimate.value // 0] | add) pts"' | column -t

echo ""
echo "=== Active Sprint ==="
WORKSPACE_ID="${2:-}"
if [ -n "$WORKSPACE_ID" ]; then
  curl -s -H "Authorization: Bearer $ZENHUB_TOKEN" \
    -H "Content-Type: application/json" \
    -X POST "https://api.zenhub.com/public/graphql" \
    -d "{\"query\": \"{ workspace(id: \\\"$WORKSPACE_ID\\\") { activeSprint { name startAt endAt } } }\"}" \
    | jq '.data.workspace.activeSprint'
fi

echo ""
echo "=== Epic Details ==="
EPIC_NUMBER="${3:-}"
if [ -n "$EPIC_NUMBER" ]; then
  curl -s -H "X-Authentication-Token: $ZENHUB_TOKEN" \
    "$ZENHUB_BASE/p1/repositories/$REPO_ID/epics/$EPIC_NUMBER" \
    | jq '{total_epic_estimates: .total_epic_estimates, issues_count: (.issues | length), pipeline_distribution: [.issues[] | .pipeline.name] | group_by(.) | map({pipeline: .[0], count: length})}'
fi

echo ""
echo "=== Issues with Estimates ==="
curl -s -H "X-Authentication-Token: $ZENHUB_TOKEN" \
  "$ZENHUB_BASE/p1/repositories/$REPO_ID/board" \
  | jq '[.pipelines[].issues[] | select(.estimate.value != null)] | length as $estimated | [.pipelines[].issues[]] | length as $total | {total: $total, estimated: $estimated, unestimated: ($total - $estimated)}'
```

## Output Format

```
ZENHUB BOARD HEALTH: [repo_name]
Total Issues:    [count]
Estimated:       [count]
Unestimated:     [count]

PIPELINE DISTRIBUTION
Pipeline         Issues  Points
New Issues       [n]     [n]
Backlog          [n]     [n]
In Progress      [n]     [n]
Review/QA        [n]     [n]
Done             [n]     [n]

ACTIVE SPRINT
Sprint:          [name]
Period:          [start] - [end]

EPIC PROGRESS
Epic             Issues  Completed
[title]          [n]     [n]
```
