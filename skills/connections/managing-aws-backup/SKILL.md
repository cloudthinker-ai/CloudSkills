---
name: managing-aws-backup
description: |
  AWS Backup vault, plan, and job management. Covers backup vaults, backup plans, backup selections, recovery points, backup jobs, restore jobs, and compliance frameworks. Use when auditing backup coverage, checking backup job status, reviewing recovery points, or validating backup compliance.
connection_type: aws
preload: false
---

# AWS Backup Management Skill

Analyze and manage AWS Backup plans, vaults, recovery points, and job statuses.

## MANDATORY: Discovery-First Pattern

**Always list vaults and plans before querying specific resources.**

### Phase 1: Discovery

```bash
#!/bin/bash
export AWS_PAGER=""

echo "=== Backup Vaults ==="
aws backup list-backup-vaults --output text \
  --query 'BackupVaultList[].[BackupVaultName,NumberOfRecoveryPoints,CreationDate]'

echo ""
echo "=== Backup Plans ==="
aws backup list-backup-plans --output text \
  --query 'BackupPlansList[].[BackupPlanId,BackupPlanName,CreationDate,LastExecutionDate]'

echo ""
echo "=== Backup Selections ==="
for plan_id in $(aws backup list-backup-plans --output text --query 'BackupPlansList[].BackupPlanId'); do
  aws backup list-backup-selections --backup-plan-id "$plan_id" --output text \
    --query "BackupSelectionsList[].[\"$plan_id\",SelectionId,SelectionName,IamRoleArn]" &
done
wait
```

### Phase 2: Analysis

```bash
#!/bin/bash
export AWS_PAGER=""

echo "=== Recent Backup Jobs (last 24h) ==="
aws backup list-backup-jobs \
  --by-created-after "$(date -u -d '24 hours ago' +%Y-%m-%dT%H:%M:%S 2>/dev/null || date -u -v-1d +%Y-%m-%dT%H:%M:%S)" \
  --output text \
  --query 'BackupJobs[].[BackupJobId,ResourceType,State,StatusMessage,CreationDate]' | head -20

echo ""
echo "=== Failed Backup Jobs (last 7 days) ==="
aws backup list-backup-jobs \
  --by-state FAILED \
  --by-created-after "$(date -u -d '7 days ago' +%Y-%m-%dT%H:%M:%S 2>/dev/null || date -u -v-7d +%Y-%m-%dT%H:%M:%S)" \
  --output text \
  --query 'BackupJobs[].[ResourceArn,ResourceType,StatusMessage,CreationDate]' | head -15

echo ""
echo "=== Recovery Points Summary ==="
for vault in $(aws backup list-backup-vaults --output text --query 'BackupVaultList[].BackupVaultName'); do
  aws backup list-recovery-points-by-backup-vault --backup-vault-name "$vault" --max-results 5 --output text \
    --query "RecoveryPoints[].[\"$vault\",ResourceType,Status,CreationDate,CompletionDate]" &
done
wait

echo ""
echo "=== Restore Jobs (recent) ==="
aws backup list-restore-jobs --output text \
  --query 'RestoreJobs[:5].[RestoreJobId,Status,CreationDate,CompletionDate,RecoveryPointArn]' 2>/dev/null
```

## Output Format

- Target ≤50 lines per output
- Use `--output text --query` for all commands
- Tab-delimited fields: VaultName, PlanName, JobId, State, ResourceType
- Aggregate job counts by status when many jobs exist
- Never dump full plan rules -- summarize schedule and lifecycle

## Common Pitfalls

- **Job states**: CREATED, PENDING, RUNNING, ABORTING, ABORTED, COMPLETED, FAILED, EXPIRED, PARTIAL
- **Recovery point lifecycle**: Check `Lifecycle` for transition to cold storage and deletion rules
- **Cross-region copies**: Backup plans can copy to other regions -- check `CopyActions` in plan rules
- **Vault lock**: Locked vaults prevent deletion of recovery points -- check `Locked` and `MinRetentionDays`
- **Resource selection**: Selections use tag-based or ARN-based targeting -- verify coverage with `list-protected-resources`
- **Compliance frameworks**: Use `list-frameworks` and `list-report-plans` for compliance auditing
