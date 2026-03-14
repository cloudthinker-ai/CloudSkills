---
name: aws-cost-optimization
description: |
  AWS native cost optimization using Compute Optimizer, Trusted Advisor cost checks, Savings Plan analysis, Cost Explorer, and resource rightsizing. Covers EC2 rightsizing, idle resource detection, Savings Plan and Reserved Instance recommendations, and cost anomaly detection. Use when optimizing AWS infrastructure costs with native AWS tools.
connection_type: aws
preload: false
---

# AWS Cost Optimization Skill

Optimize AWS infrastructure costs using native AWS services and recommendations.

## MANDATORY: Discovery-First Pattern

**Always check account context and available optimization services before querying.**

### Phase 1: Discovery

```bash
#!/bin/bash

echo "=== AWS Account Context ==="
aws sts get-caller-identity --output json | jq '{account: .Account, arn: .Arn}'

echo ""
echo "=== Compute Optimizer Status ==="
aws compute-optimizer get-enrollment-status --output json | jq '{
    status: .status,
    memberAccountsEnrolled: .memberAccountsEnrolled
}'

echo ""
echo "=== Cost Explorer - Current Month Spend ==="
START=$(date -u +%Y-%m-01)
END=$(date -u +%Y-%m-%d)
aws ce get-cost-and-usage --time-period Start=${START},End=${END} \
    --granularity MONTHLY --metrics BlendedCost --output json | jq -r '
    .ResultsByTime[0] | "Period: \(.TimePeriod.Start) to \(.TimePeriod.End)\nTotal: $\(.Total.BlendedCost.Amount)"
'

echo ""
echo "=== Trusted Advisor Cost Checks ==="
aws support describe-trusted-advisor-checks --language en --output json 2>/dev/null | jq -r '
    .checks[] | select(.category == "cost_optimizing") | "\(.id)\t\(.name)"
' | head -15 || echo "Trusted Advisor requires Business/Enterprise support plan"
```

## Core Helper Functions

```bash
#!/bin/bash

ce_query() {
    local start="$1"
    local end="$2"
    local granularity="${3:-MONTHLY}"
    local group_by="${4:-}"

    local cmd="aws ce get-cost-and-usage --time-period Start=${start},End=${end} --granularity ${granularity} --metrics BlendedCost UnblendedCost"
    [ -n "$group_by" ] && cmd="${cmd} --group-by Type=DIMENSION,Key=${group_by}"
    eval "$cmd --output json"
}

compute_optimizer() {
    aws compute-optimizer "$@" --output json 2>/dev/null
}
```

## Output Rules
- **TOKEN EFFICIENCY**: Target ≤50 lines per output
- Use `--output json` with jq for all AWS CLI calls
- Round costs to 2 decimal places

## Common Operations

### Compute Optimizer Recommendations

```bash
#!/bin/bash
echo "=== EC2 Rightsizing Recommendations ==="
aws compute-optimizer get-ec2-instance-recommendations --output json | jq -r '
    .instanceRecommendations[] |
    "\(.instanceArn | split("/") | last)\tCurrent: \(.currentInstanceType)\tRecommended: \(.recommendationOptions[0].instanceType)\tSavings: \(.recommendationOptions[0].estimatedMonthlySavings.value // 0 | . * 100 | round / 100) \(.recommendationOptions[0].estimatedMonthlySavings.currency // "USD")\tRisk: \(.finding)"
' | sort -t':' -k4 -rn | column -t | head -20

echo ""
echo "=== EBS Volume Recommendations ==="
aws compute-optimizer get-ebs-volume-recommendations --output json | jq -r '
    .volumeRecommendations[] |
    "\(.volumeArn | split("/") | last)\tCurrent: \(.currentConfiguration.volumeType) \(.currentConfiguration.volumeSize)GiB\tRecommended: \(.volumeRecommendationOptions[0].configuration.volumeType) \(.volumeRecommendationOptions[0].configuration.volumeSize)GiB\tFinding: \(.finding)"
' | head -15

echo ""
echo "=== Lambda Recommendations ==="
aws compute-optimizer get-lambda-function-recommendations --output json | jq -r '
    .lambdaFunctionRecommendations[] |
    "\(.functionArn | split(":") | last)\tCurrent: \(.currentMemorySize)MB\tRecommended: \(.memorySizeRecommendationOptions[0].memorySize)MB\tFinding: \(.finding)"
' | head -10
```

### Savings Plan Analysis

