---
name: managing-vertex-ai
description: |
  Google Vertex AI platform management. Covers model management, training pipelines, prediction endpoints, feature store, experiments, datasets, and custom jobs. Use when managing ML models on GCP, deploying prediction endpoints, investigating training failures, or auditing Vertex AI resources.
connection_type: gcp
preload: false
---

# Vertex AI Management Skill

Manage and monitor Google Cloud Vertex AI ML platform resources.

## MANDATORY: Discovery-First Pattern

**Always list existing resources before creating or modifying anything.**

### Phase 1: Discovery

```bash
#!/bin/bash

REGION="${CLOUDSDK_COMPUTE_REGION:-us-central1}"
PROJECT="${CLOUDSDK_CORE_PROJECT:-$(gcloud config get-value project 2>/dev/null)}"

echo "=== Project & Region ==="
echo "Project: $PROJECT"
echo "Region: $REGION"

echo ""
echo "=== Models ==="
gcloud ai models list --region="$REGION" --format="table(name.basename(), displayName, createTime.date())" 2>/dev/null | head -15

echo ""
echo "=== Endpoints ==="
gcloud ai endpoints list --region="$REGION" --format="table(name.basename(), displayName, createTime.date())" 2>/dev/null | head -15

echo ""
echo "=== Training Pipelines ==="
gcloud ai custom-jobs list --region="$REGION" --format="table(name.basename(), displayName, state, createTime.date())" 2>/dev/null | head -10

echo ""
echo "=== Feature Stores ==="
gcloud ai featurestores list --region="$REGION" --format="table(name.basename(), state, createTime.date())" 2>/dev/null | head -10
```

## Core Helper Functions

```bash
#!/bin/bash

REGION="${CLOUDSDK_COMPUTE_REGION:-us-central1}"
PROJECT="${CLOUDSDK_CORE_PROJECT:-$(gcloud config get-value project 2>/dev/null)}"

# Vertex AI REST API helper
vertex_api() {
    local method="${1:-GET}"
    local endpoint="$2"
    local data="${3:-}"
    local base="https://${REGION}-aiplatform.googleapis.com/v1"
    local url="${base}/projects/${PROJECT}/locations/${REGION}/${endpoint}"
    local token
    token=$(gcloud auth print-access-token 2>/dev/null)

    if [ -n "$data" ]; then
        curl -s -X "$method" -H "Authorization: Bearer $token" \
            -H "Content-Type: application/json" "$url" -d "$data"
    else
        curl -s -X "$method" -H "Authorization: Bearer $token" "$url"
    fi
}

# gcloud AI wrapper
vai() {
    gcloud ai "$@" --region="$REGION" --format=json 2>/dev/null
}
```

## Output Rules
- **TOKEN EFFICIENCY**: Target ≤50 lines per output
- Use `--format=json` with jq or `--format=table` for CLI
- Never dump full resource descriptions -- extract key fields
- Use resource basename instead of full resource path in displays

## Common Operations

### Model Registry and Versions

```bash
#!/bin/bash
echo "=== All Models ==="
vai models list | jq -r '.[] | "\(.name | split("/")[-1])\t\(.displayName)\t\(.createTime[0:16])"' | column -t

MODEL_ID="${1:-}"
if [ -n "$MODEL_ID" ]; then
    echo ""
    echo "=== Model Details ==="
    vai models describe "$MODEL_ID" | jq '{
        id: (.name | split("/")[-1]),
        display_name: .displayName,
        container: .containerSpec.imageUri,
        artifact_uri: .artifactUri,
        created: .createTime,
        deployed_models: [.deployedModels[]? | {endpoint: (.endpoint | split("/")[-1]), id: .deployedModelId}]
    }'

    echo ""
    echo "=== Model Versions ==="
    vai models list-versions "$MODEL_ID" | jq -r '
        .[] | "\(.name | split("/")[-1])\t\(.versionId)\t\(.createTime[0:16])"
    ' | column -t | head -10
fi
```

### Endpoint Health and Traffic

