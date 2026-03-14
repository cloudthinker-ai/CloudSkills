---
name: api-contract-review
enabled: true
description: |
  Provides a structured review checklist for evaluating API contracts including REST, gRPC, and GraphQL endpoints. This template covers naming conventions, versioning, error handling, pagination, authentication, rate limiting, and backward compatibility to ensure APIs meet organizational standards before launch.
required_connections:
  - prefix: api-docs
    label: "API Documentation Platform"
config_fields:
  - key: api_name
    label: "API Name"
    required: true
    placeholder: "e.g., Orders API v2"
  - key: api_type
    label: "API Type"
    required: true
    placeholder: "e.g., REST, gRPC, GraphQL"
  - key: api_spec_url
    label: "API Specification URL"
    required: false
    placeholder: "e.g., link to OpenAPI spec"
features:
  - API_REVIEW
  - CONTRACT
  - ARCHITECTURE
---

# API Contract Review

## Phase 1: General Design Review

Evaluate overall API design quality.

- [ ] API follows organizational naming conventions
- [ ] Resources/entities are named using nouns (REST)
- [ ] Consistent casing (camelCase, snake_case) throughout
- [ ] Versioning strategy defined (URL path, header, query param)
- [ ] API specification file exists (OpenAPI, protobuf, GraphQL schema)
- [ ] Description and documentation for all endpoints
- [ ] Examples provided for request/response bodies

## Phase 2: Endpoint Review

For each endpoint:

| Endpoint | Method | Auth | Rate Limited | Paginated | Idempotent | Cacheable |
|----------|--------|------|-------------|-----------|------------|-----------|
|          |        | Y/N  | Y/N         | Y/N       | Y/N        | Y/N       |

**Request Validation:**
- [ ] All inputs validated and documented
- [ ] Required vs optional fields clearly marked
- [ ] Input size limits defined
- [ ] Content type specified
- [ ] File upload limits defined (if applicable)

**Response Design:**
- [ ] Consistent response envelope structure
- [ ] Appropriate HTTP status codes used
- [ ] Response fields documented with types
- [ ] Nullable fields clearly marked
- [ ] No sensitive data leaked in responses

## Phase 3: Error Handling Review

- [ ] Error response format is consistent across all endpoints
- [ ] Error codes are documented and unique
- [ ] Error messages are helpful but do not leak internal details
- [ ] Validation errors return field-level details
- [ ] Rate limit errors include retry-after information

**Error Response Checklist:**

| Status Code | Usage | Error Code Defined | Message Template |
|-------------|-------|--------------------|------------------|
| 400 | Bad Request | | |
| 401 | Unauthorized | | |
| 403 | Forbidden | | |
| 404 | Not Found | | |
| 409 | Conflict | | |
| 422 | Unprocessable | | |
| 429 | Rate Limited | | |
| 500 | Internal Error | | |

## Phase 4: Backward Compatibility Assessment

- [ ] No existing fields removed
- [ ] No existing field types changed
- [ ] No required fields added to existing requests
- [ ] No response field semantics changed
- [ ] Deprecation notices added for fields being phased out
- [ ] Migration guide provided for breaking changes

**Breaking Change Checklist:**

| Change | Breaking? | Migration Path | Timeline |
|--------|-----------|----------------|----------|
|        | Y/N       |                |          |

## Phase 5: Security and Performance Review

**Security:**
- [ ] Authentication mechanism appropriate for use case
- [ ] Authorization checks documented (who can access what)
- [ ] Sensitive data not included in URLs or query parameters
- [ ] CORS configuration appropriate
- [ ] Input sanitization prevents injection attacks

**Performance:**
- [ ] Pagination implemented for list endpoints
- [ ] Response size is bounded
- [ ] Appropriate caching headers defined
- [ ] Bulk/batch endpoints available where needed
- [ ] Rate limits defined and documented

## Output Format

### Summary

- **API:** ___
- **Type:** ___
- **Endpoints reviewed:** ___
- **Issues found:** ___ (Critical: ___, High: ___, Medium: ___, Low: ___)
- **Backward compatible:** Y/N

### Action Items

- [ ] Fix all Critical and High issues before launch
- [ ] Address Medium issues before GA
- [ ] Update API specification with all findings
- [ ] Publish API documentation
- [ ] Set up contract testing
- [ ] Communicate breaking changes to consumers
