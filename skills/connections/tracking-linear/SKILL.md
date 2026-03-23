---
name: tracking-linear
description: |
  Use when working with Linear — linear project management for engineering
  teams. Covers issue tracking, sprint cycles, project roadmaps, team
  management, and workflow automation. Use when querying Linear issues, managing
  sprints, analyzing team velocity, searching for tickets, or creating/updating
  issues via the Linear GraphQL API.
connection_type: linear
preload: false
---

# Linear Project Management Skill

Manage and analyze Linear issues, cycles, projects, and team workflows.

## API Overview

Linear uses a **GraphQL API** — all queries use POST to `https://api.linear.app/graphql`.

### Core Helper Function

```bash
#!/bin/bash

linear_gql() {
    local query="$1"
    curl -s -X POST "https://api.linear.app/graphql" \
        -H "Authorization: $LINEAR_API_KEY" \
        -H "Content-Type: application/json" \
        -d "{\"query\": $(echo "$query" | jq -Rs .)}"
}
```

## MANDATORY: Discovery-First Pattern

**Always discover teams, projects, and workflow states before querying specific issues.**

### Phase 1: Discovery

```bash
#!/bin/bash

echo "=== Teams ==="
linear_gql '{ teams { nodes { id name key } } }' \
    | jq -r '.data.teams.nodes[] | "\(.key)\t\(.name)\t\(.id)"' | column -t

echo ""
echo "=== Workflow States (per team) ==="
linear_gql '{ teams { nodes { name states { nodes { id name type } } } } }' \
    | jq -r '.data.teams.nodes[] | .name as $team | .states.nodes[] | "\($team)\t\(.type)\t\(.name)\t\(.id)"' \
    | column -t

echo ""
echo "=== Projects ==="
linear_gql '{ projects(first: 20) { nodes { id name state teams { nodes { key } } } } }' \
    | jq -r '.data.projects.nodes[] | "\(.name)\t\(.state)\t\(.teams.nodes | map(.key) | join(","))"' \
    | column -t

echo ""
echo "=== Active Cycles ==="
linear_gql '{ cycles(filter: { isActive: { eq: true } }) { nodes { id name startsAt endsAt team { name } } } }' \
    | jq -r '.data.cycles.nodes[] | "\(.team.name)\t\(.name)\t\(.startsAt[0:10])\t\(.endsAt[0:10])"' \
    | column -t
```

## Common Operations

### Issue Search & Filtering

```bash
#!/bin/bash
TEAM_KEY="${1:-}"
STATUS="${2:-}"
ASSIGNEE="${3:-}"

echo "=== Issues ==="
FILTER="first: 25, orderBy: updatedAt"

if [ -n "$TEAM_KEY" ]; then
    linear_gql "{
        team(id: \"${TEAM_KEY}\") {
            issues(first: 25, orderBy: updatedAt) {
                nodes {
                    id identifier title state { name type } assignee { name }
                    priority createdAt updatedAt
                }
            }
        }
    }" | jq -r '.data.team.issues.nodes[] | "\(.identifier)\t\(.state.name)\t\(.priority)\t\(.assignee.name // "unassigned")\t\(.title[0:50])"' \
    | column -t
else
    linear_gql "{
        issues(first: 25, orderBy: updatedAt) {
            nodes {
                id identifier title state { name type } assignee { name }
                team { key } priority
            }
        }
    }" | jq -r '.data.issues.nodes[] | "\(.identifier)\t\(.state.name)\t\(.team.key)\t\(.assignee.name // "unassigned")\t\(.title[0:50])"' \
    | column -t
fi
```

### Sprint / Cycle Analysis

