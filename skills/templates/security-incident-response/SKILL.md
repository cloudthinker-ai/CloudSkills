---
name: security-incident-response
enabled: true
description: |
  Use when performing security incident response — security-specific incident
  response playbook covering breach detection, compromised credentials response,
  data leak containment, evidence preservation, regulatory notification
  requirements, forensic investigation coordination, and communication
  protocols. Provides structured workflows for security incidents distinct from
  operational incidents.
required_connections:
  - prefix: slack
    label: "Slack (for secure incident coordination)"
config_fields:
  - key: incident_type
    label: "Security Incident Type"
    required: true
    placeholder: "e.g., data breach, compromised credentials, unauthorized access"
  - key: incident_description
    label: "Incident Description"
    required: true
    placeholder: "e.g., Suspicious API calls from unknown IP using valid credentials"
  - key: affected_systems
    label: "Affected Systems"
    required: false
    placeholder: "e.g., user database, API gateway, admin portal"
features:
  - INCIDENT
---

# Security Incident Response Playbook

Type: **{{ incident_type }}**
Description: **{{ incident_description }}**
Affected Systems: **{{ affected_systems }}**

## CRITICAL: Security Incident Differs from Operational Incident

- **Preserve evidence** — do not destroy logs, do not reimage systems without forensic capture
- **Limit communication** — use secure channels, need-to-know basis only
- **Legal involvement** — notify legal counsel early for breach/data exposure events
- **Regulatory obligations** — data breaches may have mandatory notification timelines

## Phase 1 — Detection and Triage (0-15 min)

### Immediate Actions
- [ ] Confirm the security event is real (not a false positive)
- [ ] Classify the incident type:
  - [ ] Unauthorized access
  - [ ] Compromised credentials
  - [ ] Data exfiltration/exposure
  - [ ] Malware/ransomware
  - [ ] Insider threat
  - [ ] DDoS attack
  - [ ] Supply chain compromise
- [ ] Assign severity based on data sensitivity and blast radius
- [ ] Open a PRIVATE incident channel (not public)
- [ ] Notify Security team lead and CISO

### Triage Questions
1. What data or systems are potentially compromised?
2. Is the attack still active or historical?
3. What is the blast radius (users, data, systems)?
4. Is there evidence of data exfiltration?
5. Are any regulatory requirements triggered (PII, PHI, PCI)?

## Phase 2 — Containment (15-60 min)

### Short-Term Containment (stop the bleeding)
- [ ] Revoke compromised credentials/API keys/tokens
- [ ] Block malicious IP addresses or user accounts
- [ ] Isolate affected systems (network segmentation, not shutdown)
- [ ] Disable compromised integrations or webhooks
- [ ] Enable enhanced logging on affected systems

### Evidence Preservation
- [ ] Capture system memory dumps before any changes
- [ ] Snapshot affected disk volumes
- [ ] Export relevant logs to secure, immutable storage
- [ ] Record network flow data
- [ ] Screenshot active sessions or dashboards
- [ ] Document chain of custody for all evidence

**WARNING:** Do NOT reimage, wipe, or restart systems before evidence is captured.

### Compromised Credentials Response
If credentials are compromised:
- [ ] Rotate ALL credentials for affected accounts immediately
- [ ] Rotate API keys, tokens, and secrets that may have been exposed
- [ ] Force password reset for affected user accounts
- [ ] Revoke all active sessions for compromised accounts
- [ ] Review access logs for unauthorized actions during exposure window
- [ ] Check if compromised credentials were used to access other systems

## Phase 3 — Investigation

### Forensic Investigation
- [ ] Establish timeline of attacker activity
- [ ] Identify initial access vector (how did they get in?)
- [ ] Map lateral movement (what else did they access?)
- [ ] Determine data accessed or exfiltrated
- [ ] Identify persistence mechanisms (backdoors, new accounts)
- [ ] Check for indicators of compromise (IoCs) across other systems

### Key Log Sources to Review
| Source | What to Look For |
|--------|-----------------|
| Authentication logs | Failed/successful logins, unusual locations, impossible travel |
| API access logs | Unusual patterns, bulk data access, new API consumers |
| Cloud audit logs | IAM changes, new resources, policy modifications |
| Network logs | Data exfiltration patterns, C2 communication, unusual destinations |
| Application logs | SQL injection attempts, privilege escalation, unauthorized actions |
| VPN/SSH logs | Unauthorized remote access, unusual connection times |

## Phase 4 — Eradication and Recovery

### Eradication
- [ ] Remove attacker access (all identified access vectors)
- [ ] Remove any persistence mechanisms (backdoors, cron jobs, new accounts)
- [ ] Patch the vulnerability that allowed initial access
- [ ] Verify no remaining unauthorized access
- [ ] Scan for IoCs across the environment

### Recovery
- [ ] Restore affected systems from known-good backups (if needed)
- [ ] Validate data integrity
- [ ] Re-enable services in a controlled manner
- [ ] Implement additional monitoring for the affected area
- [ ] Verify clean operation for 24-48 hours

## Phase 5 — Notification and Reporting

### Internal Notification
| Stakeholder | When to Notify | Method |
|------------|---------------|--------|
| CISO | Immediately | Phone + secure channel |
| Legal counsel | Within 1 hour for data breaches | Phone |
| Executive team | Within 4 hours for SEV1 security | Secure briefing |
| Engineering teams | As needed for containment | Private Slack |

### Regulatory Notification (if applicable)
| Regulation | Data Type | Notification Deadline | Authority |
|-----------|-----------|----------------------|-----------|
| GDPR | EU personal data | 72 hours | Supervisory authority |
| HIPAA | Protected health info | 60 days | HHS |
| PCI DSS | Cardholder data | Immediately | Card brands + acquirer |
| State breach laws | PII (varies by state) | Varies (24h-60 days) | State AG |

### Customer Notification
- [ ] Determine which customers are affected
- [ ] Draft notification with legal review
- [ ] Include: what happened, what data was affected, what we are doing, what they should do
- [ ] Provide identity monitoring if PII was exposed

## Post-Incident

- [ ] Conduct security post-incident review (separate from ops postmortem)
- [ ] Update threat model based on findings
- [ ] Implement additional security controls
- [ ] Update incident response playbook with lessons learned
- [ ] Schedule penetration test to validate fixes
- [ ] Review and update security monitoring rules

## Counter-Rationalizations

| Shortcut | Counter | Why |
|----------|---------|-----|
| "We can skip some steps for this case" | Adapt the workflow steps, don't skip them | Skipped steps are where incidents and oversights originate |
| "The user seems to already know what to do" | Complete all workflow phases with the user | The workflow catches blind spots that experience alone misses |
| "This is a minor case, full process is overkill" | Scale the process down, don't turn it off | Minor cases become major when unstructured; the process scales, not disappears |
| "I'll fill in the details later" | Complete each section before moving on | Deferred details are forgotten; real-time capture is more accurate |
| "The template output isn't necessary" | Always produce the structured output format | Structured output enables comparison, audit trails, and handoff to other teams |

