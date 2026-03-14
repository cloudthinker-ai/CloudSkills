---
name: vendor-risk-assessment
enabled: true
description: |
  Template for evaluating third-party vendor risk before onboarding or during periodic reviews. Covers security posture assessment, data handling practices, compliance certifications, business continuity capabilities, contractual obligations, and risk scoring to make informed vendor decisions.
required_connections:
  - prefix: jira
    label: "Jira (or project tracker)"
config_fields:
  - key: vendor_name
    label: "Vendor Name"
    required: true
    placeholder: "e.g., Acme Cloud Services"
  - key: service_category
    label: "Service Category"
    required: true
    placeholder: "e.g., SaaS, infrastructure, payment processing"
  - key: data_classification
    label: "Data Classification"
    required: true
    placeholder: "e.g., public, internal, confidential, restricted"
features:
  - COMPLIANCE
  - SECURITY
---

# Vendor Risk Assessment Skill

Assess risk for vendor **{{ vendor_name }}** ({{ service_category }}) handling **{{ data_classification }}** data.

## Workflow

### Phase 1 — Vendor Profile

```
VENDOR OVERVIEW
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Vendor: {{ vendor_name }}
[ ] Service category: {{ service_category }}
[ ] Data classification: {{ data_classification }}
[ ] Vendor headquarters: ___
[ ] Company age: ___ years
[ ] Employee count: ___
[ ] Annual revenue (if public): ___
[ ] Key customers/references: ___
[ ] Sub-processors used: ___
```

### Phase 2 — Security Assessment

```
SECURITY POSTURE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Certifications:
[ ] SOC 2 Type II (report date: ___)
[ ] ISO 27001 (certificate date: ___)
[ ] PCI DSS (if payment data)
[ ] HIPAA (if health data)
[ ] FedRAMP (if government)

Technical controls:
[ ] Encryption at rest: [ ] YES — algorithm: ___
[ ] Encryption in transit: [ ] YES — TLS version: ___
[ ] Multi-factor authentication: [ ] YES
[ ] SSO integration (SAML/OIDC): [ ] YES
[ ] Role-based access control: [ ] YES
[ ] Audit logging: [ ] YES
[ ] Vulnerability management program: [ ] YES
[ ] Penetration testing (last date: ___)
[ ] Incident response plan: [ ] YES
[ ] Security team size: ___

RISK SCORE (per category, 1-5 scale)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Category                | Score | Weight | Weighted
Authentication/AuthZ    |       | 20%    |
Data encryption         |       | 20%    |
Vulnerability mgmt      |       | 15%    |
Incident response       |       | 15%    |
Compliance certs        |       | 15%    |
Physical security       |       | 5%     |
Network security        |       | 10%    |
TOTAL                   |       |        |
```

### Phase 3 — Data Handling

```
DATA PRACTICES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Data types shared with vendor:
    - ___
    - ___
[ ] Data residency: ___
[ ] Data retention policy: ___
[ ] Data deletion capability: [ ] YES — timeline: ___
[ ] Data portability/export: [ ] YES — format: ___
[ ] Data breach notification: [ ] YES — timeline: ___
[ ] Sub-processor data sharing: [ ] YES — list provided: [ ] YES
[ ] Cross-border data transfers: [ ] YES — mechanism: ___
```

### Phase 4 — Business Continuity

```
CONTINUITY AND RELIABILITY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] SLA commitment: ___% uptime
[ ] Historical uptime (12 months): ___%
[ ] Disaster recovery plan: [ ] YES
    - RTO: ___
    - RPO: ___
[ ] Geographic redundancy: [ ] YES — regions: ___
[ ] Financial stability:
    [ ] Profitable / funded (runway: ___)
    [ ] No recent layoffs or acquisition rumors
[ ] Exit strategy:
    [ ] Data export available
    [ ] Migration support offered
    [ ] Contract termination terms acceptable
```

### Phase 5 — Risk Decision

```
RISK SUMMARY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Overall risk rating: [ ] LOW  [ ] MEDIUM  [ ] HIGH  [ ] CRITICAL

DECISION MATRIX
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Risk Level  | Data: Public | Data: Internal | Data: Confidential | Data: Restricted
LOW         | APPROVE      | APPROVE        | APPROVE            | REVIEW
MEDIUM      | APPROVE      | APPROVE        | CONDITIONAL        | ESCALATE
HIGH        | APPROVE      | CONDITIONAL    | ESCALATE           | REJECT
CRITICAL    | CONDITIONAL  | ESCALATE       | REJECT             | REJECT

Decision: [ ] APPROVED  [ ] CONDITIONAL  [ ] REJECTED
Conditions (if applicable):
- ___
- ___

Approved by: ___
Review date: ___
Next reassessment: ___
```

## Output Format

Produce a vendor risk assessment report with:
1. **Vendor profile** (company overview, service category)
2. **Security scorecard** (certifications, controls, risk scores)
3. **Data handling assessment** (practices, residency, compliance)
4. **Business continuity** (SLA, DR capabilities, financial stability)
5. **Risk decision** (rating, conditions, approval status)
