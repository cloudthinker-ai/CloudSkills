---
name: managing-k8s-hpa-vpa
description: |
  Kubernetes HPA and VPA autoscaling management. Covers HorizontalPodAutoscaler configurations, scaling history, target utilization, current vs desired replicas, VerticalPodAutoscaler recommendations, update modes, and scaling event analysis. Use when debugging autoscaling behavior, reviewing scaling policies, analyzing resource right-sizing, or optimizing autoscaler configurations.
connection_type: k8s
preload: false
---

# Kubernetes HPA and VPA Autoscaling Skill

Manage and analyze HorizontalPodAutoscalers and VerticalPodAutoscalers for workload scaling.

## MANDATORY: Discovery-First Pattern

**Always list HPAs and VPAs before analyzing scaling behavior.**

### Phase 1: Discovery

```bash
#!/bin/bash

echo "=== HorizontalPodAutoscalers (all namespaces) ==="
kubectl get hpa --all-namespaces -o custom-columns='NAMESPACE:.metadata.namespace,NAME:.metadata.name,REFERENCE:.spec.scaleTargetRef.name,TARGETS:.status.currentMetrics[*].resource.current.averageUtilization,MIN:.spec.minReplicas,MAX:.spec.maxReplicas,CURRENT:.status.currentReplicas' 2>/dev/null | head -20

echo ""
echo "=== VerticalPodAutoscalers ==="
kubectl get vpa --all-namespaces -o custom-columns='NAMESPACE:.metadata.namespace,NAME:.metadata.name,MODE:.spec.updatePolicy.updateMode,TARGET:.spec.targetRef.name' 2>/dev/null | head -20

echo ""
echo "=== HPA Details ==="
kubectl get hpa --all-namespaces -o json 2>/dev/null | jq -r '
  .items[] |
  "\(.metadata.namespace)/\(.metadata.name)\tRef:\(.spec.scaleTargetRef.kind)/\(.spec.scaleTargetRef.name)\tMin:\(.spec.minReplicas // 1)\tMax:\(.spec.maxReplicas)\tCurrent:\(.status.currentReplicas)\tDesired:\(.status.desiredReplicas)"
' | head -20
```

### Phase 2: Analysis

```bash
#!/bin/bash

echo "=== HPA Scaling Status ==="
kubectl get hpa --all-namespaces -o json 2>/dev/null | jq -r '
  .items[] |
  "\(.metadata.namespace)/\(.metadata.name)\tConditions:" +
  ([.status.conditions[]? | "\(.type)=\(.status)"] | join(","))
' | head -15

echo ""
echo "=== HPAs at Max Replicas ==="
kubectl get hpa --all-namespaces -o json 2>/dev/null | jq -r '
  .items[] |
  select(.status.currentReplicas >= .spec.maxReplicas) |
  "\(.metadata.namespace)/\(.metadata.name)\tCurrent:\(.status.currentReplicas)\tMax:\(.spec.maxReplicas)\tWARN:AT_MAX"
' | head -10

echo ""
echo "=== HPAs Unable to Scale ==="
kubectl get hpa --all-namespaces -o json 2>/dev/null | jq -r '
  .items[] |
  select(.status.conditions[]? | select(.type == "ScalingActive" and .status != "True")) |
  "\(.metadata.namespace)/\(.metadata.name)\t\(.status.conditions[] | select(.type == "ScalingActive") | .reason): \(.message // "")[0:80]"
' | head -10

echo ""
echo "=== HPA Metric Sources ==="
kubectl get hpa --all-namespaces -o json 2>/dev/null | jq -r '
  .items[] |
  "\(.metadata.namespace)/\(.metadata.name)\tMetrics:" +
  ([.spec.metrics[]? |
    if .type == "Resource" then "\(.resource.name):\(.resource.target.averageUtilization // .resource.target.averageValue)%"
    elif .type == "Pods" then "pods:\(.pods.metric.name)"
    elif .type == "Object" then "object:\(.object.metric.name)"
    elif .type == "External" then "external:\(.external.metric.name)"
    else .type end
  ] | join(","))
' | head -15

echo ""
echo "=== VPA Recommendations ==="
kubectl get vpa --all-namespaces -o json 2>/dev/null | jq -r '
  .items[] |
  "\(.metadata.namespace)/\(.metadata.name)\tMode:\(.spec.updatePolicy.updateMode // "Auto")" as $header |
  .status.recommendation.containerRecommendations[]? |
  "\($header)\tContainer:\(.containerName)\tTarget-CPU:\(.target.cpu)\tTarget-Mem:\(.target.memory)\tUpperBound-CPU:\(.upperBound.cpu)\tUpperBound-Mem:\(.upperBound.memory)"
' | head -15

echo ""
echo "=== HPA Scaling Behavior ==="
kubectl get hpa --all-namespaces -o json 2>/dev/null | jq -r '
  .items[] |
  select(.spec.behavior != null) |
  "\(.metadata.namespace)/\(.metadata.name)\tScaleUp:\(.spec.behavior.scaleUp.stabilizationWindowSeconds // 0)s\tScaleDown:\(.spec.behavior.scaleDown.stabilizationWindowSeconds // 300)s"
' | head -10

echo ""
echo "=== Recent Scaling Events ==="
kubectl get events --all-namespaces --field-selector reason=SuccessfulRescale -o custom-columns='NAMESPACE:.metadata.namespace,NAME:.involvedObject.name,MESSAGE:.message,TIME:.lastTimestamp' 2>/dev/null | head -10
```

## Output Format

- Target ≤50 lines per output
- Show current/desired/min/max replicas in a single line per HPA
- Display VPA recommendations with target and upper-bound values
- Flag HPAs at max replicas or unable to scale
- Never modify autoscaler settings in analysis -- read-only inspection

## Common Pitfalls

- **Metrics Server required**: HPA needs Metrics Server for CPU/memory metrics -- check metrics-server health
- **HPA + VPA conflict**: Using HPA and VPA on the same metric (CPU/memory) causes conflicts -- use VPA in recommendation-only mode with HPA
- **Stabilization window**: Default scale-down stabilization is 300s -- prevents flapping but delays scale-down
- **Custom metrics**: External/custom metrics require metrics adapters (Prometheus Adapter, Datadog, etc.)
- **MinReplicas**: Default minReplicas is 1 -- set higher for HA workloads
- **Target utilization**: HPA targets averageUtilization across all pods -- one hot pod can trigger scaling
- **ScaleDown policies**: v2 API supports rate-limiting scale-down with `behavior.scaleDown.policies`
- **VPA update modes**: Off (recommendations only), Initial (set on pod creation), Auto (evict and recreate) -- Auto causes pod restarts
- **Resource requests required**: HPA percentage-based scaling requires resource requests on containers
- **Cooldown**: After scaling, HPA waits before re-evaluating -- rapid traffic changes may not scale fast enough
