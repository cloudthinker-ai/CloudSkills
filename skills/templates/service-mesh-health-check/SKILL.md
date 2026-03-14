---
name: service-mesh-health-check
enabled: true
description: |
  Performs a comprehensive health check of a service mesh deployment, evaluating control plane status, data plane proxy health, mTLS coverage, traffic policies, and observability configuration. Use this template for periodic mesh audits or before major mesh upgrades.
required_connections:
  - prefix: kubernetes
    label: "Kubernetes Cluster"
  - prefix: mesh
    label: "Service Mesh Control Plane"
config_fields:
  - key: mesh_type
    label: "Service Mesh Type"
    required: true
    placeholder: "e.g., Istio, Linkerd, Consul Connect"
  - key: cluster_name
    label: "Cluster Name"
    required: true
    placeholder: "e.g., prod-us-east-1"
features:
  - SERVICE_MESH
  - NETWORKING
  - SRE_OPS
---

# Service Mesh Health Check

## Phase 1: Control Plane Health

Verify the control plane is functioning correctly.

- [ ] Control plane pods running and healthy
- [ ] Control plane version: ___
- [ ] Certificate authority status and certificate expiry dates
- [ ] Configuration validation (no rejected or conflicting configs)
- [ ] Control plane resource utilization (CPU, memory)
- [ ] Control plane high availability: replicas running vs desired
- [ ] API server connectivity from control plane

## Phase 2: Data Plane Health

Assess sidecar proxy status across workloads.

| Namespace | Total Pods | Injected (%) | Proxy Version | Proxy Health | Config Sync Status |
|-----------|-----------|--------------|---------------|--------------|-------------------|
|           |           |              |               |              |                   |

- [ ] Identify pods without sidecar injection
- [ ] Identify pods with outdated proxy versions
- [ ] Check proxy resource utilization (CPU, memory per proxy)
- [ ] Verify proxy-to-control-plane connectivity

## Phase 3: Security Assessment

- [ ] mTLS mode: STRICT / PERMISSIVE / DISABLED
- [ ] Percentage of traffic encrypted with mTLS: ___%
- [ ] Authorization policies in place: Y/N
- [ ] Peer authentication policies configured: Y/N
- [ ] Certificate rotation functioning: Y/N
- [ ] External traffic ingress security: reviewed

**mTLS Coverage Matrix:**

| Source Namespace | Destination Namespace | mTLS Status | Policy |
|-----------------|----------------------|-------------|--------|
|                 |                      |             |        |

## Phase 4: Traffic Management Review

- [ ] Virtual services configured and valid
- [ ] Destination rules configured and valid
- [ ] Traffic shifting / canary configurations reviewed
- [ ] Circuit breakers configured for critical services
- [ ] Retry and timeout policies appropriate
- [ ] Rate limiting policies in place where needed

## Phase 5: Observability Verification

- [ ] Distributed tracing functional (sample traces verified)
- [ ] Metrics collection active (request rate, error rate, latency)
- [ ] Access logging configured appropriately
- [ ] Dashboards present and showing data
- [ ] Alerts configured for mesh-level failures

## Output Format

### Summary

- **Mesh type/version:** ___
- **Cluster:** ___
- **Overall health:** Healthy / Degraded / Unhealthy
- **mTLS coverage:** ___%
- **Sidecar injection rate:** ___%
- **Critical findings:** ___

### Action Items

- [ ] Remediate any control plane issues immediately
- [ ] Upgrade outdated sidecar proxies
- [ ] Enable mTLS STRICT mode for namespaces still in PERMISSIVE
- [ ] Add missing authorization policies
- [ ] Fix observability gaps
- [ ] Schedule mesh upgrade if version is behind
