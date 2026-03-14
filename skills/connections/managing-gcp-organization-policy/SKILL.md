---
name: managing-gcp-organization-policy
description: |
  GCP Organization Policy Service management. Covers org policy constraints, policy evaluation, custom constraints, dry-run policies, exception management, and compliance auditing. Use when managing GCP organization-level guardrails, reviewing constraint violations, creating custom policies, or auditing policy compliance across projects and folders.
connection_type: gcp-organization-policy
preload: false
---

# GCP Organization Policy Management Skill

Manage GCP organization policies, constraints, custom policies, and compliance.

## MANDATORY: Discovery-First Pattern

**Always inspect existing policies and constraints before modifications.**

### Phase 1: Discovery

```bash
#!/bin/bash
ORG_ID=$(gcloud organizations list --format='value(name)' --limit=1 2>/dev/null)

echo "=== Organization ==="
gcloud organizations describe "$ORG_ID" --format='table(displayName,name,lifecycleState)' 2>/dev/null

echo ""
echo "=== Active Org Policies ==="
gcloud org-policies list --organization="$ORG_ID" --format='table(constraint,listPolicy.allValues,booleanPolicy.enforced)' 2>/dev/null | head -20

echo ""
echo "=== Common Constraints ==="
for c in constraints/compute.vmExternalIpAccess constraints/iam.allowedPolicyMemberDomains constraints/compute.restrictSharedVpcSubnetworks constraints/gcp.restrictServiceUsage; do
  echo "--- $c ---"
  gcloud org-policies describe "$c" --organization="$ORG_ID" --format='value(booleanPolicy,listPolicy)' 2>/dev/null
done | head -15

echo ""
echo "=== Custom Constraints ==="
gcloud org-policies list-custom-constraints --organization="$ORG_ID" --format='table(name,actionType,condition)' 2>/dev/null | head -10
```

### Phase 2: Analysis

```bash
#!/bin/bash
ORG_ID=$(gcloud organizations list --format='value(name)' --limit=1 2>/dev/null)
CONSTRAINT="${1:?Constraint name required}"

echo "=== Constraint Detail ==="
gcloud org-policies describe "$CONSTRAINT" --organization="$ORG_ID" 2>/dev/null | head -15

echo ""
echo "=== Effective Policy (project level) ==="
PROJECT="${2:-$(gcloud config get-value project 2>/dev/null)}"
gcloud org-policies describe "$CONSTRAINT" --project="$PROJECT" --effective 2>/dev/null | head -15

echo ""
echo "=== Policy at Each Level ==="
echo "--- Organization ---"
gcloud org-policies describe "$CONSTRAINT" --organization="$ORG_ID" --format='value(booleanPolicy,listPolicy)' 2>/dev/null
echo "--- Project ---"
gcloud org-policies describe "$CONSTRAINT" --project="$PROJECT" --format='value(booleanPolicy,listPolicy)' 2>/dev/null

echo ""
echo "=== Violations ==="
gcloud asset search-all-resources --scope="organizations/$ORG_ID" --query="policy:$CONSTRAINT" --format='table(name,assetType)' 2>/dev/null | head -10
```

## Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- Show effective policies at each hierarchy level
- Summarize constraint types and enforcement status
- Highlight violations and exceptions

## Safety Rules
- **NEVER enforce constraints without dry-run testing first**
- **Review effective policy inheritance** at all levels before changes
- **Test custom constraints** on non-production projects first
- **Check for existing exceptions** before broadening constraints
- **Audit constraint violations** before enforcement
