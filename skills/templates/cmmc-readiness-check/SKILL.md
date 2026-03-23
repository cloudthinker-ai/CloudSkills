---
name: cmmc-readiness-check
enabled: true
description: |
  Use when performing cmmc readiness check — assesses organizational readiness
  for Cybersecurity Maturity Model Certification (CMMC 2.0) at the target level.
  Covers CUI identification, NIST SP 800-171 control implementation, gap
  analysis against CMMC practices, and preparation for third-party assessment at
  Level 2 or self-assessment at Level 1.
required_connections:
  - prefix: grc-tool
    label: "GRC Platform"
config_fields:
  - key: organization_name
    label: "Organization Name"
    required: true
    placeholder: "e.g., Defense Contractor Inc."
  - key: target_cmmc_level
    label: "Target CMMC Level"
    required: true
    placeholder: "e.g., Level 1, Level 2, Level 3"
  - key: cui_types
    label: "Types of CUI Handled"
    required: false
    placeholder: "e.g., technical data, export controlled, ITAR"
features:
  - COMPLIANCE
  - CMMC
  - GOVERNMENT
---

# CMMC 2.0 Readiness Check

## Phase 1: Scope Definition
1. Identify CUI and FCI within the organization
   - [ ] Controlled Unclassified Information (CUI) types
   - [ ] Federal Contract Information (FCI) locations
   - [ ] Systems processing, storing, or transmitting CUI/FCI
   - [ ] Personnel with CUI access
   - [ ] External partners and subcontractors handling CUI
2. Define the CMMC assessment boundary
3. Document data flows for CUI/FCI
4. Determine target CMMC level based on contract requirements

### CMMC Level Requirements

| Level | Practices | Assessment Type | Applies To |
|-------|-----------|----------------|------------|
| Level 1 | 17 (FAR 52.204-21) | Annual Self-Assessment | FCI only |
| Level 2 | 110 (NIST 800-171) | Triennial C3PAO Assessment | CUI |
| Level 3 | 110+ (NIST 800-172) | Government-led Assessment | Critical CUI |
| **Target** | | | |

## Phase 2: Practice Assessment (Level 1 - FCI Protection)
- [ ] AC.L1-3.1.1 - Limit system access to authorized users
- [ ] AC.L1-3.1.2 - Limit system access to authorized functions/transactions
- [ ] AC.L1-3.1.20 - Verify and control connections to external systems
- [ ] AC.L1-3.1.22 - Control information posted publicly
- [ ] IA.L1-3.5.1 - Identify system users and processes
- [ ] IA.L1-3.5.2 - Authenticate users, processes, or devices
- [ ] MP.L1-3.8.3 - Sanitize or destroy media before disposal
- [ ] PE.L1-3.10.1 - Limit physical access to authorized individuals
- [ ] PE.L1-3.10.3 - Escort visitors and monitor activity
- [ ] PE.L1-3.10.4 - Maintain audit logs of physical access
- [ ] PE.L1-3.10.5 - Control and manage physical access devices
- [ ] SC.L1-3.13.1 - Monitor and protect communications at boundaries
- [ ] SC.L1-3.13.5 - Implement subnetworks for public components
- [ ] SI.L1-3.14.1 - Identify and repair information system flaws
- [ ] SI.L1-3.14.2 - Provide protection from malicious code
- [ ] SI.L1-3.14.4 - Update malicious code protection mechanisms
- [ ] SI.L1-3.14.5 - Perform system and file scans periodically

## Phase 3: Practice Assessment (Level 2 - CUI Protection)
1. Assess all 110 NIST SP 800-171 Rev 2 practices across 14 families
   - [ ] Access Control (22 practices)
   - [ ] Awareness and Training (3 practices)
   - [ ] Audit and Accountability (9 practices)
   - [ ] Configuration Management (9 practices)
   - [ ] Identification and Authentication (11 practices)
   - [ ] Incident Response (3 practices)
   - [ ] Maintenance (6 practices)
   - [ ] Media Protection (9 practices)
   - [ ] Personnel Security (2 practices)
   - [ ] Physical Protection (6 practices)
   - [ ] Risk Assessment (3 practices)
   - [ ] Security Assessment (4 practices)
   - [ ] System and Communications Protection (16 practices)
   - [ ] System and Information Integrity (7 practices)

### Assessment Summary

| Family | Practices | Met | Not Met | Partially Met | N/A |
|--------|-----------|-----|---------|---------------|-----|
| Access Control | 22 | | | | |
| Audit & Accountability | 9 | | | | |
| Configuration Mgmt | 9 | | | | |
| ID & Authentication | 11 | | | | |
| SC Protection | 16 | | | | |
| Other families | 43 | | | | |
| **Total** | **110** | | | | |

## Phase 4: SSP & POA&M Development
1. Develop or update System Security Plan (SSP)
2. Document control implementation for each practice
3. Create Plan of Action & Milestones (POA&M) for gaps
4. Define remediation timelines (POA&M must close within 180 days)
5. Calculate SPRS score based on current implementation

### SPRS Score Calculation
- Maximum score: 110
- Current score: ___ (110 minus weighted unmet practices)
- Minimum required for contract award: varies by contract

## Phase 5: Remediation
1. Prioritize gaps by SPRS weight and risk
2. Implement technical controls (MFA, encryption, logging)
3. Develop required policies and procedures
4. Train personnel on CUI handling requirements
5. Document evidence for each implemented practice

## Phase 6: Assessment Preparation
1. Prepare evidence artifacts per practice
2. Conduct internal mock assessment
3. Engage C3PAO for Level 2 assessment (if applicable)
4. Prepare staff for assessor interviews
5. Submit self-assessment to SPRS (Level 1) or schedule C3PAO visit

## Counter-Rationalizations

| Shortcut | Counter | Why |
|----------|---------|-----|
| "We can skip some steps for this case" | Adapt the workflow steps, don't skip them | Skipped steps are where incidents and oversights originate |
| "The user seems to already know what to do" | Complete all workflow phases with the user | The workflow catches blind spots that experience alone misses |
| "This is a minor case, full process is overkill" | Scale the process down, don't turn it off | Minor cases become major when unstructured; the process scales, not disappears |
| "I'll fill in the details later" | Complete each section before moving on | Deferred details are forgotten; real-time capture is more accurate |
| "The template output isn't necessary" | Always produce the structured output format | Structured output enables comparison, audit trails, and handoff to other teams |

## Output Format
- **Scope Documentation**: CUI boundary and data flow diagrams
- **Practice Assessment**: Status per practice with evidence references
- **SPRS Score**: Current calculated score with breakdown
- **POA&M**: Remediation plan for unmet practices
- **Assessment Readiness Report**: Preparation status and timeline

## Action Items
- [ ] Identify and document all CUI within the organization
- [ ] Define CMMC assessment boundary
- [ ] Assess all practices for target level
- [ ] Calculate and submit SPRS score
- [ ] Develop POA&M for unmet practices
- [ ] Remediate gaps within 180-day timeline
- [ ] Schedule assessment (self or C3PAO)
