---
name: managing-kubeflow
description: |
  Kubeflow ML platform management on Kubernetes. Covers pipeline management, experiment tracking, notebook servers, KFServing/KServe inference, Katib hyperparameter tuning, and training operators. Use when managing ML pipelines, deploying inference services, investigating training failures, or auditing Kubeflow resources.
connection_type: kubeflow
preload: false
---

# Kubeflow Management Skill

Manage and monitor Kubeflow ML platform components on Kubernetes.

## MANDATORY: Discovery-First Pattern

**Always list namespaces and existing resources before creating or modifying anything.**

### Phase 1: Discovery

```bash
#!/bin/bash

KUBEFLOW_HOST="${KUBEFLOW_HOST:-http://localhost:8080}"
NAMESPACE="${KUBEFLOW_NAMESPACE:-kubeflow}"

kf_api() {
    local endpoint="$1"
    curl -s -H "Authorization: Bearer $KUBEFLOW_TOKEN" \
        "${KUBEFLOW_HOST}/pipeline/apis/v2beta1/${endpoint}"
}

echo "=== Kubeflow Namespaces ==="
kubectl get namespaces -l app.kubernetes.io/part-of=kubeflow --no-headers 2>/dev/null | head -10

echo ""
echo "=== Pipelines ==="
kf_api "pipelines?page_size=15" | jq -r '
    .pipelines[]? | "\(.pipeline_id[0:8])\t\(.display_name)\t\(.created_at[0:16])"
' | column -t

echo ""
echo "=== Experiments ==="
kf_api "experiments?page_size=15" | jq -r '
    .experiments[]? | "\(.experiment_id[0:8])\t\(.display_name)\t\(.created_at[0:16])"
' | column -t

echo ""
echo "=== Notebook Servers ==="
kubectl get notebooks -n "$NAMESPACE" --no-headers 2>/dev/null \
    | awk '{print $1"\t"$2"\t"$3}' | head -10

echo ""
echo "=== Inference Services ==="
kubectl get inferenceservices -n "$NAMESPACE" --no-headers 2>/dev/null \
    | awk '{print $1"\t"$2"\t"$3"\t"$4}' | head -10
```

## Core Helper Functions

```bash
#!/bin/bash

KUBEFLOW_HOST="${KUBEFLOW_HOST:-http://localhost:8080}"

# Kubeflow Pipelines API helper
kf_api() {
    local endpoint="$1"
    curl -s -H "Authorization: Bearer $KUBEFLOW_TOKEN" \
        "${KUBEFLOW_HOST}/pipeline/apis/v2beta1/${endpoint}"
}

kf_api_post() {
    local endpoint="$1"
    local data="$2"
    curl -s -X POST -H "Authorization: Bearer $KUBEFLOW_TOKEN" \
        -H "Content-Type: application/json" \
        "${KUBEFLOW_HOST}/pipeline/apis/v2beta1/${endpoint}" -d "$data"
}

# kubectl wrapper for Kubeflow CRDs
kf_get() {
    local resource="$1"
    local namespace="${2:-$KUBEFLOW_NAMESPACE}"
    kubectl get "$resource" -n "$namespace" -o json 2>/dev/null
}
```

## Output Rules
- **TOKEN EFFICIENCY**: Target ≤50 lines per output
- Use Pipelines API with jq for pipeline/experiment queries
- Use kubectl for CRD-based resources (notebooks, inference services, training jobs)
- Never dump full pipeline specs -- extract key fields

## Common Operations

### Pipeline Management

```bash
#!/bin/bash
echo "=== All Pipelines ==="
kf_api "pipelines?page_size=20" | jq -r '
    .pipelines[]? | "\(.pipeline_id[0:8])\t\(.display_name)\t\(.created_at[0:16])"
' | column -t

PIPELINE_ID="${1:-}"
if [ -n "$PIPELINE_ID" ]; then
    echo ""
    echo "=== Pipeline Versions ==="
    kf_api "pipelines/${PIPELINE_ID}/versions?page_size=10" | jq -r '
        .pipeline_versions[]? | "\(.pipeline_version_id[0:8])\t\(.display_name)\t\(.created_at[0:16])"
    ' | column -t

    echo ""
    echo "=== Recent Runs ==="
    kf_api "runs?page_size=10&sort_by=created_at%20desc&filter={\"predicates\":[{\"key\":\"pipeline_id\",\"operation\":\"EQUALS\",\"string_value\":\"${PIPELINE_ID}\"}]}" \
        | jq -r '.runs[]? | "\(.run_id[0:8])\t\(.display_name)\t\(.state)\t\(.created_at[0:16])"' | column -t
fi
```

### Experiment Tracking

