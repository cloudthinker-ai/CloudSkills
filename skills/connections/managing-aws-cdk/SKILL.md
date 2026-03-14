---
name: managing-aws-cdk
description: |
  AWS CDK infrastructure-as-code management. Covers synth, diff, deploy, bootstrap, context values, construct inspection, and stack dependencies. Use when managing CDK applications, reviewing synthesized templates, comparing deployments, or debugging construct issues.
connection_type: aws-cdk
preload: false
---

# AWS CDK Management Skill

Manage and inspect AWS CDK applications, stacks, and synthesized CloudFormation templates.

## MANDATORY: Discovery-First Pattern

**Always list stacks and synth before deploying.**

### Phase 1: Discovery

```bash
#!/bin/bash

echo "=== CDK Version ==="
cdk --version 2>/dev/null

echo ""
echo "=== Available Stacks ==="
cdk list --long 2>/dev/null

echo ""
echo "=== CDK Context ==="
cdk context --json 2>/dev/null | jq '.' | head -20

echo ""
echo "=== Project Structure ==="
cat cdk.json 2>/dev/null | jq '{app: .app, context: .context}' || \
cat cdk.json 2>/dev/null | head -20
```

## Core Helper Functions

```bash
#!/bin/bash

# CDK wrapper
cdk_cmd() {
    cdk "$@" --no-color 2>&1
}

# Synth and inspect template
cdk_synth_json() {
    local stack="$1"
    cdk synth "$stack" --quiet --json 2>/dev/null
}

# Get resource count from synthesized template
cdk_resource_count() {
    local stack="$1"
    cdk_synth_json "$stack" | jq '.Resources | length'
}
```

## Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- Use `--json` or `--quiet` to suppress banner output
- Pipe synth output through jq for filtering
- Never dump full synthesized templates -- extract resource summaries

## Common Operations

### Synthesize and Inspect

```bash
#!/bin/bash
STACK="${1:-}"

echo "=== Synthesizing ==="
if [ -n "$STACK" ]; then
    cdk synth "$STACK" --quiet --json 2>/dev/null | jq '{
        Resources: (.Resources | to_entries | map({key: .key, type: .value.Type}) | from_entries),
        ResourceCount: (.Resources | length),
        Outputs: (.Outputs | keys),
        Parameters: (.Parameters | keys)
    }'
else
    cdk synth --quiet 2>&1 | tail -5
    echo ""
    echo "=== All Stack Resource Counts ==="
    for stack in $(cdk list 2>/dev/null); do
        COUNT=$(cdk synth "$stack" --quiet --json 2>/dev/null | jq '.Resources | length')
        echo "$stack: $COUNT resources"
    done
fi
```

### Diff (Compare Deployed vs Local)

```bash
#!/bin/bash
STACK="${1:-}"

echo "=== CDK Diff ==="
if [ -n "$STACK" ]; then
    cdk diff "$STACK" --no-color 2>&1 | head -60
else
    echo "Diffing all stacks..."
    cdk diff --no-color 2>&1 | head -80
fi
```

### Deploy (with Safety)

```bash
#!/bin/bash
STACK="${1:?Stack name required}"
DRY_RUN="${2:-true}"

if [ "$DRY_RUN" = "true" ]; then
    echo "=== DRY RUN: Showing what would deploy ==="
    cdk diff "$STACK" --no-color 2>&1 | head -50
    echo ""
    echo "To actually deploy, confirm with dry_run=false"
else
    echo "=== Deploying $STACK ==="
    cdk deploy "$STACK" --require-approval=broadening --no-color 2>&1 | tail -30
fi
```

### Bootstrap Status

```bash
#!/bin/bash
ACCOUNT="${1:-$(aws sts get-caller-identity --query Account --output text 2>/dev/null)}"
REGION="${2:-$(aws configure get region 2>/dev/null)}"

echo "=== Bootstrap Stack Status ==="
aws cloudformation describe-stacks --stack-name CDKToolkit \
    --query 'Stacks[0].{Status:StackStatus,Version:Parameters[?ParameterKey==`BootstrapVersion`].ParameterValue|[0],Qualifier:Parameters[?ParameterKey==`Qualifier`].ParameterValue|[0]}' \
    --output table 2>/dev/null

echo ""
echo "=== Bootstrap Bucket ==="
aws cloudformation describe-stack-resources --stack-name CDKToolkit \
    --query 'StackResources[?ResourceType==`AWS::S3::Bucket`].{Id:LogicalResourceId,Physical:PhysicalResourceId}' \
    --output table 2>/dev/null

echo ""
echo "=== Bootstrap Version ==="
CURRENT=$(aws ssm get-parameter --name /cdk-bootstrap/hnb659fds/version \
    --query 'Parameter.Value' --output text 2>/dev/null || echo "not found")
echo "Current bootstrap version: $CURRENT"
```

### Construct and Dependency Analysis

```bash
#!/bin/bash
echo "=== Stack Dependencies ==="
cdk list --long 2>/dev/null

echo ""
echo "=== Construct Tree ==="
STACK="${1:-$(cdk list 2>/dev/null | head -1)}"
cdk synth "$STACK" --quiet 2>/dev/null
cat cdk.out/tree.json 2>/dev/null | jq '
    .tree.children | to_entries[] |
    {id: .key, construct: .value.constructInfo.fqn, children: (.value.children // {} | keys)}
' | head -40
```

## Safety Rules

- **NEVER deploy without reviewing diff first** -- always run `cdk diff` before `cdk deploy`
- **Use `--require-approval=broadening`** to require confirmation for security-sensitive changes
- **Bootstrap before first deploy** -- `cdk bootstrap` required per account/region
- **Review IAM changes carefully** -- CDK auto-generates IAM policies that may be overly permissive
- **Use `cdk destroy` with caution** -- it removes all resources in the stack

## Common Pitfalls

- **Context values**: CDK caches context lookups (VPC IDs, AMIs) -- stale context causes drift -- use `cdk context --reset`
- **Construct IDs**: Changing construct IDs causes resource replacement -- review diff carefully
- **Asset bundling**: Lambda/Docker assets require local tooling (Docker, esbuild) -- build errors are common
- **Cross-stack references**: Removing exported values breaks dependent stacks -- remove consumers first
- **Bootstrap version**: Newer CDK versions may require re-bootstrapping -- check version compatibility
- **Hotswap limitations**: `--hotswap` skips CloudFormation for speed but may leave stack in inconsistent state
- **Snapshot tests**: CDK snapshot tests break on any template change -- update snapshots after intentional changes
- **L1 vs L2 constructs**: L1 (Cfn*) constructs mirror CloudFormation directly; L2 constructs add defaults that may surprise
