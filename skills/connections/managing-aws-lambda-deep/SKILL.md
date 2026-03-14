---
name: managing-aws-lambda-deep
description: |
  Deep AWS Lambda analysis covering function inventory, cold start profiling, memory optimization, concurrency patterns, layer dependency auditing, dead letter queue health, event source mappings, and cost estimation. Goes beyond basic metrics to identify optimization opportunities.
connection_type: aws
preload: false
---

# AWS Lambda Deep Management

Advanced Lambda analysis with optimization recommendations and cost insights.

## Phase 1: Discovery

```bash
#!/bin/bash
export AWS_PAGER=""

echo "=== Lambda Function Inventory ==="
aws lambda list-functions --output json \
  | jq -r '.Functions[] | "\(.FunctionName)\t\(.Runtime // "container")\t\(.MemorySize)MB\t\(.Timeout)s\t\(.Architectures[0])\t\(.PackageType)\t\(.LastModified)"' \
  | column -t | head -30

echo ""
echo "=== Runtime Distribution ==="
aws lambda list-functions --output text \
  --query 'Functions[].[Runtime]' | sort | uniq -c | sort -rn

echo ""
echo "=== Event Source Mappings ==="
aws lambda list-event-source-mappings --output json \
  | jq -r '.EventSourceMappings[] | "\(.FunctionArn | split(":") | last)\t\(.EventSourceArn | split(":")[2])\t\(.State)\t\(.BatchSize)"' \
  | column -t | head -20

echo ""
echo "=== Layers in Use ==="
aws lambda list-layers --output json \
  | jq -r '.Layers[] | "\(.LayerName)\tv\(.LatestMatchingVersion.Version)\t\(.LatestMatchingVersion.CompatibleRuntimes[0] // "N/A")"' \
  | column -t
```

## Phase 2: Analysis

```bash
#!/bin/bash
export AWS_PAGER=""
END=$(date -u +"%Y-%m-%dT%H:%M:%S")
START=$(date -u -d "7 days ago" +"%Y-%m-%dT%H:%M:%S" 2>/dev/null || date -u -v-7d +"%Y-%m-%dT%H:%M:%S")

echo "=== Per-Function Metrics (7d) ==="
for FUNC in $(aws lambda list-functions --query 'Functions[].FunctionName' --output text); do
  {
    INV=$(aws cloudwatch get-metric-statistics --namespace AWS/Lambda --metric-name Invocations \
      --dimensions Name=FunctionName,Value="$FUNC" --start-time "$START" --end-time "$END" \
      --period 604800 --statistics Sum --output text --query 'Datapoints[0].Sum')
    ERR=$(aws cloudwatch get-metric-statistics --namespace AWS/Lambda --metric-name Errors \
      --dimensions Name=FunctionName,Value="$FUNC" --start-time "$START" --end-time "$END" \
      --period 604800 --statistics Sum --output text --query 'Datapoints[0].Sum')
    DUR=$(aws cloudwatch get-metric-statistics --namespace AWS/Lambda --metric-name Duration \
      --dimensions Name=FunctionName,Value="$FUNC" --start-time "$START" --end-time "$END" \
      --period 604800 --statistics Average Maximum --output text --query 'Datapoints[0].[Average,Maximum]')
    THR=$(aws cloudwatch get-metric-statistics --namespace AWS/Lambda --metric-name Throttles \
      --dimensions Name=FunctionName,Value="$FUNC" --start-time "$START" --end-time "$END" \
      --period 604800 --statistics Sum --output text --query 'Datapoints[0].Sum')
    printf "%s\t%s\t%s\t%s\t%s\n" "$FUNC" "${INV:-0}" "${ERR:-0}" "${DUR:-N/A}" "${THR:-0}"
  } &
done
wait

echo ""
echo "=== Dead Letter Queue Config ==="
for FUNC in $(aws lambda list-functions --query 'Functions[].FunctionName' --output text); do
  DLQ=$(aws lambda get-function-configuration --function-name "$FUNC" \
    --query 'DeadLetterConfig.TargetArn' --output text 2>/dev/null)
  [ "$DLQ" != "None" ] && [ -n "$DLQ" ] && echo "$FUNC -> $DLQ"
done

echo ""
echo "=== Provisioned Concurrency ==="
for FUNC in $(aws lambda list-functions --query 'Functions[].FunctionName' --output text); do
  aws lambda list-provisioned-concurrency-configs --function-name "$FUNC" \
    --query "ProvisionedConcurrencyConfigs[].[\"$FUNC\",RequestedProvisionedConcurrentExecutions,AvailableProvisionedConcurrentExecutions,Status]" \
    --output text 2>/dev/null
done | grep -v "^$"

echo ""
echo "=== Account Concurrency Limits ==="
aws lambda get-account-settings --query '{UnreservedConcurrency: AccountLimit.UnreservedConcurrentExecutions, TotalConcurrency: AccountLimit.ConcurrentExecutions}' --output json
```

## Output Format

```
LAMBDA DEEP ANALYSIS
=====================
Function           Invocations  Errors  Err%    Avg-ms  Max-ms   Throttles  Memory
──────────────────────────────────────────────────────────────────────────────────────
order-processor    45200        12      0.03%   120.4   890.2    0          256MB
auth-handler       128900       450     0.35%   45.2    1200.0   23         128MB
image-resizer      8900         0       0.00%   2400.1  5000.0   0          1024MB

Runtimes: nodejs20.x(5) python3.12(3) java21(1)
Concurrency: 800/1000 unreserved | Provisioned: 2 functions
DLQ configured: 3/9 functions
```

## Safety Rules

- **Read-only**: Only use `list-*`, `get-*`, and CloudWatch `get-metric-statistics`
- **Parallel execution**: Use background jobs for multi-function metric queries
- **Never invoke functions** or modify configurations without explicit confirmation
- **Cost awareness**: Large accounts may incur CloudWatch API costs with many metric queries
