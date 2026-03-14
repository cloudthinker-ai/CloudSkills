---
name: dependency-update-plan
enabled: true
description: |
  Template for planning and executing dependency updates across projects. Covers vulnerability scanning, compatibility analysis, update sequencing, testing strategy, rollback planning, and automation setup to keep dependencies current while minimizing risk of breaking changes.
required_connections:
  - prefix: github
    label: "GitHub"
config_fields:
  - key: repository
    label: "Repository"
    required: true
    placeholder: "e.g., org/web-app"
  - key: package_manager
    label: "Package Manager"
    required: true
    placeholder: "e.g., npm, pip, maven, go mod"
  - key: update_scope
    label: "Update Scope"
    required: false
    placeholder: "e.g., security-only, minor, major"
features:
  - ENGINEERING
  - SECURITY
---

# Dependency Update Plan Skill

Plan dependency updates for **{{ repository }}** using **{{ package_manager }}** — scope: **{{ update_scope }}**.

## Workflow

### Phase 1 — Dependency Audit

```
CURRENT STATE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Total dependencies: ___
    - Direct: ___
    - Transitive: ___
[ ] Outdated dependencies: ___
[ ] Dependencies with known vulnerabilities:
    - Critical: ___
    - High: ___
    - Medium: ___
    - Low: ___
[ ] Lock file present and committed: [ ] YES  [ ] NO
[ ] Last dependency update: ___
```

### Phase 2 — Update Analysis

```
UPDATE CANDIDATES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Dependency         | Current | Latest | Type   | Breaking | Risk
___________________|_________|________|________|__________|______
                   |         |        | MAJOR  |          |
                   |         |        | MINOR  |          |
                   |         |        | PATCH  |          |
                   |         |        | SECURITY|         |

RISK CLASSIFICATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
HIGH risk (major version, API changes):
- ___

MEDIUM risk (minor version, new features):
- ___

LOW risk (patch version, bug fixes):
- ___

SECURITY (must update regardless of risk):
- ___
```

### Phase 3 — Update Sequencing

```
UPDATE ORDER
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Batch 1 — Security patches (immediate):
[ ] ___
[ ] ___

Batch 2 — Low-risk patches:
[ ] ___
[ ] ___

Batch 3 — Minor updates:
[ ] ___
[ ] ___

Batch 4 — Major updates (one at a time):
[ ] ___
[ ] ___

DEPENDENCY GRAPH CONSIDERATIONS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Peer dependency conflicts identified: ___
[ ] Update order respects dependency graph
[ ] No circular update dependencies
```

### Phase 4 — Testing Strategy

```
TESTING CHECKLIST (per batch)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Lock file regenerated
[ ] Build succeeds
[ ] Unit tests pass
[ ] Integration tests pass
[ ] Type checking passes (if applicable)
[ ] Linting passes
[ ] E2E tests pass for critical paths
[ ] Manual smoke test for major updates
[ ] Performance regression check
```

### Phase 5 — Rollback Plan

```
ROLLBACK
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Previous lock file preserved
[ ] Rollback procedure:
    1. Revert lock file to previous version
    2. Reinstall dependencies
    3. Verify build and tests
[ ] Maximum acceptable rollback time: ___
```

### Phase 6 — Automation Setup

```
ONGOING MAINTENANCE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Automated dependency scanning enabled:
    [ ] Dependabot / Renovate configured
    [ ] Security alerts enabled
    [ ] Auto-merge for patch updates: [ ] YES  [ ] NO
[ ] Update cadence established:
    - Security: immediate
    - Patches: weekly
    - Minor: monthly
    - Major: quarterly review
[ ] Next scheduled update review: ___
```

## Output Format

Produce a dependency update plan with:
1. **Audit summary** (total dependencies, outdated count, vulnerability count)
2. **Update batches** (sequenced updates with risk classification)
3. **Breaking changes** (identified API changes requiring code updates)
4. **Testing results** (pass/fail per batch)
5. **Automation recommendations** (tooling and cadence)