```bash
#!/bin/bash
TEAM_KEY="${1:?Team key required (e.g., ENG)}"

echo "=== Active Cycle Issues ==="
linear_gql "{
    cycles(filter: { isActive: { eq: true }, team: { key: { eq: \"${TEAM_KEY}\" } } }) {
        nodes {
            name startsAt endsAt
            issues(first: 50) {
                nodes {
                    identifier title
                    state { name type }
                    assignee { name }
                    estimate
                }
            }
        }
    }
}" | jq -r '
    .data.cycles.nodes[] as $cycle |
    "Cycle: \($cycle.name) (\($cycle.startsAt[0:10]) to \($cycle.endsAt[0:10]))",
    "---",
    ($cycle.issues.nodes[] | "\(.identifier)\t\(.state.name)\t\(.estimate // 0)pts\t\(.assignee.name // "unassigned")\t\(.title[0:50])")
' | column -t | head -40

echo ""
echo "=== Cycle Progress Summary ==="
linear_gql "{
    cycles(filter: { isActive: { eq: true }, team: { key: { eq: \"${TEAM_KEY}\" } } }) {
        nodes {
            name
            issues(first: 100) {
                nodes { state { type } estimate }
            }
        }
    }
}" | jq '
    .data.cycles.nodes[0] |
    .issues.nodes |
    {
        total: length,
        completed: [.[] | select(.state.type == "completed")] | length,
        in_progress: [.[] | select(.state.type == "started")] | length,
        todo: [.[] | select(.state.type == "unstarted" or .state.type == "backlog")] | length,
        total_points: [.[].estimate // 0] | add,
        completed_points: [.[] | select(.state.type == "completed") | .estimate // 0] | add
    }
'
```

### Team Velocity Analysis

```bash
#!/bin/bash
TEAM_KEY="${1:?Team key required}"

echo "=== Last 4 Cycle Velocities ==="
linear_gql "{
    cycles(filter: { team: { key: { eq: \"${TEAM_KEY}\" } } }, last: 4) {
        nodes {
            name startsAt endsAt
            completedIssuesCount: issues(filter: { state: { type: { eq: completed } } }) { nodes { estimate } }
        }
    }
}" | jq -r '
    .data.cycles.nodes[] |
    "\(.name[0:20])\t\(.startsAt[0:10])\tCompleted: \(.completedIssuesCount.nodes | length) issues\t\([.completedIssuesCount.nodes[].estimate // 0] | add)pts"
' | column -t 2>/dev/null || echo "Cycle data requires specific team permissions"
```

### Project Roadmap

```bash
#!/bin/bash
PROJECT_NAME="${1:-}"

if [ -n "$PROJECT_NAME" ]; then
    echo "=== Project: $PROJECT_NAME ==="
    linear_gql "{
        projects(filter: { name: { containsIgnoreCase: \"${PROJECT_NAME}\" } }, first: 1) {
            nodes {
                name state description
                startDate targetDate
                teams { nodes { key name } }
                issues(first: 30) {
                    nodes {
                        identifier title state { name type } priority
                        dueDate assignee { name }
                    }
                }
            }
        }
    }" | jq -r '
        .data.projects.nodes[0] |
        "Project: \(.name) | State: \(.state) | Target: \(.targetDate // "none")",
        "Teams: \(.teams.nodes | map(.key) | join(", "))",
        "",
        "Issues:",
        (.issues.nodes[] | "\(.identifier)\t\(.state.name)\t\(.priority)\t\(.assignee.name // "unassigned")\t\(.title[0:50])")
    ' | column -t
else
    echo "=== All Projects ==="
    linear_gql '{ projects(first: 20) { nodes { name state startDate targetDate issueCount } } }' \
        | jq -r '.data.projects.nodes[] | "\(.name)\t\(.state)\t\(.issueCount) issues\tTarget: \(.targetDate // "none")"' \
        | column -t
fi
```

### Create Issue (when explicitly requested)

```bash
#!/bin/bash
TEAM_ID="${1:?Team ID required}"
TITLE="${2:?Title required}"
DESCRIPTION="${3:-}"
PRIORITY="${4:-0}"  # 0=no priority, 1=urgent, 2=high, 3=medium, 4=low

echo "=== Creating Linear Issue ==="
linear_gql "
    mutation {
        issueCreate(input: {
            teamId: \"${TEAM_ID}\"
            title: $(echo "$TITLE" | jq -Rs .)
            description: $(echo "$DESCRIPTION" | jq -Rs .)
            priority: ${PRIORITY}
        }) {
            success
            issue { id identifier title url }
        }
    }
" | jq '.data.issueCreate | {success: .success, id: .issue.identifier, url: .issue.url}'
```

### Search Issues

