---
name: infrastructure-drift-detection
enabled: true
description: |
  Use when performing infrastructure drift detection — detects and catalogs
  infrastructure drift between the desired state defined in Infrastructure as
  Code and the actual state of deployed resources. This template guides teams
  through drift detection, impact assessment, and reconciliation to maintain
  infrastructure consistency and compliance.
required_connections:
  - prefix: iac
    label: "IaC Platform"
  - prefix: cloud
    label: "Cloud Provider"
config_fields:
  - key: iac_tool
    label: "IaC Tool"
    required: true
    placeholder: "e.g., Terraform, Pulumi, CloudFormation"
  - key: environment
    label: "Environment"
    required: true
    placeholder: "e.g., production"
  - key: scope
    label: "Scope"
    required: false
    placeholder: "e.g., All stacks, or specific stack name"
features:
  - INFRASTRUCTURE
  - DRIFT_DETECTION
  - SRE_OPS
---

# Infrastructure Drift Detection

## Phase 1: Drift Scan

Execute drift detection across all IaC-managed resources.

- [ ] Run `terraform plan` / equivalent drift detection command
- [ ] Record total managed resources: ___
- [ ] Record resources with drift: ___
- [ ] Record unmanaged resources (exist but not in IaC): ___
- [ ] Record missing resources (in IaC but not deployed): ___

## Phase 2: Drift Inventory

Catalog each drifted resource.

| Resource | Type | Drift Category | Attribute Changed | IaC Value | Actual Value | Severity |
|----------|------|---------------|-------------------|-----------|-------------|----------|
|          |      |               |                   |           |             |          |

**Drift Categories:**

| Category | Description |
|----------|------------|
| Modified | Resource exists but attributes differ from IaC |
| Unmanaged | Resource exists in cloud but not defined in IaC |
| Missing | Resource defined in IaC but not found in cloud |
| Tainted | Resource marked for recreation |

## Phase 3: Root Cause Analysis

For each drifted resource, identify the cause.

| Root Cause | Description | Example |
|-----------|------------|---------|
| Manual change | Someone modified resource via console/CLI | Security group rule added manually |
| Auto-scaling | Cloud provider modified resource automatically | Instance count changed |
| Dependency update | Upstream change propagated | Managed policy updated by provider |
| State corruption | IaC state file is inaccurate | Failed apply left partial state |
| Intentional bypass | Emergency change not back-ported to IaC | Hotfix applied directly |

- [ ] For each drift: identify who/what made the change
- [ ] For each drift: determine if the change was intentional
- [ ] For each drift: assess security implications

## Phase 4: Impact Assessment

**Decision Matrix — Drift Severity:**

| Severity | Criteria | Response |
|----------|----------|----------|
| Critical | Security-relevant drift (IAM, firewall, encryption) | Reconcile immediately |
| High | Production configuration drift affecting behavior | Reconcile within 24 hours |
| Medium | Non-functional drift (tags, descriptions) | Reconcile in next sprint |
| Low | Cosmetic or auto-managed drift | Document and accept or reconcile at convenience |

## Phase 5: Reconciliation Plan

For each drifted resource, choose a reconciliation strategy.

- [ ] **Apply IaC state:** Overwrite actual with desired state (terraform apply)
- [ ] **Import to IaC:** Add actual state to IaC definitions
- [ ] **Accept drift:** Update IaC to match actual state (intentional changes)
- [ ] **Delete resource:** Remove unmanaged resource
- [ ] **Recreate resource:** Taint and recreate

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

- **Total managed resources:** ___
- **Resources with drift:** ___ (___%  of total)
- **Critical/High severity drifts:** ___
- **Root cause breakdown:** Manual ___%, Auto ___%, Other ___%

### Action Items

- [ ] Reconcile all Critical severity drifts immediately
- [ ] Reconcile High severity drifts within 24 hours
- [ ] Implement drift detection in CI/CD pipeline
- [ ] Enable cloud audit logging to catch manual changes
- [ ] Restrict console/CLI write access to reduce manual drift
- [ ] Schedule weekly drift detection scans
