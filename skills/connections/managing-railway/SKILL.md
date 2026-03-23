---
name: managing-railway
description: |
  Use when working with Railway — railway platform management via the railway
  CLI and Railway API. Covers projects, services, deployments, databases,
  volumes, and environment variables. Use when managing Railway deployments or
  checking service health.
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

