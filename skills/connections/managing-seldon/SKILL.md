---
name: managing-seldon
description: |
  Use when working with Seldon — seldon Core model deployment and inference
  management on Kubernetes. Covers model deployment, inference graphs, A/B
  testing, canary rollouts, monitoring, and explainability. Use when deploying
  ML models to Kubernetes, configuring inference pipelines, managing traffic
  splitting, or debugging prediction failures.
connection_type: seldon
preload: false
---

# Seldon Core Management Skill

Manage and monitor Seldon Core model deployments, inference graphs, and traffic management.

## MANDATORY: Discovery-First Pattern

**Always list existing deployments and their status before creating or modifying anything.**

### Phase 1: Discovery

```bash
#!/bin/bash

NAMESPACE="${SELDON_NAMESPACE:-default}"

echo "=== Seldon Core Version ==="
kubectl get deployment -n seldon-system seldon-controller-manager -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null
echo ""

echo ""
echo "=== Seldon Deployments ==="
kubectl get seldondeployments -n "$NAMESPACE" -o json 2>/dev/null | jq -r '
    .items[] | "\(.metadata.name)\t\(.status.state // "Unknown")\t\(.status.replicas // 0) replicas\t\(.metadata.creationTimestamp[0:16])"
' | column -t

echo ""
echo "=== Deployment Pods ==="
kubectl get pods -n "$NAMESPACE" -l seldon-deployment-id --no-headers 2>/dev/null \
    | awk '{print $1"\t"$3"\t"$4"\t"$5}' | head -15

echo ""
echo "=== Istio Virtual Services (if present) ==="
kubectl get virtualservices -n "$NAMESPACE" -l seldon-deployment-id --no-headers 2>/dev/null | head -10
```

## Core Helper Functions

```bash
#!/bin/bash

NAMESPACE="${SELDON_NAMESPACE:-default}"

# Seldon prediction helper
seldon_predict() {
    local deployment="$1"
    local data="$2"
    local endpoint="${SELDON_ENDPOINT:-http://localhost:8003}"
    curl -s -X POST "${endpoint}/seldon/${NAMESPACE}/${deployment}/api/v1.0/predictions" \
        -H "Content-Type: application/json" -d "$data"
}

# kubectl wrapper for Seldon CRDs
seldon_get() {
    local deployment="$1"
    kubectl get seldondeployment "$deployment" -n "$NAMESPACE" -o json 2>/dev/null
}

# Seldon deployment status check
seldon_status() {
    local deployment="$1"
    kubectl get seldondeployment "$deployment" -n "$NAMESPACE" -o jsonpath='{.status.state}' 2>/dev/null
}
```

## Output Rules
- **TOKEN EFFICIENCY**: Target ≤50 lines per output
- Use kubectl with jq for structured CRD queries
- Never dump full SeldonDeployment specs -- extract key fields
- Test predictions with minimal sample payloads

## Common Operations

### Deployment Health Dashboard

```bash
#!/bin/bash
echo "=== Deployment Status Overview ==="
kubectl get seldondeployments -n "$NAMESPACE" -o json 2>/dev/null | jq -r '
    .items[] | "\(.metadata.name)\t\(.status.state // "Unknown")\t\(.status.deploymentStatus | to_entries | map("\(.key)=\(.value.replicas // 0)") | join(","))"
' | column -t

echo ""
echo "=== Unhealthy Deployments ==="
kubectl get seldondeployments -n "$NAMESPACE" -o json 2>/dev/null | jq -r '
    .items[] | select(.status.state != "Available") |
    "\(.metadata.name)\t\(.status.state // "Unknown")\t\(.status.description // "no details")"
' | column -t

echo ""
echo "=== Pod Health ==="
kubectl get pods -n "$NAMESPACE" -l seldon-deployment-id -o json 2>/dev/null | jq -r '
    .items[] | select(.status.phase != "Running") |
    "\(.metadata.name)\t\(.status.phase)\t\(.status.conditions[-1].message // "")"
' | column -t
```

### Inference Graph Inspection

```bash
#!/bin/bash
DEPLOYMENT="${1:?Deployment name required}"

echo "=== Inference Graph: $DEPLOYMENT ==="
seldon_get "$DEPLOYMENT" | jq '{
    name: .metadata.name,
    state: .status.state,
    predictors: [.spec.predictors[] | {
        name: .name,
        traffic: .traffic,
        replicas: .replicas,
        graph: (.graph | {name: .name, type: .type, implementation: .implementation, children: [.children[]?.name]}),
        components: [.componentSpecs[]?.spec.containers[]? | {name: .name, image: .image}]
    }]
}'
```

