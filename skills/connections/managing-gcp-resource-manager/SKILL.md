---
name: managing-gcp-resource-manager
description: |
  GCP Resource Manager project, folder, and organization management. Covers organization hierarchy, folder structure, project management, IAM policy bindings, org-level constraints, and resource labels. Use when managing GCP organizational hierarchy, reviewing project organization, auditing IAM bindings, or inspecting folder structures.
connection_type: gcp-resource-manager
preload: false
---

# GCP Resource Manager Management Skill

Manage GCP organizations, folders, projects, IAM bindings, and resource hierarchy.

## MANDATORY: Discovery-First Pattern

**Always inspect organization and folder hierarchy before operations.**

### Phase 1: Discovery

```bash
#!/bin/bash
echo "=== Current Project ==="
gcloud config get-value project 2>/dev/null

echo ""
echo "=== Organization ==="
gcloud organizations list --format='table(displayName,name,lifecycleState)' 2>/dev/null | head -10

echo ""
ORG_ID=$(gcloud organizations list --format='value(name)' --limit=1 2>/dev/null)

echo "=== Top-Level Folders ==="
gcloud resource-manager folders list --organization="$ORG_ID" --format='table(displayName,name,lifecycleState)' 2>/dev/null | head -15

echo ""
echo "=== Projects ==="
gcloud projects list --format='table(projectId,name,lifecycleState,parent.id)' --limit=20 2>/dev/null | head -20
```

### Phase 2: Analysis

```bash
#!/bin/bash
TARGET="${1:?Project ID or folder ID required}"

if echo "$TARGET" | grep -q "^[0-9]"; then
  echo "=== Folder Details ==="
  gcloud resource-manager folders describe "$TARGET" --format='table(displayName,name,lifecycleState,parent)' 2>/dev/null

  echo ""
  echo "=== Sub-Folders ==="
  gcloud resource-manager folders list --folder="$TARGET" --format='table(displayName,name)' 2>/dev/null | head -10

  echo ""
  echo "=== Folder Projects ==="
  gcloud projects list --filter="parent.id=$TARGET" --format='table(projectId,name,lifecycleState)' 2>/dev/null | head -10

  echo ""
  echo "=== Folder IAM ==="
  gcloud resource-manager folders get-iam-policy "$TARGET" --format='table(bindings.role,bindings.members)' 2>/dev/null | head -15
else
  echo "=== Project Details ==="
  gcloud projects describe "$TARGET" --format='table(projectId,name,lifecycleState,parent)' 2>/dev/null

  echo ""
  echo "=== Project IAM ==="
  gcloud projects get-iam-policy "$TARGET" --format='table(bindings.role,bindings.members)' 2>/dev/null | head -20

  echo ""
  echo "=== Enabled APIs ==="
  gcloud services list --project="$TARGET" --format='table(config.name)' 2>/dev/null | head -15

  echo ""
  echo "=== Labels ==="
  gcloud projects describe "$TARGET" --format='table(labels)' 2>/dev/null
fi
```

## Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- Show hierarchy as tree structure when possible
- Summarize IAM bindings by role
- List projects with parent folder context

## Safety Rules
- **NEVER delete projects or folders without explicit confirmation**
- **Review IAM inheritance** before modifying folder-level bindings
- **Check project liens** before attempting deletion
- **Verify org policy impacts** before moving projects between folders
- **Audit service account permissions** at the folder/org level
