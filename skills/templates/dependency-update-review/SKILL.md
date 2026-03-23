---
name: dependency-update-review
enabled: true
description: |
  Use when performing dependency update review — dependency update PR review
  template covering CVE assessment, breaking change detection, license
  compliance, transitive dependency analysis, and upgrade risk evaluation.
  Provides a systematic framework for reviewing package updates from Dependabot,
  Renovate, or manual upgrades to ensure security and stability.
required_connections:
  - prefix: github
    label: "GitHub"
config_fields:
  - key: repository
    label: "Repository"
    required: true
    placeholder: "e.g., org/backend-service"
  - key: pr_number
    label: "PR Number"
    required: true
    placeholder: "e.g., 1234"
  - key: package_manager
    label: "Package Manager"
    required: false
    placeholder: "e.g., npm, pip, maven, go modules"
features:
  - CODE_REVIEW
---

# Dependency Update Review Skill

Review dependency update PR **#{{ pr_number }}** in **{{ repository }}** ({{ package_manager }}).

## Workflow

### Phase 1 — Security Assessment

```
CVE ASSESSMENT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Security advisory review:
    [ ] CVE identifier: ___
    [ ] Severity: critical / high / medium / low
    [ ] Affected versions: ___
    [ ] Fixed in version: ___
    [ ] Exploitability: ___
[ ] Impact analysis:
    [ ] Vulnerable code path used in application: YES / NO
    [ ] Attack vector applicable to deployment: YES / NO
    [ ] Workaround available if upgrade blocked: YES / NO
[ ] Transitive dependencies:
    [ ] Transitive vulnerability scan clean: YES / NO
    [ ] New transitive dependencies introduced: ___
```

### Phase 2 — Breaking Changes

```
BREAKING CHANGE REVIEW
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Version bump type: major / minor / patch
[ ] Changelog reviewed: YES / NO
[ ] Breaking changes identified:
    Change                      | Impact    | Migration
    ────────────────────────────┼───────────┼──────────
    ___                         | ___       | ___
[ ] API surface changes: YES / NO
[ ] Deprecation warnings addressed: YES / NO
[ ] Migration guide followed: YES / NO
```

### Phase 3 — License Compliance

```
LICENSE CHECK
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] License of updated package: ___
[ ] License compatible with project: YES / NO
[ ] License change from previous version: YES / NO
[ ] New transitive dependency licenses:
    Package          | License    | Compatible
    ─────────────────┼────────────┼───────────
    ___              | ___        | YES / NO
[ ] Copyleft license introduced: YES / NO
[ ] Legal review required: YES / NO
```

### Phase 4 — Stability Verification

```
STABILITY CHECK
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] All existing tests pass: YES / NO
[ ] Package download stats (popularity): ___
[ ] Release age (avoid day-zero releases): ___
[ ] Known regressions in release: YES / NO
[ ] Lock file properly updated: YES / NO
[ ] Build artifacts unchanged (no unexpected size changes): YES / NO
[ ] Runtime tested in staging: YES / NO
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

Produce a dependency review report with:
1. **Security verdict** (safe / requires attention / blocking)
2. **Breaking change impact** (none / low / high)
3. **License compliance status** (compliant / review needed / blocked)
4. **Upgrade recommendation** (approve / approve with changes / reject)
5. **Risk mitigation steps** if applicable