### A/B Testing Configuration

```bash
#!/bin/bash
DEPLOYMENT="${1:?Deployment name required}"

echo "=== Traffic Split: $DEPLOYMENT ==="
seldon_get "$DEPLOYMENT" | jq -r '
    .spec.predictors[] | "\(.name)\ttraffic=\(.traffic)%\treplicas=\(.replicas)\tmodel=\(.graph.name)"
' | column -t

echo ""
echo "=== A/B Test Metrics ==="
# Check if Seldon analytics is available
ANALYTICS_URL="${SELDON_ANALYTICS_URL:-http://localhost:8080}"
curl -s "${ANALYTICS_URL}/seldon-deploy/api/v1alpha1/analytics/prediction?deployment=${DEPLOYMENT}&namespace=${NAMESPACE}" 2>/dev/null \
    | jq '{
        total_predictions: .totalPredictions,
        by_predictor: .predictorPredictions,
        latency_p50: .latencyP50,
        latency_p99: .latencyP99
    }' 2>/dev/null || echo "Analytics endpoint not available -- check Seldon Deploy installation"
```

### Canary Rollout Management

```bash
#!/bin/bash
DEPLOYMENT="${1:?Deployment name required}"
DRY_RUN="${2:-true}"

echo "=== Current Traffic Split ==="
seldon_get "$DEPLOYMENT" | jq -r '
    .spec.predictors[] | "\(.name)\ttraffic=\(.traffic)%\timage=\(.componentSpecs[0].spec.containers[0].image // "N/A")"
' | column -t

if [ "$DRY_RUN" = "true" ]; then
    echo ""
    echo "DRY RUN: To modify traffic, update the SeldonDeployment spec with new traffic percentages"
    echo "Ensure all predictor traffic values sum to 100"
else
    echo ""
    echo "Apply traffic changes via kubectl apply or Seldon Deploy API"
fi
```

### Monitoring and Metrics

```bash
#!/bin/bash
DEPLOYMENT="${1:?Deployment name required}"

echo "=== Prediction Metrics (Prometheus) ==="
# Query Seldon metrics from Prometheus
PROM_URL="${PROMETHEUS_URL:-http://localhost:9090}"
curl -s "${PROM_URL}/api/v1/query?query=seldon_api_executor_server_requests_seconds_count{deployment_name=\"${DEPLOYMENT}\"}" 2>/dev/null \
    | jq -r '.data.result[]? | "\(.metric.method)\t\(.metric.code)\tcount=\(.value[1])"' | column -t

echo ""
echo "=== Latency (p99) ==="
curl -s "${PROM_URL}/api/v1/query?query=histogram_quantile(0.99,rate(seldon_api_executor_server_requests_seconds_bucket{deployment_name=\"${DEPLOYMENT}\"}[5m]))" 2>/dev/null \
    | jq -r '.data.result[]? | "\(.metric.method)\tp99=\(.value[1])s"' | column -t

echo ""
echo "=== Container Logs (last errors) ==="
kubectl logs -n "$NAMESPACE" -l seldon-deployment-id="$DEPLOYMENT" --tail=20 2>/dev/null \
    | grep -iE 'error|exception|fail' | tail -10
```

## Safety Rules

- **NEVER delete SeldonDeployments** serving production traffic without draining connections first
- **NEVER set traffic to 0%** on all predictors -- at least one predictor must receive traffic
- **Always validate traffic percentages sum to 100** before applying changes
- **Test predictions** with sample data after any deployment update
- **Canary rollbacks**: If canary shows errors, immediately shift traffic back to the stable predictor

## Output Format

Present results as a structured report:
```
Managing Seldon Report
══════════════════════
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

## Common Pitfalls

- **Image pull errors**: Private registries need imagePullSecrets in the SeldonDeployment spec -- missing secrets cause pods to hang in ImagePullBackOff
- **Resource limits**: Models without resource limits can OOM-kill other pods on the node -- always set memory limits
- **Graph type confusion**: ROUTER, COMBINER, and MODEL types have different behaviors -- incorrect type causes routing errors
- **Istio sidecar injection**: Seldon with Istio requires sidecar injection enabled -- missing sidecars break service mesh routing
- **Prepackaged servers**: Built-in servers (sklearn, xgboost, tensorflow) expect specific model artifact formats -- format mismatches cause load failures
- **Init containers**: Model download happens in init containers -- slow S3/GCS downloads cause long startup times
- **Batch processing**: Seldon batch jobs are separate from real-time serving -- do not mix configurations
- **Version conflicts**: Seldon operator version must be compatible with CRD versions -- check compatibility matrix before upgrading
