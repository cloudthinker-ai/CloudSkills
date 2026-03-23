---
name: api-versioning-strategy
enabled: true
description: |
  Use when performing api versioning strategy — template for defining and
  implementing API versioning strategies. Covers versioning scheme selection,
  backward compatibility analysis, migration path design, client communication
  planning, and deprecation timelines to manage API evolution without breaking
  existing consumers.
required_connections:
  - prefix: github
    label: "GitHub"
config_fields:
  - key: api_name
    label: "API Name"
    required: true
    placeholder: "e.g., Orders API"
  - key: current_version
    label: "Current Version"
    required: true
    placeholder: "e.g., v2"
  - key: new_version
    label: "New Version"
    required: true
    placeholder: "e.g., v3"
features:
  - DEVOPS
  - API_MANAGEMENT
---

# API Versioning Strategy Skill

Define versioning strategy for **{{ api_name }}** migration from **{{ current_version }}** to **{{ new_version }}**.

## Workflow

### Phase 1 — Current API Analysis

```
API INVENTORY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] API name: {{ api_name }}
[ ] Current version: {{ current_version }}
[ ] Endpoints in current version: ___
[ ] Active consumers:
    - Internal services: ___
    - External partners: ___
    - Public clients: ___
[ ] Request volume (daily): ___
[ ] SLA commitments: ___
```

### Phase 2 — Versioning Scheme

```
VERSIONING APPROACH
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Select versioning method:
[ ] URL path versioning: /{{ new_version }}/resource
[ ] Header versioning: Accept: application/vnd.api.{{ new_version }}+json
[ ] Query parameter: ?version={{ new_version }}
[ ] Content negotiation

DECISION MATRIX
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Factor              | URL Path | Header  | Query Param
Discoverability     | HIGH     | LOW     | MEDIUM
Cache-friendliness  | HIGH     | LOW     | HIGH
Client simplicity   | HIGH     | MEDIUM  | HIGH
RESTful purity      | LOW      | HIGH    | LOW
Current approach    | [ ]      | [ ]     | [ ]

Selected approach: ___
Justification: ___
```

### Phase 3 — Breaking Changes Analysis

```
BREAKING CHANGES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Document all changes from {{ current_version }} to {{ new_version }}:

Endpoint changes:
- Added: ___
- Modified: ___
- Removed: ___

Schema changes:
- Fields added: ___
- Fields renamed: ___
- Fields removed: ___
- Type changes: ___

Behavior changes:
- Pagination: ___
- Error format: ___
- Authentication: ___
- Rate limits: ___

Backward-compatible changes (no version bump needed):
- ___
```

### Phase 4 — Migration Path

```
CLIENT MIGRATION PLAN
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Migration guide documentation written
[ ] SDK updated for {{ new_version }}
[ ] Code examples provided for each breaking change
[ ] Migration timeline:
    - {{ new_version }} available: ___
    - {{ current_version }} deprecated: ___
    - {{ current_version }} sunset: ___
    - Parallel support window: ___ months
[ ] Client communication:
    [ ] Changelog published
    [ ] Email notification to API consumers
    [ ] Developer portal updated
    [ ] Migration support channel created
```

### Phase 5 — Implementation

```
IMPLEMENTATION CHECKLIST
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] {{ new_version }} endpoints implemented
[ ] {{ current_version }} routing still functional
[ ] Version-aware middleware/gateway configured
[ ] API documentation updated (OpenAPI/Swagger)
[ ] Integration tests cover both versions
[ ] Monitoring tracks per-version metrics:
    - Request volume by version
    - Error rates by version
    - Latency by version
[ ] Deprecation headers added to {{ current_version }} responses
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

Produce an API versioning strategy document with:
1. **Version summary** (current state, changes, new version)
2. **Versioning scheme** (selected approach with rationale)
3. **Breaking changes catalog** (complete list with migration steps)
4. **Timeline** (availability, deprecation, sunset dates)
5. **Client communication plan** (channels, schedule, support)
