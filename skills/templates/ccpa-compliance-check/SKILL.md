---
name: ccpa-compliance-check
enabled: true
description: |
  Evaluates organizational compliance with the California Consumer Privacy Act (CCPA) and California Privacy Rights Act (CPRA). Covers consumer rights implementation, data inventory, privacy notice requirements, vendor management, opt-out mechanisms, and data protection assessments.
required_connections:
  - prefix: grc-tool
    label: "GRC Platform"
config_fields:
  - key: organization_name
    label: "Organization Name"
    required: true
    placeholder: "e.g., Acme Corp"
  - key: data_subjects_count
    label: "Approximate California Consumer Count"
    required: true
    placeholder: "e.g., 100,000"
  - key: data_categories
    label: "Primary Personal Information Categories"
    required: false
    placeholder: "e.g., contact info, purchase history, browsing data"
features:
  - COMPLIANCE
  - PRIVACY
  - CCPA
---

# CCPA/CPRA Compliance Check

## Phase 1: Applicability Assessment
1. Determine CCPA/CPRA applicability
   - [ ] Annual gross revenue > $25 million
   - [ ] Buy/sell/share personal info of 100,000+ consumers/households
   - [ ] Derive 50%+ of revenue from selling/sharing personal info
2. Identify all business entities in scope
3. Determine if acting as business, service provider, or contractor
4. Identify any exemptions applicable (employee data, B2B, etc.)

## Phase 2: Data Inventory & Mapping
1. Catalog personal information collected
   - [ ] Identifiers (name, email, SSN, IP address)
   - [ ] Commercial information (purchase history)
   - [ ] Internet/network activity (browsing, search history)
   - [ ] Geolocation data
   - [ ] Professional/employment information
   - [ ] Education information
   - [ ] Inferences drawn from above
   - [ ] Sensitive personal information
2. Document data sources, purposes, and retention periods
3. Map data flows to third parties and service providers
4. Identify data sold or shared for cross-context behavioral advertising

### Data Mapping Summary

| Category | Sources | Purpose | Shared With | Sold | Retention |
|----------|---------|---------|-------------|------|-----------|
| Identifiers | | | | Yes/No | |
| Commercial | | | | Yes/No | |
| Internet activity | | | | Yes/No | |
| Geolocation | | | | Yes/No | |
| Sensitive PI | | | | Yes/No | |

## Phase 3: Consumer Rights Implementation
1. Assess consumer rights mechanisms
   - [ ] Right to Know (access requests)
   - [ ] Right to Delete
   - [ ] Right to Correct
   - [ ] Right to Opt-Out of Sale/Sharing
   - [ ] Right to Limit Use of Sensitive PI
   - [ ] Right to Non-Discrimination
   - [ ] Right to data portability
2. Verify request submission methods (minimum 2 methods required)
3. Test request fulfillment within 45-day timeline
4. Verify identity verification procedures
5. Assess authorized agent request handling

### Rights Compliance Matrix

| Right | Mechanism Exists | Process Documented | Tested | Timeline Met | Compliant |
|-------|-----------------|-------------------|--------|-------------|-----------|
| Know/Access | [ ] | [ ] | [ ] | [ ] | [ ] |
| Delete | [ ] | [ ] | [ ] | [ ] | [ ] |
| Correct | [ ] | [ ] | [ ] | [ ] | [ ] |
| Opt-Out Sale/Share | [ ] | [ ] | [ ] | [ ] | [ ] |
| Limit Sensitive PI | [ ] | [ ] | [ ] | [ ] | [ ] |

## Phase 4: Privacy Notice Review
1. Review privacy policy for required disclosures
   - [ ] Categories of PI collected in past 12 months
   - [ ] Purposes for each category
   - [ ] Categories of third parties PI shared with
   - [ ] Consumer rights description
   - [ ] "Do Not Sell or Share My Personal Information" link
   - [ ] "Limit the Use of My Sensitive Personal Information" link
   - [ ] Updated within past 12 months
2. Verify notice at collection is provided
3. Review financial incentive notices if applicable
4. Assess cookie banner and GPC signal handling

## Phase 5: Vendor & Service Provider Management
1. Review service provider and contractor agreements
   - [ ] Written contract with CCPA-required terms
   - [ ] Purpose limitations specified
   - [ ] Prohibition on selling/sharing received PI
   - [ ] Obligation to assist with consumer requests
   - [ ] Right to audit compliance
2. Assess third-party data sharing agreements
3. Verify data processing agreements are current

## Phase 6: Data Protection Assessment
1. Evaluate security measures for personal information
2. Assess data minimization practices
3. Review data retention and deletion schedules
4. Verify breach notification procedures
5. Conduct risk assessment for high-risk processing (CPRA requirement)

## Output Format
- **Applicability Determination**: Criteria met and entities in scope
- **Data Inventory**: Complete PI catalog with flows and purposes
- **Rights Assessment**: Compliance status per consumer right
- **Privacy Notice Gap Analysis**: Required vs. current disclosures
- **Remediation Plan**: Prioritized actions with timelines

## Action Items
- [ ] Complete personal information data mapping
- [ ] Implement missing consumer rights mechanisms
- [ ] Update privacy policy with all required disclosures
- [ ] Review and update service provider agreements
- [ ] Implement opt-out signal handling (GPC)
- [ ] Conduct annual data protection assessment
- [ ] Train staff on CCPA request handling procedures
