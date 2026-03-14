---
name: managing-cloudformation-deep
description: |
  AWS CloudFormation deep stack management. Covers stack operations, change sets, drift detection, nested stacks, stack sets, resource imports, template analysis, and rollback troubleshooting. Use when managing complex CloudFormation deployments, debugging stack failures, detecting drift, operating stack sets, or analyzing template dependencies.
connection_type: aws-cloudformation
preload: false
---

# CloudFormation Deep Management Skill

Deep management of CloudFormation stacks, change sets, drift detection, stack sets, and rollbacks.

## MANDATORY: Discovery-First Pattern

**Always inspect stack status and recent events before operations.**

### Phase 1: Discovery

```bash
#!/bin/bash
echo "=== Active Stacks ==="
aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE UPDATE_ROLLBACK_COMPLETE ROLLBACK_COMPLETE --query 'StackSummaries[*].{Name:StackName,Status:StackStatus,Updated:LastUpdatedTime}' --output table 2>/dev/null | head -20

echo ""
echo "=== Failed Stacks ==="
aws cloudformation list-stacks --stack-status-filter CREATE_FAILED UPDATE_FAILED DELETE_FAILED --query 'StackSummaries[*].{Name:StackName,Status:StackStatus,Reason:StackStatusReason}' --output table 2>/dev/null | head -10

echo ""
echo "=== Stack Sets ==="
aws cloudformation list-stack-sets --status ACTIVE --query 'Summaries[*].{Name:StackSetName,Status:Status,DriftStatus:DriftStatus}' --output table 2>/dev/null | head -10

echo ""
echo "=== Exports ==="
aws cloudformation list-exports --query 'Exports[*].{Name:Name,Value:Value,Stack:ExportingStackId}' --output table 2>/dev/null | head -10
```

### Phase 2: Analysis

```bash
#!/bin/bash
STACK="${1:?Stack name required}"

echo "=== Stack Detail ==="
aws cloudformation describe-stacks --stack-name "$STACK" --query 'Stacks[0].{Status:StackStatus,Created:CreationTime,Updated:LastUpdatedTime,DriftStatus:DriftInformation.StackDriftStatus}' --output table 2>/dev/null

echo ""
echo "=== Resources ==="
aws cloudformation list-stack-resources --stack-name "$STACK" --query 'StackResourceSummaries[*].{Logical:LogicalResourceId,Type:ResourceType,Status:ResourceStatus}' --output table 2>/dev/null | head -20

echo ""
echo "=== Recent Events ==="
aws cloudformation describe-stack-events --stack-name "$STACK" --query 'StackEvents[:10].[Timestamp,LogicalResourceId,ResourceStatus,ResourceStatusReason]' --output table 2>/dev/null | head -15

echo ""
echo "=== Drift Detection ==="
DRIFT_ID=$(aws cloudformation detect-stack-drift --stack-name "$STACK" --query 'StackDriftDetectionId' --output text 2>/dev/null)
echo "Drift detection started: $DRIFT_ID"
aws cloudformation describe-stack-drift-detection-status --stack-drift-detection-id "$DRIFT_ID" 2>/dev/null | jq '{Status: .DetectionStatus, DriftStatus: .StackDriftStatus, DriftedResources: .DriftedStackResourceCount}' 2>/dev/null

echo ""
echo "=== Outputs ==="
aws cloudformation describe-stacks --stack-name "$STACK" --query 'Stacks[0].Outputs[*].{Key:OutputKey,Value:OutputValue}' --output table 2>/dev/null | head -10
```

## Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- Show resource status summaries, not full template dumps
- Highlight failed events and drift status
- Summarize nested stack hierarchy concisely

## Safety Rules
- **NEVER delete stacks without explicit confirmation**
- **Always create change sets** before updating stacks
- **Review change set resources** before execution
- **Enable termination protection** on critical stacks
- **Check cross-stack dependencies** (exports/imports) before deletion
- **Use `--retain-resources`** for resources that cannot be deleted
