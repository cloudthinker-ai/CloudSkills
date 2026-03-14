---
name: code-review-guidelines
enabled: true
description: |
  Structured code review template covering correctness, security, performance, maintainability, and testing. Provides a consistent review checklist, severity classification, and feedback framework to ensure thorough reviews and constructive feedback across engineering teams.
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
  - key: review_focus
    label: "Review Focus Area"
    required: false
    placeholder: "e.g., security, performance, general"
features:
  - ENGINEERING
  - CODE_QUALITY
---

# Code Review Guidelines Skill

Review PR **#{{ pr_number }}** in **{{ repository }}** with focus on **{{ review_focus }}**.

## Workflow

### Phase 1 — PR Context

```
PR OVERVIEW
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] PR title and description reviewed
[ ] Linked issue/ticket understood
[ ] Change scope assessed:
    - Files changed: ___
    - Lines added: ___
    - Lines removed: ___
[ ] PR size classification:
    [ ] Small (< 200 lines) — full review
    [ ] Medium (200-500 lines) — structured review
    [ ] Large (> 500 lines) — consider splitting
```

### Phase 2 — Correctness Review

```
CORRECTNESS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Logic is correct and matches requirements
[ ] Edge cases handled:
    [ ] Null/undefined inputs
    [ ] Empty collections
    [ ] Boundary values
    [ ] Concurrent access
[ ] Error handling is appropriate:
    [ ] Errors are caught at the right level
    [ ] Error messages are informative
    [ ] Errors do not leak sensitive information
[ ] Data validation present for external inputs
[ ] State management is consistent
[ ] No off-by-one errors
```

### Phase 3 — Security Review

```
SECURITY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] No hardcoded secrets, credentials, or API keys
[ ] Input sanitization for user-provided data
[ ] SQL injection prevention (parameterized queries)
[ ] XSS prevention (output encoding)
[ ] Authentication/authorization checks in place
[ ] Sensitive data not logged
[ ] Dependencies do not introduce known vulnerabilities
[ ] CORS configuration appropriate
```

### Phase 4 — Performance Review

```
PERFORMANCE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] No N+1 query patterns
[ ] Database queries are indexed appropriately
[ ] No unnecessary data fetching (over-fetching)
[ ] Caching considered where appropriate
[ ] No blocking operations on hot paths
[ ] Memory allocation patterns reasonable
[ ] No resource leaks (connections, file handles)
[ ] Pagination implemented for list endpoints
```

### Phase 5 — Maintainability Review

```
MAINTAINABILITY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Code is readable and self-documenting
[ ] Naming conventions followed
[ ] No unnecessary complexity
[ ] DRY principle applied (no copy-paste code)
[ ] Functions/methods are focused (single responsibility)
[ ] Comments explain "why" not "what"
[ ] No dead code introduced
[ ] Consistent with existing codebase patterns
```

### Phase 6 — Testing Review

```
TESTING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Unit tests cover new logic
[ ] Edge cases tested
[ ] Integration tests for API changes
[ ] Test assertions are specific (not just "no error")
[ ] Tests are independent and repeatable
[ ] No flaky test patterns introduced
[ ] Test coverage maintained or improved
[ ] Manual testing instructions provided (if applicable)
```

### Phase 7 — Review Summary

```
REVIEW DECISION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Decision: [ ] APPROVE  [ ] REQUEST CHANGES  [ ] COMMENT

SEVERITY CLASSIFICATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Critical (must fix):
- ___

Major (should fix):
- ___

Minor (nice to have):
- ___

Nitpick (optional):
- ___
```

## Output Format

Produce a code review summary with:
1. **PR overview** (scope, risk level, change type)
2. **Findings** by severity (critical, major, minor, nitpick)
3. **Security assessment** (any vulnerabilities found)
4. **Performance assessment** (any concerns identified)
5. **Recommendation** (approve, request changes, or needs discussion)
