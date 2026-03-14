---
name: employee-offboarding-it
enabled: true
description: |
  IT offboarding workflow for departing employees covering access revocation, device collection, data handling, license reclamation, and compliance documentation. Ensures all IT access is properly removed, company assets are returned, and data retention policies are followed during employee separation.
required_connections:
  - prefix: itsm
    label: "ITSM Tool (ServiceNow, Freshservice, etc.)"
config_fields:
  - key: employee_name
    label: "Departing Employee Name"
    required: true
    placeholder: "e.g., Jane Smith"
  - key: department
    label: "Department"
    required: true
    placeholder: "e.g., Engineering, Marketing, Sales"
  - key: last_day
    label: "Last Working Day"
    required: true
    placeholder: "e.g., 2026-04-15"
  - key: manager_name
    label: "Manager Name"
    required: true
    placeholder: "e.g., John Doe"
  - key: separation_type
    label: "Separation Type (voluntary/involuntary)"
    required: false
    placeholder: "e.g., voluntary, involuntary, contract end"
features:
  - HELPDESK
---

# Employee IT Offboarding Workflow

IT offboarding for **{{ employee_name }}** ({{ department }})
Last Day: **{{ last_day }}** | Manager: {{ manager_name }} | Type: {{ separation_type }}

## Phase 1 — Pre-Departure (3-5 business days before last day)

### Access Audit
- [ ] Inventory all systems and applications {{ employee_name }} has access to
- [ ] Document all group memberships and role assignments
- [ ] Identify any shared accounts or service accounts managed by the employee
- [ ] Check for any API keys, tokens, or secrets created by the employee
- [ ] Review file shares and cloud storage permissions

### Data Handling
- [ ] Coordinate with {{ manager_name }} on data transfer requirements
- [ ] Identify critical files that need to be transferred to a colleague
- [ ] Back up email mailbox per retention policy
- [ ] Back up personal drive / OneDrive / Google Drive per retention policy
- [ ] Document any knowledge transfer requirements

### Device Planning
- [ ] Identify all company devices assigned to {{ employee_name }}
- [ ] Schedule device return (in-person or shipping label for remote)
- [ ] Prepare device wipe checklist

## Phase 2 — Last Day (end of business on {{ last_day }})

### Immediate Access Revocation
- [ ] Disable Active Directory / identity provider account
- [ ] Revoke SSO access (all connected applications disabled automatically)
- [ ] Disable email account (convert to shared mailbox if needed)
- [ ] Revoke VPN access
- [ ] Remove from MFA/2FA
- [ ] Disable remote access tools
- [ ] Revoke badge/physical access (coordinate with facilities)

### Application-Specific Revocation
- [ ] Remove from Slack / Teams / collaboration platforms
- [ ] Revoke access to source code repositories (GitHub, GitLab, Bitbucket)
- [ ] Remove from cloud console access (AWS, Azure, GCP)
- [ ] Revoke ITSM portal access
- [ ] Remove from SaaS applications not covered by SSO
- [ ] Revoke any delegated admin permissions

### Communication
- [ ] Set up email auto-reply / forwarding (per policy, max 30 days)
- [ ] Update voicemail greeting if applicable
- [ ] Remove from email distribution lists

## Phase 3 — Post-Departure (within 5 business days)

### Device Processing
- [ ] Collect all company devices (laptop, phone, tablet, peripherals)
- [ ] Verify device encryption status before wipe
- [ ] Perform secure data wipe on all returned devices
- [ ] Update asset management records (return to inventory)
- [ ] Reclaim software licenses from device

### License Reclamation
- [ ] Reclaim all named-user software licenses
- [ ] Deactivate license seats for SaaS tools
- [ ] Update license count in asset management

### Compliance & Documentation
- [ ] Confirm all access has been revoked (audit log review)
- [ ] Document offboarding completion in ITSM
- [ ] File offboarding checklist for compliance records
- [ ] Notify {{ manager_name }} of completion
- [ ] Close offboarding ticket

## Output Format

Generate a tracked offboarding report with:
1. **Summary** with employee details and completion status
2. **Access revocation checklist** with timestamps
3. **Asset return status** with device details
4. **Compliance sign-off** confirmation
