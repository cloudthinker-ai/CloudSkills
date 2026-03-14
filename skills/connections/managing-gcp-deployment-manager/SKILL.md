---
name: managing-gcp-deployment-manager
description: |
  GCP Deployment Manager template and deployment management. Covers deployment creation, template validation, resource inspection, manifest review, deployment updates, and type provider management. Use when deploying GCP resources via Deployment Manager, reviewing deployment status, inspecting manifests, or troubleshooting failed deployments.
connection_type: gcp-deployment-manager
preload: false
---

# GCP Deployment Manager Management Skill

Manage GCP Deployment Manager deployments, templates, manifests, and type providers.

## MANDATORY: Discovery-First Pattern

**Always inspect existing deployments and project status before operations.**

### Phase 1: Discovery

```bash
#!/bin/bash
echo "=== Current Project ==="
gcloud config get-value project 2>/dev/null

echo ""
echo "=== Deployments ==="
gcloud deployment-manager deployments list --format='table(name,operation.status,insertTime)' 2>/dev/null | head -15

echo ""
echo "=== Available Types ==="
gcloud deployment-manager types list --format='table(name)' 2>/dev/null | head -15

echo ""
echo "=== Composite Types ==="
gcloud deployment-manager type-providers list --format='table(name,insertTime)' 2>/dev/null | head -10
```

### Phase 2: Analysis

```bash
#!/bin/bash
DEPLOYMENT="${1:?Deployment name required}"

echo "=== Deployment Resources ==="
gcloud deployment-manager deployments describe "$DEPLOYMENT" --format='table(resources[].name, resources[].type, resources[].update.state)' 2>/dev/null | head -20

echo ""
echo "=== Deployment Manifest ==="
MANIFEST=$(gcloud deployment-manager deployments describe "$DEPLOYMENT" --format='value(deployment.manifest)' 2>/dev/null | sed 's|.*/||')
gcloud deployment-manager manifests describe "$MANIFEST" --deployment "$DEPLOYMENT" --format='value(layout)' 2>/dev/null | head -25

echo ""
echo "=== Deployment Errors ==="
gcloud deployment-manager deployments describe "$DEPLOYMENT" --format='table(resources[].update.error.errors[].code, resources[].update.error.errors[].message)' 2>/dev/null | head -10

echo ""
echo "=== Preview (dry-run) ==="
TEMPLATE="${2:-}"
if [ -n "$TEMPLATE" ]; then
  gcloud deployment-manager deployments update "$DEPLOYMENT" --config "$TEMPLATE" --preview 2>&1 | tail -15
fi
```

## Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- Show resource types and statuses, not full manifests
- Summarize deployment operations concisely
- Highlight errors and warnings

## Safety Rules
- **NEVER delete deployments without explicit confirmation**
- **Always use `--preview`** before applying updates
- **Review manifest changes** before confirming updates
- **Check resource dependencies** before deletion
- **Use `--delete-policy ABANDON`** to preserve resources when removing deployments
