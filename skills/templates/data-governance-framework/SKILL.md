---
name: data-governance-framework
enabled: true
description: |
  Use when performing data governance framework — establishes a comprehensive
  data governance framework covering data ownership, quality standards,
  classification, lineage tracking, access policies, and stewardship roles.
  Produces actionable policies and procedures to ensure data is managed as a
  strategic organizational asset.
required_connections:
  - prefix: data-catalog
    label: "Data Catalog Platform"
config_fields:
  - key: organization_name
    label: "Organization Name"
    required: true
    placeholder: "e.g., Acme Corp"
  - key: data_domains
    label: "Primary Data Domains"
    required: true
    placeholder: "e.g., Customer, Product, Financial, Operational"
  - key: regulatory_requirements
    label: "Regulatory Requirements"
    required: false
    placeholder: "e.g., GDPR, CCPA, HIPAA, SOX"
features:
  - DATA
  - GOVERNANCE
  - COMPLIANCE
---

# Data Governance Framework

## Phase 1: Governance Structure
1. Define governance organization
   - [ ] Data governance council (executive sponsors)
   - [ ] Data domain owners (business leaders per domain)
   - [ ] Data stewards (operational responsibility per domain)
   - [ ] Data engineers (technical implementation)
   - [ ] Data protection officer (privacy and compliance)
2. Define decision rights and escalation paths
3. Establish governance meeting cadence
4. Create governance charter and mandate

### RACI Matrix

| Activity | Council | Domain Owner | Data Steward | Data Engineer | DPO |
|----------|---------|-------------|-------------|---------------|-----|
| Policy creation | A | R | C | I | C |
| Data classification | I | A | R | C | C |
| Quality standards | I | A | R | C | I |
| Access approval | I | A | R | I | C |
| Compliance monitoring | A | I | R | C | R |
| Issue resolution | A | R | C | C | C |

## Phase 2: Data Classification & Inventory
1. Define data classification levels
   - [ ] Public - no restrictions
   - [ ] Internal - organization-wide access
   - [ ] Confidential - role-based access
   - [ ] Restricted - strict access controls (PII, PHI, financial)
2. Inventory and classify data assets
3. Document data lineage (source to consumption)
4. Map data to regulatory requirements

### Data Asset Inventory

| Domain | Dataset | Classification | Owner | Steward | Regulatory | Quality Score |
|--------|---------|---------------|-------|---------|-----------|--------------|
|        |         | Public/Internal/Confidential/Restricted | | | GDPR/CCPA/HIPAA/None | /100 |

## Phase 3: Data Quality Standards
1. Define data quality dimensions
   - [ ] Completeness - required fields populated
   - [ ] Accuracy - values reflect reality
   - [ ] Consistency - same data matches across systems
   - [ ] Timeliness - data available when needed
   - [ ] Uniqueness - no unintended duplicates
   - [ ] Validity - values conform to expected formats
2. Set quality thresholds per domain
3. Implement automated quality monitoring
4. Define data quality incident process

### Quality Thresholds

| Domain | Completeness | Accuracy | Consistency | Timeliness | Overall Target |
|--------|-------------|----------|-------------|------------|---------------|
| Customer | > % | > % | > % | < hrs | > % |
| Product | > % | > % | > % | < hrs | > % |
| Financial | > % | > % | > % | < hrs | > % |

## Phase 4: Access & Security Policies
1. Define data access policies
   - [ ] Role-based access control (RBAC) for data assets
   - [ ] Data access request and approval workflow
   - [ ] Sensitive data masking and anonymization rules
   - [ ] Data sharing agreements for external parties
   - [ ] Data retention and deletion schedules
   - [ ] Audit logging for data access
2. Implement technical controls for data protection
3. Define breach notification procedures

## Phase 5: Data Lifecycle Management
1. Define lifecycle stages
   - [ ] Creation / ingestion standards
   - [ ] Storage and retention policies
   - [ ] Usage and sharing guidelines
   - [ ] Archival procedures
   - [ ] Deletion and destruction procedures
2. Implement automated lifecycle enforcement
3. Document data retention schedule per regulation

## Phase 6: Monitoring & Continuous Improvement
1. Establish governance metrics
   - [ ] Data quality scores by domain (monthly)
   - [ ] Policy compliance rate
   - [ ] Access review completion rate
   - [ ] Data incident count and resolution time
   - [ ] Governance adoption rate across teams
2. Conduct quarterly governance reviews
3. Update policies based on regulatory changes

## Counter-Rationalizations

| Shortcut | Counter | Why |
|----------|---------|-----|
| "We can skip some steps for this case" | Adapt the workflow steps, don't skip them | Skipped steps are where incidents and oversights originate |
| "The user seems to already know what to do" | Complete all workflow phases with the user | The workflow catches blind spots that experience alone misses |
| "This is a minor case, full process is overkill" | Scale the process down, don't turn it off | Minor cases become major when unstructured; the process scales, not disappears |
| "I'll fill in the details later" | Complete each section before moving on | Deferred details are forgotten; real-time capture is more accurate |
| "The template output isn't necessary" | Always produce the structured output format | Structured output enables comparison, audit trails, and handoff to other teams |

## Output Format
- **Governance Charter**: Roles, responsibilities, and decision rights
- **Data Classification Guide**: Levels with handling requirements
- **Quality Standards**: Thresholds and monitoring procedures
- **Access Policy**: RBAC model and approval workflows
- **Lifecycle Policy**: Retention schedules and procedures

## Action Items
- [ ] Establish data governance council with executive sponsorship
- [ ] Appoint domain owners and data stewards
- [ ] Classify and inventory all critical data assets
- [ ] Define and implement data quality standards
- [ ] Publish data access and retention policies
- [ ] Set up governance metrics dashboard
- [ ] Schedule quarterly governance review meetings
