---
name: managing-digitalocean-app-platform
description: |
  DigitalOcean App Platform management via the doctl CLI. Covers apps, components, deployments, logs, domains, alerts, and billing. Use when managing App Platform applications or checking deployment health.
connection_type: digitalocean-app-platform
preload: false
---

# Managing DigitalOcean App Platform

Manage DigitalOcean App Platform using the `doctl apps` CLI.

## MANDATORY: Discovery-First Pattern

**Always discover available resources before performing analysis.**

### Phase 1: Discovery

```bash
#!/bin/bash

echo "=== Apps ==="
doctl apps list --format ID,Spec.Name,DefaultIngress,ActiveDeployment.Phase,Region,UpdatedAt --no-header 2>/dev/null | head -20

echo ""
echo "=== App Tiers ==="
doctl apps tier list --format Name,Slug,BuildSeconds,EgressBandwidthBytes --no-header 2>/dev/null | head -10

echo ""
echo "=== App Regions ==="
doctl apps region list --format Slug,Label,Default --no-header 2>/dev/null | head -10
```

### Phase 2: Analysis

```bash
#!/bin/bash

APP_ID="${1:?App ID required}"

echo "=== App Details ==="
doctl apps get "$APP_ID" --format ID,Spec.Name,DefaultIngress,ActiveDeployment.Phase,Region,CreatedAt,UpdatedAt --no-header 2>/dev/null

echo ""
echo "=== App Components ==="
doctl apps get "$APP_ID" -o json 2>/dev/null | jq '{
    services: [.spec.services[]? | {name, http_port, instance_count, instance_size_slug, source: (.github.repo // .git.repo_clone_url // "N/A")}],
    workers: [.spec.workers[]? | {name, instance_count, instance_size_slug}],
    static_sites: [.spec.static_sites[]? | {name, source: (.github.repo // "N/A")}],
    databases: [.spec.databases[]? | {name, engine, version, production}],
    jobs: [.spec.jobs[]? | {name, kind, instance_count}]
}' | head -30

echo ""
echo "=== Recent Deployments ==="
doctl apps list-deployments "$APP_ID" --format ID,Phase,Progress,CreatedAt,UpdatedAt --no-header 2>/dev/null | head -10

echo ""
echo "=== App Logs (Recent) ==="
doctl apps logs "$APP_ID" --type run --follow=false 2>/dev/null | tail -20

echo ""
echo "=== App Domains ==="
doctl apps list-domains "$APP_ID" --format ID,Spec.Domain,Phase --no-header 2>/dev/null | head -10

echo ""
echo "=== Alerts ==="
doctl apps list-alerts "$APP_ID" --format ID,Spec.Rule,Spec.Disabled --no-header 2>/dev/null | head -10

echo ""
echo "=== Deployment Details (Latest) ==="
DEPLOY_ID=$(doctl apps list-deployments "$APP_ID" --format ID --no-header 2>/dev/null | head -1)
if [ -n "$DEPLOY_ID" ]; then
    doctl apps get-deployment "$APP_ID" "$DEPLOY_ID" -o json 2>/dev/null | jq '{
        id, phase, progress,
        services: [.services[]? | {name, source_commit_hash: .source_commit_hash[:8]}],
        created_at, updated_at
    }'
fi
```

## Output Format

```
APP_ID                                NAME        INGRESS                      PHASE    REGION
abc123-def456-ghi789                  my-app      my-app-abc12.ondigitalocean  ACTIVE   nyc
```

## Safety Rules
- Use read-only commands: `list`, `get`, `logs`
- Never run `delete`, `update`, `create` without explicit user confirmation
- Use `--format` and `--no-header` for clean output
- Limit output with `| head -N` and `| tail -N` to stay under 50 lines
