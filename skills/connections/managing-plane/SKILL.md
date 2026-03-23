---
name: managing-plane
description: |
  Use when working with Plane — plane project management covering workspaces,
  projects, issues, cycles, and modules. Use when auditing Plane workspace
  usage, managing issues and cycles, analyzing project health, or reviewing team
  workload across a Plane instance.
connection_type: plane
preload: false
---

# Managing Plane

Plane project management analysis and operations via the Plane REST API.

## Discovery Phase

```bash
#!/bin/bash
PLANE_BASE="${PLANE_URL:-https://api.plane.so}/api/v1"
WORKSPACE="${1:?Workspace slug required}"

echo "=== Workspace Info ==="
curl -s -H "X-API-Key: $PLANE_API_KEY" \
  "$PLANE_BASE/workspaces/$WORKSPACE/" \
  | jq '{name, slug, total_members, created_at}'

echo ""
echo "=== Projects ==="
curl -s -H "X-API-Key: $PLANE_API_KEY" \
  "$PLANE_BASE/workspaces/$WORKSPACE/projects/" \
  | jq -r '.results[]? // .[]? | "\(.id)\t\(.identifier)\t\(.name[0:30])\t\(.network) network"' | column -t

echo ""
echo "=== Members ==="
curl -s -H "X-API-Key: $PLANE_API_KEY" \
  "$PLANE_BASE/workspaces/$WORKSPACE/members/" \
  | jq -r '.results[]? // .[]? | "\(.member.display_name)\t\(.role_name // .role)\t\(.member.email)"' | column -t

echo ""
echo "=== States ==="
PROJECT_ID="${2:-}"
if [ -n "$PROJECT_ID" ]; then
  curl -s -H "X-API-Key: $PLANE_API_KEY" \
    "$PLANE_BASE/workspaces/$WORKSPACE/projects/$PROJECT_ID/states/" \
    | jq -r '.results[]? // .[]? | "\(.id)\t\(.name)\t\(.group)"' | column -t
fi
```

## Analysis Phase

```bash
#!/bin/bash
PLANE_BASE="${PLANE_URL:-https://api.plane.so}/api/v1"
WORKSPACE="${1:?Workspace slug required}"
PROJECT_ID="${2:?Project ID required}"

echo "=== Issues Overview ==="
curl -s -H "X-API-Key: $PLANE_API_KEY" \
  "$PLANE_BASE/workspaces/$WORKSPACE/projects/$PROJECT_ID/issues/" \
  | jq -r '.results[]? // .[]? | "\(.sequence_id)\t\(.name[0:40])\t\(.state_detail.name // "unknown")\t\(.priority)\t\(.assignee_detail.display_name // "unassigned")"' \
  | column -t | head -25

echo ""
echo "=== Active Cycles ==="
curl -s -H "X-API-Key: $PLANE_API_KEY" \
  "$PLANE_BASE/workspaces/$WORKSPACE/projects/$PROJECT_ID/cycles/" \
  | jq -r '.results[]? // .[]? | select(.status == "current" or .status == "upcoming") | "\(.name[0:30])\t\(.status)\t\(.start_date)\t\(.end_date)\tissues=\(.total_issues)"' | column -t

echo ""
echo "=== Modules ==="
curl -s -H "X-API-Key: $PLANE_API_KEY" \
  "$PLANE_BASE/workspaces/$WORKSPACE/projects/$PROJECT_ID/modules/" \
  | jq -r '.results[]? // .[]? | "\(.name[0:30])\t\(.status)\tissues=\(.total_issues)\tcompleted=\(.completed_issues)"' | column -t

echo ""
echo "=== Labels ==="
curl -s -H "X-API-Key: $PLANE_API_KEY" \
  "$PLANE_BASE/workspaces/$WORKSPACE/projects/$PROJECT_ID/labels/" \
  | jq -r '.results[]? // .[]? | "\(.name)\t\(.color)"' | column -t
```

## Output Format

```
PLANE PROJECT HEALTH: [project_name]
Workspace:     [name]
Total Issues:  [count]
Members:       [count]

ISSUE STATUS DISTRIBUTION
State          Count   Priority Breakdown
Backlog        [n]     urgent=[n] high=[n]
In Progress    [n]     urgent=[n] high=[n]
Done           [n]

CYCLE HEALTH
Cycle              Status    Issues  Completed
[name]             current   [n]     [n]

MODULE PROGRESS
Module             Issues  Completed  Progress
[name]             [n]     [n]        [pct]%
```

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

