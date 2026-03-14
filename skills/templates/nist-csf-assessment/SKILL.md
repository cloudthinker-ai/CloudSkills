---
name: nist-csf-assessment
enabled: true
description: |
  Conducts an assessment against the NIST Cybersecurity Framework (CSF 2.0), evaluating organizational maturity across all six core functions: Govern, Identify, Protect, Detect, Respond, and Recover. Produces a current state profile, target profile, and prioritized gap remediation plan.
required_connections:
  - prefix: grc-tool
    label: "GRC Platform"
config_fields:
  - key: organization_name
    label: "Organization Name"
    required: true
    placeholder: "e.g., Acme Corp"
  - key: industry
    label: "Industry Sector"
    required: true
    placeholder: "e.g., Financial Services, Healthcare, Technology"
  - key: target_tier
    label: "Target Implementation Tier"
    required: false
    placeholder: "e.g., Tier 2 (Risk Informed), Tier 3 (Repeatable)"
features:
  - COMPLIANCE
  - NIST
  - CYBERSECURITY
---

# NIST Cybersecurity Framework 2.0 Assessment

## Phase 1: Scoping & Context
1. Define assessment scope
   - [ ] Business units included
   - [ ] Systems and assets in scope
   - [ ] Critical business processes
   - [ ] Regulatory requirements applicable
2. Identify stakeholders and interview participants
3. Gather existing security documentation
4. Define target implementation tier

### Implementation Tier Assessment

| Criterion | Tier 1 (Partial) | Tier 2 (Risk Informed) | Tier 3 (Repeatable) | Tier 4 (Adaptive) |
|-----------|-----------------|----------------------|--------------------|--------------------|
| Risk Management Process | Ad hoc | Approved but informal | Formal, org-wide | Continuously improving |
| Integrated Risk Program | Limited | Some awareness | Org-wide awareness | Active participation |
| External Participation | None | Informal | Formal agreements | Active contribution |
| **Current Tier** | [ ] | [ ] | [ ] | [ ] |
| **Target Tier** | [ ] | [ ] | [ ] | [ ] |

## Phase 2: Govern (GV) Function Assessment
- [ ] GV.OC - Organizational Context understood
- [ ] GV.RM - Risk Management Strategy established
- [ ] GV.RR - Roles, Responsibilities, and Authorities defined
- [ ] GV.PO - Policy established and communicated
- [ ] GV.OV - Oversight of cybersecurity strategy
- [ ] GV.SC - Supply Chain Risk Management

## Phase 3: Identify (ID) Function Assessment
- [ ] ID.AM - Asset Management
- [ ] ID.RA - Risk Assessment
- [ ] ID.IM - Improvement processes

## Phase 4: Protect (PR) Function Assessment
- [ ] PR.AA - Identity Management, Authentication, and Access Control
- [ ] PR.AT - Awareness and Training
- [ ] PR.DS - Data Security
- [ ] PR.PS - Platform Security
- [ ] PR.IR - Technology Infrastructure Resilience

## Phase 5: Detect (DE) Function Assessment
- [ ] DE.CM - Continuous Monitoring
- [ ] DE.AE - Adverse Event Analysis

## Phase 6: Respond (RS) Function Assessment
- [ ] RS.MA - Incident Management
- [ ] RS.AN - Incident Analysis
- [ ] RS.CO - Incident Response Reporting and Communication
- [ ] RS.MI - Incident Mitigation

## Phase 7: Recover (RC) Function Assessment
- [ ] RC.RP - Incident Recovery Plan Execution
- [ ] RC.CO - Recovery Communication

### Maturity Scoring Summary

| Function | Categories | Current Score (1-4) | Target Score (1-4) | Gap |
|----------|-----------|--------------------|--------------------|-----|
| Govern (GV) | 6 | | | |
| Identify (ID) | 3 | | | |
| Protect (PR) | 5 | | | |
| Detect (DE) | 2 | | | |
| Respond (RS) | 4 | | | |
| Recover (RC) | 2 | | | |
| **Overall** | **22** | | | |

## Phase 8: Gap Analysis & Roadmap
1. Compare current profile to target profile
2. Prioritize gaps by risk and business impact
3. Develop remediation roadmap with quick wins and long-term initiatives
4. Estimate resource requirements per initiative
5. Define success metrics and milestones

## Output Format
- **Current State Profile**: Maturity score per function and category
- **Target State Profile**: Desired maturity levels with justification
- **Gap Analysis**: Prioritized list of gaps with severity
- **Remediation Roadmap**: Phased plan with timelines and resources
- **Executive Summary**: One-page overview for leadership

## Action Items
- [ ] Complete stakeholder interviews
- [ ] Assess all six CSF functions
- [ ] Score current and target maturity levels
- [ ] Prioritize gaps by risk impact
- [ ] Develop phased remediation roadmap
- [ ] Present findings to executive leadership
- [ ] Schedule follow-up assessment in 12 months