```bash
#!/bin/bash
echo "=== Savings Plans Utilization ==="
aws ce get-savings-plans-utilization --time-period Start=$(date -u -d '30 days ago' +%Y-%m-%d),End=$(date -u +%Y-%m-%d) --output json | jq '{
    totalCommitment: .Total.Utilization.TotalCommitment,
    usedCommitment: .Total.Utilization.UsedCommitment,
    unusedCommitment: .Total.Utilization.UnusedCommitment,
    utilizationPercentage: .Total.Utilization.UtilizationPercentage
}'

echo ""
echo "=== Savings Plan Recommendations ==="
aws ce get-savings-plans-purchase-recommendation \
    --savings-plans-type COMPUTE_SP --term-in-years ONE_YEAR \
    --payment-option NO_UPFRONT --lookback-period-in-days SIXTY_DAYS --output json | jq -r '
    .SavingsPlansPurchaseRecommendation.SavingsPlansPurchaseRecommendationDetails[] |
    "Hourly: $\(.HourlyCommitmentToPurchase)\tSavings: $\(.EstimatedMonthlySavingsAmount)/mo\tROI: \(.EstimatedROI)%"
' | head -10
```

### Trusted Advisor Cost Checks

```bash
#!/bin/bash
echo "=== Trusted Advisor Cost Optimization ==="
for CHECK_ID in $(aws support describe-trusted-advisor-checks --language en --output json 2>/dev/null | jq -r '.checks[] | select(.category == "cost_optimizing") | .id'); do
    RESULT=$(aws support describe-trusted-advisor-check-result --check-id "$CHECK_ID" --language en --output json 2>/dev/null)
    NAME=$(echo "$RESULT" | jq -r '.result.checkId')
    STATUS=$(echo "$RESULT" | jq -r '.result.status')
    FLAGGED=$(echo "$RESULT" | jq '.result.flaggedResources | length')
    SAVINGS=$(echo "$RESULT" | jq -r '.result.categorySpecificSummary.costOptimizing.estimatedMonthlySavings // 0')
    echo "$STATUS\t$FLAGGED flagged\tSavings: \$$SAVINGS/mo\t$CHECK_ID"
done | column -t | head -15 2>/dev/null || echo "Trusted Advisor requires Business/Enterprise support plan"
```

### Cost Anomaly Detection

```bash
#!/bin/bash
echo "=== Cost Anomaly Monitors ==="
aws ce get-anomaly-monitors --output json | jq -r '
    .AnomalyMonitors[] | "\(.MonitorName)\t\(.MonitorType)\tDimension: \(.MonitorDimension // "N/A")"
' | column -t

echo ""
echo "=== Recent Cost Anomalies ==="
aws ce get-anomalies --date-interval Start=$(date -u -d '30 days ago' +%Y-%m-%d),End=$(date -u +%Y-%m-%d) --output json | jq -r '
    .Anomalies[] |
    "\(.AnomalyStartDate[0:10])\t\(.DimensionValue)\tExpected: $\(.Impact.MaxImpact)\tActual: $\(.Impact.TotalActualSpend // "N/A")\tSeverity: \(.AnomalyScore.MaxScore)"
' | sort -r | head -15
```

### Idle Resource Detection

```bash
#!/bin/bash
echo "=== Unattached EBS Volumes ==="
aws ec2 describe-volumes --filters Name=status,Values=available --output json | jq -r '
    .Volumes[] | "\(.VolumeId)\t\(.Size)GiB\t\(.VolumeType)\t\(.AvailabilityZone)\tCreated: \(.CreateTime[0:10])"
' | column -t | head -15

echo ""
echo "=== Unused Elastic IPs ==="
aws ec2 describe-addresses --output json | jq -r '
    .Addresses[] | select(.AssociationId == null) |
    "\(.PublicIp)\tAllocation: \(.AllocationId)\tDomain: \(.Domain)"
' | column -t

echo ""
echo "=== Idle Load Balancers ==="
for LB_ARN in $(aws elbv2 describe-load-balancers --output json | jq -r '.LoadBalancers[].LoadBalancerArn'); do
    TG_COUNT=$(aws elbv2 describe-target-groups --load-balancer-arn "$LB_ARN" --output json | jq '.TargetGroups | length')
    if [ "$TG_COUNT" = "0" ]; then
        aws elbv2 describe-load-balancers --load-balancer-arns "$LB_ARN" --output json | jq -r '
            .LoadBalancers[] | "\(.LoadBalancerName)\t\(.Type)\tNo target groups"
        '
    fi
done | head -10
```

## Safety Rules
- **Read-only first**: All optimization queries are read-only -- implementation is separate
- **Savings Plan purchases**: Never purchase Savings Plans without finance approval
- **Instance changes**: Rightsizing requires workload validation before resizing
- **Support plan requirement**: Trusted Advisor cost checks require Business or Enterprise support

## Common Pitfalls
- **Compute Optimizer enrollment**: Must be enrolled before recommendations are generated (takes 12+ hours)
- **Cost Explorer lag**: Cost data is delayed by 24-48 hours
- **Blended vs unblended**: Blended costs average RI discounts across linked accounts -- use unblended for true cost
- **Region scope**: Compute Optimizer and some checks are region-specific -- query all relevant regions
- **Savings Plan vs RI**: Savings Plans are more flexible than RIs -- evaluate both before purchasing
- **Tag-based analysis**: Untagged resources cannot be attributed -- enforce tagging policies first
