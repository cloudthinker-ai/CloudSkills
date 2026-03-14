---
name: release-readiness-review
enabled: true
description: |
  Comprehensive checklist for evaluating release readiness before deploying to production. Covers code completeness, testing validation, documentation updates, monitoring readiness, rollback procedures, stakeholder sign-offs, and go/no-go decision criteria to ensure confident releases.
required_connections:
  - prefix: github
    label: "GitHub"
  - prefix: jira
    label: "Jira (or project tracker)"
config_fields:
  - key: release_version
    label: "Release Version"
    required: true
    placeholder: "e.g., v4.2.0"
  - key: release_name
    label: "Release Name/Description"
    required: true
    placeholder: "e.g., Q1 payment redesign"
  - key: release_date
    label: "Target Release Date"
    required: true
    placeholder: "e.g., 2026-04-15"
features:
  - COMPLIANCE
  - RELEASE
---

# Release Readiness Review Skill

Evaluate readiness for **{{ release_name }}** ({{ release_version }}) targeted for **{{ release_date }}**.

## Workflow

### Phase 1 — Feature Completeness

```
FEATURE STATUS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] All planned features complete:
    Feature                | Status    | Owner   | Tests
    _______________________|___________|_________|______
                           |           |         |
                           |           |         |
                           |           |         |

[ ] Features deferred to next release:
    - ___
    - ___
[ ] All PRs merged: [ ] YES — count: ___
[ ] No open blockers: [ ] CONFIRMED
[ ] Code freeze in effect: [ ] YES — since: ___
```

### Phase 2 — Testing Validation

```
TEST RESULTS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Unit tests: ___ pass / ___ fail / ___ skip (coverage: ___%)
[ ] Integration tests: ___ pass / ___ fail
[ ] E2E tests: ___ pass / ___ fail
[ ] Performance tests:
    - P95 latency: ___ms (SLO: ___ms)
    - Throughput: ___ RPS (target: ___ RPS)
    - No performance regressions: [ ] CONFIRMED
[ ] Security scan: [ ] PASS — vulnerabilities: ___
[ ] Accessibility tests: [ ] PASS
[ ] Manual QA sign-off: [ ] YES — by: ___
[ ] Staging environment validated: [ ] YES
[ ] Load test completed: [ ] YES — results: ___

TEST DECISION MATRIX
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Category      | Required | Status  | Blocking
Unit          | YES      |         |
Integration   | YES      |         |
E2E           | YES      |         |
Performance   | YES      |         |
Security      | YES      |         |
Accessibility | NO       |         |
```

### Phase 3 — Operational Readiness

```
OPERATIONS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Deployment runbook reviewed and updated
[ ] Rollback procedure tested
[ ] Database migrations:
    - Migrations to apply: ___
    - Backward compatible: [ ] YES
    - Rollback script ready: [ ] YES
[ ] Feature flags configured:
    - Flags for this release: ___
    - Gradual rollout plan: ___
[ ] Monitoring and alerting:
    - Dashboards updated: [ ] YES
    - Alerts configured for new features: [ ] YES
    - On-call team briefed: [ ] YES
[ ] Infrastructure changes required: [ ] YES  [ ] NO
    - Changes applied: [ ] YES
```

### Phase 4 — Documentation and Communication

```
DOCUMENTATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Release notes written
[ ] API documentation updated
[ ] User-facing documentation updated
[ ] Internal knowledge base updated
[ ] Changelog updated

COMMUNICATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Customer-facing announcement prepared
[ ] Internal team notification prepared
[ ] Support team briefed on changes
[ ] Known issues documented
```

### Phase 5 — Go/No-Go Decision

```
SIGN-OFFS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Role              | Name   | Decision     | Date
Engineering Lead  | ___    | GO / NO-GO   | ___
QA Lead           | ___    | GO / NO-GO   | ___
Product Owner     | ___    | GO / NO-GO   | ___
Operations Lead   | ___    | GO / NO-GO   | ___
Security          | ___    | GO / NO-GO   | ___

FINAL DECISION: [ ] GO  [ ] NO-GO  [ ] CONDITIONAL GO

Conditions (if conditional):
- ___
- ___

Release window: ___
Release owner: ___
```

## Output Format

Produce a release readiness report with:
1. **Release summary** (version, features, scope)
2. **Test results** (pass/fail rates, coverage, performance)
3. **Operational readiness** (deployment plan, rollback, monitoring)
4. **Risk assessment** (known issues, blockers, mitigations)
5. **Decision** (GO / NO-GO with sign-offs and conditions)
