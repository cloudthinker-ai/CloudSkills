---
name: threat-model-template
enabled: true
description: |
  Use when performing threat model template — guides teams through a structured
  threat modeling exercise using the STRIDE methodology. This template helps
  identify threats, assess risks, and define mitigations for a system or
  feature, producing a comprehensive threat model document that satisfies
  security review requirements.
required_connections:
  - prefix: wiki
    label: "Documentation Platform"
  - prefix: security
    label: "Security Tooling"
config_fields:
  - key: system_name
    label: "System Name"
    required: true
    placeholder: "e.g., Payment Processing Service"
  - key: author
    label: "Author"
    required: true
    placeholder: "e.g., Security Team"
  - key: methodology
    label: "Methodology"
    required: false
    placeholder: "e.g., STRIDE, PASTA, DREAD"
features:
  - THREAT_MODEL
  - SECURITY
  - ARCHITECTURE
---

# Threat Model

## Phase 1: System Decomposition

Define the system boundaries and components.

1. - [ ] System description and purpose
2. - [ ] Architecture diagram with trust boundaries
3. - [ ] Identify all entry points (APIs, UIs, message queues, file inputs)
4. - [ ] Identify all data stores
5. - [ ] Identify all external dependencies
6. - [ ] Identify all user roles and privilege levels

**Trust Boundaries:**

| Boundary | Components Inside | Components Outside | Data Crossing |
|----------|-------------------|-------------------|---------------|
|          |                   |                   |               |

**Assets:**

| Asset | Sensitivity | Confidentiality | Integrity | Availability |
|-------|------------|-----------------|-----------|--------------|
|       | High/Med/Low | Required Y/N   | Required Y/N | Required Y/N |

## Phase 2: Threat Identification (STRIDE)

For each component and data flow, evaluate STRIDE threats.

| Component/Flow | Spoofing | Tampering | Repudiation | Info Disclosure | Denial of Service | Elevation of Privilege |
|---------------|----------|-----------|-------------|-----------------|-------------------|----------------------|
|               | Y/N      | Y/N       | Y/N         | Y/N             | Y/N               | Y/N                  |

**Detailed Threat Catalog:**

| ID | Threat | STRIDE Category | Component | Attack Vector | Likelihood | Impact | Risk Score |
|----|--------|----------------|-----------|---------------|-----------|--------|------------|
| T1 |        |                |           |               |           |        |            |

**Likelihood Scale:** 1 (Very Low) - 5 (Very High)
**Impact Scale:** 1 (Negligible) - 5 (Critical)
**Risk Score:** Likelihood x Impact

## Phase 3: Risk Assessment

**Risk Matrix:**

|              | Impact: 1 | Impact: 2 | Impact: 3 | Impact: 4 | Impact: 5 |
|--------------|-----------|-----------|-----------|-----------|-----------|
| Likelihood: 5 | Medium   | High      | High      | Critical  | Critical  |
| Likelihood: 4 | Medium   | Medium    | High      | High      | Critical  |
| Likelihood: 3 | Low      | Medium    | Medium    | High      | High      |
| Likelihood: 2 | Low      | Low       | Medium    | Medium    | High      |
| Likelihood: 1 | Low      | Low       | Low       | Medium    | Medium    |

## Phase 4: Mitigation Planning

For each threat with risk score >= Medium:

| Threat ID | Mitigation Strategy | Control Type | Status | Owner | Priority |
|-----------|-------------------|-------------|--------|-------|----------|
|           | Accept / Mitigate / Transfer / Avoid | Preventive / Detective / Corrective | | | |

**Mitigation Details:**

For each mitigation:
1. - [ ] Describe the control
2. - [ ] Implementation effort estimate
3. - [ ] Residual risk after mitigation
4. - [ ] Verification method

## Phase 5: Validation

- [ ] All entry points have been analyzed
- [ ] All data stores have been analyzed
- [ ] All trust boundaries have been identified
- [ ] All high/critical risks have mitigations
- [ ] Mitigations are testable and verifiable
- [ ] Model reviewed by security team

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

- **System:** ___
- **Threats identified:** ___
- **Critical risks:** ___
- **High risks:** ___
- **Mitigations defined:** ___
- **Residual risk assessment:** Acceptable / Needs Attention / Unacceptable

### Action Items

- [ ] Implement all Critical risk mitigations before launch
- [ ] Implement High risk mitigations within first sprint post-launch
- [ ] Schedule penetration test to validate mitigations
- [ ] Update threat model when architecture changes
- [ ] Review threat model annually at minimum
