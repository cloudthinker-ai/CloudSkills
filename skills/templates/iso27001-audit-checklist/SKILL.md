---
name: iso27001-audit-checklist
enabled: true
description: |
  Provides a comprehensive audit checklist aligned with ISO 27001:2022 Annex A controls for information security management systems. Covers all 93 controls across organizational, people, physical, and technological domains with evidence collection guidance and gap remediation planning.
required_connections:
  - prefix: grc-tool
    label: "GRC Platform"
config_fields:
  - key: organization_name
    label: "Organization Name"
    required: true
    placeholder: "e.g., Acme Corp"
  - key: scope
    label: "ISMS Scope"
    required: true
    placeholder: "e.g., Cloud infrastructure and SaaS platform"
  - key: audit_type
    label: "Audit Type"
    required: false
    placeholder: "e.g., internal, surveillance, recertification"
features:
  - COMPLIANCE
  - ISO27001
  - AUDIT
---

# ISO 27001:2022 Audit Checklist

## Phase 1: ISMS Documentation Review
1. Review ISMS documentation
   - [ ] Information security policy and objectives
   - [ ] Scope of the ISMS
   - [ ] Risk assessment methodology
   - [ ] Risk treatment plan
   - [ ] Statement of Applicability (SoA)
   - [ ] Roles and responsibilities documented
   - [ ] Management review meeting minutes
2. Verify document control and version management
3. Check mandatory documented information per clause requirements

## Phase 2: Organizational Controls (A.5)
- [ ] A.5.1 - Policies for information security
- [ ] A.5.2 - Information security roles and responsibilities
- [ ] A.5.3 - Segregation of duties
- [ ] A.5.4 - Management responsibilities
- [ ] A.5.5 - Contact with authorities
- [ ] A.5.6 - Contact with special interest groups
- [ ] A.5.7 - Threat intelligence
- [ ] A.5.8 - Information security in project management
- [ ] A.5.9 - Inventory of information and associated assets
- [ ] A.5.10 - Acceptable use of information and associated assets
- [ ] A.5.11 - Return of assets
- [ ] A.5.12 - Classification of information
- [ ] A.5.13 - Labelling of information
- [ ] A.5.14 - Information transfer
- [ ] A.5.15 - Access control
- [ ] A.5.16 - Identity management
- [ ] A.5.17 - Authentication information
- [ ] A.5.18 - Access rights
- [ ] A.5.19-A.5.22 - Supplier management
- [ ] A.5.23 - Information security for cloud services
- [ ] A.5.24-A.5.28 - Incident management
- [ ] A.5.29-A.5.30 - Business continuity
- [ ] A.5.31-A.5.36 - Compliance and reviews
- [ ] A.5.37 - Documented operating procedures

## Phase 3: People Controls (A.6)
- [ ] A.6.1 - Screening
- [ ] A.6.2 - Terms and conditions of employment
- [ ] A.6.3 - Information security awareness, education, training
- [ ] A.6.4 - Disciplinary process
- [ ] A.6.5 - Responsibilities after termination
- [ ] A.6.6 - Confidentiality or non-disclosure agreements
- [ ] A.6.7 - Remote working
- [ ] A.6.8 - Information security event reporting

## Phase 4: Physical Controls (A.7)
- [ ] A.7.1 - Physical security perimeters
- [ ] A.7.2 - Physical entry
- [ ] A.7.3 - Securing offices, rooms, and facilities
- [ ] A.7.4 - Physical security monitoring
- [ ] A.7.5 - Protecting against physical and environmental threats
- [ ] A.7.6-A.7.8 - Working in secure areas, clear desk/screen
- [ ] A.7.9-A.7.14 - Equipment security

## Phase 5: Technological Controls (A.8)
- [ ] A.8.1 - User endpoint devices
- [ ] A.8.2 - Privileged access rights
- [ ] A.8.3 - Information access restriction
- [ ] A.8.4 - Access to source code
- [ ] A.8.5 - Secure authentication
- [ ] A.8.6 - Capacity management
- [ ] A.8.7 - Protection against malware
- [ ] A.8.8 - Management of technical vulnerabilities
- [ ] A.8.9 - Configuration management
- [ ] A.8.10 - Information deletion
- [ ] A.8.11 - Data masking
- [ ] A.8.12 - Data leakage prevention
- [ ] A.8.13 - Information backup
- [ ] A.8.14 - Redundancy of information processing facilities
- [ ] A.8.15 - Logging
- [ ] A.8.16 - Monitoring activities
- [ ] A.8.17 - Clock synchronization
- [ ] A.8.18-A.8.25 - Software and network security
- [ ] A.8.26-A.8.28 - Application security and testing
- [ ] A.8.29-A.8.34 - Operations security

### Gap Assessment Summary

| Domain | Controls Assessed | Conforming | Minor Gaps | Major Gaps | Not Applicable |
|--------|------------------|------------|------------|------------|----------------|
| Organizational (A.5) | 37 | | | | |
| People (A.6) | 8 | | | | |
| Physical (A.7) | 14 | | | | |
| Technological (A.8) | 34 | | | | |
| **Total** | **93** | | | | |

## Phase 6: Remediation Planning
1. Prioritize gaps by risk severity
2. Assign remediation owners and deadlines
3. Define evidence requirements for each gap
4. Schedule follow-up assessments
5. Update risk treatment plan

## Output Format
- **Audit Report**: Control-by-control assessment with findings
- **Gap Analysis**: Summary of non-conformities with severity ratings
- **Evidence Matrix**: Required evidence per control with collection status
- **Remediation Plan**: Prioritized actions with owners and deadlines
- **Statement of Applicability Update**: Revised SoA reflecting current state

## Action Items
- [ ] Complete documentation review for all ISMS documents
- [ ] Assess all 93 Annex A controls
- [ ] Document evidence collected per control
- [ ] Classify and prioritize all gaps found
- [ ] Assign remediation actions with deadlines
- [ ] Schedule management review of audit findings
