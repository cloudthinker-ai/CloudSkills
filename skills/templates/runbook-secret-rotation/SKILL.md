---
name: runbook-secret-rotation
enabled: true
description: |
  Use when performing runbook secret rotation — secret and credential rotation
  procedure covering discovery, rotation execution, deployment, and validation.
  Use for scheduled credential rotation, responding to leaked secrets, or
  compliance-driven key rotation.
required_connections: []
config_fields:
  - key: secret_type
    label: "Secret Type"
    required: true
    placeholder: "e.g., database password, API key, TLS certificate"
  - key: secret_name
    label: "Secret Name / Identifier"
    required: true
    placeholder: "e.g., prod/db/primary-password, stripe-api-key"
  - key: rotation_reason
    label: "Rotation Reason"
    required: true
    placeholder: "e.g., scheduled rotation, suspected compromise, employee offboarding"
  - key: affected_services
    label: "Services Using This Secret"
    required: false
    placeholder: "e.g., api-service, payment-worker, auth-service"
features:
  - RUNBOOK
  - SECURITY
---

# Secret Rotation Runbook Skill

Rotate **{{ secret_type }}**: **{{ secret_name }}**
Reason: **{{ rotation_reason }}** | Services: **{{ affected_services }}**

## Workflow

### Phase 1 — Secret Discovery and Audit

```
SECRET DISCOVERY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SECRET DETAILS
  Type: {{ secret_type }}
  Name/ID: {{ secret_name }}
  Storage: [Secrets Manager / Vault / env vars / config files]
  Last rotated: ___
  Rotation policy: every ___ days
  Current version: ___

CONSUMERS
[ ] Identify all services using this secret:
    Service: ___ | How consumed: [env var / mounted secret / API call]
    Service: ___ | How consumed: [env var / mounted secret / API call]
    Service: ___ | How consumed: [env var / mounted secret / API call]
[ ] Identify CI/CD pipelines referencing this secret
[ ] Identify third-party integrations using this credential
[ ] Check for hardcoded references in code repositories
[ ] Check for references in configuration management

URGENCY ASSESSMENT
[ ] Is this a suspected compromise? YES / NO
  If YES: treat as emergency, skip to Phase 3 immediately
[ ] Is there a compliance deadline? ___
[ ] Can we do a rolling rotation (dual-credential period)? YES / NO
```

### Phase 2 — Pre-Rotation Preparation

```
PRE-ROTATION PREPARATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Verify secret management system is healthy
[ ] Confirm rollback procedure (can old secret be restored?)
[ ] Notify service owners of upcoming rotation
[ ] Schedule rotation window (if non-emergency)
[ ] Verify all consumer services support graceful secret reload
[ ] Test rotation procedure in staging environment
[ ] Prepare new credential value:
    - Generate with appropriate strength/length
    - Meets complexity requirements: YES / NO
    - Does NOT resemble previous value: YES / NO
```

### Phase 3 — Rotation Execution

```
ROTATION EXECUTION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
STEP 1: CREATE NEW SECRET
[ ] Generate new credential value
[ ] Store as new version in secret manager
    New version ID: ___
[ ] Verify new secret is retrievable

STEP 2: DUAL-CREDENTIAL PERIOD (if supported)
[ ] Configure target system to accept BOTH old and new credentials
    - Database: CREATE new user or ALTER password while keeping old session
    - API key: Add new key to allowlist before revoking old
    - TLS cert: Deploy new cert alongside old one
[ ] Verify old credential still works
[ ] Verify new credential works
[ ] Record dual-credential start time: ___

STEP 3: DEPLOY NEW SECRET TO CONSUMERS
  For each service in {{ affected_services }}:
  [ ] Service: ___ — updated to new secret version
      Method: [restart / rolling deploy / hot reload / env refresh]
  [ ] Service: ___ — updated to new secret version
  [ ] Service: ___ — updated to new secret version
  [ ] CI/CD pipelines updated
  [ ] Third-party integrations updated

STEP 4: REVOKE OLD SECRET
[ ] Confirm all consumers using new secret (no auth with old)
[ ] Revoke / disable old credential
[ ] Record revocation timestamp: ___
```

### Phase 4 — Post-Rotation Validation

```
POST-ROTATION VALIDATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
AUTHENTICATION HEALTH
[ ] All services authenticating successfully with new secret
[ ] No authentication failures in logs (401s, connection refused)
[ ] No services still using old credential
[ ] API response times unaffected

SERVICE HEALTH (check each consumer)
[ ] Service: ___ — healthy, using new secret
[ ] Service: ___ — healthy, using new secret
[ ] Service: ___ — healthy, using new secret
[ ] CI/CD pipeline test run successful with new secret
[ ] Scheduled jobs executing with new secret

SECURITY VERIFICATION
[ ] Old credential confirmed revoked (test fails as expected)
[ ] Audit log shows rotation event
[ ] No copies of old secret in temporary files or logs
[ ] Secret not exposed in environment dumps or error messages
```

### Phase 5 — Rollback Procedure

```
ROLLBACK (if new secret causes issues)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
1. [ ] Re-enable old credential on target system
2. [ ] Revert consumer services to previous secret version
3. [ ] Verify services authenticating with old credential
4. [ ] Investigate why new credential failed
5. [ ] Re-attempt rotation after fixing root cause

NOTE: If rotation was due to compromise, DO NOT rollback.
      Instead, generate a different new credential.
```

### Phase 6 — Documentation and Automation

```
DOCUMENTATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Update secret rotation log:
    Secret: {{ secret_name }}
    Rotated: [timestamp]
    Reason: {{ rotation_reason }}
    Old version: ___ (revoked)
    New version: ___
    Next rotation due: ___
[ ] Update rotation schedule / calendar
[ ] If manual: create automation ticket to auto-rotate this secret
[ ] Review and update consumer service documentation
[ ] Close change management ticket
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

Produce a secret rotation report with:
1. **Rotation summary** (secret type, name, reason, timestamps)
2. **Consumer inventory** of all services updated
3. **Execution log** with dual-credential period and revocation
4. **Validation results** (authentication health per service)
5. **Security confirmation** (old credential revoked, no leakage)
6. **Next rotation** scheduled date
