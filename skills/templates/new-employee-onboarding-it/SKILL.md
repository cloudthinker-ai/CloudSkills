---
name: new-employee-onboarding-it
enabled: true
description: |
  IT onboarding checklist for new employees covering account provisioning, hardware setup, access permissions, software installation, and initial training. Generates a comprehensive onboarding task list that tracks progress through each phase from pre-arrival preparation to first-week orientation, ensuring no critical IT setup steps are missed.
required_connections:
  - prefix: itsm
    label: "ITSM Tool (ServiceNow, Freshservice, etc.)"
config_fields:
  - key: employee_name
    label: "New Employee Name"
    required: true
    placeholder: "e.g., Jane Smith"
  - key: department
    label: "Department"
    required: true
    placeholder: "e.g., Engineering, Marketing, Sales"
  - key: role
    label: "Job Title / Role"
    required: true
    placeholder: "e.g., Software Engineer, Marketing Manager"
  - key: start_date
    label: "Start Date"
    required: true
    placeholder: "e.g., 2026-04-01"
  - key: manager_name
    label: "Manager Name"
    required: false
    placeholder: "e.g., John Doe"
  - key: location
    label: "Office Location / Remote"
    required: false
    placeholder: "e.g., NYC Office, Remote - US East"
features:
  - HELPDESK
---

# New Employee IT Onboarding Checklist

IT onboarding workflow for **{{ employee_name }}** ({{ role }}, {{ department }})
Start Date: **{{ start_date }}** | Location: {{ location }} | Manager: {{ manager_name }}

## Phase 1 — Pre-Arrival (5-3 business days before start)

### Account Provisioning
- [ ] Create Active Directory / identity provider account
- [ ] Set up corporate email (Google Workspace / Microsoft 365)
- [ ] Generate temporary password and document securely
- [ ] Add to appropriate organizational unit / groups based on {{ department }}
- [ ] Configure email distribution lists for {{ department }}
- [ ] Create accounts for collaboration tools (Slack, Teams, Zoom)

### Access Permissions
- [ ] Assign role-based access permissions for {{ role }}
- [ ] Set up VPN credentials (if {{ location }} is remote)
- [ ] Configure MFA/2FA enrollment invitation
- [ ] Grant access to department-specific applications
- [ ] Set up SSO for all provisioned SaaS applications
- [ ] Create ITSM portal account for submitting future requests

### Hardware Preparation
- [ ] Allocate laptop/desktop from inventory (check asset management)
- [ ] Install standard OS image and apply latest patches
- [ ] Install required software stack for {{ role }}
- [ ] Configure device encryption (BitLocker / FileVault)
- [ ] Enroll device in MDM (Intune, Jamf, etc.)
- [ ] Prepare peripheral equipment (monitor, keyboard, mouse, headset)
- [ ] For remote: arrange shipping with tracking to {{ location }}

## Phase 2 — Day 1 Setup

### Device Handoff
- [ ] Hand off configured laptop/desktop to {{ employee_name }}
- [ ] Walk through initial login and password change
- [ ] Complete MFA/2FA enrollment
- [ ] Verify email access and calendar sync
- [ ] Test VPN connectivity (if applicable)
- [ ] Verify printing setup (if in-office)

### Application Access Verification
- [ ] Confirm access to all provisioned SaaS apps
- [ ] Verify role-based permissions are correct
- [ ] Test file share / cloud storage access
- [ ] Verify collaboration tool access (Slack/Teams channels)

### Security & Compliance
- [ ] Complete security awareness acknowledgment
- [ ] Review acceptable use policy
- [ ] Set up password manager enrollment
- [ ] Configure email signature per company template

## Phase 3 — First Week

### Training & Orientation
- [ ] Schedule IT orientation session (security policies, helpdesk process)
- [ ] Share IT self-service portal link and knowledge base
- [ ] Provide helpdesk contact information and escalation path
- [ ] Walk through password reset self-service process

### Validation
- [ ] Confirm all applications functioning correctly
- [ ] Verify {{ employee_name }} can access all required resources
- [ ] Check in with {{ manager_name }} for any additional IT needs
- [ ] Close onboarding ticket in ITSM system
- [ ] Update asset management records with assignment

## Output Format

Generate a tracked checklist with:
1. **Summary header** with employee details and completion percentage
2. **Phase-by-phase checklist** with status indicators
3. **Blockers or pending items** requiring attention
4. **ITSM ticket reference** for tracking
