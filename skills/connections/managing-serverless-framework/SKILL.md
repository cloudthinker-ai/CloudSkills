---
name: managing-serverless-framework
description: |
  Serverless Framework service management. Covers service deployment, function invocation, log streaming, plugin management, stage/region configuration, CloudFormation stack inspection, and offline local development. Use when deploying serverless services, invoking functions, debugging with logs, or managing multi-stage environments.
connection_type: serverless-framework
preload: false
---

# Serverless Framework Management Skill

Manage Serverless Framework services, deploy functions, stream logs, and inspect deployments.

## MANDATORY: Discovery-First Pattern

**Always inspect service configuration and deployment status before operations.**

### Phase 1: Discovery

```bash
#!/bin/bash
echo "=== Serverless Version ==="
serverless --version 2>/dev/null || sls --version 2>/dev/null

echo ""
echo "=== Service Info ==="
sls info 2>/dev/null | head -20

echo ""
echo "=== Service Config ==="
if [ -f serverless.yml ]; then
  grep -E "^(service|provider|plugins):" serverless.yml
  echo ""
  echo "Functions:"
  grep -E "^\s+\w+:" serverless.yml | grep -A0 -B0 "handler" | head -15
fi

echo ""
echo "=== Plugins ==="
if [ -f serverless.yml ]; then
  grep -A 20 "^plugins:" serverless.yml | head -15
fi

echo ""
echo "=== Stages ==="
sls info --stage dev 2>/dev/null | head -5
sls info --stage prod 2>/dev/null | head -5
```

### Phase 2: Analysis

```bash
#!/bin/bash
STAGE="${1:-dev}"
FUNCTION="${2:-}"

echo "=== Deployment Info (stage=$STAGE) ==="
sls info --stage "$STAGE" 2>/dev/null | head -25

echo ""
echo "=== Deployed Functions ==="
sls info --stage "$STAGE" 2>/dev/null | grep -A 1 "functions:" | head -15

if [ -n "$FUNCTION" ]; then
  echo ""
  echo "=== Function Logs ($FUNCTION) ==="
  sls logs -f "$FUNCTION" --stage "$STAGE" --startTime 5m 2>/dev/null | tail -20
fi

echo ""
echo "=== CloudFormation Stack ==="
SERVICE=$(grep "^service:" serverless.yml 2>/dev/null | awk '{print $2}')
aws cloudformation describe-stacks --stack-name "${SERVICE}-${STAGE}" --query 'Stacks[0].{Status:StackStatus,LastUpdated:LastUpdatedTime,Outputs:Outputs[*].OutputKey}' 2>/dev/null | head -10
```

## Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- Show function endpoints and names, not full config
- Filter logs by time range to avoid flooding
- Summarize stage deployments concisely

## Safety Rules
- **NEVER run `sls deploy` to production without `--stage` confirmation**
- **Use `sls deploy --noDeploy`** to generate CloudFormation without deploying
- **Test locally with `sls offline`** or `sls invoke local` before deploying
- **Review `sls diff`** when available via plugins
- **Pin plugin versions** in `package.json` for reproducibility
