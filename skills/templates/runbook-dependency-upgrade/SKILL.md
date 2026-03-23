---
name: runbook-dependency-upgrade
enabled: true
description: |
  Use when performing runbook dependency upgrade — dependency upgrade workflow
  covering compatibility check, testing, deployment, and monitoring. Use for
  library upgrades, framework version bumps, runtime updates, or security patch
  application.
required_connections: []
config_fields:
  - key: dependency_name
    label: "Dependency Name"
    required: true
    placeholder: "e.g., react, spring-boot, python"
  - key: current_version
    label: "Current Version"
    required: true
    placeholder: "e.g., 3.1.2"
  - key: target_version
    label: "Target Version"
    required: true
    placeholder: "e.g., 3.2.0"
  - key: affected_services
    label: "Affected Services"
    required: false
    placeholder: "e.g., api-service, web-frontend"
features:
  - RUNBOOK
  - DEPLOYMENT
---

# Dependency Upgrade Runbook Skill

Upgrade **{{ dependency_name }}** from **{{ current_version }}** to **{{ target_version }}**.
Affected services: **{{ affected_services }}**

## Workflow

### Phase 1 — Compatibility Assessment

```
COMPATIBILITY ASSESSMENT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
UPGRADE DETAILS
  Dependency: {{ dependency_name }}
  Current: {{ current_version }}
  Target: {{ target_version }}
  Change type: [MAJOR / MINOR / PATCH]
  Release date: ___
  End-of-life for current version: ___

CHANGELOG REVIEW
[ ] Read changelog / release notes for all versions between current and target
[ ] Identify breaking changes: ___
[ ] Identify deprecated APIs being used: ___
[ ] Identify new features to leverage: ___
[ ] Review security advisories (CVEs fixed): ___

DEPENDENCY TREE IMPACT
[ ] Check transitive dependency changes
[ ] Identify conflicting version requirements
[ ] Verify peer dependency compatibility
[ ] Check compatibility with other major dependencies:
    Dependency: ___ (version: ___) — compatible: YES / NO
    Dependency: ___ (version: ___) — compatible: YES / NO

RISK ASSESSMENT
  Risk level: [LOW / MEDIUM / HIGH / CRITICAL]
  Estimated code changes required: ___
  Estimated testing effort: ___
```

### Phase 2 — Code Changes and Local Testing

```
CODE CHANGES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Create feature branch for upgrade
[ ] Update dependency version in manifest:
    - package.json / pom.xml / requirements.txt / go.mod / Gemfile
[ ] Run dependency resolution (npm install / mvn resolve / pip install)
[ ] Fix compilation errors: ___ files changed
[ ] Update deprecated API calls: ___ call sites
[ ] Update configuration for new version requirements
[ ] Update type definitions (if applicable)

LOCAL TESTING
[ ] Application builds without errors
[ ] Unit tests pass: ___ / ___ passing
[ ] Integration tests pass: ___ / ___ passing
[ ] Manual smoke test of critical paths:
    [ ] Path: ___ — Result: PASS / FAIL
    [ ] Path: ___ — Result: PASS / FAIL
    [ ] Path: ___ — Result: PASS / FAIL
[ ] Performance benchmark (no regression):
    Before: ___ ms avg | After: ___ ms avg
```

### Phase 3 — Staging Deployment and Testing

```
STAGING DEPLOYMENT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Deploy to staging environment
[ ] Verify application starts without errors
[ ] Run full test suite in staging:
    Unit: ___ / ___ passing
    Integration: ___ / ___ passing
    E2E: ___ / ___ passing
[ ] Run performance / load tests:
    Throughput: ___ RPS (baseline: ___ RPS)
    Latency p95: ___ ms (baseline: ___ ms)
    Error rate: ___% (baseline: ___%)
[ ] Verify logging and monitoring still functioning
[ ] Test rollback procedure in staging:
    [ ] Revert to {{ current_version }}
    [ ] Confirm application works on old version
    [ ] Re-deploy {{ target_version }}

SECURITY SCAN
[ ] Run dependency vulnerability scan (Snyk, Dependabot, etc.)
[ ] No new HIGH/CRITICAL vulnerabilities introduced
[ ] License compliance check passed
```

### Phase 4 — Production Deployment

```
PRODUCTION DEPLOYMENT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PRE-DEPLOYMENT
[ ] Code review approved
[ ] Staging sign-off obtained
[ ] Deployment window confirmed
[ ] Rollback plan documented and ready
[ ] On-call engineer notified

DEPLOYMENT STRATEGY
[ ] Canary: deploy to ___% of instances first
[ ] Blue-green: deploy to inactive environment
[ ] Rolling: update instances in batches of ___

EXECUTION
[ ] Deploy to production: ___
[ ] Monitor canary / first batch for ___ minutes
[ ] Check error rate: ___% (threshold: ___%)
[ ] Check latency: ___ ms (threshold: ___ ms)
[ ] Proceed with full rollout: YES / ROLLBACK
[ ] Full rollout complete at: ___
```

### Phase 5 — Post-Deployment Monitoring

```
POST-DEPLOYMENT MONITORING (24-72h)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
HEALTH METRICS (check at T+1h, T+4h, T+24h, T+72h)
  Metric          Pre-upgrade   Post-upgrade  Status
  ─────────────── ───────────── ───────────── ─────────
  Error rate      ___%          ___%          OK / WARN
  Latency (p95)   ___ms         ___ms         OK / WARN
  Memory usage    ___MB         ___MB         OK / WARN
  CPU usage       ___%          ___%          OK / WARN
  Throughput      ___RPS        ___RPS        OK / WARN

[ ] No new error patterns in logs
[ ] No increase in exception rates
[ ] No memory leaks (memory stable over time)
[ ] No performance degradation under load
[ ] Downstream services unaffected
```

### Phase 6 — Rollback and Cleanup

```
ROLLBACK (if issues detected)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Trigger: error rate > ___%, latency regression > ___%, crash loops
1. [ ] Revert deployment to previous version ({{ current_version }})
2. [ ] Verify application healthy on old version
3. [ ] Investigate failure root cause
4. [ ] Fix and re-attempt upgrade

CLEANUP (if upgrade successful)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Merge upgrade branch to main
[ ] Remove any temporary compatibility shims
[ ] Update documentation with new version
[ ] Close upgrade ticket
[ ] Plan removal of deprecated API usage (if deferred)
[ ] Schedule next dependency review: ___
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

Produce a dependency upgrade report with:
1. **Upgrade summary** (dependency, versions, risk level)
2. **Compatibility assessment** with breaking changes identified
3. **Test results** (unit, integration, e2e, performance)
4. **Deployment log** with canary/rollout progression
5. **Post-deployment metrics** comparison (before vs. after)
6. **Issues and follow-up** actions