```bash
#!/bin/bash
EXPERIMENT_ID="${1:?Experiment ID required}"

echo "=== Experiment Runs ==="
kf_api "runs?page_size=15&sort_by=created_at%20desc&filter={\"predicates\":[{\"key\":\"experiment_id\",\"operation\":\"EQUALS\",\"string_value\":\"${EXPERIMENT_ID}\"}]}" \
    | jq -r '.runs[]? | "\(.run_id[0:8])\t\(.display_name)\t\(.state)\t\(.created_at[0:16])\t\(.finished_at[0:16] // "running")"' | column -t

echo ""
echo "=== Run States Summary ==="
kf_api "runs?page_size=100&filter={\"predicates\":[{\"key\":\"experiment_id\",\"operation\":\"EQUALS\",\"string_value\":\"${EXPERIMENT_ID}\"}]}" \
    | jq '[.runs[]?.state] | group_by(.) | map({state: .[0], count: length})'
```

### Notebook Server Management

```bash
#!/bin/bash
NAMESPACE="${1:-$KUBEFLOW_NAMESPACE}"

echo "=== Notebook Servers ==="
kubectl get notebooks -n "$NAMESPACE" -o json 2>/dev/null | jq -r '
    .items[] | "\(.metadata.name)\t\(.status.conditions[-1].type // "Unknown")\t\(.spec.template.spec.containers[0].resources.limits // {} | to_entries | map("\(.key)=\(.value)") | join(","))"
' | column -t

echo ""
echo "=== Notebook Pod Status ==="
kubectl get pods -n "$NAMESPACE" -l app=notebook --no-headers 2>/dev/null \
    | awk '{print $1"\t"$3"\t"$4"\t"$5}' | head -15

echo ""
echo "=== PVC Usage ==="
kubectl get pvc -n "$NAMESPACE" -l app=notebook --no-headers 2>/dev/null \
    | awk '{print $1"\t"$2"\t"$4"\t"$6}' | head -10
```

### KServe Inference Services

```bash
#!/bin/bash
NAMESPACE="${1:-$KUBEFLOW_NAMESPACE}"

echo "=== Inference Services ==="
kubectl get inferenceservices -n "$NAMESPACE" -o json 2>/dev/null | jq -r '
    .items[] | "\(.metadata.name)\t\(.status.conditions[] | select(.type=="Ready") | .status)\t\(.status.url // "no-url")"
' | column -t

ISVC="${2:-}"
if [ -n "$ISVC" ]; then
    echo ""
    echo "=== InferenceService Detail: $ISVC ==="
    kubectl get inferenceservice "$ISVC" -n "$NAMESPACE" -o json 2>/dev/null | jq '{
        name: .metadata.name,
        ready: (.status.conditions[] | select(.type=="Ready") | .status),
        url: .status.url,
        predictor: .spec.predictor,
        traffic: .status.components.predictor.traffic
    }' | head -30
fi
```

### Katib Hyperparameter Tuning

```bash
#!/bin/bash
NAMESPACE="${1:-$KUBEFLOW_NAMESPACE}"

echo "=== Katib Experiments ==="
kubectl get experiments.kubeflow.org -n "$NAMESPACE" -o json 2>/dev/null | jq -r '
    .items[] | "\(.metadata.name)\t\(.status.conditions[-1].type // "Unknown")\t\(.status.currentOptimalTrial.bestTrialName // "none")\ttrials=\(.status.trialsSucceeded // 0)/\(.status.trials // 0)"
' | column -t

EXPERIMENT="${2:-}"
if [ -n "$EXPERIMENT" ]; then
    echo ""
    echo "=== Best Trial: $EXPERIMENT ==="
    kubectl get experiment.kubeflow.org "$EXPERIMENT" -n "$NAMESPACE" -o json 2>/dev/null | jq '{
        optimal_trial: .status.currentOptimalTrial.bestTrialName,
        optimal_metric: .status.currentOptimalTrial.observation,
        parameters: .status.currentOptimalTrial.parameterAssignments
    }'
fi
```

## Safety Rules

- **NEVER delete pipelines or experiments** without checking for active runs -- running jobs will be orphaned
- **NEVER scale down inference services** without checking current traffic -- causes immediate prediction failures
- **Always check notebook server PVCs** before deleting -- user data may be stored on persistent volumes
- **Katib experiments**: Do not terminate experiments prematurely -- partial results may be misleading
- **Namespace isolation**: Verify the correct namespace before any operation -- multi-tenant environments share the cluster

## Common Pitfalls

- **Istio auth**: Kubeflow behind Istio requires proper auth headers -- missing tokens cause silent 403 errors
- **Pipeline version confusion**: Pipeline IDs and version IDs are different -- always specify the version for reproducibility
- **Notebook image compatibility**: Custom notebook images must include Jupyter server -- missing dependencies cause startup failures
- **KServe model formats**: Model storage format must match the serving runtime -- mismatches cause load failures
- **Resource quotas**: Namespace resource quotas can block notebook or training job creation -- check quota before launching
- **Katib metrics collection**: Katib scrapes metrics from training logs -- incorrect metric name or log format causes missing results
- **Multi-user isolation**: Profile namespaces are per-user -- cross-namespace access requires explicit RBAC
- **Pipeline artifacts**: Large artifacts in MinIO/S3 can fill storage -- monitor artifact store capacity