```bash
#!/bin/bash
QUERY="${1:?Search query required}"

echo "=== Search: $QUERY ==="
linear_gql "{
    issueSearch(query: $(echo "$QUERY" | jq -Rs .), first: 15) {
        nodes {
            identifier title
            state { name }
            assignee { name }
            team { key }
            priority
            updatedAt
        }
    }
}" | jq -r '.data.issueSearch.nodes[] | "\(.identifier)\t\(.state.name)\t\(.team.key)\t\(.assignee.name // "unassigned")\t\(.title[0:50])"' \
    | column -t
```

### Issue Detail

```bash
#!/bin/bash
ISSUE_ID="${1:?Issue ID required (e.g., ENG-123)}"

echo "=== Issue: $ISSUE_ID ==="
linear_gql "{
    issue(id: \"${ISSUE_ID}\") {
        identifier title description
        state { name type }
        assignee { name email }
        team { key name }
        priority priorityLabel
        estimate
        dueDate
        createdAt updatedAt
        project { name }
        cycle { name }
        parent { identifier title }
        children { nodes { identifier title state { name } } }
        labels { nodes { name color } }
    }
}" | jq '{
    id: .data.issue.identifier,
    title: .data.issue.title,
    state: .data.issue.state.name,
    assignee: .data.issue.assignee.name,
    priority: .data.issue.priorityLabel,
    estimate: .data.issue.estimate,
    due: .data.issue.dueDate,
    project: .data.issue.project.name,
    cycle: .data.issue.cycle.name,
    labels: [.data.issue.labels.nodes[].name],
    children: [.data.issue.children.nodes[] | "\(.identifier): \(.title)"]
}'
```

## Output Format

Present results as a structured report:
```
Tracking Linear Report
══════════════════════
Resources discovered: [count]

Resource       Status    Key Metric    Issues
──────────────────────────────────────────────
[name]         [ok/warn] [value]       [findings]

Summary: [total] resources | [ok] healthy | [warn] warnings | [crit] critical
Action Items: [list of prioritized findings]
```

Target ≤50 lines of output. Use tables for multi-resource comparisons.

## Anti-Hallucination Rules

1. **NEVER assume resource names** — always discover via CLI/API in Phase 1 before referencing in Phase 2.
2. **NEVER fabricate metric names or dimensions** — verify against the service documentation or `--help` output.
3. **NEVER mix CLI commands between service versions** — confirm which version/API you are targeting.
4. **ALWAYS use the discovery → verify → analyze chain** — every resource referenced must have been discovered first.
5. **ALWAYS handle empty results gracefully** — an empty response is valid data, not an error to retry.

## Counter-Rationalizations

| Shortcut | Counter | Why |
|----------|---------|-----|
| "I'll skip discovery and check known resources" | Always run Phase 1 discovery first | Resource names change, new resources appear — assumed names cause errors |
| "The user only asked for a quick check" | Follow the full discovery → analysis flow | Quick checks miss critical issues; structured analysis catches silent failures |
| "Default configuration is probably fine" | Audit configuration explicitly | Defaults often leave logging, security, and optimization features disabled |
| "Metrics aren't needed for this" | Always check relevant metrics when available | API/CLI responses show current state; metrics reveal trends and intermittent issues |
| "I don't have access to that" | Try the command and report the actual error | Assumed permission failures prevent useful investigation; actual errors are informative |

## Common Pitfalls

- **GraphQL vs REST**: Linear uses GraphQL only — all queries are POST to `/graphql`, not REST GET/POST
- **Team key vs team ID**: `key` is short (e.g., `ENG`), `id` is UUID — queries that filter by team often need the UUID
- **Pagination with `first`/`after`**: Linear uses cursor-based pagination — check `pageInfo.hasNextPage` and `pageInfo.endCursor`
- **State type vs name**: `state.type` is canonical (`completed`, `started`, `unstarted`, `backlog`, `cancelled`); `state.name` is team-specific
- **Priority numbering**: 0=no priority, 1=urgent, 2=high, 3=medium, 4=low (reversed from common sense)
- **Rate limits**: Linear API has rate limits — add `sleep 0.2` between batch mutations
- **Issue identifier vs ID**: `identifier` is human-readable (e.g., `ENG-123`); `id` is internal UUID — use identifier for display, id for API calls
- **Cycle filter**: `isActive` filter finds the current running cycle — completed cycles need date-based filtering
