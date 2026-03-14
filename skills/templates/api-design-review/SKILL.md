---
name: api-design-review
enabled: true
description: |
  Structured review template for evaluating API designs before implementation. Covers RESTful conventions, naming consistency, error handling patterns, pagination strategy, versioning, security considerations, and documentation completeness to ensure APIs are intuitive and maintainable.
required_connections:
  - prefix: github
    label: "GitHub"
config_fields:
  - key: api_name
    label: "API Name"
    required: true
    placeholder: "e.g., Customer Management API"
  - key: api_spec_url
    label: "API Spec URL or Path"
    required: true
    placeholder: "e.g., docs/openapi/customers.yaml"
  - key: api_style
    label: "API Style"
    required: false
    placeholder: "e.g., REST, GraphQL, gRPC"
features:
  - ENGINEERING
  - API_MANAGEMENT
---

# API Design Review Skill

Review the design of **{{ api_name }}** ({{ api_style }}) from spec at **{{ api_spec_url }}**.

## Workflow

### Phase 1 — API Overview Assessment

```
API SUMMARY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] API purpose and domain clearly defined
[ ] Target consumers identified:
    - Internal services: ___
    - External partners: ___
    - Public developers: ___
[ ] Endpoints/operations count: ___
[ ] Resources/entities modeled: ___
[ ] API style: {{ api_style }}
```

### Phase 2 — Resource Design

```
RESOURCE MODELING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Resources represent domain nouns (not verbs)
[ ] Resource naming is consistent:
    [ ] Plural nouns for collections
    [ ] Lowercase with hyphens
    [ ] No unnecessary nesting (max 2 levels)
[ ] Resource relationships clearly expressed
[ ] Sub-resources vs. independent resources appropriate
[ ] Resource identifiers are opaque and stable

NAMING CONSISTENCY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Convention      | Consistent | Issues
Field casing    | [ ]        | ___
Date formats    | [ ]        | ___
Enum values     | [ ]        | ___
ID field naming | [ ]        | ___
```

### Phase 3 — Operations Review

```
HTTP METHODS / OPERATIONS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] GET for reads (no side effects)
[ ] POST for creation (returns 201)
[ ] PUT/PATCH for updates (PUT full, PATCH partial)
[ ] DELETE for removal (idempotent)
[ ] No state changes via GET
[ ] Idempotency considered for POST operations
[ ] Bulk operations provided where needed

STATUS CODES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] 200/201/204 used correctly for success
[ ] 400 for client validation errors
[ ] 401 for authentication failures
[ ] 403 for authorization failures
[ ] 404 for not found
[ ] 409 for conflicts
[ ] 429 for rate limiting
[ ] 500 reserved for unexpected server errors
```

### Phase 4 — Error Handling

```
ERROR RESPONSE FORMAT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Consistent error response structure defined
[ ] Error responses include:
    [ ] Machine-readable error code
    [ ] Human-readable message
    [ ] Field-level validation details
    [ ] Request correlation ID
[ ] Error codes are documented and stable
[ ] No sensitive information leaked in errors
[ ] Validation errors return all failures (not just first)
```

### Phase 5 — Pagination, Filtering, and Sorting

```
COLLECTION HANDLING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Pagination implemented for all list endpoints:
    [ ] Cursor-based (preferred for large datasets)
    [ ] Offset-based (simpler, acceptable for small sets)
[ ] Default and maximum page sizes defined
[ ] Filtering parameters are consistent
[ ] Sorting parameters are consistent
[ ] Total count available (or indicated if unavailable)
[ ] Link headers or next/prev cursors provided
```

### Phase 6 — Security Review

```
SECURITY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Authentication method defined (OAuth2, API key, JWT)
[ ] Authorization model documented (RBAC, ABAC, scopes)
[ ] Rate limiting strategy defined
[ ] Input validation rules specified
[ ] Sensitive fields identified and handled:
    [ ] PII fields masked in logs
    [ ] Sensitive fields excluded from list responses
[ ] CORS policy appropriate for consumers
[ ] HTTPS enforced
```

## Output Format

Produce an API design review report with:
1. **Design summary** (API purpose, style, scope)
2. **Compliance scorecard** (REST conventions, naming, consistency)
3. **Issues found** by severity (blocking, major, minor)
4. **Recommendations** (specific changes with examples)
5. **Approval status** (APPROVED / REVISIONS NEEDED)
