---
name: managing-serverless-framework
description: |
  Use when working with Serverless Framework — serverless Framework service
  management. Covers service deployment, function invocation, log streaming,
  plugin management, stage/region configuration, CloudFormation stack
  inspection, and offline local development. Use when deploying serverless
  services, invoking functions, debugging with logs, or managing multi-stage
  environments.
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

## Output Format

Present results as a structured report:
```
Managing Serverless Framework Report
════════════════════════════════════
Resources discovered: [count]

Resource       Status    Key Metric    Issues
──────────────────────────────────────────────
[name]         [ok/warn] [value]       [findings]

Summary: [total] resources | [ok] healthy | [warn] warnings | [crit] critical
Action Items: [list of prioritized findings]
```

Target ≤50 lines of output. Use tables for multi-resource comparisons.

## Anti-Hallucination Rules

1. **NEVER assume resource names** — always discover via CLI/API in Phase 1 before referencing in Phase 2.
2. **NEVER fabricate metric names or dimensions** — verify against the service documentation or `--help` output.
3. **NEVER mix CLI commands between service versions** — confirm which version/API you are targeting.
4. **ALWAYS use the discovery → verify → analyze chain** — every resource referenced must have been discovered first.
5. **ALWAYS handle empty results gracefully** — an empty response is valid data, not an error to retry.

## Counter-Rationalizations

| Shortcut | Counter | Why |
|----------|---------|-----|
| "I'll skip discovery and check known resources" | Always run Phase 1 discovery first | Resource names change, new resources appear — assumed names cause errors |
| "The user only asked for a quick check" | Follow the full discovery → analysis flow | Quick checks miss critical issues; structured analysis catches silent failures |
| "Default configuration is probably fine" | Audit configuration explicitly | Defaults often leave logging, security, and optimization features disabled |
| "Metrics aren't needed for this" | Always check relevant metrics when available | API/CLI responses show current state; metrics reveal trends and intermittent issues |
| "I don't have access to that" | Try the command and report the actual error | Assumed permission failures prevent useful investigation; actual errors are informative |

