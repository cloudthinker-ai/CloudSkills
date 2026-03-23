---
name: certificate-expiry-incident
enabled: true
description: |
  Use when performing certificate expiry incident — tLS/SSL certificate expiry
  incident response and prevention playbook. Covers emergency certificate
  renewal, impact assessment, interim mitigations, certificate chain validation,
  automated renewal configuration, monitoring setup, and organizational
  processes to prevent certificate-related outages.
required_connections:
  - prefix: slack
    label: "Slack (for incident coordination)"
config_fields:
  - key: affected_domain
    label: "Affected Domain"
    required: true
    placeholder: "e.g., api.example.com, *.example.com"
  - key: certificate_provider
    label: "Certificate Provider"
    required: false
    placeholder: "e.g., Let's Encrypt, DigiCert, ACM"
  - key: expiry_status
    label: "Expiry Status"
    required: true
    placeholder: "e.g., expired 2 hours ago, expires in 24 hours"
features:
  - INCIDENT
---

# Certificate Expiry Incident Response

Domain: **{{ affected_domain }}**
Provider: **{{ certificate_provider }}**
Status: **{{ expiry_status }}**

## Impact of Expired Certificates

- Browsers show security warnings, blocking user access
- API clients reject connections with TLS errors
- Mobile apps may hard-fail with certificate pinning errors
- Service-to-service communication breaks if mTLS is used
- Webhooks from third parties fail
- Search engine rankings can be affected

## Phase 1 — Immediate Diagnosis (0-5 min)

### Check Certificate Status
```bash
# Check certificate expiry for a domain
echo | openssl s_client -servername {{ affected_domain }} -connect {{ affected_domain }}:443 2>/dev/null | openssl x509 -noout -dates -subject -issuer

# Check certificate chain
echo | openssl s_client -servername {{ affected_domain }} -connect {{ affected_domain }}:443 -showcerts 2>/dev/null

# Check days until expiry
echo | openssl s_client -servername {{ affected_domain }} -connect {{ affected_domain }}:443 2>/dev/null | openssl x509 -noout -checkend 0
# Exit code 1 = expired, 0 = still valid

# Check from a specific file
openssl x509 -in /path/to/cert.pem -noout -dates

# Verify certificate matches private key
openssl x509 -noout -modulus -in cert.pem | openssl md5
openssl rsa -noout -modulus -in key.pem | openssl md5
# Both MD5 values must match
```

### Identify All Affected Endpoints
- [ ] Which domains use this certificate? (check SANs)
- [ ] Is this a wildcard cert affecting multiple subdomains?
- [ ] Where is this certificate deployed? (load balancers, CDN, servers, containers)
- [ ] Are there any certificate-pinned clients?

## Phase 2 — Emergency Renewal (5-30 min)

### Option 1: Automated Renewal (Let's Encrypt / ACME)
```bash
# Certbot renewal
sudo certbot renew --cert-name {{ affected_domain }} --force-renewal

# Verify new certificate
sudo certbot certificates --cert-name {{ affected_domain }}
```

### Option 2: Cloud Provider Managed Certificates
```bash
# AWS ACM — request new certificate
aws acm request-certificate \
  --domain-name {{ affected_domain }} \
  --validation-method DNS

# GCP — managed certificate auto-renews; check status
gcloud compute ssl-certificates describe CERT_NAME

# Azure — check App Service managed certificate
az webapp config ssl list --resource-group RG_NAME
```

### Option 3: Manual Certificate Renewal
1. Generate new CSR:
```bash
openssl req -new -newkey rsa:2048 -nodes \
  -keyout {{ affected_domain }}.key \
  -out {{ affected_domain }}.csr \
  -subj "/CN={{ affected_domain }}"
```
2. Submit CSR to certificate provider ({{ certificate_provider }})
3. Complete domain validation (DNS or HTTP)
4. Download and install new certificate

### Option 4: Emergency Self-Signed (last resort, internal only)
```bash
openssl req -x509 -newkey rsa:2048 -nodes \
  -keyout emergency.key -out emergency.crt \
  -days 30 -subj "/CN={{ affected_domain }}"
```
**WARNING:** Self-signed certificates will cause browser warnings and API client failures. Use only for internal services as a temporary measure.

## Phase 3 — Deploy New Certificate

### Deployment Checklist
- [ ] New certificate validated (correct domain, valid chain, key matches)
- [ ] Deploy to load balancer(s)
- [ ] Deploy to CDN edge (if applicable)
- [ ] Deploy to application servers (if terminating TLS)
- [ ] Update Kubernetes secrets (if applicable)
- [ ] Restart/reload web servers (nginx, Apache, etc.)
- [ ] Flush any TLS session caches

### Verification After Deployment
```bash
# Verify new certificate is being served
echo | openssl s_client -servername {{ affected_domain }} -connect {{ affected_domain }}:443 2>/dev/null | openssl x509 -noout -dates -subject

# Test HTTPS connectivity
curl -vI https://{{ affected_domain }} 2>&1 | grep -E "expire|subject|issuer|SSL"

# Check certificate chain is complete
echo | openssl s_client -servername {{ affected_domain }} -connect {{ affected_domain }}:443 2>/dev/null | grep -E "Verify|depth"
```

### Verification Checklist
- [ ] Certificate shows new expiry date
- [ ] Full certificate chain is valid
- [ ] No mixed content warnings
- [ ] API clients connecting successfully
- [ ] Monitoring tools reporting healthy
- [ ] SSL Labs test passing (https://www.ssllabs.com/ssltest/)

## Phase 4 — Prevention

### Automated Renewal Setup
- [ ] Configure ACME/certbot auto-renewal with cron or systemd timer
- [ ] Use cloud-managed certificates where possible (ACM, GCP managed)
- [ ] Test renewal process in staging before relying on it

### Monitoring and Alerting
- [ ] Set up certificate expiry monitoring (alert at 30, 14, 7, 3, 1 days)
- [ ] Monitor certificate validity from external vantage points
- [ ] Add certificate expiry to team dashboard
- [ ] Configure alerts for renewal failures

### Organizational Process
- [ ] Maintain certificate inventory (domain, provider, expiry, owner, location)
- [ ] Assign certificate ownership to specific teams
- [ ] Include certificate review in quarterly security audits
- [ ] Document renewal procedures in runbook
- [ ] Add certificate checks to production readiness review

## Counter-Rationalizations

| Shortcut | Counter | Why |
|----------|---------|-----|
| "We can skip some steps for this case" | Adapt the workflow steps, don't skip them | Skipped steps are where incidents and oversights originate |
| "The user seems to already know what to do" | Complete all workflow phases with the user | The workflow catches blind spots that experience alone misses |
| "This is a minor case, full process is overkill" | Scale the process down, don't turn it off | Minor cases become major when unstructured; the process scales, not disappears |
| "I'll fill in the details later" | Complete each section before moving on | Deferred details are forgotten; real-time capture is more accurate |
| "The template output isn't necessary" | Always produce the structured output format | Structured output enables comparison, audit trails, and handoff to other teams |

