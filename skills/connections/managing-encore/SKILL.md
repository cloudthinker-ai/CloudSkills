---
name: managing-encore
description: |
  Encore cloud application platform management. Covers service architecture, API inspection, infrastructure provisioning, environment management, deployment history, and local development. Use when building backend applications with Encore, inspecting service APIs, managing environments, or reviewing deployment status.
connection_type: encore
preload: false
---

# Encore Management Skill

Manage Encore applications, inspect services, review deployments, and configure environments.

## MANDATORY: Discovery-First Pattern

**Always inspect Encore app structure and environment status before operations.**

### Phase 1: Discovery

```bash
#!/bin/bash
echo "=== Encore Version ==="
encore version 2>/dev/null

echo ""
echo "=== App Config ==="
cat encore.app 2>/dev/null | head -10

echo ""
echo "=== Services ==="
find . -name "encore.service.ts" -o -name "encore.service.go" 2>/dev/null | head -15

echo ""
echo "=== API Endpoints ==="
grep -rn "//encore:api\|@api\|api\.NewEndpoint" --include="*.go" --include="*.ts" . 2>/dev/null | head -15

echo ""
echo "=== Environments ==="
encore env list 2>/dev/null | head -10
```

### Phase 2: Analysis

```bash
#!/bin/bash
ENV="${1:-staging}"

echo "=== App Metadata ==="
encore app show 2>/dev/null | head -10

echo ""
echo "=== Service Diagram ==="
encore diagram 2>/dev/null | head -20

echo ""
echo "=== Deployment History ==="
encore deploy list --env "$ENV" 2>/dev/null | head -10

echo ""
echo "=== Infrastructure Resources ==="
encore infra list --env "$ENV" 2>/dev/null | head -15

echo ""
echo "=== Secrets ==="
encore secret list 2>/dev/null | head -10
```

## Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- Show service topology and API endpoints concisely
- Summarize deployment history with status
- List infrastructure resources by type

## Safety Rules
- **NEVER deploy to production without reviewing changes**
- **Use `encore run`** for local development and testing
- **Review service dependencies** before deployments
- **Check environment configuration** matches target
- **Use Encore dashboard** for detailed observability
