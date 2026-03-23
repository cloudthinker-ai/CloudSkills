---
name: aws-eventbridge
description: |
  Use when working with Aws Eventbridge — aWS EventBridge event bus management,
  rule analysis, target health monitoring, and schema registry exploration.
  Covers event pattern matching, rule invocation metrics, dead-letter queue
  analysis, cross-account event routing, and event replay.
connection_type: aws
preload: false
---

# AWS EventBridge Skill

Analyze AWS EventBridge event buses and rules with parallel execution and anti-hallucination guardrails.

**Relationship to other AWS skills:**

- `aws-eventbridge/` → EventBridge-specific analysis (event buses, rules, targets, schemas)
- `aws/` → "How to execute" (parallel patterns, throttling, output format)

## CRITICAL: Parallel Execution Requirement

**ALL independent operations MUST run in parallel using background jobs (&) and wait.**

```bash
#!/bin/bash
export AWS_PAGER=""

for rule in $rules; do
  get_rule_details "$rule" &
done
wait
```

## Helper Functions

```bash
#!/bin/bash
export AWS_PAGER=""

# List event buses
list_event_buses() {
  aws events list-event-buses \
    --output text \
    --query 'EventBuses[].[Name,Arn,Policy]'
}

# List rules on an event bus
list_rules() {
  local bus_name=${1:-default}
  aws events list-rules --event-bus-name "$bus_name" \
    --output text \
    --query 'Rules[].[Name,State,ScheduleExpression,EventPattern]'
}

# Get rule targets
get_rule_targets() {
  local rule_name=$1 bus_name=${2:-default}
  aws events list-targets-by-rule --rule "$rule_name" --event-bus-name "$bus_name" \
    --output text \
    --query 'Targets[].[Id,Arn,DeadLetterConfig.Arn]'
}

# Get rule invocation metrics
get_rule_metrics() {
  local rule_name=$1 days=${2:-7}
  local end_time start_time
  end_time=$(date -u +"%Y-%m-%dT%H:%M:%S")
  start_time=$(date -u -d "$days days ago" +"%Y-%m-%dT%H:%M:%S" 2>/dev/null || date -u -v-${days}d +"%Y-%m-%dT%H:%M:%S")
  aws cloudwatch get-metric-statistics \
    --namespace AWS/Events --metric-name Invocations \
    --dimensions Name=RuleName,Value="$rule_name" \
    --start-time "$start_time" --end-time "$end_time" \
    --period $((days * 86400)) --statistics Sum \
    --output text --query 'Datapoints[0].Sum'
}

# List schemas in registry
list_schemas() {
  local registry=${1:-discovered-schemas}
  aws schemas list-schemas --registry-name "$registry" \
    --output text \
    --query 'Schemas[].[SchemaName,SchemaVersion,LastModified]' 2>/dev/null
}
```

## Common Operations

### 1. Event Bus and Rule Inventory

```bash
#!/bin/bash
export AWS_PAGER=""
BUSES=$(aws events list-event-buses --output text --query 'EventBuses[].Name')
for bus in $BUSES; do
  {
    rule_count=$(aws events list-rules --event-bus-name "$bus" --output text --query 'length(Rules)')
    printf "%s\tRules:%s\n" "$bus" "$rule_count"
    aws events list-rules --event-bus-name "$bus" \
      --output text \
      --query 'Rules[].[Name,State,ScheduleExpression]'
  } &
done
wait
```

### 2. Rule Invocation and Failure Metrics

```bash
#!/bin/bash
export AWS_PAGER=""
END=$(date -u +"%Y-%m-%dT%H:%M:%S")
START=$(date -u -d "7 days ago" +"%Y-%m-%dT%H:%M:%S" 2>/dev/null || date -u -v-7d +"%Y-%m-%dT%H:%M:%S")
RULES=$(aws events list-rules --output text --query 'Rules[].Name')
for rule in $RULES; do
  {
    invocations=$(aws cloudwatch get-metric-statistics \
      --namespace AWS/Events --metric-name Invocations \
      --dimensions Name=RuleName,Value="$rule" \
      --start-time "$START" --end-time "$END" \
      --period 604800 --statistics Sum \
      --output text --query 'Datapoints[0].Sum')
    failed=$(aws cloudwatch get-metric-statistics \
      --namespace AWS/Events --metric-name FailedInvocations \
      --dimensions Name=RuleName,Value="$rule" \
      --start-time "$START" --end-time "$END" \
      --period 604800 --statistics Sum \
      --output text --query 'Datapoints[0].Sum')
    printf "%s\tInvocations:%s\tFailed:%s\n" "$rule" "${invocations:-0}" "${failed:-0}"
  } &
done
wait
```

