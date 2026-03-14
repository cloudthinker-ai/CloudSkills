---
name: managing-k8s-flux-deep
description: |
  Flux CD deep-dive management for Kubernetes GitOps delivery. Covers GitRepository sources, Kustomization reconciliation, HelmRelease status, HelmRepository health, ImagePolicy automation, notification providers, and multi-tenancy configurations. Use when debugging reconciliation failures, analyzing Flux source health, reviewing Helm release drift, or auditing image automation pipelines.
connection_type: k8s
preload: false
---

# Flux CD Deep-Dive Skill

Advanced analysis of Flux CD GitOps sources, reconciliation, and deployment pipelines.

## MANDATORY: Discovery-First Pattern

**Always check Flux installation and source health before inspecting reconciliation.**

### Phase 1: Discovery

```bash
#!/bin/bash

echo "=== Flux Components ==="
kubectl get deployment -n flux-system -o custom-columns='NAME:.metadata.name,READY:.status.readyReplicas,IMAGE:.spec.template.spec.containers[0].image' 2>/dev/null

echo ""
echo "=== Flux Version ==="
kubectl get deployment source-controller -n flux-system -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null
echo ""

echo ""
echo "=== GitRepositories ==="
kubectl get gitrepositories --all-namespaces -o custom-columns='NAMESPACE:.metadata.namespace,NAME:.metadata.name,READY:.status.conditions[?(@.type=="Ready")].status,REVISION:.status.artifact.revision,AGE:.metadata.creationTimestamp' 2>/dev/null | head -15

echo ""
echo "=== HelmRepositories ==="
kubectl get helmrepositories --all-namespaces -o custom-columns='NAMESPACE:.metadata.namespace,NAME:.metadata.name,READY:.status.conditions[?(@.type=="Ready")].status,URL:.spec.url' 2>/dev/null | head -15

echo ""
echo "=== OCIRepositories ==="
kubectl get ocirepositories --all-namespaces -o custom-columns='NAMESPACE:.metadata.namespace,NAME:.metadata.name,READY:.status.conditions[?(@.type=="Ready")].status' 2>/dev/null | head -10

echo ""
echo "=== Kustomizations ==="
kubectl get kustomizations --all-namespaces -o custom-columns='NAMESPACE:.metadata.namespace,NAME:.metadata.name,READY:.status.conditions[?(@.type=="Ready")].status,REVISION:.status.lastAppliedRevision' 2>/dev/null | head -15
```

### Phase 2: Analysis

```bash
#!/bin/bash

echo "=== HelmReleases ==="
kubectl get helmreleases --all-namespaces -o custom-columns='NAMESPACE:.metadata.namespace,NAME:.metadata.name,READY:.status.conditions[?(@.type=="Ready")].status,CHART:.spec.chart.spec.chart,VERSION:.spec.chart.spec.version' 2>/dev/null | head -15

echo ""
echo "=== Failed Reconciliations ==="
kubectl get kustomizations,helmreleases --all-namespaces -o json 2>/dev/null | jq -r '
  .items[] |
  select(.status.conditions[]? | select(.type == "Ready" and .status != "True")) |
  "\(.kind)/\(.metadata.name)\t\(.status.conditions[] | select(.type == "Ready") | .reason): \(.message // "")[0:80]"
' | head -15

echo ""
echo "=== Source Errors ==="
kubectl get gitrepositories,helmrepositories --all-namespaces -o json 2>/dev/null | jq -r '
  .items[] |
  select(.status.conditions[]? | select(.type == "Ready" and .status != "True")) |
  "\(.kind)/\(.metadata.name)\t\(.status.conditions[] | select(.type == "Ready") | .message // "unknown")[0:80]"
' | head -10

echo ""
echo "=== Image Policies ==="
kubectl get imagepolicies --all-namespaces -o custom-columns='NAMESPACE:.metadata.namespace,NAME:.metadata.name,LATEST:.status.latestImage' 2>/dev/null | head -10

echo ""
echo "=== Image Update Automations ==="
kubectl get imageupdateautomations --all-namespaces -o custom-columns='NAMESPACE:.metadata.namespace,NAME:.metadata.name,LAST_RUN:.status.lastAutomationRunTime' 2>/dev/null | head -10

echo ""
echo "=== Notification Providers ==="
kubectl get providers --all-namespaces -o custom-columns='NAMESPACE:.metadata.namespace,NAME:.metadata.name,TYPE:.spec.type' 2>/dev/null | head -10

echo ""
echo "=== Alerts ==="
kubectl get alerts --all-namespaces -o custom-columns='NAMESPACE:.metadata.namespace,NAME:.metadata.name,SEVERITY:.spec.summary' 2>/dev/null | head -10

echo ""
echo "=== Suspended Resources ==="
kubectl get kustomizations,helmreleases --all-namespaces -o json 2>/dev/null | jq -r '
  .items[] | select(.spec.suspend == true) |
  "\(.kind)/\(.metadata.namespace)/\(.metadata.name)\tSUSPENDED"
'

echo ""
echo "=== Source Controller Logs (errors) ==="
kubectl logs deployment/source-controller -n flux-system --tail=15 2>/dev/null | grep -i "error\|fail" | head -5
```

## Output Format

- Target ≤50 lines per output
- Use `-o custom-columns` for CRD resource listings
- Show Ready status and last applied revision for quick health check
- Group HelmReleases by namespace for organized view
- Never dump full Kustomization patches -- show source ref and status only

## Common Pitfalls

- **Dependency ordering**: Kustomizations support `dependsOn` -- circular dependencies cause deadlocks
- **Suspend flag**: `spec.suspend: true` stops reconciliation -- check before assuming failures
- **Source interval**: `spec.interval` controls how often sources are checked -- too frequent causes rate limits
- **HelmRelease remediation**: `spec.install.remediation` and `spec.upgrade.remediation` control retry behavior
- **Drift detection**: Enable `spec.force` on Kustomizations to correct drift -- but may cause disruption
- **Multi-tenancy**: Use `spec.serviceAccountName` on Kustomizations for RBAC scoping per tenant
- **Image automation**: Requires image-reflector and image-automation controllers -- not installed by default
- **Prune**: `spec.prune: true` on Kustomizations deletes resources removed from Git -- use with caution
- **Health checks**: Custom health checks in Kustomizations can delay Ready status -- check `spec.healthChecks`
