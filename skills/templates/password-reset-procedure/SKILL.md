---
name: password-reset-procedure
enabled: true
description: |
  Use when performing password reset procedure — self-service and assisted
  password reset workflow covering identity verification, reset execution across
  multiple systems, MFA recovery, and account lockout resolution. Provides
  step-by-step procedures for end users to reset passwords independently or with
  helpdesk assistance while maintaining security and audit compliance.
required_connections:
  - prefix: itsm
    label: "ITSM Tool (ServiceNow, Freshservice, etc.)"
config_fields:
  - key: user_name
    label: "Affected User Name"
    required: true
    placeholder: "e.g., Jane Smith"
  - key: system_name
    label: "System / Application"
    required: true
    placeholder: "e.g., Active Directory, Google Workspace, Salesforce"
  - key: issue_type
    label: "Issue Type"
    required: true
    placeholder: "e.g., forgotten password, account locked, MFA lost"
features:
  - HELPDESK
---

# Password Reset Procedure

Password reset for **{{ user_name }}** on **{{ system_name }}**
Issue: **{{ issue_type }}**

## Decision Tree

```
START: What is the issue?
│
├─ Forgotten Password
│  ├─ Self-service portal available? → Guide to self-service reset
│  └─ No self-service? → Proceed to Assisted Reset
│
├─ Account Locked Out
│  ├─ Too many failed attempts? → Unlock account, then optional reset
│  └─ Locked by admin/policy? → Escalate to security team
│
├─ MFA Device Lost/Changed
│  ├─ Backup codes available? → Use backup code
│  └─ No backup codes? → MFA Recovery Process
│
└─ Expired Password
   └─ Guide through forced password change flow
```

## Self-Service Reset Path

### Prerequisites
- User has access to registered recovery email or phone
- Self-service portal is operational

### Steps
1. Direct {{ user_name }} to the self-service password reset portal
2. User selects "Forgot Password" or "Reset Password"
3. User verifies identity via registered recovery method (email/SMS code)
4. User creates new password meeting complexity requirements
5. User confirms new password works for login
6. User re-enrolls MFA if prompted

## Assisted Reset Path (Helpdesk Agent)

### Identity Verification (REQUIRED before any reset)
- [ ] Verify {{ user_name }}'s identity using **at least two** of the following:
  - Employee ID number
  - Date of birth
  - Manager's name
  - Last four digits of phone number on file
  - Security questions (if configured)
  - Video call identity verification (for high-security systems)

### Password Reset Execution
- [ ] Access admin console for {{ system_name }}
- [ ] Locate {{ user_name }}'s account
- [ ] Generate temporary password (minimum 16 characters, random)
- [ ] Set "must change password at next login" flag
- [ ] Deliver temporary password via secure channel (NOT email):
  - Preferred: in-person, phone call, or secure messaging
  - Never: email, Slack DM, or unencrypted channel
- [ ] Verify {{ user_name }} successfully logs in with temporary password
- [ ] Confirm {{ user_name }} has set a new permanent password

### Account Lockout Resolution
- [ ] Check lockout reason in AD/IdP audit logs
- [ ] If excessive failed attempts: unlock account and advise user
- [ ] If suspicious activity detected: escalate to security team before unlocking
- [ ] Clear lockout counter
- [ ] Monitor for repeated lockouts (may indicate compromised credentials)

### MFA Recovery
- [ ] Verify identity with enhanced verification (manager confirmation required)
- [ ] Remove existing MFA enrollment from {{ user_name }}'s account
- [ ] Generate new MFA enrollment invitation
- [ ] Guide {{ user_name }} through MFA re-enrollment
- [ ] Verify MFA is working with test login
- [ ] Remind user to save backup codes securely

## Password Policy Reference

```
MINIMUM REQUIREMENTS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Length:          12+ characters (16+ recommended)
Complexity:     Upper + lower + number + special character
History:        Cannot reuse last 12 passwords
Max Age:        90 days (or per organizational policy)
Lockout:        5 failed attempts = 15-minute lockout
```

## Post-Reset Actions

- [ ] Document reset in ITSM ticket with verification method used
- [ ] Advise {{ user_name }} to update saved passwords in password manager
- [ ] If password was potentially compromised: force reset on all linked systems
- [ ] Close ticket

## Counter-Rationalizations

| Shortcut | Counter | Why |
|----------|---------|-----|
| "We can skip some steps for this case" | Adapt the workflow steps, don't skip them | Skipped steps are where incidents and oversights originate |
| "The user seems to already know what to do" | Complete all workflow phases with the user | The workflow catches blind spots that experience alone misses |
| "This is a minor case, full process is overkill" | Scale the process down, don't turn it off | Minor cases become major when unstructured; the process scales, not disappears |
| "I'll fill in the details later" | Complete each section before moving on | Deferred details are forgotten; real-time capture is more accurate |
| "The template output isn't necessary" | Always produce the structured output format | Structured output enables comparison, audit trails, and handoff to other teams |

## Output Format

Generate a reset summary with:
1. **User and system details**
2. **Verification method** used
3. **Reset actions** taken with timestamps
4. **Follow-up items** if any
