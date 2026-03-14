---
name: access-request-workflow
enabled: true
description: |
  Standardized access request process with multi-level approval chain for granting system, application, and data access. Covers request submission, manager approval, security review, provisioning, and access certification to ensure least-privilege compliance and audit trail documentation.
required_connections:
  - prefix: itsm
    label: "ITSM Tool (ServiceNow, Freshservice, etc.)"
config_fields:
  - key: requester_name
    label: "Requester Name"
    required: true
    placeholder: "e.g., Jane Smith"
  - key: system_name
    label: "System / Application Name"
    required: true
    placeholder: "e.g., Salesforce, AWS Console, GitHub"
  - key: access_level
    label: "Access Level Requested"
    required: true
    placeholder: "e.g., Read-only, Editor, Admin"
  - key: business_justification
    label: "Business Justification"
    required: true
    placeholder: "e.g., Required for Q2 project deliverables"
  - key: duration
    label: "Access Duration (permanent/temporary)"
    required: false
    placeholder: "e.g., permanent, 90 days, until 2026-06-30"
features:
  - HELPDESK
---

# Access Request Workflow

Access request for **{{ requester_name }}** to **{{ system_name }}**
Level: **{{ access_level }}** | Duration: {{ duration }}

## Step 1 — Request Validation

### Pre-checks
- [ ] Verify {{ requester_name }} is an active employee
- [ ] Confirm {{ system_name }} is a recognized system in the service catalog
- [ ] Check if {{ requester_name }} already has access to {{ system_name }}
- [ ] Validate that {{ access_level }} is an available role in {{ system_name }}
- [ ] Review business justification: "{{ business_justification }}"

### Risk Assessment
```
ACCESS RISK CLASSIFICATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
System: {{ system_name }}
Requested Level: {{ access_level }}

Risk Level:
- LOW: Read-only access to non-sensitive systems
- MEDIUM: Write access or access to internal business data
- HIGH: Admin access, PII/PHI data, financial systems, production infrastructure
- CRITICAL: Domain admin, security tools, audit systems

Required Approvals by Risk:
- LOW: Manager approval only
- MEDIUM: Manager + system owner approval
- HIGH: Manager + system owner + security team approval
- CRITICAL: Manager + system owner + security team + CISO approval
```

## Step 2 — Approval Chain

### Manager Approval
- [ ] Notify direct manager of {{ requester_name }}
- [ ] Manager confirms business need and role appropriateness
- [ ] Manager approval received: ______ (date/time)

### System Owner Approval (if MEDIUM+ risk)
- [ ] Identify system owner for {{ system_name }}
- [ ] System owner reviews access level appropriateness
- [ ] System owner approval received: ______ (date/time)

### Security Review (if HIGH+ risk)
- [ ] Security team reviews for least-privilege compliance
- [ ] Check for segregation of duties conflicts
- [ ] Security approval received: ______ (date/time)

## Step 3 — Provisioning

- [ ] Create or update account in {{ system_name }}
- [ ] Assign {{ access_level }} role/permissions
- [ ] If temporary: set access expiration for {{ duration }}
- [ ] Configure MFA if required by system
- [ ] Add to appropriate groups/roles
- [ ] Send access credentials securely to {{ requester_name }}

## Step 4 — Verification & Documentation

- [ ] {{ requester_name }} confirms successful access
- [ ] Document access grant in ITSM with approval chain
- [ ] Update access matrix / entitlement records
- [ ] Schedule access review date (quarterly or per {{ duration }})
- [ ] Close access request ticket

## Output Format

Generate an access request summary with:
1. **Request details** (requester, system, level, justification)
2. **Risk classification** with required approvals
3. **Approval chain status** with timestamps
4. **Provisioning confirmation** and next review date
