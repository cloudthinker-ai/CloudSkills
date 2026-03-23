---
name: technical-debt-assessment
enabled: true
description: |
  Use when performing technical debt assessment — template for systematically
  identifying, categorizing, and prioritizing technical debt across a codebase
  or system. Covers code quality metrics, architecture smells, dependency risks,
  test coverage gaps, and creates a prioritized remediation backlog with
  business impact analysis.
required_connections:
  - prefix: github
    label: "GitHub"
config_fields:
  - key: repository
    label: "Repository"
    required: true
    placeholder: "e.g., org/payment-service"
  - key: assessment_scope
    label: "Assessment Scope"
    required: true
    placeholder: "e.g., full codebase, backend module, data layer"
features:
  - ENGINEERING
  - CODE_QUALITY
---

# Technical Debt Assessment Skill

Assess technical debt in **{{ repository }}** — scope: **{{ assessment_scope }}**.

## Workflow

### Phase 1 — Code Quality Metrics

```
CODE METRICS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Lines of code: ___
[ ] Cyclomatic complexity (average): ___
[ ] Files with complexity > 20: ___
[ ] Duplicated code blocks: ___
[ ] Code smells (linter warnings): ___
[ ] Test coverage: ___%
[ ] Files with 0% coverage: ___
[ ] TODO/HACK/FIXME comments: ___
[ ] Dead code identified: ___ files / ___ functions
```

### Phase 2 — Architecture Assessment

```
ARCHITECTURE DEBT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Circular dependencies: ___
[ ] God classes/modules (> 500 lines): ___
[ ] Tight coupling indicators:
    - Direct database access outside data layer: ___
    - Hard-coded service URLs: ___
    - Shared mutable state: ___
[ ] Missing abstractions:
    - ___
    - ___
[ ] Inconsistent patterns:
    - ___
    - ___
[ ] Deprecated patterns still in use: ___
```

### Phase 3 — Dependency Health

```
DEPENDENCY ANALYSIS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Total dependencies: ___
[ ] Outdated dependencies:
    - Major version behind: ___
    - Minor version behind: ___
    - Patch version behind: ___
[ ] Dependencies with known vulnerabilities: ___
    - Critical: ___
    - High: ___
    - Medium: ___
[ ] Unmaintained dependencies (no release in 12+ months): ___
[ ] License compliance issues: ___
```

### Phase 4 — Testing Gaps

```
TEST DEBT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Unit test coverage: ___%
[ ] Integration test coverage: ___%
[ ] Critical paths without tests:
    - ___
    - ___
[ ] Flaky tests: ___
[ ] Slow tests (> 10s): ___
[ ] Missing test categories:
    [ ] Contract tests
    [ ] Load tests
    [ ] Security tests
    [ ] Chaos tests
```

### Phase 5 — Debt Categorization

```
TECHNICAL DEBT INVENTORY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Category        | Items | Severity | Business Impact | Effort
━━━━━━━━━━━━━━━━|━━━━━━━|━━━━━━━━━━|━━━━━━━━━━━━━━━━━|━━━━━━
Code quality    |       |          |                 |
Architecture    |       |          |                 |
Dependencies    |       |          |                 |
Testing         |       |          |                 |
Documentation   |       |          |                 |
Infrastructure  |       |          |                 |
Security        |       |          |                 |

PRIORITY MATRIX
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                High Business Impact   Low Business Impact
High Effort   | PLAN (schedule)       | DEFER
Low Effort    | DO NOW                | BATCH (group with other work)
```

### Phase 6 — Remediation Backlog

```
PRIORITIZED REMEDIATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Sprint 1 (Quick Wins):
[ ] ___  — effort: ___  impact: ___
[ ] ___  — effort: ___  impact: ___

Sprint 2-3 (Planned Work):
[ ] ___  — effort: ___  impact: ___
[ ] ___  — effort: ___  impact: ___

Quarterly Goals:
[ ] ___  — effort: ___  impact: ___
[ ] ___  — effort: ___  impact: ___

Tracked but Deferred:
[ ] ___  — reason: ___
[ ] ___  — reason: ___
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

Produce a technical debt assessment report with:
1. **Debt summary** (total items, severity distribution, debt score)
2. **Category breakdown** (code, architecture, dependencies, testing)
3. **Priority matrix** (impact vs effort classification)
4. **Remediation backlog** (prioritized action items with estimates)
5. **Recommendations** (process changes to prevent future debt accumulation)
