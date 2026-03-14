---
name: managing-gcp-policy-intelligence
description: |
  GCP Policy Intelligence and IAM recommender management. Covers IAM recommender insights, policy analyzer, policy troubleshooter, access approval settings, and security health analytics. Use when analyzing IAM permissions, reviewing policy recommendations, troubleshooting access denials, or optimizing least-privilege access across GCP resources.
connection_type: gcp-policy-intelligence
preload: false
---

# GCP Policy Intelligence Management Skill

Manage GCP Policy Intelligence tools including IAM recommender, policy analyzer, and troubleshooter.

## MANDATORY: Discovery-First Pattern

**Always inspect current IAM state and recommendations before changes.**

### Phase 1: Discovery

```bash
#!/bin/bash
PROJECT="${1:-$(gcloud config get-value project 2>/dev/null)}"

echo "=== IAM Recommender Insights ==="
gcloud recommender insights list --project="$PROJECT" --insight-type=google.iam.policy.Insight --location=global --format='table(name.basename(),description,stateInfo.state)' 2>/dev/null | head -15

echo ""
echo "=== IAM Recommendations ==="
gcloud recommender recommendations list --project="$PROJECT" --recommender=google.iam.policy.Recommender --location=global --format='table(name.basename(),description,stateInfo.state,priority)' 2>/dev/null | head -15

echo ""
echo "=== Service Account Insights ==="
gcloud recommender insights list --project="$PROJECT" --insight-type=google.iam.serviceAccount.Insight --location=global --format='table(name.basename(),description)' 2>/dev/null | head -10

echo ""
echo "=== Unused Service Accounts ==="
gcloud recommender recommendations list --project="$PROJECT" --recommender=google.iam.serviceAccount.Recommender --location=global --format='table(name.basename(),description,priority)' 2>/dev/null | head -10
```

### Phase 2: Analysis

```bash
#!/bin/bash
PROJECT="${1:-$(gcloud config get-value project 2>/dev/null)}"
MEMBER="${2:-}"

echo "=== Policy Analyzer ==="
if [ -n "$MEMBER" ]; then
  gcloud asset analyze-iam-policy --organization="$(gcloud organizations list --format='value(name)' --limit=1 2>/dev/null)" --identity="$MEMBER" --format='table(identityList.identities,accessControlLists.accesses.role)' 2>/dev/null | head -20
fi

echo ""
echo "=== Policy Troubleshooter ==="
RESOURCE="${3:-}"
PERMISSION="${4:-}"
if [ -n "$MEMBER" ] && [ -n "$RESOURCE" ] && [ -n "$PERMISSION" ]; then
  gcloud policy-troubleshoot iam "$RESOURCE" --permission="$PERMISSION" --principal-email="$MEMBER" 2>/dev/null | head -20
fi

echo ""
echo "=== Excess Permissions ==="
gcloud recommender insights list --project="$PROJECT" --insight-type=google.iam.policy.Insight --location=global --filter="category=PERMISSION_USAGE" --format='table(description,stateInfo.state)' 2>/dev/null | head -10

echo ""
echo "=== Lateral Movement Risks ==="
gcloud recommender insights list --project="$PROJECT" --insight-type=google.iam.policy.Insight --location=global --filter="category=SECURITY" --format='table(description,severity)' 2>/dev/null | head -10
```

## Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- Show recommendation summaries with priority
- Highlight unused permissions and service accounts
- Summarize policy analysis results concisely

## Safety Rules
- **NEVER apply IAM recommendations without reviewing the role changes**
- **Test permission removals** on non-production projects first
- **Review service account usage** before disabling
- **Check dependent workloads** before revoking permissions
- **Use policy troubleshooter** to verify access before/after changes
