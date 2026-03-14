---
name: secrets-rotation-audit
enabled: true
description: |
  Audits the rotation status of all secrets, credentials, API keys, and certificates across services and environments. This template identifies stale secrets, missing rotation policies, and non-compliant credential management practices, producing a remediation plan to strengthen secrets hygiene.
required_connections:
  - prefix: vault
    label: "Secrets Manager"
  - prefix: cloud
    label: "Cloud Provider"
config_fields:
  - key: environment
    label: "Environment"
    required: true
    placeholder: "e.g., production"
  - key: rotation_policy_days
    label: "Max Secret Age (days)"
    required: true
    placeholder: "e.g., 90"
features:
  - SECRETS_MANAGEMENT
  - SECURITY_AUDIT
  - SRE_OPS
---

# Secrets Rotation Audit

## Phase 1: Secrets Inventory

Catalog all secrets and credentials in scope.

| Secret ID | Type | Service/Owner | Created | Last Rotated | Age (days) | Rotation Policy | Compliant |
|-----------|------|---------------|---------|-------------|------------|-----------------|-----------|
|           |      |               |         |             |            |                 |           |

**Secret Types:** API Key, Database Credential, TLS Certificate, SSH Key, OAuth Token, Service Account Key, Encryption Key, Webhook Secret

## Phase 2: Compliance Assessment

Evaluate each secret against the rotation policy.

- [ ] Total secrets inventoried: ___
- [ ] Secrets within rotation policy: ___
- [ ] Secrets overdue for rotation: ___
- [ ] Secrets with no rotation policy: ___
- [ ] Secrets with unknown last rotation date: ___

**Compliance by Type:**

| Secret Type | Total | Compliant | Non-Compliant | Compliance Rate |
|-------------|-------|-----------|---------------|-----------------|
| API Keys    |       |           |               |                 |
| DB Credentials |    |           |               |                 |
| TLS Certificates | |           |               |                 |
| SSH Keys    |       |           |               |                 |
| Service Account Keys | |       |               |                 |
| Other       |       |           |               |                 |

## Phase 3: Risk Assessment

For each non-compliant secret, assess risk.

**Decision Matrix:**

| Risk | Criteria | Action |
|------|----------|--------|
| Critical | Secret >2x policy age, has broad permissions, no MFA protection | Rotate immediately, investigate for compromise |
| High | Secret >policy age, used in production, shared across services | Rotate within 48 hours |
| Medium | Secret >policy age, limited scope, single-service use | Rotate within 7 days |
| Low | Secret approaching policy age, rotation scheduled | Ensure scheduled rotation proceeds |

- [ ] Check for secrets stored in plaintext (code repos, config files, wikis)
- [ ] Identify secrets shared across multiple services or teams
- [ ] Verify secrets are accessed only by authorized principals
- [ ] Check for leaked secrets in public repositories or logs

## Phase 4: Automation Assessment

- [ ] Percentage of secrets with automated rotation: ___%
- [ ] Secrets manager integration coverage: ___%
- [ ] Rotation automation tool: ___
- [ ] Gaps in automation (manual rotation still required): list

## Phase 5: Remediation Plan

For each non-compliant secret:

1. - [ ] Rotate the secret
2. - [ ] Update all consumers of the secret
3. - [ ] Verify service continuity after rotation
4. - [ ] Enable automated rotation if not already configured
5. - [ ] Document rotation procedure

## Output Format

### Summary

- **Total secrets audited:** ___
- **Overall compliance rate:** ___%
- **Critical/High risk secrets requiring immediate rotation:** ___
- **Automated rotation coverage:** ___%

### Action Items

- [ ] Rotate all Critical risk secrets immediately
- [ ] Rotate all High risk secrets within 48 hours
- [ ] Enable automated rotation for all eligible secrets
- [ ] Remove any plaintext secrets from code or config
- [ ] Establish quarterly secrets rotation audit cadence
- [ ] Report compliance status to security team
