---
name: soc2-compliance-check
enabled: true
description: |
  Use when performing soc2 compliance check — assess SOC2 Type II compliance
  readiness across Trust Service Criteria: security, availability, processing
  integrity, confidentiality, and privacy. Covers access controls, change
  management, monitoring, incident response, and vendor management. Use for
  audit preparation or continuous compliance monitoring.
required_connections:
  - prefix: github
    label: "GitHub (or version control)"
config_fields:
  - key: organization
    label: "Organization Name"
    required: true
    placeholder: "e.g., Acme Corp"
  - key: audit_period
    label: "Audit Period"
    required: true
    placeholder: "e.g., 2025-01-01 to 2025-12-31"
  - key: trust_criteria
    label: "Trust Service Criteria in Scope"
    required: false
    placeholder: "e.g., security, availability, confidentiality"
features:
  - COMPLIANCE
  - SECURITY
---

# SOC2 Compliance Check Skill

Assess SOC2 Type II readiness for **{{ organization }}** covering audit period **{{ audit_period }}**.

## Workflow

### Step 1 — Scope Definition

Establish what is in scope:
1. **Trust Service Criteria**: {{ trust_criteria | "Security (required), Availability, Confidentiality" }}
2. **Systems in scope**: [list services, infrastructure, third-party tools]
3. **Prior audit findings**: [review any open items from previous audit]

### Step 2 — CC6: Logical & Physical Access Controls

```
ACCESS CONTROLS (CC6)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] User access provisioning requires manager approval
[ ] User access reviews conducted quarterly
[ ] Terminated users deprovisioned within 24 hours
[ ] MFA enforced for all production access
[ ] Privileged access limited and logged
[ ] SSH keys / API tokens rotated on schedule
[ ] Physical data center access controlled (if applicable)
[ ] Vendor access reviewed and time-limited
[ ] Role-based access control (RBAC) implemented
```

### Step 3 — CC7: System Operations & Monitoring

```
SYSTEM OPERATIONS (CC7)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Infrastructure monitoring with alerting (uptime, errors, latency)
[ ] Security event monitoring and SIEM in place
[ ] Vulnerability scanning on regular cadence
[ ] Patch management process with defined SLAs
[ ] Capacity monitoring with proactive scaling
[ ] Backup procedures documented and tested
[ ] Backup restoration tested at least annually
[ ] Incident detection within defined time thresholds
```

### Step 4 — CC8: Change Management

```
CHANGE MANAGEMENT (CC8)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] All code changes require peer review (PR approval)
[ ] CI/CD pipeline enforces automated tests before deploy
[ ] Production deployments logged with who/what/when
[ ] Infrastructure changes via IaC (Terraform, CloudFormation)
[ ] Change approval process for production changes
[ ] Separation of duties: developers cannot deploy to production alone
[ ] Rollback procedures documented for all deployments
[ ] Emergency change process defined and documented
```

### Step 5 — Incident Response & Communication

```
INCIDENT RESPONSE (CC7.3-CC7.5)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Incident response plan documented and current
[ ] On-call rotation staffed 24/7
[ ] Incident severity classification defined
[ ] Communication procedures for security incidents
[ ] Post-incident reviews conducted for SEV1/SEV2
[ ] Annual incident response drill or tabletop exercise
[ ] Customer notification process for data breaches
```

### Step 6 — Risk Assessment & Vendor Management

```
RISK & VENDOR MANAGEMENT (CC3, CC9)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Annual risk assessment conducted
[ ] Risk register maintained with owners and mitigations
[ ] Vendor inventory maintained with criticality ratings
[ ] Critical vendors have SOC2 reports or equivalent
[ ] Vendor access reviewed annually
[ ] Business continuity plan documented
[ ] Data processing agreements in place with vendors
```

### Step 7 — Evidence Collection Checklist

For each control, gather evidence:
- **Access reviews**: Export of quarterly review with approvals
- **Change management**: Sample PRs showing review process
- **Monitoring**: Screenshots of dashboards and alert configurations
- **Incident response**: Post-mortem documents from audit period
- **Vendor management**: Vendor SOC2 reports or security questionnaires
- **Training**: Security awareness training completion records

### Step 8 — Gap Analysis & Remediation

| Control Area | Status | Gaps Found | Remediation | Priority | Owner |
|-------------|--------|------------|-------------|----------|-------|
| Access Controls | READY/GAP | [details] | [action] | P1/P2 | [name] |
| System Operations | READY/GAP | [details] | [action] | P1/P2 | [name] |
| Change Management | READY/GAP | [details] | [action] | P1/P2 | [name] |
| Incident Response | READY/GAP | [details] | [action] | P1/P2 | [name] |
| Risk Management | READY/GAP | [details] | [action] | P1/P2 | [name] |

## Counter-Rationalizations

| Shortcut | Counter | Why |
|----------|---------|-----|
| "We can skip some steps for this case" | Adapt the workflow steps, don't skip them | Skipped steps are where incidents and oversights originate |
| "The user seems to already know what to do" | Complete all workflow phases with the user | The workflow catches blind spots that experience alone misses |
| "This is a minor case, full process is overkill" | Scale the process down, don't turn it off | Minor cases become major when unstructured; the process scales, not disappears |
| "I'll fill in the details later" | Complete each section before moving on | Deferred details are forgotten; real-time capture is more accurate |
| "The template output isn't necessary" | Always produce the structured output format | Structured output enables comparison, audit trails, and handoff to other teams |

## Output Format

Produce a SOC2 readiness report with:
1. **Scope summary** (criteria, systems, audit period)
2. **Control assessment** per Trust Service Category with READY/GAP status
3. **Evidence checklist** with collection status per control
4. **Gap analysis** with prioritized remediation actions
5. **Readiness score** (% of controls audit-ready)
