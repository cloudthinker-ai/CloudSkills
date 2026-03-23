---
name: ssl-certificate-rotation
enabled: true
description: |
  Use when performing ssl certificate rotation — sSL/TLS certificate rotation
  workflow covering certificate discovery, renewal planning, deployment
  procedures, and validation. Supports ACM, Let's Encrypt, and manual CA
  certificates. Use for scheduled rotations, expiring certificate remediation,
  or certificate automation setup.
required_connections:
  - prefix: aws
    label: "AWS (or cloud provider)"
config_fields:
  - key: domain
    label: "Domain Name"
    required: true
    placeholder: "e.g., *.example.com"
  - key: cert_provider
    label: "Certificate Provider"
    required: true
    placeholder: "e.g., ACM, Let's Encrypt, DigiCert"
  - key: environment
    label: "Environment"
    required: true
    placeholder: "e.g., production"
features:
  - SECURITY
  - DEPLOYMENT
---

# SSL/TLS Certificate Rotation Skill

Rotate SSL/TLS certificates for **{{ domain }}** in **{{ environment }}** using **{{ cert_provider }}**.

## Workflow

### Step 1 — Certificate Discovery

Inventory all certificates for {{ domain }}:

```
CERTIFICATE INVENTORY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
| Domain | Provider | Expiry | Location | Auto-Renew |
|--------|----------|--------|----------|------------|
| {{ domain }} | {{ cert_provider }} | [date] | [ALB/NLB/CDN/server] | YES/NO |

[ ] All certificates for {{ domain }} identified
[ ] Wildcard vs specific-domain certs documented
[ ] Certificate chain (intermediate CAs) documented
[ ] SANs (Subject Alternative Names) listed
[ ] Expiration dates within 30 days flagged
```

### Step 2 — Pre-Rotation Checks

```
PRE-ROTATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Current certificate details captured (serial, fingerprint, expiry)
[ ] DNS validation records accessible (if DNS validation used)
[ ] Domain ownership verified
[ ] Certificate private key stored securely
[ ] Deployment locations identified:
    [ ] Load balancers (ALB/NLB/ELB)
    [ ] CDN distributions (CloudFront/Cloudflare)
    [ ] API gateways
    [ ] Application servers (Nginx/Apache/Caddy)
    [ ] Kubernetes secrets (TLS secrets)
    [ ] Other services: [list]
[ ] Change window scheduled (if manual rotation)
[ ] Rollback certificate available (current cert not yet expired)
```

### Step 3 — Certificate Generation / Renewal

```
RENEWAL — {{ cert_provider }}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
ACM (AWS Certificate Manager):
[ ] Request new certificate or trigger renewal
[ ] Complete domain validation (DNS or email)
[ ] Verify certificate status: ISSUED
[ ] Note new certificate ARN

Let's Encrypt:
[ ] Run certbot renew (or ACME client)
[ ] Verify challenge completed successfully
[ ] New certificate and key files generated
[ ] Certificate chain includes intermediate CA

Manual CA (DigiCert, Sectigo, etc.):
[ ] Generate new CSR with correct SANs
[ ] Submit CSR to CA
[ ] Complete domain validation
[ ] Download issued certificate and chain
[ ] Verify certificate matches private key

VALIDATION:
[ ] Certificate subject matches {{ domain }}
[ ] SANs include all required domains
[ ] Key size ≥ 2048 (RSA) or 256 (ECDSA)
[ ] Validity period confirmed
[ ] Certificate chain is complete
```

### Step 4 — Certificate Deployment

```
DEPLOYMENT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
For each deployment location:

Load Balancers:
[ ] Update listener certificate (ALB/NLB)
[ ] Verify HTTPS listener using new certificate
[ ] Old certificate removed from listener (after validation)

CDN:
[ ] Update distribution SSL certificate
[ ] Wait for distribution deployment (may take 15-30 min)
[ ] Verify edge locations serving new certificate

Kubernetes:
[ ] Update TLS secret: kubectl create secret tls --cert --key
[ ] Restart pods or trigger ingress controller reload
[ ] Verify ingress serving new certificate

Application Servers:
[ ] Copy certificate files to server
[ ] Update Nginx/Apache config if paths changed
[ ] Reload web server (nginx -s reload / apachectl graceful)
[ ] Verify server serving new certificate
```

### Step 5 — Post-Rotation Validation

```
VALIDATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] openssl s_client confirms new certificate serial/fingerprint
[ ] Certificate chain is complete (no missing intermediates)
[ ] TLS version negotiation working (TLS 1.2+ only)
[ ] OCSP stapling working (if configured)
[ ] HSTS headers present
[ ] SSL Labs scan: A or A+ rating
[ ] No mixed content warnings on web pages
[ ] All endpoints responding with valid certificate
[ ] Monitoring alerts cleared for certificate expiry
[ ] Certificate expiry monitoring updated with new dates
```

### Step 6 — Cleanup & Documentation

```
POST-ROTATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Old certificate removed from deployment locations
[ ] Old certificate revoked (if compromised) or archived
[ ] Certificate inventory updated
[ ] Next rotation date scheduled
[ ] Automation reviewed (can this be fully automated next time?)
[ ] Runbook updated with any lessons learned
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

Produce a certificate rotation report with:
1. **Certificate inventory** with old and new certificate details
2. **Deployment locations** with update status per location
3. **Validation results** (TLS check, chain validation, SSL Labs)
4. **Issues encountered** and resolutions
5. **Next rotation date** and automation recommendations
