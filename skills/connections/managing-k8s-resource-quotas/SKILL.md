---
name: managing-k8s-resource-quotas
description: |
  Kubernetes ResourceQuota and LimitRange management. Covers quota inventory, usage vs limits, LimitRange defaults, namespace resource consumption, quota violations, and capacity planning. Use when auditing resource governance, debugging quota-rejected deployments, reviewing namespace limits, or planning capacity allocation across namespaces.
connection_type: k8s
preload: false
---

# Kubernetes ResourceQuota and LimitRange Skill

Manage and analyze ResourceQuotas and LimitRanges for namespace resource governance.

## MANDATORY: Discovery-First Pattern

**Always list quotas and limit ranges before analyzing usage.**

### Phase 1: Discovery

```bash
#!/bin/bash

echo "=== ResourceQuotas (all namespaces) ==="
kubectl get resourcequotas --all-namespaces -o custom-columns='NAMESPACE:.metadata.namespace,NAME:.metadata.name,AGE:.metadata.creationTimestamp' 2>/dev/null | head -20

echo ""
echo "=== Quota Usage Summary ==="
kubectl get resourcequotas --all-namespaces -o json 2>/dev/null | jq -r '
  .items[] |
  "\(.metadata.namespace)/\(.metadata.name)" as $name |
  .status.hard | to_entries[] |
  "\($name)\t\(.key)\tUsed:\(.value // "0")\tHard:\((.value) // "unset")"
' | head -30
# Better approach with both used and hard
kubectl get resourcequotas --all-namespaces -o json 2>/dev/null | jq -r '
  .items[] |
  "\(.metadata.namespace)/\(.metadata.name)" as $name |
  (.status.hard // {}) as $hard |
  (.status.used // {}) as $used |
  $hard | to_entries[] |
  "\($name)\t\(.key)\tUsed:\($used[.key] // "0")\tHard:\(.value)"
' | head -30

echo ""
echo "=== LimitRanges (all namespaces) ==="
kubectl get limitranges --all-namespaces -o custom-columns='NAMESPACE:.metadata.namespace,NAME:.metadata.name' 2>/dev/null | head -20
```

### Phase 2: Analysis

```bash
#!/bin/bash

echo "=== Quota Utilization (% used) ==="
kubectl get resourcequotas --all-namespaces -o json 2>/dev/null | jq -r '
  .items[] |
  "\(.metadata.namespace)/\(.metadata.name)" as $name |
  (.status.hard // {}) as $hard |
  (.status.used // {}) as $used |
  $hard | to_entries[] |
  select(.key | test("cpu|memory|pods|persistentvolumeclaims|services")) |
  "\($name)\t\(.key)\t\($used[.key] // "0")/\(.value)"
' | head -20

echo ""
echo "=== Near-Limit Quotas (>80% used) ==="
kubectl get resourcequotas --all-namespaces -o json 2>/dev/null | jq -r '
  .items[] |
  "\(.metadata.namespace)/\(.metadata.name)" as $name |
  (.status.hard // {}) as $hard |
  (.status.used // {}) as $used |
  $hard | to_entries[] |
  select(.key == "pods" or .key == "count/deployments.apps") |
  select(($used[.key] // "0" | tonumber) > (.value | tonumber) * 0.8) |
  "\($name)\t\(.key)\tUsed:\($used[.key])\tLimit:\(.value)\tWARN:>80%"
'

echo ""
echo "=== LimitRange Defaults ==="
kubectl get limitranges --all-namespaces -o json 2>/dev/null | jq -r '
  .items[] |
  "\(.metadata.namespace)/\(.metadata.name)" as $name |
  .spec.limits[] |
  "\($name)\tType:\(.type)\tDefaultCPU:\(.default.cpu // "none")\tDefaultMem:\(.default.memory // "none")\tMaxCPU:\(.max.cpu // "none")\tMaxMem:\(.max.memory // "none")"
' | head -15

echo ""
echo "=== Namespaces Without Quotas ==="
QUOTA_NS=$(kubectl get resourcequotas --all-namespaces -o jsonpath='{.items[*].metadata.namespace}' 2>/dev/null | tr ' ' '\n' | sort -u)
ALL_NS=$(kubectl get namespaces -o jsonpath='{.items[*].metadata.name}' 2>/dev/null | tr ' ' '\n' | sort)
comm -23 <(echo "$ALL_NS") <(echo "$QUOTA_NS") | grep -v "^kube-" | head -10

echo ""
echo "=== Namespaces Without LimitRanges ==="
LR_NS=$(kubectl get limitranges --all-namespaces -o jsonpath='{.items[*].metadata.namespace}' 2>/dev/null | tr ' ' '\n' | sort -u)
comm -23 <(echo "$ALL_NS") <(echo "$LR_NS") | grep -v "^kube-" | head -10

echo ""
echo "=== Recent Quota Violation Events ==="
kubectl get events --all-namespaces --field-selector reason=FailedCreate -o json 2>/dev/null | jq -r '
  .items[] |
  select(.message | test("quota|exceeded|forbidden"; "i")) |
  "\(.metadata.namespace)\t\(.involvedObject.name)\t\(.message[0:80])\t\(.lastTimestamp)"
' | head -10
```

## Output Format

- Target ≤50 lines per output
- Show used/hard ratios for quick capacity assessment
- Flag quotas at >80% utilization
- List namespaces without governance (no quota or LimitRange)
- Never modify quotas in analysis -- read-only inspection

## Common Pitfalls

- **Quota scope**: Quotas apply per-namespace -- no cluster-wide quota (use ClusterResourceQuota in OpenShift)
- **Request vs limit**: Quotas can track `requests.cpu` and `limits.cpu` separately -- both must be set on pods
- **LimitRange defaults**: LimitRange sets defaults for pods without resource specs -- essential for quota enforcement
- **Count quotas**: `count/` prefix counts object instances (e.g., `count/deployments.apps`) -- not resource consumption
- **Terminating vs non-terminating**: Quotas can scope to `Terminating` or `NotTerminating` pods via `scopes`
- **Priority class**: Quotas can be scoped to specific PriorityClasses -- useful for preemption budgets
- **BestEffort scope**: Quota with `BestEffort` scope only applies to pods without resource requests
- **Admission rejection**: Quota violations are rejected at admission time -- check events for FailedCreate
