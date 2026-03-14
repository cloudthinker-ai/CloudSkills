---
name: managing-railway
description: |
  Railway platform management via the railway CLI and Railway API. Covers projects, services, deployments, databases, volumes, and environment variables. Use when managing Railway deployments or checking service health.
connection_type: railway
preload: false
---

# Managing Railway

Manage Railway platform using the `railway` CLI and Railway GraphQL API.

## MANDATORY: Discovery-First Pattern

**Always discover available resources before performing analysis.**

### Phase 1: Discovery

```bash
#!/bin/bash

echo "=== Current Project ==="
railway status 2>/dev/null

echo ""
echo "=== Projects ==="
railway list 2>/dev/null | head -20

echo ""
echo "=== Services in Current Project ==="
railway service list 2>/dev/null | head -20

echo ""
echo "=== Environments ==="
railway environment list 2>/dev/null | head -10

echo ""
echo "=== Variables ==="
railway variables list 2>/dev/null | head -20

echo ""
echo "=== Volumes ==="
railway volume list 2>/dev/null | head -10
```

### Phase 2: Analysis

```bash
#!/bin/bash

echo "=== Deployment History ==="
railway logs --deployment 2>/dev/null | head -30

echo ""
echo "=== Service Health (Recent Logs) ==="
railway logs --lines 30 2>/dev/null | tail -20

echo ""
echo "=== Project Details via API ==="
curl -s "https://backboard.railway.app/graphql/v2" \
    -H "Authorization: Bearer $RAILWAY_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"query": "{ me { projects { edges { node { id name description services { edges { node { id name } } } environments { edges { node { id name } } } } } } } }"}' 2>/dev/null | jq '.data.me.projects.edges[] | .node | {id, name, description, services: [.services.edges[].node.name], environments: [.environments.edges[].node.name]}' | head -30

echo ""
echo "=== Deployment Status via API ==="
curl -s "https://backboard.railway.app/graphql/v2" \
    -H "Authorization: Bearer $RAILWAY_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"query": "{ me { projects { edges { node { name deployments(first: 5) { edges { node { id status createdAt } } } } } } } }"}' 2>/dev/null | jq '.data.me.projects.edges[].node | {project: .name, deployments: [.deployments.edges[].node | {id: .id[:12], status, createdAt}]}' | head -20
```

## Output Format

```
PROJECT       SERVICE     ENVIRONMENT   STATUS
my-app        web         production    deployed
my-app        api         production    deployed
my-app        postgres    production    running
```

## Safety Rules
- Use read-only commands: `status`, `list`, `logs`
- Never run `delete`, `down`, `remove` without explicit user confirmation
- Use `| head -N` to limit log output
- Limit output to stay under 50 lines
