---
name: monorepo-migration-guide
enabled: true
description: |
  Use when performing monorepo migration guide — step-by-step guide for
  migrating from multiple repositories to a monorepo structure. Covers
  repository consolidation strategy, history preservation, build system
  selection, CI/CD reconfiguration, code ownership setup, and dependency
  management to enable a successful monorepo transition.
required_connections:
  - prefix: github
    label: "GitHub"
config_fields:
  - key: target_monorepo
    label: "Target Monorepo Name"
    required: true
    placeholder: "e.g., org/platform"
  - key: source_repos
    label: "Source Repositories"
    required: true
    placeholder: "e.g., org/frontend, org/backend, org/shared-libs"
  - key: build_tool
    label: "Build Tool"
    required: false
    placeholder: "e.g., Turborepo, Nx, Bazel, Pants"
features:
  - ENGINEERING
  - ARCHITECTURE
---

# Monorepo Migration Guide Skill

Migrate **{{ source_repos }}** into monorepo **{{ target_monorepo }}** using **{{ build_tool }}**.

## Workflow

### Phase 1 — Assessment

```
REPOSITORY INVENTORY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Source repositories:
    Repo               | Language | Size   | Commits | Contributors
    ___________________|__________|________|_________|_____________
                       |          |        |         |
                       |          |        |         |
                       |          |        |         |

[ ] Shared dependencies identified: ___
[ ] Cross-repo dependencies mapped: ___
[ ] CI/CD pipelines to migrate: ___
[ ] Total git history size: ___ GB
```

### Phase 2 — Structure Design

```
MONOREPO LAYOUT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
{{ target_monorepo }}/
  packages/
    [ ] ___ (from repo: ___)
    [ ] ___ (from repo: ___)
    [ ] ___ (from repo: ___)
  libs/
    [ ] shared utilities
    [ ] common types/interfaces
  tools/
    [ ] build scripts
    [ ] code generators
  .github/
    [ ] workflows (consolidated CI/CD)
    [ ] CODEOWNERS

[ ] Package naming convention defined: ___
[ ] Import alias strategy defined: ___
[ ] Workspace configuration (package.json / go.work / etc.)
```

### Phase 3 — History Migration

```
GIT HISTORY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Strategy (choose one):
[ ] Preserve full history (git filter-repo + subtree merge)
[ ] Preserve history with path rewrite
[ ] Fresh start (squash history, archive originals)

For each repo:
[ ] ___ — history migrated to packages/___ [ ] VERIFIED
[ ] ___ — history migrated to packages/___ [ ] VERIFIED
[ ] ___ — history migrated to packages/___ [ ] VERIFIED

[ ] Tags and releases preserved
[ ] Blame history intact
[ ] No merge conflicts in consolidated history
```

### Phase 4 — Build System Setup

```
BUILD CONFIGURATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] {{ build_tool }} installed and configured
[ ] Task pipeline defined:
    - build -> test -> lint (dependency order)
[ ] Incremental builds working (only changed packages)
[ ] Dependency graph validated
[ ] Remote caching configured (if applicable)
[ ] Build times:
    - Full build: ___
    - Incremental build: ___
    - Affected-only build: ___
```

### Phase 5 — CI/CD Migration

```
CI/CD RECONFIGURATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] CI pipeline runs only affected packages on PR
[ ] CD pipeline deploys only changed services
[ ] CODEOWNERS file configured per package
[ ] Branch protection rules applied
[ ] PR checks scoped to affected packages
[ ] Release workflow supports per-package versioning
[ ] Artifact publishing configured per package
```

### Phase 6 — Validation and Cutover

```
VALIDATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] All packages build successfully
[ ] All tests pass in monorepo
[ ] CI/CD pipeline produces correct artifacts
[ ] Developer workflow documented:
    [ ] Setup instructions
    [ ] Common commands
    [ ] Troubleshooting guide
[ ] Original repos archived (read-only)
[ ] Redirect notices added to original repos
[ ] Team training completed
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

Produce a monorepo migration report with:
1. **Migration summary** (repos consolidated, history preserved, timeline)
2. **Structure overview** (monorepo layout, package map)
3. **Build performance** (full vs incremental build times)
4. **CI/CD configuration** (pipeline design, affected-only runs)
5. **Follow-up items** (developer training, documentation, optimization)
