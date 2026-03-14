---
name: managing-k8s-pod-disruption
description: |
  Kubernetes PodDisruptionBudget management and disruption analysis. Covers PDB inventory, allowed disruptions, eviction status, node drain impact, workload protection coverage, and PDB misconfiguration detection. Use when auditing disruption protection, planning node maintenance, debugging stuck evictions, or reviewing PDB coverage across workloads.
connection_type: k8s
preload: false
---

# Kubernetes PodDisruptionBudget Skill

Manage and analyze PodDisruptionBudgets for workload availability during disruptions.

## MANDATORY: Discovery-First Pattern

**Always list PDBs and their status before analyzing disruption impact.**

### Phase 1: Discovery

```bash
#!/bin/bash

echo "=== PodDisruptionBudgets (all namespaces) ==="
kubectl get pdb --all-namespaces -o custom-columns='NAMESPACE:.metadata.namespace,NAME:.metadata.name,MIN-AVAILABLE:.spec.minAvailable,MAX-UNAVAILABLE:.spec.maxUnavailable,ALLOWED-DISRUPTIONS:.status.disruptionsAllowed,CURRENT:.status.currentHealthy,DESIRED:.status.desiredHealthy,EXPECTED:.status.expectedPods' 2>/dev/null

echo ""
echo "=== PDB Selector Mapping ==="
kubectl get pdb --all-namespaces -o json 2>/dev/null | jq -r '
  .items[] |
  "\(.metadata.namespace)/\(.metadata.name)\tSelector:\(.spec.selector.matchLabels | to_entries | map("\(.key)=\(.value)") | join(","))"
' | head -20
```

### Phase 2: Analysis

```bash
#!/bin/bash

echo "=== Blocking PDBs (zero disruptions allowed) ==="
kubectl get pdb --all-namespaces -o json 2>/dev/null | jq -r '
  .items[] |
  select(.status.disruptionsAllowed == 0) |
  "\(.metadata.namespace)/\(.metadata.name)\tAllowed:0\tCurrent:\(.status.currentHealthy)/\(.status.desiredHealthy)\tMinAvailable:\(.spec.minAvailable // "N/A")\tMaxUnavailable:\(.spec.maxUnavailable // "N/A")"
' | head -15

echo ""
echo "=== Misconfigured PDBs ==="
kubectl get pdb --all-namespaces -o json 2>/dev/null | jq -r '
  .items[] |
  select(
    (.spec.minAvailable == "100%" or .spec.maxUnavailable == 0 or .spec.maxUnavailable == "0%") or
    (.status.expectedPods == 0)
  ) |
  "\(.metadata.namespace)/\(.metadata.name)\tReason:" +
  (if .spec.minAvailable == "100%" then "minAvailable=100% blocks all evictions"
   elif .spec.maxUnavailable == 0 or .spec.maxUnavailable == "0%" then "maxUnavailable=0 blocks all evictions"
   elif .status.expectedPods == 0 then "no matching pods found"
   else "unknown" end)
' | head -10

echo ""
echo "=== Workloads Without PDBs ==="
kubectl get deployments --all-namespaces -o json 2>/dev/null | jq -r '
  .items[] |
  select(.spec.replicas > 1) |
  "\(.metadata.namespace)/\(.metadata.name)\tReplicas:\(.spec.replicas)"
' > /tmp/deployments.txt
kubectl get pdb --all-namespaces -o json 2>/dev/null | jq -r '
  .items[] |
  "\(.metadata.namespace)/\(.spec.selector.matchLabels | to_entries | map(.value) | join("-"))"
' > /tmp/pdbs.txt
echo "Multi-replica deployments without PDB protection:"
wc -l /tmp/deployments.txt /tmp/pdbs.txt 2>/dev/null
head -10 /tmp/deployments.txt

echo ""
echo "=== Node Drain Simulation ==="
echo "Nodes and their pod counts:"
kubectl get pods --all-namespaces -o json 2>/dev/null | jq -r '
  [.items[] | select(.status.phase == "Running") | .spec.nodeName] |
  group_by(.) | map({node: .[0], pods: length}) |
  sort_by(-.pods)[] |
  "\(.node)\t\(.pods) pods"
' | head -10

echo ""
echo "=== Recent Eviction Events ==="
kubectl get events --all-namespaces --field-selector reason=Evicted -o custom-columns='NAMESPACE:.metadata.namespace,NAME:.involvedObject.name,MESSAGE:.message,TIME:.lastTimestamp' 2>/dev/null | head -10
```

## Output Format

- Target ≤50 lines per output
- Use `-o custom-columns` for PDB listings
- Show disruptionsAllowed prominently -- zero means blocking
- Flag misconfigured PDBs (100% minAvailable, 0 maxUnavailable)
- Never modify PDBs in analysis -- read-only inspection

## Common Pitfalls

- **Blocking drain**: PDBs with minAvailable=100% or maxUnavailable=0 block node drains indefinitely
- **No matching pods**: PDB selector not matching any pods makes the PDB ineffective -- check labels
- **Single replica**: PDB on a single-replica deployment with minAvailable=1 blocks all evictions
- **Percentage vs absolute**: minAvailable can be number or percentage -- percentage rounds up
- **Unhealthy pods**: Unhealthy pods count against currentHealthy -- can prevent disruptions even when enough replicas exist
- **StatefulSets**: PDBs are critical for StatefulSets during rolling updates -- ensure maxUnavailable allows progress
- **Cluster autoscaler**: CA respects PDBs -- blocking PDBs prevent node scale-down
- **Multiple PDBs**: Multiple PDBs selecting the same pods all must allow disruption -- most restrictive wins
