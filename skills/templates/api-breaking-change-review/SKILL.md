---
name: api-breaking-change-review
enabled: true
description: |
  API backwards compatibility review template for detecting breaking changes in REST, GraphQL, and gRPC APIs. Covers endpoint modifications, schema changes, response format changes, deprecation policy enforcement, and versioning strategy validation to prevent disruption to API consumers.
required_connections:
  - prefix: github
    label: "GitHub"
config_fields:
  - key: repository
    label: "Repository"
    required: true
    placeholder: "e.g., org/api-service"
  - key: pr_number
    label: "PR Number"
    required: true
    placeholder: "e.g., 1234"
  - key: api_type
    label: "API Type"
    required: true
    placeholder: "e.g., REST, GraphQL, gRPC"
features:
  - CODE_REVIEW
---

# API Breaking Change Review Skill

Review PR **#{{ pr_number }}** in **{{ repository }}** for **{{ api_type }}** breaking changes.

## Workflow

### Phase 1 — Breaking Change Detection

```
BREAKING CHANGE ANALYSIS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Endpoint/field removal:
    [ ] No existing endpoints removed without deprecation
    [ ] No required fields removed from responses
    [ ] No existing enum values removed
[ ] Type changes:
    [ ] No response field type changes (string -> int)
    [ ] No narrowing of accepted input types
    [ ] No changes to nullable/required status
[ ] Behavioral changes:
    [ ] No changes to default values
    [ ] No changes to error codes for existing scenarios
    [ ] No changes to pagination behavior
    [ ] No changes to sorting/filtering defaults
[ ] Authentication/Authorization:
    [ ] No new auth requirements on existing endpoints
    [ ] No scope/permission changes for existing operations
```

### Phase 2 — Versioning Strategy

```
VERSIONING CHECK
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Versioning approach:
    - URL path versioning: /v1/, /v2/
    - Header versioning: Accept-Version
    - Query parameter: ?version=2
[ ] Version bump required: YES / NO
[ ] Previous version still supported: YES / NO
[ ] Version sunset timeline defined: ___
[ ] Consumer migration guide provided: YES / NO
```

### Phase 3 — Deprecation Policy

```
DEPRECATION REVIEW
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Deprecated items marked with:
    [ ] Deprecation header in responses
    [ ] Documentation annotation
    [ ] OpenAPI/schema deprecated flag
    [ ] Sunset date communicated
[ ] Deprecation timeline:
    - Deprecation announced: ___
    - Migration deadline: ___
    - Removal date: ___
[ ] Affected consumers notified: YES / NO
[ ] Usage metrics for deprecated endpoints: ___
```

### Phase 4 — Consumer Impact

```
CONSUMER IMPACT ASSESSMENT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Known consumers identified: ___
[ ] Consumer contract tests exist: YES / NO
[ ] Contract tests pass with changes: YES / NO
[ ] SDK updates required: YES / NO
[ ] Documentation updated: YES / NO
[ ] Changelog entry added: YES / NO
```

## Output Format

Produce a breaking change report with:
1. **Breaking changes found** (list with severity)
2. **Backwards-compatible alternatives** for each breaking change
3. **Versioning recommendation** (bump version or make additive)
4. **Consumer migration plan** if breaking changes are necessary
5. **API contract test results**
