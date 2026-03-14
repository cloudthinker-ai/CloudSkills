---
name: aws-step-functions
description: |
  AWS Step Functions execution analysis, state machine management, error tracking, and performance optimization. Covers execution history, failure investigation, state transition metrics, Express vs Standard comparison, and workflow visualization.
connection_type: aws
preload: false
---

# AWS Step Functions Skill

Analyze AWS Step Functions state machines with parallel execution and anti-hallucination guardrails.

**Relationship to other AWS skills:**

- `aws-step-functions/` → Step Functions-specific analysis (state machines, executions, errors)
- `aws/` → "How to execute" (parallel patterns, throttling, output format)

## CRITICAL: Parallel Execution Requirement

**ALL independent operations MUST run in parallel using background jobs (&) and wait.**

```bash
#!/bin/bash
export AWS_PAGER=""

for sm_arn in $state_machines; do
  get_execution_history "$sm_arn" &
done
wait
```

## Helper Functions

```bash
#!/bin/bash
export AWS_PAGER=""

# List all state machines
list_state_machines() {
  aws stepfunctions list-state-machines \
    --output text \
    --query 'stateMachines[].[stateMachineArn,name,type,creationDate]'
}

# Get state machine details
describe_state_machine() {
  local sm_arn=$1
  aws stepfunctions describe-state-machine --state-machine-arn "$sm_arn" \
    --output text \
    --query '[name,status,type,creationDate,loggingConfiguration.level,tracingConfiguration.enabled]'
}

# List recent executions
list_executions() {
  local sm_arn=$1 status=${2:-""}
  local status_filter=""
  [ -n "$status" ] && status_filter="--status-filter $status"
  aws stepfunctions list-executions --state-machine-arn "$sm_arn" $status_filter \
    --max-results 20 \
    --output text \
    --query 'executions[].[executionArn,name,status,startDate,stopDate]'
}

# Get execution details
describe_execution() {
  local exec_arn=$1
  aws stepfunctions describe-execution --execution-arn "$exec_arn" \
    --output text \
    --query '[name,status,startDate,stopDate,error,cause]'
}

# Get execution history (last N events)
get_execution_events() {
  local exec_arn=$1 max=${2:-20}
  aws stepfunctions get-execution-history --execution-arn "$exec_arn" \
    --max-results "$max" --reverse-order \
    --output text \
    --query 'events[].[timestamp,type,id]'
}
```

## Common Operations

### 1. State Machine Inventory

```bash
#!/bin/bash
export AWS_PAGER=""
aws stepfunctions list-state-machines \
  --output text \
  --query 'stateMachines[].[name,type,creationDate]' | sort -k2
```

### 2. Execution Success/Failure Summary

```bash
#!/bin/bash
export AWS_PAGER=""
SMS=$(aws stepfunctions list-state-machines --output text --query 'stateMachines[].stateMachineArn')
for sm in $SMS; do
  {
    name=$(echo "$sm" | sed 's|.*:||')
    running=$(aws stepfunctions list-executions --state-machine-arn "$sm" --status-filter RUNNING --max-results 100 --output text --query 'length(executions)')
    succeeded=$(aws stepfunctions list-executions --state-machine-arn "$sm" --status-filter SUCCEEDED --max-results 100 --output text --query 'length(executions)')
    failed=$(aws stepfunctions list-executions --state-machine-arn "$sm" --status-filter FAILED --max-results 100 --output text --query 'length(executions)')
    printf "%s\tRunning:%s\tSucceeded:%s\tFailed:%s\n" "$name" "$running" "$succeeded" "$failed"
  } &
done
wait
```

### 3. Failed Execution Investigation

```bash
#!/bin/bash
export AWS_PAGER=""
SM_ARN=$1
FAILED=$(aws stepfunctions list-executions --state-machine-arn "$SM_ARN" \
  --status-filter FAILED --max-results 10 \
  --output text --query 'executions[].executionArn')
for exec_arn in $FAILED; do
  aws stepfunctions describe-execution --execution-arn "$exec_arn" \
    --output text \
    --query '[name,status,startDate,stopDate,error,cause]' &
done
wait
```

### 4. Execution Duration Analysis

```bash
#!/bin/bash
export AWS_PAGER=""
SM_ARN=$1
END=$(date -u +"%Y-%m-%dT%H:%M:%S")
START=$(date -u -d "7 days ago" +"%Y-%m-%dT%H:%M:%S" 2>/dev/null || date -u -v-7d +"%Y-%m-%dT%H:%M:%S")
aws cloudwatch get-metric-statistics \
  --namespace AWS/States --metric-name ExecutionTime \
  --dimensions Name=StateMachineArn,Value="$SM_ARN" \
  --start-time "$START" --end-time "$END" \
  --period 86400 --statistics Average Maximum Minimum \
  --output text --query 'Datapoints[*].[Timestamp,Average,Maximum,Minimum]' | sort -k1
```

### 5. Execution Metrics Overview

```bash
#!/bin/bash
export AWS_PAGER=""
SMS=$(aws stepfunctions list-state-machines --output text --query 'stateMachines[].stateMachineArn')
END=$(date -u +"%Y-%m-%dT%H:%M:%S")
START=$(date -u -d "7 days ago" +"%Y-%m-%dT%H:%M:%S" 2>/dev/null || date -u -v-7d +"%Y-%m-%dT%H:%M:%S")
for sm in $SMS; do
  {
    name=$(echo "$sm" | sed 's|.*:||')
    started=$(aws cloudwatch get-metric-statistics \
      --namespace AWS/States --metric-name ExecutionsStarted \
      --dimensions Name=StateMachineArn,Value="$sm" \
      --start-time "$START" --end-time "$END" \
      --period 604800 --statistics Sum \
      --output text --query 'Datapoints[0].Sum')
    failed=$(aws cloudwatch get-metric-statistics \
      --namespace AWS/States --metric-name ExecutionsFailed \
      --dimensions Name=StateMachineArn,Value="$sm" \
      --start-time "$START" --end-time "$END" \
      --period 604800 --statistics Sum \
      --output text --query 'Datapoints[0].Sum')
    printf "%s\tStarted:%s\tFailed:%s\n" "$name" "${started:-0}" "${failed:-0}"
  } &
done
wait
```

## Anti-Hallucination Rules

1. **Standard vs Express** - Standard workflows record full execution history and are billed per state transition. Express workflows are billed by duration and do not retain history in the API (use CloudWatch Logs).
2. **Execution history limits** - Standard workflow execution history is limited to 25,000 events. Express workflows log to CloudWatch only.
3. **list-executions pagination** - Results are paginated and ordered by start date descending. The `--max-results` parameter caps at 100 per page.
4. **Error vs Cause** - `error` is the error code (e.g., States.TaskFailed). `cause` is the detailed message. Both may be null for non-error terminations.
5. **CloudWatch metrics namespace** - Step Functions uses `AWS/States`, not `AWS/StepFunctions`.

## Common Pitfalls

- **Express workflow history**: Express executions cannot be described via `describe-execution` after completion. Use CloudWatch Logs Insights to analyze them.
- **ARN format**: State machine ARNs and execution ARNs have different formats. Do not construct execution ARNs manually.
- **Concurrent execution limits**: Default is 1,000,000 open executions per account per region. Express workflows have a 100,000 concurrent execution limit.
- **CloudWatch statistics syntax**: Use spaces not commas: `--statistics Average Maximum`.
- **Map state parallelism**: Map states run iterations in parallel by default. Use `MaxConcurrency` to control. Failures in map iterations may not fail the entire execution depending on error handling.
