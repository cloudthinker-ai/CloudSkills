---
name: managing-aws-amplify
description: |
  AWS Amplify application management and deployment analysis. Covers Amplify apps, branches, backend environments, build status, domain associations, and webhook configurations. Use when inspecting Amplify deployments, debugging build failures, reviewing hosting configurations, or auditing Amplify app settings.
connection_type: aws
preload: false
---

# AWS Amplify Management Skill

Analyze and manage AWS Amplify applications, deployments, and hosting configurations.

## MANDATORY: Discovery-First Pattern

**Always list apps and branches before querying specific resources.**

### Phase 1: Discovery

```bash
#!/bin/bash
export AWS_PAGER=""

echo "=== Amplify Apps ==="
aws amplify list-apps --output text \
  --query 'apps[].[appId,name,defaultDomain,platform,repository]'

echo ""
echo "=== App Branches ==="
for app_id in $(aws amplify list-apps --output text --query 'apps[].appId'); do
  aws amplify list-branches --app-id "$app_id" --output text \
    --query "branchSummaries[].[\"$app_id\",branchName,stage,activeJobId,lastDeployTime]" &
done
wait

echo ""
echo "=== Domain Associations ==="
for app_id in $(aws amplify list-apps --output text --query 'apps[].appId'); do
  aws amplify list-domain-associations --app-id "$app_id" --output text \
    --query "domainAssociations[].[\"$app_id\",domainName,domainStatus,certificateVerificationDNSRecord]" &
done
wait
```

### Phase 2: Analysis

```bash
#!/bin/bash
export AWS_PAGER=""

echo "=== Recent Build Jobs ==="
for app_id in $(aws amplify list-apps --output text --query 'apps[].appId'); do
  for branch in $(aws amplify list-branches --app-id "$app_id" --output text --query 'branchSummaries[].branchName'); do
    aws amplify list-jobs --app-id "$app_id" --branch-name "$branch" --max-items 3 --output text \
      --query "jobSummaries[].[\"$app_id\",\"$branch\",jobId,status,startTime,endTime]" &
  done
done
wait

echo ""
echo "=== Backend Environments ==="
for app_id in $(aws amplify list-apps --output text --query 'apps[].appId'); do
  aws amplify list-backend-environments --app-id "$app_id" --output text \
    --query "backendEnvironments[].[\"$app_id\",environmentName,stackName,deploymentArtifacts]" 2>/dev/null &
done
wait

echo ""
echo "=== Webhooks ==="
for app_id in $(aws amplify list-apps --output text --query 'apps[].appId'); do
  aws amplify list-webhooks --app-id "$app_id" --output text \
    --query "webhooks[].[\"$app_id\",webhookId,branchName,webhookUrl]" 2>/dev/null &
done
wait
```

## Output Format

- Target ≤50 lines per output
- Use `--output text --query` for all commands
- Tab-delimited fields: AppId, Name, Branch, Status
- Aggregate build results by status when listing many jobs
- Never dump full build logs -- extract key error lines only

## Common Pitfalls

- **Build logs**: Use `get-job` to retrieve build steps, not CloudWatch Logs
- **Branch auto-detection**: Amplify may auto-detect branches from repo -- check `enableAutoBranchCreation`
- **Custom domains**: Domain verification can take time -- check `domainStatus` before assuming failure
- **Webhooks**: Each branch can have its own webhook -- list per branch, not per app
- **Platform field**: Values are `WEB` (static) or `WEB_DYNAMIC` (SSR) -- affects build behavior
