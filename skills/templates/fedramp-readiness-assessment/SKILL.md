---
name: fedramp-readiness-assessment
enabled: true
description: |
  Use when performing fedramp readiness assessment — assesses an organization's
  readiness for FedRAMP authorization, covering the 325+ NIST 800-53 controls
  required at Low, Moderate, or High baselines. Includes system boundary
  definition, control implementation status, POA&M development, and 3PAO
  assessment preparation.
required_connections:
  - prefix: grc-tool
    label: "GRC Platform"
config_fields:
  - key: target_impact_level
    label: "Target Impact Level"
    required: true
    placeholder: "e.g., Low, Moderate, High"
  - key: authorization_path
    label: "Authorization Path"
    required: true
    placeholder: "e.g., Agency ATO, JAB P-ATO"
  - key: system_name
    label: "Cloud Service Offering Name"
    required: true
    placeholder: "e.g., MyApp Cloud Platform"
features:
  - COMPLIANCE
  - FEDRAMP
  - GOVERNMENT
---

# FedRAMP Readiness Assessment

## Phase 1: Scope & Boundary Definition
1. Define the cloud service offering (CSO) boundary
   - [ ] System components and architecture
   - [ ] Data flow diagrams
   - [ ] Network architecture diagrams
   - [ ] External interconnections
   - [ ] Shared responsibility model with IaaS/PaaS provider
2. Identify the authorization boundary
3. Classify data types processed by the system
4. Determine FIPS 199 impact level (Confidentiality, Integrity, Availability)

### Impact Level Determination

| Security Objective | Impact Level | Justification |
|-------------------|-------------|---------------|
| Confidentiality | Low/Moderate/High | |
| Integrity | Low/Moderate/High | |
| Availability | Low/Moderate/High | |
| **Overall** | **Low/Moderate/High** | |

## Phase 2: Control Baseline Assessment
1. Assess control implementation against FedRAMP baseline
   - [ ] Access Control (AC) family
   - [ ] Audit and Accountability (AU) family
   - [ ] Security Assessment (CA) family
   - [ ] Configuration Management (CM) family
   - [ ] Contingency Planning (CP) family
   - [ ] Identification and Authentication (IA) family
   - [ ] Incident Response (IR) family
   - [ ] Maintenance (MA) family
   - [ ] Media Protection (MP) family
   - [ ] Physical and Environmental (PE) family
   - [ ] Planning (PL) family
   - [ ] Program Management (PM) family
   - [ ] Personnel Security (PS) family
   - [ ] Risk Assessment (RA) family
   - [ ] System and Services Acquisition (SA) family
   - [ ] System and Communications Protection (SC) family
   - [ ] System and Information Integrity (SI) family

### Control Assessment Summary

| Family | Total Controls | Implemented | Partially | Not Implemented | N/A |
|--------|---------------|-------------|-----------|-----------------|-----|
| AC | | | | | |
| AU | | | | | |
| CA | | | | | |
| CM | | | | | |
| CP | | | | | |
| IA | | | | | |
| IR | | | | | |
| SC | | | | | |
| SI | | | | | |
| Other | | | | | |

## Phase 3: Documentation Preparation
1. Prepare required FedRAMP documentation
   - [ ] System Security Plan (SSP)
   - [ ] Control Implementation Summary (CIS)
   - [ ] Policies and procedures for each control family
   - [ ] Incident Response Plan
   - [ ] Contingency Plan (and test results)
   - [ ] Configuration Management Plan
   - [ ] Supply Chain Risk Management Plan
   - [ ] Privacy Impact Assessment (PIA)
   - [ ] User Guide and administrator documentation
2. Complete FedRAMP Readiness Assessment Report (RAR)
3. Prepare continuous monitoring plan

## Phase 4: Technical Implementation Gaps
1. Identify and remediate technical gaps
   - [ ] FIPS 140-2/140-3 validated cryptography
   - [ ] Multi-factor authentication for all users
   - [ ] Continuous monitoring and vulnerability scanning
   - [ ] Audit logging with integrity verification
   - [ ] Session management and timeout controls
   - [ ] DNSSEC implementation
   - [ ] TLS 1.2+ for all connections
2. Develop POA&M for items requiring remediation

### POA&M Summary

| ID | Control | Weakness | Severity | Remediation Plan | Target Date | Status |
|----|---------|----------|----------|-----------------|-------------|--------|
|    |         |          | High/Mod/Low |            |             |        |

## Phase 5: 3PAO Assessment Preparation
1. Select accredited 3PAO
2. Prepare evidence artifacts per control
3. Conduct internal mock assessment
4. Schedule and scope 3PAO engagement
5. Prepare staff for assessment interviews

## Phase 6: Continuous Monitoring Setup
1. Implement automated vulnerability scanning (monthly)
2. Configure security event logging and alerting
3. Plan annual security assessment schedule
4. Set up monthly POA&M reporting
5. Define significant change process

## Counter-Rationalizations

| Shortcut | Counter | Why |
|----------|---------|-----|
| "We can skip some steps for this case" | Adapt the workflow steps, don't skip them | Skipped steps are where incidents and oversights originate |
| "The user seems to already know what to do" | Complete all workflow phases with the user | The workflow catches blind spots that experience alone misses |
| "This is a minor case, full process is overkill" | Scale the process down, don't turn it off | Minor cases become major when unstructured; the process scales, not disappears |
| "I'll fill in the details later" | Complete each section before moving on | Deferred details are forgotten; real-time capture is more accurate |
| "The template output isn't necessary" | Always produce the structured output format | Structured output enables comparison, audit trails, and handoff to other teams |

## Output Format
- **Readiness Scorecard**: Per-family compliance percentage
- **Gap Analysis**: Controls not yet implemented with severity
- **POA&M**: Plan of Action and Milestones for all gaps
- **Documentation Checklist**: Required documents with completion status
- **Timeline to Authorization**: Estimated path with milestones

## Action Items
- [ ] Complete system boundary and impact level determination
- [ ] Assess all controls against the target baseline
- [ ] Draft System Security Plan
- [ ] Remediate high-severity gaps
- [ ] Complete FedRAMP Readiness Assessment Report
- [ ] Engage 3PAO for independent assessment
- [ ] Submit authorization package
