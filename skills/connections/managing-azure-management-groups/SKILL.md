---
name: managing-azure-management-groups
description: |
  Azure Management Groups hierarchy and governance management. Covers management group tree structure, subscription placement, policy assignments, RBAC inheritance, compliance status, and governance auditing. Use when managing Azure tenant hierarchy, assigning policies to management groups, reviewing subscription organization, or auditing inherited access controls.
connection_type: azure-management-groups
preload: false
---

# Azure Management Groups Management Skill

Manage Azure Management Group hierarchies, subscription placement, policy assignments, and RBAC.

## MANDATORY: Discovery-First Pattern

**Always inspect the management group hierarchy and policy state before changes.**

### Phase 1: Discovery

```bash
#!/bin/bash
echo "=== Tenant Info ==="
az account show --query '{TenantId:tenantId,Name:name}' -o table 2>/dev/null

echo ""
echo "=== Management Group Hierarchy ==="
az account management-group list --query '[*].{Name:name,DisplayName:displayName,Id:id}' -o table 2>/dev/null | head -20

echo ""
echo "=== Root Management Group ==="
az account management-group show --name $(az account show --query tenantId -o tsv) --expand --recurse -o json 2>/dev/null | jq '{name: .displayName, children: [.children[]? | {name: .displayName, type: .type, childCount: (.children // [] | length)}]}' | head -20

echo ""
echo "=== Subscriptions ==="
az account list --query '[*].{Name:name,Id:id,State:state}' -o table 2>/dev/null | head -15
```

### Phase 2: Analysis

```bash
#!/bin/bash
MG_NAME="${1:?Management group name required}"

echo "=== Management Group Details ==="
az account management-group show --name "$MG_NAME" --expand --recurse -o json 2>/dev/null | jq '{name: .displayName, children: [.children[]? | {name: .displayName, type: .type}]}' | head -20

echo ""
echo "=== Policy Assignments ==="
az policy assignment list --scope "/providers/Microsoft.Management/managementGroups/$MG_NAME" --query '[*].{Name:name,Policy:policyDefinitionId,Enforcement:enforcementMode}' -o table 2>/dev/null | head -15

echo ""
echo "=== Role Assignments ==="
az role assignment list --scope "/providers/Microsoft.Management/managementGroups/$MG_NAME" --query '[*].{Principal:principalName,Role:roleDefinitionName,Scope:scope}' -o table 2>/dev/null | head -15

echo ""
echo "=== Compliance ==="
az policy state summarize --management-group "$MG_NAME" --query '{compliant: results.resourceDetails[0].count, nonCompliant: results.resourceDetails[1].count}' -o table 2>/dev/null | head -10
```

## Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- Show hierarchy as tree structure when possible
- Summarize policy assignments with enforcement mode
- List RBAC by management group scope

## Safety Rules
- **NEVER move subscriptions without understanding inherited policies**
- **Review policy inheritance** before assigning to management groups
- **Check RBAC inheritance** impacts on child resources
- **Test policies at lower MG levels** before applying to root
- **Verify management group deletion** has no child resources
