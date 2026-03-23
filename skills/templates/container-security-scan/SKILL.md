---
name: container-security-scan
enabled: true
description: |
  Use when performing container security scan — provides a structured process
  for scanning container images and runtime environments for security
  vulnerabilities, misconfigurations, and compliance violations. This template
  covers image scanning, Dockerfile best practices, runtime security policies,
  and remediation tracking.
required_connections:
  - prefix: registry
    label: "Container Registry"
  - prefix: scanner
    label: "Security Scanner"
config_fields:
  - key: image_name
    label: "Image Name"
    required: true
    placeholder: "e.g., myapp:latest"
  - key: compliance_standard
    label: "Compliance Standard"
    required: false
    placeholder: "e.g., CIS Docker Benchmark"
features:
  - CONTAINER_SECURITY
  - VULNERABILITY_SCAN
  - SRE_OPS
---

# Container Security Scan

## Phase 1: Image Analysis

Analyze the container image composition.

- [ ] Base image: ___
- [ ] Base image age (days since last update): ___
- [ ] Total layers: ___
- [ ] Image size: ___
- [ ] OS packages installed: ___
- [ ] Application dependencies: ___
- [ ] Run as root: Y/N
- [ ] Exposed ports: ___

## Phase 2: Vulnerability Scan

Run vulnerability scanner and catalog findings.

| CVE ID | Package | Severity | CVSS Score | Fixed Version | Exploitable | Status |
|--------|---------|----------|------------|---------------|-------------|--------|
|        |         |          |            |               |             |        |

**Severity Summary:**

| Severity | Count | With Fix Available | Without Fix |
|----------|-------|--------------------|-------------|
| Critical |       |                    |             |
| High     |       |                    |             |
| Medium   |       |                    |             |
| Low      |       |                    |             |

## Phase 3: Dockerfile Best Practices

Evaluate against Dockerfile security checklist.

- [ ] Uses specific base image tag (not `latest`)
- [ ] Base image is from a trusted registry
- [ ] Multi-stage build used to minimize final image
- [ ] Runs as non-root user
- [ ] No secrets or credentials in image layers
- [ ] COPY preferred over ADD
- [ ] Health check defined
- [ ] Minimal packages installed (no unnecessary tools)
- [ ] .dockerignore file present and comprehensive
- [ ] Image is signed / verified

## Phase 4: Runtime Security Assessment

- [ ] Read-only root filesystem enforced
- [ ] Resource limits (CPU, memory) defined
- [ ] Security context configured (no privilege escalation)
- [ ] Network policies restrict unnecessary connectivity
- [ ] Seccomp or AppArmor profile applied
- [ ] No host namespace sharing (PID, network, IPC)
- [ ] No host path mounts to sensitive directories

## Phase 5: Remediation Priority

**Decision Matrix:**

| Priority | Criteria | SLA |
|----------|----------|-----|
| P0 | Critical CVE with known exploit, fix available | 24 hours |
| P1 | Critical/High CVE, fix available | 7 days |
| P2 | Medium CVE or best practice violation | 30 days |
| P3 | Low CVE or informational finding | Next release cycle |

## Counter-Rationalizations

| Shortcut | Counter | Why |
|----------|---------|-----|
| "We can skip some steps for this case" | Adapt the workflow steps, don't skip them | Skipped steps are where incidents and oversights originate |
| "The user seems to already know what to do" | Complete all workflow phases with the user | The workflow catches blind spots that experience alone misses |
| "This is a minor case, full process is overkill" | Scale the process down, don't turn it off | Minor cases become major when unstructured; the process scales, not disappears |
| "I'll fill in the details later" | Complete each section before moving on | Deferred details are forgotten; real-time capture is more accurate |
| "The template output isn't necessary" | Always produce the structured output format | Structured output enables comparison, audit trails, and handoff to other teams |

## Output Format

### Summary

- **Image:** ___
- **Scan date:** ___
- **Critical vulnerabilities:** ___
- **High vulnerabilities:** ___
- **Dockerfile compliance:** ___% of checks passed
- **Runtime security:** ___% of checks passed

### Action Items

- [ ] Patch all Critical/High CVEs with available fixes
- [ ] Update base image to latest patched version
- [ ] Fix Dockerfile best practice violations
- [ ] Apply runtime security policies
- [ ] Schedule rescan after remediation
- [ ] Add image to continuous scanning pipeline
