---
name: aws-secrets-manager
description: |
  AWS Secrets Manager secret rotation status, access analysis, cost tracking, and lifecycle management. Covers secret inventory, rotation configuration audit, last access tracking, resource policy review, and version management.
connection_type: aws
preload: false
---

# AWS Secrets Manager Skill

Analyze AWS Secrets Manager secrets with parallel execution and anti-hallucination guardrails.

**Relationship to other AWS skills:**

- `aws-secrets-manager/` → Secrets Manager-specific analysis (rotation, access, lifecycle)
- `aws/` → "How to execute" (parallel patterns, throttling, output format)

## CRITICAL: Parallel Execution Requirement

**ALL independent operations MUST run in parallel using background jobs (&) and wait.**

```bash
#!/bin/bash
export AWS_PAGER=""

for secret in $secrets; do
  get_secret_metadata "$secret" &
done
wait
```

## Helper Functions

```bash
#!/bin/bash
export AWS_PAGER=""

# List all secrets
list_secrets() {
  aws secretsmanager list-secrets \
    --output text \
    --query 'SecretList[].[Name,RotationEnabled,LastRotatedDate,LastAccessedDate,CreatedDate]'
}

# Get secret metadata (NOT the value)
describe_secret() {
  local secret_id=$1
  aws secretsmanager describe-secret --secret-id "$secret_id" \
    --output text \
    --query '[Name,RotationEnabled,RotationRules.AutomaticallyAfterDays,LastRotatedDate,LastAccessedDate,LastChangedDate,VersionIdsToStages]'
}

# Get rotation configuration
get_rotation_config() {
  local secret_id=$1
  aws secretsmanager describe-secret --secret-id "$secret_id" \
    --output text \
    --query '[Name,RotationEnabled,RotationLambdaARN,RotationRules.AutomaticallyAfterDays,RotationRules.ScheduleExpression]'
}

# Get resource policy
get_resource_policy() {
  local secret_id=$1
  aws secretsmanager get-resource-policy --secret-id "$secret_id" \
    --output text \
    --query '[Name,ResourcePolicy]' 2>/dev/null
}

# List secret versions
list_versions() {
  local secret_id=$1
  aws secretsmanager list-secret-version-ids --secret-id "$secret_id" \
    --output text \
    --query 'Versions[].[VersionId,VersionStages[],CreatedDate]'
}
```

## Common Operations

### 1. Secret Inventory with Rotation Status

```bash
#!/bin/bash
export AWS_PAGER=""
aws secretsmanager list-secrets \
  --output text \
  --query 'SecretList[].[Name,RotationEnabled,LastRotatedDate,LastAccessedDate]' \
  | sort -k2
```

### 2. Rotation Compliance Audit

```bash
#!/bin/bash
export AWS_PAGER=""
SECRETS=$(aws secretsmanager list-secrets --output text --query 'SecretList[].Name')
for secret in $SECRETS; do
  aws secretsmanager describe-secret --secret-id "$secret" \
    --output text \
    --query '[Name,RotationEnabled,RotationLambdaARN,RotationRules.AutomaticallyAfterDays,LastRotatedDate]' &
done
wait
```

### 3. Stale Secrets Analysis (Not Accessed or Rotated)

```bash
#!/bin/bash
export AWS_PAGER=""
THRESHOLD_DAYS=90
THRESHOLD_DATE=$(date -u -d "$THRESHOLD_DAYS days ago" +"%Y-%m-%d" 2>/dev/null || date -u -v-${THRESHOLD_DAYS}d +"%Y-%m-%d")
aws secretsmanager list-secrets \
  --output text \
  --query 'SecretList[].[Name,LastAccessedDate,LastChangedDate,RotationEnabled]' \
  | awk -v thresh="$THRESHOLD_DATE" '$2 < thresh || $2 == "None" {print "STALE\t" $0}'
```

### 4. Resource Policy Review

```bash
#!/bin/bash
export AWS_PAGER=""
SECRETS=$(aws secretsmanager list-secrets --output text --query 'SecretList[].Name')
for secret in $SECRETS; do
  {
    policy=$(aws secretsmanager get-resource-policy --secret-id "$secret" \
      --output text --query 'ResourcePolicy' 2>/dev/null)
    if [ -n "$policy" ] && [ "$policy" != "None" ]; then
      printf "%s\tHAS_POLICY\n" "$secret"
    else
      printf "%s\tNO_POLICY\n" "$secret"
    fi
  } &
done
wait
```

### 5. Secret Version and Staging Labels

```bash
#!/bin/bash
export AWS_PAGER=""
SECRETS=$(aws secretsmanager list-secrets --output text --query 'SecretList[].Name' | head -20)
for secret in $SECRETS; do
  aws secretsmanager list-secret-version-ids --secret-id "$secret" \
    --output text \
    --query "Versions[].[\"$secret\",VersionId,VersionStages[],CreatedDate]" &
done
wait
```

## Anti-Hallucination Rules

1. **Never retrieve secret values in analysis** - Use `describe-secret` and `list-secrets` for metadata. Never call `get-secret-value` during analysis scripts. Secret values must never appear in output.
2. **LastAccessedDate granularity** - This is updated at most once per day and rounded to the date. It does not provide time-of-day precision.
3. **RotationEnabled != actively rotating** - A secret can have `RotationEnabled=true` but fail rotation. Check `LastRotatedDate` and CloudWatch metrics for actual rotation success.
4. **Cost is per secret per month** - $0.40/secret/month + $0.05/10,000 API calls. Secrets are billed regardless of access frequency.
5. **Deletion is scheduled, not immediate** - `delete-secret` schedules deletion (7-30 day window). During this window, the secret can be recovered.

## Common Pitfalls

- **Secrets Manager vs SSM Parameter Store**: Secrets Manager provides rotation, cross-account access, and secret versioning. SSM SecureString is simpler but lacks these features.
- **Rotation Lambda permissions**: The rotation Lambda needs permissions to both Secrets Manager and the target service (e.g., RDS). Missing permissions cause silent rotation failures.
- **Staging labels**: AWSCURRENT is the active version. AWSPENDING exists during rotation. AWSPREVIOUS is the previous version. Custom labels can be added.
- **CloudWatch statistics syntax**: Use spaces not commas: `--statistics Average Maximum`.
- **Cross-region replication**: Secrets can be replicated to other regions. Replica secrets are read-only. Check with `describe-secret` for `ReplicationStatus`.
