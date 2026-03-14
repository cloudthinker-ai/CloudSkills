---
name: managing-sagemaker
description: |
  AWS SageMaker ML platform management. Covers training jobs, model endpoints, model registry, pipelines, feature store, experiments, and hyperparameter tuning. Use when managing ML training workflows, deploying model endpoints, investigating failed training jobs, or auditing SageMaker resource utilization.
connection_type: aws
preload: false
---

# SageMaker Management Skill

Manage and monitor AWS SageMaker ML training, deployment, and operations.

## MANDATORY: Discovery-First Pattern

**Always list existing resources before creating or modifying anything.**

### Phase 1: Discovery

```bash
#!/bin/bash

sm_api() {
    aws sagemaker "$@" --output json 2>/dev/null
}

echo "=== SageMaker Domain ==="
sm_api list-domains | jq -r '.Domains[] | "\(.DomainId)\t\(.DomainName)\t\(.Status)"' | column -t

echo ""
echo "=== Recent Training Jobs ==="
sm_api list-training-jobs --max-results 10 --sort-by CreationTime --sort-order Descending \
    | jq -r '.TrainingJobSummaries[] | "\(.TrainingJobName)\t\(.TrainingJobStatus)\t\(.CreationTime[0:16])"' | column -t

echo ""
echo "=== Active Endpoints ==="
sm_api list-endpoints --sort-by CreationTime --sort-order Descending \
    | jq -r '.Endpoints[] | "\(.EndpointName)\t\(.EndpointStatus)\t\(.CreationTime[0:16])"' | column -t

echo ""
echo "=== Model Registry ==="
sm_api list-model-package-groups --max-results 10 \
    | jq -r '.ModelPackageGroupSummaryList[] | "\(.ModelPackageGroupName)\t\(.CreationTime[0:16])"' | column -t
```

## Core Helper Functions

```bash
#!/bin/bash

# SageMaker CLI wrapper
sm_api() {
    aws sagemaker "$@" --output json 2>/dev/null
}

# CloudWatch logs for training jobs
sm_logs() {
    local job_name="$1"
    local log_group="/aws/sagemaker/TrainingJobs"
    aws logs get-log-events \
        --log-group-name "$log_group" \
        --log-stream-name "${job_name}/algo-1-$(date +%s)" \
        --limit 50 --output json 2>/dev/null | jq -r '.events[].message'
}

# Describe any resource with truncated output
sm_describe() {
    local resource_type="$1"
    local resource_name="$2"
    sm_api "describe-${resource_type}" --"${resource_type}-name" "$resource_name" | jq 'del(.ResponseMetadata)' | head -50
}
```

## Output Rules
- **TOKEN EFFICIENCY**: Target ≤50 lines per output
- Use `--output json` with jq filtering for all commands
- Never dump full describe output -- extract key fields
- Truncate ARNs to resource name when displaying lists

## Common Operations

### Training Job Status and Debugging

```bash
#!/bin/bash
JOB_NAME="${1:?Training job name required}"

echo "=== Training Job Details ==="
sm_api describe-training-job --training-job-name "$JOB_NAME" | jq '{
    name: .TrainingJobName,
    status: .TrainingJobStatus,
    failure_reason: .FailureReason,
    instance_type: .ResourceConfig.InstanceType,
    instance_count: .ResourceConfig.InstanceCount,
    duration_seconds: (.TrainingEndTime // now | tostring | split(".")[0] | tonumber) - (.TrainingStartTime | tostring | split(".")[0] | tonumber),
    algorithm: (.AlgorithmSpecification.TrainingImage // .AlgorithmSpecification.AlgorithmName),
    input_channels: [.InputDataConfig[]? | .ChannelName],
    output_path: .OutputDataConfig.S3OutputPath,
    billable_seconds: .BillableTimeInSeconds
}'

echo ""
echo "=== Metrics ==="
sm_api describe-training-job --training-job-name "$JOB_NAME" | jq -r '
    .FinalMetricDataList[]? | "\(.MetricName)\t\(.Value)\t\(.Timestamp[0:16])"
' | column -t
```

### Endpoint Health and Monitoring

