---
name: compliance-code-review
enabled: true
description: |
  Use when performing compliance code review — regulatory compliance code review
  template covering SOC 2, HIPAA, PCI DSS, and GDPR requirements. Evaluates code
  changes for data handling compliance, audit logging, access controls,
  encryption standards, and data retention policies to ensure regulatory
  requirements are met in code.
required_connections:
  - prefix: github
    label: "GitHub"
config_fields:
  - key: repository
    label: "Repository"
    required: true
    placeholder: "e.g., org/payments-service"
  - key: pr_number
    label: "PR Number"
    required: true
    placeholder: "e.g., 1234"
  - key: compliance_frameworks
    label: "Compliance Frameworks"
    required: true
    placeholder: "e.g., SOC2, HIPAA, PCI-DSS, GDPR"
features:
  - CODE_REVIEW
---

# Compliance Code Review Skill

Review PR **#{{ pr_number }}** in **{{ repository }}** for **{{ compliance_frameworks }}** compliance.

## Workflow

### Phase 1 — Data Handling

```
DATA HANDLING REVIEW
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Data classification:
    [ ] Data types identified (PII, PHI, PCI, public)
    [ ] Handling appropriate for classification level
    [ ] Data flow documented
[ ] Data storage:
    [ ] Encryption at rest for sensitive data
    [ ] Encryption keys managed via KMS (not hardcoded)
    [ ] Data retention policies enforced
    [ ] Data deletion/anonymization capabilities
[ ] Data transmission:
    [ ] TLS 1.2+ enforced for all transmissions
    [ ] No sensitive data in URLs or query parameters
    [ ] API responses filtered to authorized data only
[ ] Data minimization:
    [ ] Only necessary data collected
    [ ] Data not retained beyond required period
    [ ] Unnecessary PII fields removed
```

### Phase 2 — Audit Logging

```
AUDIT TRAIL
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Audit events:
    [ ] Authentication events logged (login, logout, failures)
    [ ] Authorization failures logged
    [ ] Data access logged (read of sensitive records)
    [ ] Data modification logged (create, update, delete)
    [ ] Configuration changes logged
[ ] Log integrity:
    [ ] Logs written to tamper-evident store
    [ ] Log retention meets compliance requirement: ___ days
    [ ] Logs include: timestamp, actor, action, resource, outcome
    [ ] No sensitive data in log entries (passwords, tokens)
```

### Phase 3 — Access Controls

```
ACCESS CONTROL REVIEW
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Authentication:
    [ ] MFA enforced for privileged operations
    [ ] Session management secure (timeout, invalidation)
    [ ] Password policy meets requirements
[ ] Authorization:
    [ ] Role-based access control implemented
    [ ] Least-privilege principle applied
    [ ] Separation of duties enforced
    [ ] Administrative access restricted and audited
[ ] Access review:
    [ ] Service accounts documented
    [ ] API key rotation supported
    [ ] Access provisioning/deprovisioning automated
```

### Phase 4 — Framework-Specific Requirements

```
SOC 2 SPECIFIC
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Change management process followed
[ ] Code review by authorized personnel
[ ] Monitoring and alerting for security events
[ ] Incident response procedures referenced

HIPAA SPECIFIC
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] PHI access logged with BAA compliance
[ ] Minimum necessary standard applied
[ ] Emergency access procedures defined
[ ] Patient data de-identification where possible

PCI DSS SPECIFIC
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Cardholder data not stored unless necessary
[ ] PAN masked in display (first 6, last 4)
[ ] Cryptographic key management documented
[ ] No storage of CVV, track data, or PIN

GDPR SPECIFIC
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Consent management implemented
[ ] Right to erasure supported (data deletion)
[ ] Data portability supported (export)
[ ] Privacy by design principles applied
[ ] Data processing agreement compliance
```

## Counter-Rationalizations

| Shortcut | Counter | Why |
|----------|---------|-----|
| "We can skip some steps for this case" | Adapt the workflow steps, don't skip them | Skipped steps are where incidents and oversights originate |
| "The user seems to already know what to do" | Complete all workflow phases with the user | The workflow catches blind spots that experience alone misses |
| "This is a minor case, full process is overkill" | Scale the process down, don't turn it off | Minor cases become major when unstructured; the process scales, not disappears |
| "I'll fill in the details later" | Complete each section before moving on | Deferred details are forgotten; real-time capture is more accurate |
| "The template output isn't necessary" | Always produce the structured output format | Structured output enables comparison, audit trails, and handoff to other teams |

## Output Format

Produce a compliance review report with:
1. **Compliance status per framework** (compliant / gaps found / non-compliant)
2. **Findings by control area** (data handling, audit, access)
3. **Risk rating** per finding (critical / high / medium / low)
4. **Remediation requirements** with regulatory references
5. **Evidence of compliance** for audit documentation
