---
name: pci-dss-assessment
enabled: true
description: |
  Use when performing pci dss assessment — pCI DSS v4.0 compliance assessment
  covering cardholder data protection, network segmentation, vulnerability
  management, access control, and monitoring. Use for self-assessment
  questionnaires (SAQ), audit preparation, or continuous compliance validation.
required_connections:
  - prefix: aws
    label: "AWS (or cloud provider)"
config_fields:
  - key: merchant_name
    label: "Merchant / Service Provider Name"
    required: true
    placeholder: "e.g., Acme Payments"
  - key: saq_type
    label: "SAQ Type"
    required: true
    placeholder: "e.g., SAQ-A, SAQ-D, ROC"
  - key: cde_scope
    label: "Cardholder Data Environment Scope"
    required: true
    placeholder: "e.g., payment-api, tokenization-service"
features:
  - COMPLIANCE
  - SECURITY
  - PAYMENTS
---

# PCI DSS Assessment Skill

Perform a PCI DSS v4.0 assessment for **{{ merchant_name }}** ({{ saq_type }}) covering CDE: **{{ cde_scope }}**.

## Workflow

### Step 1 — Scope & CDE Identification

Define the Cardholder Data Environment (CDE):
1. **Systems that store, process, or transmit cardholder data**: [list]
2. **Connected-to systems**: Systems with network connectivity to CDE
3. **Security-impacting systems**: Firewalls, IDS, auth servers affecting CDE
4. **Data flow diagram**: Map cardholder data from entry to storage/disposal

### Step 2 — Requirement 1-2: Network Security

```
NETWORK SECURITY (Req 1-2)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Network segmentation isolates CDE from other networks
[ ] Firewall rules restrict inbound/outbound CDE traffic to required only
[ ] Default deny rule on all firewalls
[ ] Firewall rule review completed in last 6 months
[ ] DMZ implemented for public-facing CDE components
[ ] Wireless networks separated from CDE
[ ] Network diagram current and accurate
[ ] No direct public access to CDE systems
```

### Step 3 — Requirement 3-4: Protect Cardholder Data

```
DATA PROTECTION (Req 3-4)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] PAN stored only where business-justified
[ ] PAN rendered unreadable (tokenization, truncation, hashing, encryption)
[ ] Full track data never stored after authorization
[ ] CVV never stored after authorization
[ ] PIN data never stored after authorization
[ ] Encryption keys managed with split knowledge and dual control
[ ] Key rotation performed annually
[ ] Data retention policy enforced — PAN purged when no longer needed
[ ] Strong cryptography for PAN transmission over public networks (TLS 1.2+)
[ ] PAN never sent via unencrypted email or messaging
```

### Step 4 — Requirement 5-6: Vulnerability Management

```
VULNERABILITY MANAGEMENT (Req 5-6)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Anti-malware deployed on all CDE systems
[ ] Anti-malware signatures updated automatically
[ ] Quarterly internal vulnerability scans passing
[ ] Quarterly ASV external scans passing
[ ] Annual penetration test conducted
[ ] Critical patches applied within 30 days
[ ] Secure development lifecycle (SDLC) followed
[ ] Code reviews or SAST for custom application code
[ ] Public-facing web apps protected by WAF or annual app assessment
```

### Step 5 — Requirement 7-9: Access Control

```
ACCESS CONTROL (Req 7-9)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] CDE access restricted to need-to-know basis
[ ] Unique ID for every person with CDE access
[ ] MFA for all remote and administrative CDE access
[ ] Default/vendor passwords changed before production
[ ] User access reviewed at least every 6 months
[ ] Inactive accounts disabled within 90 days
[ ] Session lock after 15 minutes of inactivity
[ ] Physical access to CDE restricted and monitored
```

### Step 6 — Requirement 10-12: Monitoring & Policy

```
MONITORING & POLICY (Req 10-12)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Audit trails capture all access to CDE and cardholder data
[ ] Audit logs reviewed daily (automated or manual)
[ ] Audit log retention ≥12 months (3 months immediately available)
[ ] Time synchronization (NTP) on all CDE systems
[ ] IDS/IPS monitors CDE network traffic
[ ] File integrity monitoring on critical system files
[ ] Information security policy published and reviewed annually
[ ] Security awareness training for all personnel annually
[ ] Incident response plan tested annually
[ ] Service provider compliance confirmed annually
```

### Step 7 — Assessment Summary

| PCI DSS Requirement | Status | Findings |
|---------------------|--------|----------|
| 1-2: Network Security | IN PLACE / NOT IN PLACE | [details] |
| 3-4: Data Protection | IN PLACE / NOT IN PLACE | [details] |
| 5-6: Vuln Management | IN PLACE / NOT IN PLACE | [details] |
| 7-9: Access Control | IN PLACE / NOT IN PLACE | [details] |
| 10-12: Monitoring | IN PLACE / NOT IN PLACE | [details] |

## Counter-Rationalizations

| Shortcut | Counter | Why |
|----------|---------|-----|
| "We can skip some steps for this case" | Adapt the workflow steps, don't skip them | Skipped steps are where incidents and oversights originate |
| "The user seems to already know what to do" | Complete all workflow phases with the user | The workflow catches blind spots that experience alone misses |
| "This is a minor case, full process is overkill" | Scale the process down, don't turn it off | Minor cases become major when unstructured; the process scales, not disappears |
| "I'll fill in the details later" | Complete each section before moving on | Deferred details are forgotten; real-time capture is more accurate |
| "The template output isn't necessary" | Always produce the structured output format | Structured output enables comparison, audit trails, and handoff to other teams |

## Output Format

Produce a PCI DSS assessment report with:
1. **Scope definition** with CDE diagram and data flow
2. **Requirement checklists** with IN PLACE / NOT IN PLACE per control
3. **Compensating controls** documented where applicable
4. **Remediation plan** for NOT IN PLACE findings with deadlines
5. **SAQ completion status** with overall compliance determination
