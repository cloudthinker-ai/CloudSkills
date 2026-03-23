---
name: cis-benchmark-k8s
enabled: true
description: |
  Use when performing cis benchmark k8s — cIS Benchmark assessment for
  Kubernetes covering control plane configuration, worker node security, RBAC
  policies, pod security, network policies, and secrets management. Based on CIS
  Kubernetes Benchmark v1.8. Use for cluster hardening or compliance validation.
required_connections:
  - prefix: kubernetes
    label: "Kubernetes Cluster"
config_fields:
  - key: cluster_name
    label: "Cluster Name"
    required: true
    placeholder: "e.g., prod-us-east-1"
  - key: k8s_version
    label: "Kubernetes Version"
    required: true
    placeholder: "e.g., 1.29"
  - key: distribution
    label: "Distribution"
    required: false
    placeholder: "e.g., EKS, GKE, AKS, kubeadm"
features:
  - SECURITY
  - COMPLIANCE
  - KUBERNETES
---

# CIS Benchmark for Kubernetes Skill

Run CIS Kubernetes Benchmark v1.8 assessment for cluster **{{ cluster_name }}** ({{ k8s_version }}, {{ distribution | "self-managed" }}).

## Workflow

### Step 1 — Assessment Context

1. **Cluster**: {{ cluster_name }}
2. **Version**: {{ k8s_version }}
3. **Distribution**: {{ distribution | "self-managed" }}
4. **Note**: For managed services (EKS/GKE/AKS), control plane checks are provider-managed. Focus on worker node and workload checks.

### Step 2 — Control Plane Configuration

```
CONTROL PLANE (Section 1)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
API SERVER
[ ] 1.1  — Anonymous auth disabled (--anonymous-auth=false)
[ ] 1.2  — Basic auth file not used
[ ] 1.3  — Token auth file not used
[ ] 1.4  — RBAC authorization enabled
[ ] 1.5  — NodeRestriction admission plugin enabled
[ ] 1.6  — Audit logging enabled with appropriate policy
[ ] 1.7  — AlwaysAdmit admission controller not set
[ ] 1.8  — Encryption provider configured for secrets at rest
[ ] 1.9  — TLS certificates valid and not expired

CONTROLLER MANAGER
[ ] 1.10 — Service account credentials rotated
[ ] 1.11 — RotateKubeletServerCertificate enabled
[ ] 1.12 — Service account private key file set

SCHEDULER
[ ] 1.13 — Profiling disabled (--profiling=false)
[ ] 1.14 — Bind address not set to 0.0.0.0
```

### Step 3 — Worker Node Security

```
WORKER NODES (Section 2)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
KUBELET
[ ] 2.1  — Anonymous auth disabled on kubelet
[ ] 2.2  — Authorization mode not set to AlwaysAllow
[ ] 2.3  — Client CA file configured
[ ] 2.4  — Read-only port disabled (--read-only-port=0)
[ ] 2.5  — Streaming connection idle timeout configured
[ ] 2.6  — Protect kernel defaults enabled
[ ] 2.7  — RotateKubeletServerCertificate enabled
[ ] 2.8  — Hostname override not used (unless required)

FILE PERMISSIONS
[ ] 2.9  — Kubelet config file permissions: 644 or more restrictive
[ ] 2.10 — Kubelet config file ownership: root:root
[ ] 2.11 — PKI directory permissions: 755 or more restrictive
```

### Step 4 — RBAC & Service Accounts

```
RBAC & SERVICE ACCOUNTS (Section 3)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] 3.1  — cluster-admin role used sparingly
[ ] 3.2  — Minimize wildcard use in Roles and ClusterRoles
[ ] 3.3  — No default service account used for workloads
[ ] 3.4  — Service account token auto-mount disabled by default
[ ] 3.5  — No pods running with cluster-admin privileges
[ ] 3.6  — Audit RBAC bindings for over-permissioned accounts
[ ] 3.7  — Minimize use of privileged containers
```

### Step 5 — Pod Security

```
POD SECURITY (Section 4)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] 4.1  — Pod Security Standards enforced (Baseline minimum)
[ ] 4.2  — Privileged containers not allowed (except system)
[ ] 4.3  — hostPID and hostIPC not allowed
[ ] 4.4  — hostNetwork not allowed (except system pods)
[ ] 4.5  — Containers run as non-root (runAsNonRoot: true)
[ ] 4.6  — Root filesystem read-only where possible
[ ] 4.7  — NET_RAW capability dropped
[ ] 4.8  — Seccomp profile set (RuntimeDefault or custom)
[ ] 4.9  — Resource limits (CPU/memory) set for all containers
[ ] 4.10 — No containers mount Docker socket
```

### Step 6 — Network Policies & Secrets

```
NETWORK & SECRETS (Section 5)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] 5.1  — NetworkPolicy defined for all namespaces
[ ] 5.2  — Default deny ingress policy per namespace
[ ] 5.3  — Default deny egress policy per namespace
[ ] 5.4  — Kubernetes secrets encrypted at rest (EncryptionConfiguration)
[ ] 5.5  — External secrets manager used (Vault, AWS SM, etc.)
[ ] 5.6  — No secrets in environment variables (use volumes)
[ ] 5.7  — Ingress/egress TLS termination configured
```

### Step 7 — Scoring & Report

| CIS Section | Passed | Failed | N/A | Score |
|-------------|--------|--------|-----|-------|
| 1. Control Plane | X | Y | Z | % |
| 2. Worker Nodes | X | Y | Z | % |
| 3. RBAC | X | Y | Z | % |
| 4. Pod Security | X | Y | Z | % |
| 5. Network & Secrets | X | Y | Z | % |
| **Overall** | **X** | **Y** | **Z** | **%** |

## Counter-Rationalizations

| Shortcut | Counter | Why |
|----------|---------|-----|
| "We can skip some steps for this case" | Adapt the workflow steps, don't skip them | Skipped steps are where incidents and oversights originate |
| "The user seems to already know what to do" | Complete all workflow phases with the user | The workflow catches blind spots that experience alone misses |
| "This is a minor case, full process is overkill" | Scale the process down, don't turn it off | Minor cases become major when unstructured; the process scales, not disappears |
| "I'll fill in the details later" | Complete each section before moving on | Deferred details are forgotten; real-time capture is more accurate |
| "The template output isn't necessary" | Always produce the structured output format | Structured output enables comparison, audit trails, and handoff to other teams |

## Output Format

Produce a CIS Kubernetes Benchmark report with:
1. **Cluster metadata** (name, version, distribution, node count)
2. **Per-section checklists** with PASS/FAIL/N-A and remediation commands
3. **Score summary** with per-section and overall percentages
4. **Critical findings** requiring immediate attention
5. **Remediation runbook** with kubectl/manifest patches for failed controls
