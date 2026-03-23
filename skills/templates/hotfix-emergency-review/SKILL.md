---
name: hotfix-emergency-review
enabled: true
description: |
  Use when performing hotfix emergency review — expedited review process
  template for production hotfixes covering incident correlation, minimal change
  verification, rollback readiness, regression risk assessment, and
  post-incident follow-up tracking. Provides a streamlined but thorough review
  framework for emergency fixes that balances speed with safety.
required_connections:
  - prefix: github
    label: "GitHub"
config_fields:
  - key: repository
    label: "Repository"
    required: true
    placeholder: "e.g., org/production-service"
  - key: pr_number
    label: "PR Number"
    required: true
    placeholder: "e.g., 1234"
  - key: incident_id
    label: "Incident ID"
    required: true
    placeholder: "e.g., INC-5678"
features:
  - CODE_REVIEW
---

# Hotfix Emergency Review Skill

Emergency review of PR **#{{ pr_number }}** in **{{ repository }}** for incident **{{ incident_id }}**.

## Workflow

### Phase 1 — Incident Correlation

```
INCIDENT VERIFICATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Incident details:
    - Incident ID: {{ incident_id }}
    - Severity: SEV1 / SEV2 / SEV3
    - Impact: ___
    - Root cause identified: YES / NO
    - Root cause: ___
[ ] Fix correlation:
    [ ] Changes directly address the root cause
    [ ] No unrelated changes included
    [ ] Fix matches incident investigation findings
[ ] Current status:
    - Incident start time: ___
    - Current mitigation: ___
    - Users affected: ___
```

### Phase 2 — Minimal Change Verification

```
CHANGE SCOPE CHECK
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Minimal fix:
    [ ] Only changes necessary for the fix are included
    [ ] No refactoring or cleanup bundled in
    [ ] No feature work included
    [ ] Change is the smallest safe fix possible
[ ] Change assessment:
    - Files changed: ___
    - Lines added: ___
    - Lines removed: ___
    [ ] Change size appropriate for hotfix: YES / NO
[ ] Alternative approaches considered: ___
```

### Phase 3 — Safety Checks

```
SAFETY VERIFICATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Regression risk:
    [ ] Fix does not break existing functionality
    [ ] Critical path tested manually
    [ ] Automated tests pass (or known failures documented)
    [ ] Fix does not introduce new security vulnerabilities
[ ] Rollback readiness:
    [ ] Rollback procedure documented
    [ ] Rollback can be done quickly (< 5 minutes)
    [ ] Feature flags available for instant rollback
    [ ] Database changes are rollback-safe
[ ] Deployment safety:
    [ ] Canary deployment possible: YES / NO
    [ ] Health checks will catch regressions: YES / NO
    [ ] Monitoring dashboards identified for post-deploy
    [ ] Alerting covers the fixed scenario
```

### Phase 4 — Post-Incident Tracking

```
FOLLOW-UP ITEMS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Technical debt:
    [ ] TODO: Proper fix ticket created: ___
    [ ] TODO: Tests to add: ___
    [ ] TODO: Monitoring to improve: ___
    [ ] TODO: Documentation to update: ___
[ ] Process improvements:
    [ ] Post-incident review scheduled: YES / NO
    [ ] Runbook update needed: YES / NO
    [ ] Alert tuning needed: YES / NO
[ ] Hotfix to be cherry-picked to: ___
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

Produce an emergency review report with:
1. **Incident correlation** (confirmed fix addresses root cause)
2. **Change scope** (minimal / acceptable / too broad)
3. **Safety assessment** (safe to deploy / deploy with caution / needs rework)
4. **Rollback readiness** (ready / partially ready / not ready)
5. **Follow-up items** tracked for post-incident
