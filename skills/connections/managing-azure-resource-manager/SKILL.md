---
name: managing-azure-resource-manager
description: |
  Azure Resource Manager (ARM) template and deployment management. Covers template validation, deployment operations, resource group inspection, what-if analysis, deployment history, and template spec management. Use when deploying ARM templates, reviewing deployment status, analyzing resource groups, or troubleshooting failed deployments.
connection_type: azure-resource-manager
preload: false
---

# Azure Resource Manager Management Skill

Manage ARM template deployments, resource groups, deployment history, and template specs.

## MANDATORY: Discovery-First Pattern

**Always inspect resource groups and deployment status before operations.**

### Phase 1: Discovery

```bash
#!/bin/bash
echo "=== Current Account ==="
az account show --query '{Name:name,Id:id,TenantId:tenantId}' -o table 2>/dev/null

echo ""
echo "=== Resource Groups ==="
az group list --query '[*].{Name:name,Location:location,State:properties.provisioningState}' -o table 2>/dev/null | head -20

echo ""
echo "=== Recent Deployments ==="
az deployment sub list --query '[*].{Name:name,State:properties.provisioningState,Timestamp:properties.timestamp}' -o table 2>/dev/null | head -10

echo ""
echo "=== Template Specs ==="
az ts list --query '[*].{Name:name,Version:versions[-1].name,Location:location}' -o table 2>/dev/null | head -10
```

### Phase 2: Analysis

```bash
#!/bin/bash
RG="${1:?Resource group name required}"

echo "=== Resource Group Resources ==="
az resource list -g "$RG" --query '[*].{Name:name,Type:type,Location:location}' -o table 2>/dev/null | head -20

echo ""
echo "=== Deployment History ==="
az deployment group list -g "$RG" --query '[*].{Name:name,State:properties.provisioningState,Timestamp:properties.timestamp,Mode:properties.mode}' -o table 2>/dev/null | head -10

echo ""
echo "=== Failed Deployments ==="
az deployment group list -g "$RG" --query "[?properties.provisioningState=='Failed'].{Name:name,Error:properties.error.message}" -o table 2>/dev/null | head -10

echo ""
echo "=== What-If (if template provided) ==="
TEMPLATE="${2:-}"
if [ -n "$TEMPLATE" ]; then
  az deployment group what-if -g "$RG" --template-file "$TEMPLATE" 2>&1 | tail -20
fi
```

## Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- Show resource counts by type, not full resource listings
- Summarize deployment states and highlight failures
- Use what-if output for change previews

## Safety Rules
- **NEVER deploy in Complete mode without explicit confirmation** (deletes unmanaged resources)
- **Always run `what-if`** before deploying templates
- **Use Incremental mode** by default
- **Review deployment error details** before retrying
- **Validate templates** with `az deployment group validate` before deploying