```bash
#!/bin/bash
echo "=== All Endpoints Status ==="
sm_api list-endpoints | jq -r '
    .Endpoints[] | "\(.EndpointName)\t\(.EndpointStatus)\t\(.CreationTime[0:16])"
' | column -t

ENDPOINT="${1:-}"
if [ -n "$ENDPOINT" ]; then
    echo ""
    echo "=== Endpoint Config: $ENDPOINT ==="
    sm_api describe-endpoint --endpoint-name "$ENDPOINT" | jq '{
        name: .EndpointName,
        status: .EndpointStatus,
        config: .EndpointConfigName,
        creation: .CreationTime,
        last_modified: .LastModifiedTime,
        variants: [.ProductionVariants[]? | {name: .VariantName, weight: .CurrentWeight, instance_type: .CurrentInstanceCount}]
    }'

    echo ""
    echo "=== Endpoint Metrics (last hour) ==="
    aws cloudwatch get-metric-statistics \
        --namespace AWS/SageMaker \
        --metric-name Invocations \
        --dimensions Name=EndpointName,Value="$ENDPOINT" \
        --start-time "$(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S)" \
        --end-time "$(date -u +%Y-%m-%dT%H:%M:%S)" \
        --period 300 --statistics Sum --output json 2>/dev/null \
        | jq -r '.Datapoints | sort_by(.Timestamp) | .[] | "\(.Timestamp[0:16])\t\(.Sum) invocations"'
fi
```

### Model Registry and Versioning

```bash
#!/bin/bash
GROUP_NAME="${1:?Model package group name required}"

echo "=== Model Packages in $GROUP_NAME ==="
sm_api list-model-packages \
    --model-package-group-name "$GROUP_NAME" \
    --sort-by CreationTime --sort-order Descending --max-results 10 \
    | jq -r '.ModelPackageSummaryList[] | "\(.ModelPackageArn | split("/")[-1])\t\(.ModelPackageStatus)\t\(.ModelApprovalStatus)\t\(.CreationTime[0:16])"' | column -t

echo ""
echo "=== Latest Approved Model ==="
sm_api list-model-packages \
    --model-package-group-name "$GROUP_NAME" \
    --model-approval-status Approved --max-results 1 \
    | jq '.ModelPackageSummaryList[0]'
```

### Pipeline Execution Status

```bash
#!/bin/bash
echo "=== SageMaker Pipelines ==="
sm_api list-pipelines --max-results 10 \
    | jq -r '.PipelineSummaries[] | "\(.PipelineName)\t\(.CreationTime[0:16])"' | column -t

PIPELINE="${1:-}"
if [ -n "$PIPELINE" ]; then
    echo ""
    echo "=== Recent Executions: $PIPELINE ==="
    sm_api list-pipeline-executions --pipeline-name "$PIPELINE" --max-results 5 \
        | jq -r '.PipelineExecutionSummaries[] | "\(.PipelineExecutionArn | split("/")[-1])\t\(.PipelineExecutionStatus)\t\(.StartTime[0:16])"' | column -t
fi
```

### Feature Store Inspection

```bash
#!/bin/bash
echo "=== Feature Groups ==="
sm_api list-feature-groups --max-results 20 \
    | jq -r '.FeatureGroupSummaries[] | "\(.FeatureGroupName)\t\(.FeatureGroupStatus)\t\(.CreationTime[0:16])"' | column -t

FG_NAME="${1:-}"
if [ -n "$FG_NAME" ]; then
    echo ""
    echo "=== Feature Group Details: $FG_NAME ==="
    sm_api describe-feature-group --feature-group-name "$FG_NAME" | jq '{
        name: .FeatureGroupName,
        status: .FeatureGroupStatus,
        record_id: .RecordIdentifierFeatureName,
        event_time: .EventTimeFeatureName,
        online_store: (.OnlineStoreConfig != null),
        offline_store: (.OfflineStoreConfig != null),
        features: [.FeatureDefinitions[] | "\(.FeatureName):\(.FeatureType)"]
    }'
fi
```

## Safety Rules

- **NEVER delete endpoints in production** without explicit user confirmation -- this causes immediate downtime
- **NEVER approve model packages** without reviewing metrics -- always check validation results first
- **Always use DRY RUN** for pipeline triggers -- show parameters before executing
- **Cost awareness**: GPU instances (ml.p3, ml.p4, ml.g5) are expensive -- always check instance type before launching training
- **Endpoint auto-scaling**: Check scaling policies before modifying endpoint configurations

## Common Pitfalls

- **Training job timeout**: Default max runtime is 86400s (24h) -- long-running jobs may be killed silently
- **Endpoint update vs create**: Updating endpoint config creates a new config -- old configs are not auto-deleted
- **S3 permissions**: Training jobs need IAM role with S3 access to input/output buckets -- check role trust policy
- **VPC mode**: Training in VPC mode requires NAT gateway for internet access -- common cause of stuck jobs
- **Spot training**: Spot instances can be interrupted -- enable checkpointing to avoid losing progress
- **Model registry approval**: Models must be explicitly approved before deployment -- Pending status blocks pipelines
- **Feature store sync**: Online and offline stores may have sync lag -- materialization jobs must complete first
- **Pipeline retries**: Failed pipeline steps do not auto-retry by default -- configure retry policies explicitly
