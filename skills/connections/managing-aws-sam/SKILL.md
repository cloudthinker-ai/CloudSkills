---
name: managing-aws-sam
description: |
  AWS Serverless Application Model (SAM) management. Covers template validation, local testing, build and packaging, deployment orchestration, stack inspection, log tailing, and API Gateway debugging. Use when building serverless applications with SAM, testing locally, deploying Lambda functions, or troubleshooting API Gateway endpoints.
connection_type: aws-sam
preload: false
---

# AWS SAM Management Skill

Manage AWS SAM applications, build and deploy serverless stacks, test locally, and inspect deployments.

## MANDATORY: Discovery-First Pattern

**Always validate templates and check deployment status before operations.**

### Phase 1: Discovery

```bash
#!/bin/bash
echo "=== SAM Version ==="
sam --version 2>/dev/null

echo ""
echo "=== Template Validation ==="
sam validate 2>&1 | head -5

echo ""
echo "=== Template Resources ==="
if [ -f template.yaml ]; then
  grep "Type: AWS::" template.yaml | sort | uniq -c | sort -rn | head -15
elif [ -f template.yml ]; then
  grep "Type: AWS::" template.yml | sort | uniq -c | sort -rn | head -15
fi

echo ""
echo "=== Functions ==="
sam list resources --output json 2>/dev/null | jq -r '.[] | select(.LogicalResourceId | test("Function|Lambda")) | "\(.LogicalResourceId) | \(.PhysicalResourceId)"' 2>/dev/null | head -10

echo ""
echo "=== Deployed Endpoints ==="
sam list endpoints --output json 2>/dev/null | jq -r '.[] | "\(.LogicalResourceId) | \(.PhysicalResourceId)"' | head -10
```

### Phase 2: Analysis

```bash
#!/bin/bash
STACK="${1:-}"
FUNCTION="${2:-}"

echo "=== Stack Status ==="
sam list resources ${STACK:+--stack-name "$STACK"} --output json 2>/dev/null | jq -r '.[] | "\(.LogicalResourceId) | \(.ResourceType) | \(.ResourceStatus)"' | head -20

echo ""
echo "=== Build ==="
sam build 2>&1 | tail -10

echo ""
if [ -n "$FUNCTION" ]; then
  echo "=== Function Logs (last 5 min) ==="
  sam logs -n "$FUNCTION" ${STACK:+--stack-name "$STACK"} --start-time "5min ago" 2>/dev/null | tail -20
fi

echo ""
echo "=== Stack Outputs ==="
aws cloudformation describe-stacks ${STACK:+--stack-name "$STACK"} --query 'Stacks[0].Outputs[*].{Key:OutputKey,Value:OutputValue}' --output table 2>/dev/null | head -15
```

## Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- Summarize function counts and resource types
- Tail logs with time filters to avoid flooding
- Show endpoints and outputs, not full template dumps

## Safety Rules
- **NEVER deploy without `sam validate` and `sam build` first**
- **Use `sam deploy --guided`** for first-time deployments
- **Test locally with `sam local invoke`** before deploying
- **Review changeset** before confirming deployment
- **Use `--no-execute-changeset`** for dry-run deployments