### 3. Target Health Analysis

```bash
#!/bin/bash
export AWS_PAGER=""
RULES=$(aws events list-rules --output text --query 'Rules[].Name')
for rule in $RULES; do
  {
    targets=$(aws events list-targets-by-rule --rule "$rule" \
      --output text \
      --query 'Targets[].[Id,Arn]')
    printf "RULE:%s\n%s\n" "$rule" "$targets"
  } &
done
wait
```

### 4. Dead Letter Queue Analysis

```bash
#!/bin/bash
export AWS_PAGER=""
RULES=$(aws events list-rules --output text --query 'Rules[].Name')
for rule in $RULES; do
  dlq=$(aws events list-targets-by-rule --rule "$rule" \
    --output text \
    --query 'Targets[?DeadLetterConfig.Arn!=null].[Id,Arn,DeadLetterConfig.Arn]') &
done
wait
```

### 5. Schema Registry Exploration

```bash
#!/bin/bash
export AWS_PAGER=""
REGISTRIES=$(aws schemas list-registries --output text --query 'Registries[].RegistryName' 2>/dev/null)
for reg in $REGISTRIES; do
  aws schemas list-schemas --registry-name "$reg" \
    --output text \
    --query "Schemas[].[\"$reg\",SchemaName,LastModified]" &
done
wait
```

## Anti-Hallucination Rules

1. **Default event bus exists implicitly** - You do not need to create the "default" event bus. It always exists. Custom buses must be created.
2. **ScheduleExpression vs EventPattern** - A rule has either a schedule (cron/rate) OR an event pattern, not both.
3. **Invocations metric counts target invocations** - One event matching a rule with 3 targets produces 3 invocations, not 1.
4. **FailedInvocations != dropped events** - FailedInvocations means the target was invoked but failed. Events that match no rules are silently dropped.
5. **Schema discovery must be enabled** - The discovered-schemas registry only populates if schema discovery is enabled on the event bus.

## Output Format

Present results as a structured report:
```
Aws Eventbridge Report
══════════════════════
Resources discovered: [count]

Resource       Status    Key Metric    Issues
──────────────────────────────────────────────
[name]         [ok/warn] [value]       [findings]

Summary: [total] resources | [ok] healthy | [warn] warnings | [crit] critical
Action Items: [list of prioritized findings]
```

Target ≤50 lines of output. Use tables for multi-resource comparisons.

## Counter-Rationalizations

| Shortcut | Counter | Why |
|----------|---------|-----|
| "I'll skip discovery and check known resources" | Always run Phase 1 discovery first | Resource names change, new resources appear — assumed names cause errors |
| "The user only asked for a quick check" | Follow the full discovery → analysis flow | Quick checks miss critical issues; structured analysis catches silent failures |
| "Default configuration is probably fine" | Audit configuration explicitly | Defaults often leave logging, security, and optimization features disabled |
| "Metrics aren't needed for this" | Always check relevant metrics when available | API/CLI responses show current state; metrics reveal trends and intermittent issues |
| "I don't have access to that" | Try the command and report the actual error | Assumed permission failures prevent useful investigation; actual errors are informative |

## Common Pitfalls

- **Event size limit**: Events are limited to 256 KB. Larger payloads must use S3 references.
- **Rule limit**: Default 300 rules per event bus per account. Check with service quotas.
- **Cross-account events**: Require explicit resource policy on the target event bus. Source account needs `events:PutEvents` permission.
- **CloudWatch statistics syntax**: Use spaces not commas: `--statistics Average Maximum`.
- **Retry policy**: EventBridge retries failed invocations for up to 24 hours by default. Configure retry policy per target.
