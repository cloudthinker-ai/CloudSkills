---
name: certificate-renewal-automation
enabled: true
description: |
  Use when performing certificate renewal automation — runbook for TLS/SSL
  certificate renewal across infrastructure. Covers certificate inventory,
  expiration tracking, CSR generation, certificate issuance, deployment to load
  balancers and CDNs, chain validation, and post-renewal verification to prevent
  outages from expired certificates.
required_connections:
  - prefix: aws
    label: "AWS (or cloud provider)"
config_fields:
  - key: domain
    label: "Domain Name"
    required: true
    placeholder: "e.g., api.example.com"
  - key: certificate_type
    label: "Certificate Type"
    required: true
    placeholder: "e.g., ACM, Let's Encrypt, DigiCert"
  - key: expiration_date
    label: "Current Expiration Date"
    required: true
    placeholder: "e.g., 2026-05-15"
features:
  - DEVOPS
  - SECURITY
---

# Certificate Renewal Automation Skill

Renew TLS certificate for **{{ domain }}** ({{ certificate_type }}, expires **{{ expiration_date }}**).

## Workflow

### Phase 1 — Certificate Inventory

```
CERTIFICATE MAP
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Domain: {{ domain }}
[ ] Certificate type: {{ certificate_type }}
[ ] Current expiration: {{ expiration_date }}
[ ] Days until expiration: ___
[ ] SANs (Subject Alternative Names):
    - ___
    - ___
[ ] Deployed locations:
    [ ] Load balancer(s): ___
    [ ] CDN distribution(s): ___
    [ ] Application server(s): ___
    [ ] API gateway(s): ___
[ ] Certificate chain: Root CA -> Intermediate -> Leaf
```

### Phase 2 — Renewal Execution

```
CERTIFICATE RENEWAL
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
For ACM (AWS Certificate Manager):
[ ] Request renewal via ACM console or CLI
[ ] DNS validation records confirmed
[ ] Certificate status: ISSUED

For Let's Encrypt:
[ ] Certbot renewal executed
[ ] ACME challenge completed
[ ] New certificate files generated

For Manual CA:
[ ] CSR generated with correct SANs
[ ] CSR submitted to CA
[ ] Certificate received and validated
[ ] Private key securely stored

[ ] New certificate details:
    - Serial: ___
    - Valid from: ___
    - Valid until: ___
    - Key algorithm: ___
    - Key size: ___
```

### Phase 3 — Certificate Deployment

```
DEPLOYMENT CHECKLIST
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Certificate chain validated (no missing intermediates)
[ ] Deploy to each endpoint:
    [ ] Load balancer — applied and listener updated
    [ ] CDN — distribution updated, propagation complete
    [ ] Application servers — certificate files replaced, service reloaded
    [ ] API gateway — certificate attached to custom domain
[ ] OCSP stapling configured (if applicable)
[ ] HSTS headers verified
```

### Phase 4 — Post-Renewal Validation

```
VALIDATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] TLS connection test successful (openssl s_client)
[ ] Certificate chain complete and trusted
[ ] No mixed content warnings
[ ] SSL Labs rating: ___ (target: A+)
[ ] All SANs resolving correctly
[ ] HTTP to HTTPS redirect working
[ ] No certificate errors in browser
[ ] Monitoring updated with new expiration date
[ ] Alert threshold set: ___ days before expiration
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

Produce a certificate renewal report with:
1. **Certificate summary** (domain, type, old and new expiration dates)
2. **Deployment log** (each endpoint updated with timestamps)
3. **Validation results** (TLS test, chain verification, SSL Labs score)
4. **Monitoring status** (alerting configured for next renewal)
5. **Next renewal date** and recommended automation improvements
