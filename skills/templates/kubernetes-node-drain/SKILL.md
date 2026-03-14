---
name: kubernetes-node-drain
enabled: true
description: |
  Runbook for safely draining Kubernetes nodes for maintenance, upgrades, or decommissioning. Covers pod disruption budget validation, workload rescheduling, persistent volume handling, cordon and drain execution, and post-drain verification to ensure zero workload disruption.
required_connections:
  - prefix: kubernetes
    label: "Kubernetes Cluster"
config_fields:
  - key: cluster_name
    label: "Cluster Name"
    required: true
    placeholder: "e.g., prod-us-east-1"
  - key: node_name
    label: "Node Name"
    required: true
    placeholder: "e.g., ip-10-0-1-42.ec2.internal"
  - key: drain_reason
    label: "Drain Reason"
    required: true
    placeholder: "e.g., OS patching, instance type upgrade, decommission"
features:
  - DEVOPS
  - KUBERNETES
---

# Kubernetes Node Drain Skill

Safely drain node **{{ node_name }}** in cluster **{{ cluster_name }}** for: **{{ drain_reason }}**.

## Workflow

### Phase 1 — Node Assessment

```
NODE INVENTORY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Node status: Ready / NotReady / SchedulingDisabled
[ ] Node labels and taints documented
[ ] Pods running on node:
    - Total pods: ___
    - DaemonSet pods (will not be evicted): ___
    - Pods with local storage: ___
    - Pods without PDB: ___
    - StatefulSet pods: ___
[ ] Resource utilization:
    - CPU: ___% allocated
    - Memory: ___% allocated
[ ] Persistent volumes attached to node: ___
```

### Phase 2 — Pre-Drain Validation

```
CAPACITY AND SAFETY CHECKS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Remaining cluster capacity sufficient:
    - Available CPU after drain: ___ cores
    - Available memory after drain: ___ GB
    - Node count after drain: ___ / ___
[ ] Pod Disruption Budgets (PDBs) reviewed:
    - PDB-protected workloads: ___
    - All PDBs allow at least 1 disruption: [ ] YES  [ ] NO
[ ] No single-replica deployments without PDB: [ ] CONFIRMED
[ ] Anti-affinity rules will not block rescheduling: [ ] CONFIRMED
[ ] No critical CronJobs currently running on node: [ ] CONFIRMED
```

### Phase 3 — Cordon Node

```
CORDON
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Execute: kubectl cordon {{ node_name }}
[ ] Verify node shows SchedulingDisabled
[ ] Confirm no new pods scheduled to node
[ ] Timestamp: ___
```

### Phase 4 — Drain Execution

```
DRAIN
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Execute drain command:
    kubectl drain {{ node_name }} \
      --ignore-daemonsets \
      --delete-emptydir-data \
      --grace-period=60 \
      --timeout=300s

[ ] Monitor pod evictions:
    - Pods evicted successfully: ___ / ___
    - Pods stuck in Terminating: ___
    - PDB violations encountered: ___

[ ] Handle stuck pods (if any):
    [ ] Investigate pod stuck reasons
    [ ] Force delete if safe: kubectl delete pod <name> --force
    [ ] Escalate if critical workload affected

[ ] Drain complete — timestamp: ___
```

### Phase 5 — Post-Drain Verification

```
POST-DRAIN CHECKS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] All evicted pods rescheduled and Running on other nodes
[ ] No pods in Pending state due to capacity
[ ] Service endpoints updated (removed drained node)
[ ] Health checks passing for affected services
[ ] Persistent volumes reattached to new nodes (if applicable)
[ ] No increase in error rates across cluster
[ ] Monitoring shows stable request handling
```

### Phase 6 — Node Maintenance and Restoration

```
POST-MAINTENANCE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
After maintenance is complete:
[ ] Node maintenance performed: {{ drain_reason }}
[ ] Uncordon node: kubectl uncordon {{ node_name }}
[ ] Verify node status: Ready
[ ] Verify pods can be scheduled to node
[ ] Node labels and taints reapplied (if needed)
[ ] OR — node decommissioned and removed from cluster
```

## Output Format

Produce a node drain report with:
1. **Drain summary** (node, cluster, reason, timestamps)
2. **Pod eviction details** (counts, rescheduling status)
3. **Capacity impact** (cluster utilization before and after)
4. **Issues encountered** (stuck pods, PDB violations, rescheduling failures)
5. **Final status** (DRAINED / RESTORED / DECOMMISSIONED)
