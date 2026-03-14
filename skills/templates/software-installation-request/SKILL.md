---
name: software-installation-request
enabled: true
description: |
  Software request, approval, licensing check, and deployment workflow covering the full lifecycle from user request through procurement, license validation, security review, installation, and verification. Ensures software installations comply with licensing agreements and security policies.
required_connections:
  - prefix: itsm
    label: "ITSM Tool (ServiceNow, Freshservice, etc.)"
config_fields:
  - key: requester_name
    label: "Requester Name"
    required: true
    placeholder: "e.g., Jane Smith"
  - key: software_name
    label: "Software Name & Version"
    required: true
    placeholder: "e.g., Adobe Creative Cloud, Visual Studio 2025"
  - key: business_justification
    label: "Business Justification"
    required: true
    placeholder: "e.g., Required for design deliverables in Q2 campaign"
  - key: device_name
    label: "Target Device"
    required: false
    placeholder: "e.g., LAPTOP-JS-1234"
features:
  - HELPDESK
---

# Software Installation Request Workflow

Software request: **{{ software_name }}** for **{{ requester_name }}**
Device: {{ device_name }}
Justification: {{ business_justification }}

## Step 1 — Request Validation

- [ ] Verify {{ requester_name }} is an active employee
- [ ] Check if {{ software_name }} is on the approved software list
- [ ] If not approved: escalate for security review before proceeding
- [ ] Verify {{ device_name }} meets minimum system requirements

### Approved Software Check
```
STATUS CHECK
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Software: {{ software_name }}
Status: [ ] Approved / [ ] Requires Review / [ ] Blocked

If APPROVED: proceed to license check
If REQUIRES REVIEW: submit to security team for evaluation
If BLOCKED: deny request with explanation and suggest alternative
```

## Step 2 — Approval

- [ ] Manager approval for {{ requester_name }}
- [ ] Budget approval if purchase required (check cost center)
- [ ] Security team approval (if not on pre-approved list)
- [ ] All approvals documented in ITSM ticket

## Step 3 — License Check

- [ ] Check existing license inventory for {{ software_name }}
- [ ] Available license seat?
  - **Yes**: Assign license to {{ requester_name }}
  - **No**: Initiate procurement
- [ ] License type verification:
  - Per-user, per-device, or concurrent?
  - Is current license type appropriate?
- [ ] Check license expiration date
- [ ] Verify license compliance (not over-allocated)

### Procurement (if needed)
- [ ] Submit purchase request with cost and justification
- [ ] Obtain purchase approval from budget owner
- [ ] Process procurement through vendor or reseller
- [ ] Receive license keys / subscription activation
- [ ] Record new licenses in asset management system

## Step 4 — Deployment

### Pre-Installation
- [ ] Verify {{ device_name }} has sufficient disk space
- [ ] Check for conflicting software that needs removal
- [ ] Back up user data if significant system changes needed
- [ ] Verify OS version compatibility

### Installation
- [ ] Deploy via software distribution tool (SCCM, Intune, Jamf) if available
- [ ] Or install manually:
  - Download installer from approved source (vendor portal or internal repo)
  - Run installation with admin privileges
  - Apply license key or sign in with licensed account
  - Configure application settings per company standards
- [ ] Install any required plugins or add-ons

### Post-Installation
- [ ] Verify {{ software_name }} launches correctly
- [ ] Verify license is activated and shows correct license type
- [ ] Run basic functionality test
- [ ] Notify {{ requester_name }} of installation completion

## Step 5 — Documentation

- [ ] Update asset management with software assignment
- [ ] Record license allocation (user, device, license key/seat)
- [ ] Update ITSM ticket with installation details
- [ ] Provide {{ requester_name }} with getting-started documentation if available
- [ ] Close ticket

## Output Format

Generate an installation report with:
1. **Request summary** (software, requester, justification)
2. **License status** (existing/procured, type, expiration)
3. **Installation details** (method, device, configuration)
4. **Completion confirmation**
