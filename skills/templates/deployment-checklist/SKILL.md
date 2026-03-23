---
name: deployment-checklist
enabled: true
description: |
  Use when performing deployment checklist — run a structured pre-deployment and
  post-deployment checklist for any service release. Guides through readiness
  gates (tests, migrations, feature flags, rollback plan), live health checks,
  and go/no-go decisions. Use during deployment planning or to validate a
  release is safe to proceed.
required_connections:
  - prefix: github
    label: "GitHub (or GitLab / Bitbucket)"
config_fields:
  - key: service_name
    label: "Service Name"
    required: true
    placeholder: "e.g., payment-api"
  - key: version
    label: "Version / Tag"
    required: true
    placeholder: "e.g., v2.4.1"
  - key: environment
    label: "Target Environment"
    required: true
    placeholder: "e.g., production, staging"
  - key: rollback_version
    label: "Rollback Version"
    required: false
    placeholder: "e.g., v2.4.0"
features:
  - DEPLOYMENT
---

# Deployment Checklist Skill

Run a thorough pre- and post-deployment safety check for **{{ service_name }} {{ version }}** to **{{ environment }}**.

## Workflow

### Step 1 — Gather Deployment Context

Collect the following information to complete the checklist:

1. **Code changes**: Fetch the PR/MR or compare tag diff to understand scope of changes
2. **Changelog / Release notes**: Review what is in this release
3. **Test status**: Confirm all CI checks pass for the target commit/tag
4. **Migration status**: Check if any database or infrastructure migrations are included
5. **Dependency changes**: Review `package.json`, `requirements.txt`, `go.mod`, etc. for dependency updates
6. **Feature flags**: List any feature flags introduced or changed in this release

### Step 2 — Pre-Deployment Checklist

Go through each item. Mark **PASS**, **FAIL**, or **SKIP** with reasoning:

```
PRE-DEPLOYMENT CHECKLIST
Service: {{ service_name }}
Version: {{ version }}
Environment: {{ environment }}
Rollback: {{ rollback_version | "Not specified" }}
Date: [auto-populated]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
READINESS GATES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] All CI tests passing on target commit
[ ] Code review approved (≥2 reviewers for production)
[ ] Security scan / SAST passed
[ ] No known CVEs introduced in dependencies
[ ] QA/staging validation complete

MIGRATIONS & DATA
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] No database migrations — OR — migrations reviewed and tested
[ ] Migrations are backwards-compatible (old code can run against new schema)
[ ] Migration rollback procedure documented
[ ] Data backups confirmed for {{ environment }}

INFRASTRUCTURE & CONFIG
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Environment variables / secrets updated for {{ environment }}
[ ] Infrastructure changes (Terraform/CDK) applied or not needed
[ ] New dependencies/services provisioned
[ ] Load balancer health check paths verified

DEPLOYMENT STRATEGY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Deployment strategy defined: [ ] rolling  [ ] blue-green  [ ] canary  [ ] full-replace
[ ] Rollback procedure documented and tested
[ ] Rollback version confirmed: {{ rollback_version | "❌ NOT SPECIFIED" }}
[ ] On-call engineer notified / on standby

FEATURE FLAGS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] New feature flags are OFF by default for {{ environment }}
[ ] Existing flag changes reviewed and approved
[ ] Kill switches available for risky features

COMMUNICATIONS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Stakeholders notified (if user-impacting)
[ ] Status page updated (if applicable)
[ ] Customer support briefed (if applicable)
```

### Step 3 — Go / No-Go Decision

Evaluate the checklist results:

- **GO**: All gates PASS or SKIP with documented justification
- **NO-GO**: Any FAIL without explicit waiver — block deployment and resolve the failing item
- **CONDITIONAL GO**: ≥1 SKIP with documented risk accepted by engineering lead

Report the go/no-go decision clearly with reasoning.

### Step 4 — Deployment Execution

If GO:
1. Trigger deployment via CI/CD pipeline or documented runbook
2. Monitor key metrics for 15 minutes post-deploy:
   - Error rate (should stay within ±2% of baseline)
   - P95 latency (should not increase >20% from baseline)
   - CPU/memory on new pods/instances
3. Verify health check endpoints return 200

### Step 5 — Post-Deployment Checklist

After deployment completes:

```
POST-DEPLOYMENT CHECKLIST
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] All instances/pods running target version {{ version }}
[ ] Health checks passing on all nodes
[ ] No spike in error rate vs pre-deploy baseline
[ ] No degradation in P95 latency
[ ] Key user journeys validated (smoke test)
[ ] Logs show no unexpected errors
[ ] Monitoring alerts not firing
[ ] Database connections stable
[ ] Feature flags toggled as planned
[ ] Deployment record logged (version, timestamp, deployer)
```

### Step 6 — Stabilization Window

- Monitor for **30 minutes** post-deploy before considering deployment complete
- If any POST-DEPLOY item FAILS during this window → **initiate rollback**
- Rollback trigger: `ERROR RATE > 5%` or `P95 LATENCY 2x baseline` sustained for 5 minutes

### Rollback Procedure (if needed)

```
ROLLBACK INITIATED
Reason: [describe trigger]
Rollback to: {{ rollback_version }}

Steps:
1. Trigger rollback deployment (revert to {{ rollback_version }})
2. Verify old version running on all nodes
3. Confirm metrics return to pre-deploy baseline
4. Notify stakeholders of rollback
5. Create post-mortem issue to investigate root cause
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

Produce a structured checklist report with:
1. **Summary header** (service, version, environment, timestamp, deployer)
2. **Pre-deployment checklist** with PASS/FAIL/SKIP per item
3. **Go/No-Go decision** with justification
4. **Post-deployment results** (after monitoring window)
5. **Action items** (any follow-ups needed)
