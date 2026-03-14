---
name: managing-aws-sso
description: |
  AWS IAM Identity Center (SSO) management. Covers SSO instance configuration, permission sets, account assignments, user and group provisioning, session policies, and access auditing. Use when managing single sign-on access to AWS accounts, reviewing permission sets, auditing account assignments, or configuring identity source integration.
connection_type: aws-sso
preload: false
---

# AWS SSO (IAM Identity Center) Management Skill

Manage AWS IAM Identity Center permission sets, account assignments, users, and groups.

## MANDATORY: Discovery-First Pattern

**Always inspect SSO instance and permission sets before making changes.**

### Phase 1: Discovery

```bash
#!/bin/bash
echo "=== SSO Instance ==="
INSTANCE_ARN=$(aws sso-admin list-instances --query 'Instances[0].InstanceArn' --output text 2>/dev/null)
IDENTITY_STORE_ID=$(aws sso-admin list-instances --query 'Instances[0].IdentityStoreId' --output text 2>/dev/null)
echo "Instance ARN: $INSTANCE_ARN"
echo "Identity Store: $IDENTITY_STORE_ID"

echo ""
echo "=== Permission Sets ==="
aws sso-admin list-permission-sets --instance-arn "$INSTANCE_ARN" --query 'PermissionSets' --output text 2>/dev/null | tr '\t' '\n' | while read ps; do
  NAME=$(aws sso-admin describe-permission-set --instance-arn "$INSTANCE_ARN" --permission-set-arn "$ps" --query 'PermissionSet.Name' --output text 2>/dev/null)
  DURATION=$(aws sso-admin describe-permission-set --instance-arn "$INSTANCE_ARN" --permission-set-arn "$ps" --query 'PermissionSet.SessionDuration' --output text 2>/dev/null)
  echo "$NAME | duration=$DURATION"
done | head -15

echo ""
echo "=== Groups ==="
aws identitystore list-groups --identity-store-id "$IDENTITY_STORE_ID" --query 'Groups[*].{Name:DisplayName,Id:GroupId}' --output table 2>/dev/null | head -15

echo ""
echo "=== Users ==="
aws identitystore list-users --identity-store-id "$IDENTITY_STORE_ID" --query 'Users[*].{Name:UserName,DisplayName:DisplayName}' --output table 2>/dev/null | head -15
```

### Phase 2: Analysis

```bash
#!/bin/bash
INSTANCE_ARN=$(aws sso-admin list-instances --query 'Instances[0].InstanceArn' --output text 2>/dev/null)
ACCOUNT_ID="${1:?AWS Account ID required}"

echo "=== Account Assignments ==="
aws sso-admin list-account-assignments --instance-arn "$INSTANCE_ARN" --account-id "$ACCOUNT_ID" --permission-set-arn $(aws sso-admin list-permission-sets --instance-arn "$INSTANCE_ARN" --query 'PermissionSets[0]' --output text 2>/dev/null) --query 'AccountAssignments[*].{Principal:PrincipalId,Type:PrincipalType,PermissionSet:PermissionSetArn}' --output table 2>/dev/null | head -15

echo ""
echo "=== Permission Set Policies ==="
PS_ARN="${2:-}"
if [ -n "$PS_ARN" ]; then
  echo "--- Managed Policies ---"
  aws sso-admin list-managed-policies-in-permission-set --instance-arn "$INSTANCE_ARN" --permission-set-arn "$PS_ARN" --query 'AttachedManagedPolicies[*].{Name:Name,Arn:Arn}' --output table 2>/dev/null | head -10

  echo ""
  echo "--- Inline Policy ---"
  aws sso-admin get-inline-policy-for-permission-set --instance-arn "$INSTANCE_ARN" --permission-set-arn "$PS_ARN" --query 'InlinePolicy' --output text 2>/dev/null | head -10

  echo ""
  echo "--- Permissions Boundary ---"
  aws sso-admin get-permissions-boundary-for-permission-set --instance-arn "$INSTANCE_ARN" --permission-set-arn "$PS_ARN" 2>/dev/null | jq '.' | head -5
fi
```

## Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- Show permission set names with session durations
- Summarize account assignments by principal
- List group memberships concisely

## Safety Rules
- **NEVER remove permission sets from production accounts without confirmation**
- **Review inline policies** before attaching to permission sets
- **Audit account assignments** before modifying group memberships
- **Test permission sets** on sandbox accounts first
- **Check session duration policies** for security compliance
