---
name: managing-sst
description: |
  SST (Serverless Stack) application management. Covers stack deployment, live Lambda debugging, console access, resource binding, secret management, and multi-stage environments. Use when building full-stack serverless apps with SST, debugging Lambda functions live, managing secrets, or inspecting deployed infrastructure.
connection_type: sst
preload: false
---

# SST Management Skill

Manage SST applications, deploy stacks, debug live Lambdas, and inspect bound resources.

## MANDATORY: Discovery-First Pattern

**Always inspect SST project config and deployment status before operations.**

### Phase 1: Discovery

```bash
#!/bin/bash
echo "=== SST Version ==="
npx sst version 2>/dev/null || sst version 2>/dev/null

echo ""
echo "=== SST Config ==="
if [ -f sst.config.ts ]; then
  head -30 sst.config.ts
elif [ -f sst.config.js ]; then
  head -30 sst.config.js
fi

echo ""
echo "=== Stacks ==="
ls stacks/ 2>/dev/null || ls infra/ 2>/dev/null || echo "Check sst.config for stack definitions"

echo ""
echo "=== Secrets ==="
npx sst secrets list 2>/dev/null | head -15
```

### Phase 2: Analysis

```bash
#!/bin/bash
STAGE="${1:-dev}"

echo "=== Stack Status (stage=$STAGE) ==="
npx sst diff --stage "$STAGE" 2>&1 | tail -25

echo ""
echo "=== Bound Resources ==="
npx sst bind -- printenv 2>/dev/null | grep SST_ | head -15

echo ""
echo "=== Deployed Outputs ==="
aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE --query "StackSummaries[?contains(StackName, '-${STAGE}-')].{Name:StackName,Status:StackStatus,Updated:LastUpdatedTime}" --output table 2>/dev/null | head -15

echo ""
echo "=== Functions ==="
aws lambda list-functions --query "Functions[?contains(FunctionName, '-${STAGE}-')].{Name:FunctionName,Runtime:Runtime,Memory:MemorySize}" --output table 2>/dev/null | head -15
```

## Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- Show bound resource names and outputs, not full stack details
- Summarize function configurations concisely
- Redact secret values in output

## Safety Rules
- **NEVER run `sst deploy` to production without explicit stage confirmation**
- **Use `sst diff`** before deploying to review changes
- **Never expose secrets** -- use `sst secrets` for secret management
- **Use `sst dev`** for local development with live debugging
- **Review IAM changes** in diff output before deploying
