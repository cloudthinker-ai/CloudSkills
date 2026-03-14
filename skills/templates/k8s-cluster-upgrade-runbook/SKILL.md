---
name: k8s-cluster-upgrade-runbook
enabled: true
description: |
  Kubernetes cluster upgrade runbook covering pre-upgrade checks, API deprecation review, node upgrade procedure, validation tests, and rollback steps. Supports EKS, GKE, AKS, and self-managed clusters. Use for minor/major version upgrades.
required_connections:
  - prefix: kubernetes
    label: "Kubernetes Cluster"
config_fields:
  - key: cluster_name
    label: "Cluster Name"
    required: true
    placeholder: "e.g., prod-us-east-1"
  - key: current_version
    label: "Current Version"
    required: true
    placeholder: "e.g., 1.28"
  - key: target_version
    label: "Target Version"
    required: true
    placeholder: "e.g., 1.29"
  - key: distribution
    label: "Distribution"
    required: false
    placeholder: "e.g., EKS, GKE, AKS, kubeadm"
features:
  - KUBERNETES
  - DEPLOYMENT
---

# Kubernetes Cluster Upgrade Runbook Skill

Upgrade cluster **{{ cluster_name }}** from **{{ current_version }}** to **{{ target_version }}** ({{ distribution | "self-managed" }}).

## Workflow

### Step 1 — Pre-Upgrade Assessment

```
PRE-UPGRADE CHECKS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
CLUSTER HEALTH
[ ] All nodes in Ready state
[ ] No pods in CrashLoopBackOff or Pending state
[ ] Cluster autoscaler healthy (if enabled)
[ ] etcd cluster healthy (self-managed only)
[ ] Control plane components healthy
[ ] PodDisruptionBudgets reviewed (won't block node drain)

API COMPATIBILITY
[ ] Reviewed deprecated APIs between {{ current_version }} and {{ target_version }}
[ ] No workloads using removed APIs
[ ] Ran: kubectl deprecations (or pluto scan)
[ ] Helm charts compatible with {{ target_version }}
[ ] CRDs compatible with target version
[ ] Admission webhooks compatible

ADD-ONS & COMPONENTS
[ ] CoreDNS version compatible
[ ] kube-proxy version compatible
[ ] CNI plugin compatible (Calico, Cilium, VPC-CNI)
[ ] CSI drivers compatible
[ ] Ingress controller compatible
[ ] Cert-manager compatible
[ ] Monitoring stack compatible (Prometheus, etc.)
```

### Step 2 — Backup & Snapshot

```
BACKUP
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] etcd snapshot taken (self-managed clusters)
[ ] Cluster state exported (kubectl get all --all-namespaces -o yaml)
[ ] PV snapshots taken for critical volumes
[ ] Helm release manifests backed up
[ ] Custom resource definitions backed up
[ ] Backup verified and stored securely
```

### Step 3 — Control Plane Upgrade

```
CONTROL PLANE UPGRADE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
For managed (EKS/GKE/AKS):
[ ] Initiate control plane upgrade via cloud provider
[ ] Monitor upgrade progress
[ ] Verify API server responding with target version

For self-managed:
[ ] Upgrade kubeadm on first control plane node
[ ] Run: kubeadm upgrade plan
[ ] Run: kubeadm upgrade apply {{ target_version }}
[ ] Upgrade kubelet and kubectl on control plane nodes
[ ] Restart kubelet on each control plane node
[ ] Verify all control plane nodes on target version
```

### Step 4 — Worker Node Upgrade

```
WORKER NODE UPGRADE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Strategy: [ ] Rolling (one at a time)  [ ] Blue-green (new node group)

For each node (or node group):
[ ] Cordon node: kubectl cordon <node>
[ ] Drain node: kubectl drain <node> --ignore-daemonsets --delete-emptydir-data
[ ] Verify pods rescheduled to other nodes
[ ] Upgrade node (AMI swap / kubeadm upgrade)
[ ] Uncordon node: kubectl uncordon <node>
[ ] Verify node Ready with target version
[ ] Verify pods running on upgraded node
[ ] Wait for stability (5 min) before next node

Progress tracking:
  Nodes upgraded: ___/___
  Nodes remaining: ___
```

### Step 5 — Add-On Upgrades

```
ADD-ON UPGRADES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] CoreDNS upgraded to compatible version
[ ] kube-proxy upgraded to {{ target_version }}
[ ] CNI plugin upgraded (if needed)
[ ] CSI drivers upgraded (if needed)
[ ] Ingress controller upgraded (if needed)
[ ] Cert-manager upgraded (if needed)
[ ] Monitoring agents upgraded (if needed)
```

### Step 6 — Post-Upgrade Validation

```
VALIDATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
CLUSTER HEALTH
[ ] All nodes Ready and on target version
[ ] All system pods healthy (kube-system namespace)
[ ] DNS resolution working (test with nslookup from pod)
[ ] Service discovery working
[ ] Cluster autoscaler functioning

WORKLOAD HEALTH
[ ] All deployments at desired replica count
[ ] No pods in error state
[ ] Application health checks passing
[ ] Ingress/load balancer routing correctly
[ ] Persistent volumes mounted and accessible

FUNCTIONALITY
[ ] Pod scheduling working (create test pod)
[ ] Horizontal Pod Autoscaler responding
[ ] Network policies enforced
[ ] RBAC working correctly
[ ] Logging and monitoring data flowing
```

### Step 7 — Rollback Procedure

```
ROLLBACK (if critical issues found)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Managed clusters:
[ ] Initiate control plane downgrade (if supported)
[ ] Roll back node groups to previous AMI/version

Self-managed:
[ ] Restore etcd from snapshot
[ ] Downgrade kubeadm, kubelet, kubectl
[ ] Verify cluster state restored

All:
[ ] Verify workloads healthy after rollback
[ ] Document reason for rollback
[ ] Plan remediation before retry
```

## Output Format

Produce an upgrade execution report with:
1. **Pre-upgrade assessment** with compatibility check results
2. **Upgrade execution log** with timestamps per step
3. **Node upgrade progress** tracker
4. **Validation results** with PASS/FAIL per check
5. **Issues encountered** with resolution or rollback decision
