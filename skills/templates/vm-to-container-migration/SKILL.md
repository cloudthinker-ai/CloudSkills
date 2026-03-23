---
name: vm-to-container-migration
enabled: true
description: |
  Use when performing vm to container migration — provides a structured approach
  for migrating VM-based workloads to containers, covering application analysis,
  Dockerfile creation, orchestration setup, storage and networking adaptation,
  and progressive rollout strategies. Targets Kubernetes or similar container
  platforms.
required_connections:
  - prefix: container-registry
    label: "Container Registry"
  - prefix: k8s
    label: "Kubernetes Cluster"
config_fields:
  - key: source_vm_os
    label: "Source VM Operating System"
    required: true
    placeholder: "e.g., Ubuntu 22.04, RHEL 8"
  - key: target_platform
    label: "Target Container Platform"
    required: true
    placeholder: "e.g., EKS, GKE, AKS, OpenShift"
  - key: application_type
    label: "Application Type"
    required: false
    placeholder: "e.g., Java Spring Boot, Node.js, Python Django"
features:
  - CLOUD_MIGRATION
  - CONTAINERS
  - KUBERNETES
---

# VM to Container Migration Plan

## Phase 1: Application Analysis
1. Profile the VM workload
   - [ ] Identify all running processes and services
   - [ ] Map filesystem dependencies and mount points
   - [ ] Document network ports and protocols
   - [ ] Identify persistent storage requirements
   - [ ] Catalog environment variables and configuration files
   - [ ] List cron jobs and scheduled tasks
2. Assess containerization readiness

### Readiness Checklist

| Criterion | Status | Notes |
|-----------|--------|-------|
| Stateless or state externalized | [ ] | |
| Single process per container viable | [ ] | |
| Logs written to stdout/stderr | [ ] | |
| Configuration via env vars possible | [ ] | |
| No dependency on host-specific paths | [ ] | |
| Health check endpoint available | [ ] | |
| Graceful shutdown handling | [ ] | |

## Phase 2: Container Image Creation
1. Write Dockerfile based on application requirements
2. Separate build-time and runtime dependencies
3. Implement multi-stage builds to minimize image size
4. Configure non-root user for security
5. Add health check instructions
6. Build and scan image for vulnerabilities

## Phase 3: Kubernetes Manifest Design
1. Create Deployment or StatefulSet manifests
2. Define resource requests and limits
3. Configure ConfigMaps and Secrets
4. Set up PersistentVolumeClaims for stateful data
5. Define Services and Ingress rules
6. Configure horizontal pod autoscaling
7. Implement pod disruption budgets

## Phase 4: Storage & Networking Adaptation
1. Migrate persistent data to cloud-native storage
2. Replace VM networking with Kubernetes Services
3. Configure service mesh if needed (Istio, Linkerd)
4. Set up network policies for pod-to-pod communication
5. Implement external DNS and certificate management

## Phase 5: Testing & Validation
1. Deploy containerized workload to staging
2. Run functional tests against containerized version
3. Compare performance metrics (latency, throughput, resource usage)
4. Validate persistent storage behavior (writes, reads, failover)
5. Test scaling behavior under load
6. Verify logging and monitoring integration

## Phase 6: Progressive Rollout
1. Deploy to production alongside existing VM workload
2. Route a percentage of traffic to containers
3. Monitor error rates and latency
4. Gradually increase traffic to containers
5. Decommission VM workload after stabilization

## Counter-Rationalizations

| Shortcut | Counter | Why |
|----------|---------|-----|
| "We can skip some steps for this case" | Adapt the workflow steps, don't skip them | Skipped steps are where incidents and oversights originate |
| "The user seems to already know what to do" | Complete all workflow phases with the user | The workflow catches blind spots that experience alone misses |
| "This is a minor case, full process is overkill" | Scale the process down, don't turn it off | Minor cases become major when unstructured; the process scales, not disappears |
| "I'll fill in the details later" | Complete each section before moving on | Deferred details are forgotten; real-time capture is more accurate |
| "The template output isn't necessary" | Always produce the structured output format | Structured output enables comparison, audit trails, and handoff to other teams |

## Output Format
- **Application Profile**: Dependencies, ports, storage, config summary
- **Dockerfile and Kubernetes Manifests**: Production-ready artifacts
- **Migration Runbook**: Step-by-step guide with validation checks
- **Performance Comparison**: VM vs. container metrics
- **Rollback Procedure**: Steps to revert traffic to VM

## Action Items
- [ ] Complete application profiling on source VM
- [ ] Create and test Dockerfile in development
- [ ] Write Kubernetes manifests and validate in staging
- [ ] Set up CI/CD pipeline for container builds
- [ ] Execute progressive rollout to production
- [ ] Monitor containerized workload for 14 days
- [ ] Decommission source VM after sign-off