```bash
#!/bin/bash
echo "=== Endpoint Summary ==="
vai endpoints list | jq -r '.[] | "\(.name | split("/")[-1])\t\(.displayName)\t\(.deployedModels | length) models"' | column -t

ENDPOINT_ID="${1:-}"
if [ -n "$ENDPOINT_ID" ]; then
    echo ""
    echo "=== Deployed Models on $ENDPOINT_ID ==="
    vai endpoints describe "$ENDPOINT_ID" | jq '{
        id: (.name | split("/")[-1]),
        display_name: .displayName,
        deployed_models: [.deployedModels[]? | {
            model_id: .id,
            display_name: .displayName,
            machine_type: .dedicatedResources.machineSpec.machineType,
            min_replicas: .dedicatedResources.minReplicaCount,
            max_replicas: .dedicatedResources.maxReplicaCount,
            traffic_split: .trafficPercentage
        }]
    }'
fi
```

### Training Pipeline Status

```bash
#!/bin/bash
echo "=== Training Pipelines ==="
vai training-pipelines list | jq -r '
    .[] | "\(.name | split("/")[-1])\t\(.displayName)\t\(.state)\t\(.createTime[0:16])"
' | column -t | head -15

PIPELINE_ID="${1:-}"
if [ -n "$PIPELINE_ID" ]; then
    echo ""
    echo "=== Pipeline Details ==="
    vai training-pipelines describe "$PIPELINE_ID" | jq '{
        state: .state,
        error: .error,
        training_task: .trainingTaskDefinition,
        start_time: .startTime,
        end_time: .endTime,
        model_to_upload: .modelToUpload.displayName
    }'
fi
```

### Experiment Tracking

```bash
#!/bin/bash
echo "=== Experiments ==="
vertex_api GET "metadataStores/default/contexts?filter=schema_title=%22system.Experiment%22" \
    | jq -r '.contexts[]? | "\(.name | split("/")[-1])\t\(.createTime[0:16])"' | column -t | head -15

EXPERIMENT="${1:-}"
if [ -n "$EXPERIMENT" ]; then
    echo ""
    echo "=== Runs in $EXPERIMENT ==="
    vertex_api GET "metadataStores/default/contexts?filter=schema_title=%22system.ExperimentRun%22%20AND%20parent_contexts=%22projects/${PROJECT}/locations/${REGION}/metadataStores/default/contexts/${EXPERIMENT}%22" \
        | jq -r '.contexts[]? | "\(.name | split("/")[-1])\t\(.metadata.state // "unknown")\t\(.createTime[0:16])"' | column -t | head -20
fi
```

### Feature Store Management

```bash
#!/bin/bash
echo "=== Feature Stores ==="
vai featurestores list | jq -r '.[] | "\(.name | split("/")[-1])\t\(.state)\t\(.onlineServingConfig.fixedNodeCount // 0) nodes"' | column -t

FS_NAME="${1:-}"
if [ -n "$FS_NAME" ]; then
    echo ""
    echo "=== Entity Types in $FS_NAME ==="
    vai featurestores entity-types list --featurestore="$FS_NAME" \
        | jq -r '.[] | "\(.name | split("/")[-1])\t\(.createTime[0:16])"' | column -t
fi
```

## Safety Rules

- **NEVER undeploy models from production endpoints** without explicit confirmation -- causes immediate prediction failures
- **NEVER delete models** that have active deployments -- undeploy first
- **Always check traffic split** before modifying endpoint configurations
- **Cost awareness**: GPU machines (n1-standard + NVIDIA T4/V100/A100) incur high costs -- verify machine type before launching
- **Quota limits**: Check regional quotas before launching large training jobs

## Common Pitfalls

- **Region consistency**: Models, endpoints, and datasets must be in the same region -- cross-region references fail
- **Endpoint traffic split**: Traffic percentages must sum to 100 -- partial updates cause deployment errors
- **Custom container ports**: Vertex AI expects predictions on port 8080 by default -- configure AIP_HTTP_PORT if different
- **Service account permissions**: Custom training jobs need the Vertex AI Service Agent role -- missing permissions cause silent failures
- **Pipeline caching**: Vertex Pipelines cache steps by default -- use `enable_caching=False` for non-deterministic steps
- **Feature store ingestion**: Online serving has eventual consistency -- writes may not be immediately readable
- **Quota exhaustion**: GPU quota is per-region -- training jobs queue indefinitely when quota is exhausted
- **Model artifacts**: Model must be in GCS -- local paths are not supported for deployment
