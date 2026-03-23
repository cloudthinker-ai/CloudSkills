---
name: pr-review-checklist
enabled: true
description: |
  Use when performing pr review checklist — structured pull request review
  checklist covering security, performance, testing, documentation, and code
  quality. Provides a comprehensive, consistent review framework to ensure
  thorough reviews across all engineering teams and prevent common issues from
  reaching production.
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
  - key: review_depth
    label: "Review Depth"
    required: false
    placeholder: "e.g., standard, thorough, quick"
features:
  - CODE_REVIEW
---

# PR Review Checklist Skill

Review PR **#{{ pr_number }}** in **{{ repository }}** at **{{ review_depth }}** depth.

## Workflow

### Phase 1 — Context Understanding

```
CONTEXT CHECK
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] PR description is clear and explains the "why"
[ ] Linked issue/ticket exists and matches the changes
[ ] Change scope is appropriate (not too large)
[ ] Branch is up to date with target branch
[ ] No unrelated changes bundled in
```

### Phase 2 — Code Quality

```
CODE QUALITY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Code is readable and self-documenting
[ ] Naming conventions followed (variables, functions, classes)
[ ] No dead code or commented-out code
[ ] DRY principle — no unnecessary duplication
[ ] Error handling is comprehensive
[ ] Edge cases are handled
[ ] No hardcoded values (use constants/config)
[ ] Logging is appropriate (not excessive, not missing)
```

### Phase 3 — Security

```
SECURITY CHECK
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] No secrets, keys, or credentials in code
[ ] Input validation present for user data
[ ] SQL injection prevention (parameterized queries)
[ ] XSS prevention (output encoding)
[ ] Authentication/authorization checks in place
[ ] Sensitive data not logged
[ ] Dependencies free of known CVEs
```

### Phase 4 — Performance

```
PERFORMANCE CHECK
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] No N+1 query patterns
[ ] Database queries are optimized (indexes used)
[ ] No unnecessary memory allocations
[ ] Caching considered where appropriate
[ ] No blocking operations in async paths
[ ] Pagination used for large data sets
```

### Phase 5 — Testing

```
TESTING CHECK
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Unit tests cover new/changed logic
[ ] Edge cases tested
[ ] Error scenarios tested
[ ] Integration tests for API/DB changes
[ ] Tests are deterministic (no flaky tests)
[ ] Test names clearly describe what they verify
[ ] Code coverage maintained or improved
```

### Phase 6 — Documentation

```
DOCUMENTATION CHECK
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Public APIs documented
[ ] Complex logic has explanatory comments
[ ] README updated if applicable
[ ] Migration guide provided for breaking changes
[ ] Changelog entry added if required
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

Produce a review summary with:
1. **Overall assessment** (approve / request changes / comment)
2. **Findings by category** (security, performance, testing, quality)
3. **Severity classification** (critical / major / minor / nitpick)
4. **Specific actionable feedback** for each finding
