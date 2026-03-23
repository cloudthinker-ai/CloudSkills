---
name: managing-sanity
description: |
  Use when working with Sanity — sanity.io headless CMS management covering
  dataset inventory, document type analysis, GROQ query monitoring, asset
  management, webhook tracking, and project member auditing. Use when reviewing
  content schemas, investigating query performance, monitoring content
  publishing, or auditing project access and API token usage.
connection_type: sanity
preload: false
---

# Sanity Management Skill

Manage and monitor Sanity.io projects, datasets, documents, assets, and webhooks.

## MANDATORY: Discovery-First Pattern

**Always list datasets and document types before querying specific documents.**

### Phase 1: Discovery

```bash
#!/bin/bash

SANITY_API="https://${SANITY_PROJECT_ID}.api.sanity.io/v2024-01-01"
SANITY_MGMT="https://api.sanity.io/v2024-01-01"

sanity_api() {
    curl -s -H "Authorization: Bearer $SANITY_API_TOKEN" \
         -H "Content-Type: application/json" \
         "${SANITY_API}/${1}"
}

sanity_mgmt() {
    curl -s -H "Authorization: Bearer $SANITY_API_TOKEN" \
         -H "Content-Type: application/json" \
         "${SANITY_MGMT}/${1}"
}

echo "=== Project Info ==="
sanity_mgmt "projects/${SANITY_PROJECT_ID}" | jq '{
    displayName: .displayName,
    organizationId: .organizationId,
    studioHost: .studioHost,
    createdAt: .createdAt
}'

echo ""
echo "=== Datasets ==="
sanity_mgmt "projects/${SANITY_PROJECT_ID}/datasets" | jq -r '
    .[] |
    "\(.name)\t\(.aclMode)"
' | column -t

echo ""
echo "=== Document Types ==="
DATASET="${SANITY_DATASET:-production}"
sanity_api "data/query/${DATASET}?query=*%5B%5D%7B_type%7D%20%7C%20order(_type)%20%5B0...500%5D" | jq -r '
    .result | group_by(._type) | map({type: .[0]._type, count: length}) |
    sort_by(-.count)[] |
    "\(.type)\t\(.count) docs"
' | column -t | head -25
```

### Phase 2: Analysis

```bash
#!/bin/bash

DATASET="${SANITY_DATASET:-production}"

echo "=== Draft Documents ==="
sanity_api "data/query/${DATASET}?query=*%5B_id%20in%20path(%22drafts.**%22)%5D%20%7C%20order(_updatedAt%20desc)%20%5B0...15%5D%7B_id%2C_type%2C_updatedAt%7D" | jq -r '
    .result[] |
    "\(._type)\t\(._id)\t\(._updatedAt[:10])"
' | column -t | head -15

echo ""
echo "=== Recent Changes ==="
sanity_api "data/query/${DATASET}?query=*%20%7C%20order(_updatedAt%20desc)%20%5B0...10%5D%7B_id%2C_type%2C_updatedAt%2C_createdAt%7D" | jq -r '
    .result[] |
    "\(._type)\t\(._id[:30])\t\(._updatedAt[:16])"
' | column -t

echo ""
echo "=== Assets ==="
sanity_api "data/query/${DATASET}?query=count(*%5B_type%20%3D%3D%20%22sanity.imageAsset%22%5D)" | jq '{image_assets: .result}'
sanity_api "data/query/${DATASET}?query=count(*%5B_type%20%3D%3D%20%22sanity.fileAsset%22%5D)" | jq '{file_assets: .result}'

echo ""
echo "=== Webhooks ==="
sanity_mgmt "hooks/projects/${SANITY_PROJECT_ID}" | jq -r '
    .[] |
    "\(.id)\t\(.name)\t\(.isDisabled // false)\t\(.dataset // "*")"
' | column -t

echo ""
echo "=== Project Members ==="
sanity_mgmt "projects/${SANITY_PROJECT_ID}/members" | jq -r '
    .[] |
    "\(.id)\t\(.role)\t\(.isRobot // false)"
' | column -t | head -15
```

## Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- Use GROQ queries with projections to limit returned fields
- Never dump full document content -- extract _type, _id, and timestamps

## Output Format

Present results as a structured report:
```
Managing Sanity Report
══════════════════════
Resources discovered: [count]

Resource       Status    Key Metric    Issues
──────────────────────────────────────────────
[name]         [ok/warn] [value]       [findings]

Summary: [total] resources | [ok] healthy | [warn] warnings | [crit] critical
Action Items: [list of prioritized findings]
```

Target ≤50 lines of output. Use tables for multi-resource comparisons.

## Anti-Hallucination Rules

1. **NEVER assume resource names** — always discover via CLI/API in Phase 1 before referencing in Phase 2.
2. **NEVER fabricate metric names or dimensions** — verify against the service documentation or `--help` output.
3. **NEVER mix CLI commands between service versions** — confirm which version/API you are targeting.
4. **ALWAYS use the discovery → verify → analyze chain** — every resource referenced must have been discovered first.
5. **ALWAYS handle empty results gracefully** — an empty response is valid data, not an error to retry.

## Counter-Rationalizations

| Shortcut | Counter | Why |
|----------|---------|-----|
| "I'll skip discovery and check known resources" | Always run Phase 1 discovery first | Resource names change, new resources appear — assumed names cause errors |
| "The user only asked for a quick check" | Follow the full discovery → analysis flow | Quick checks miss critical issues; structured analysis catches silent failures |
| "Default configuration is probably fine" | Audit configuration explicitly | Defaults often leave logging, security, and optimization features disabled |
| "Metrics aren't needed for this" | Always check relevant metrics when available | API/CLI responses show current state; metrics reveal trends and intermittent issues |
| "I don't have access to that" | Try the command and report the actual error | Assumed permission failures prevent useful investigation; actual errors are informative |

## Common Pitfalls

- **Draft prefix**: Drafts have _id prefixed with "drafts." -- they are separate documents from published
- **Dataset isolation**: Datasets are fully isolated -- ensure querying the correct dataset
- **GROQ injection**: User-supplied GROQ parameters should be sanitized
- **CDN caching**: API CDN may serve stale data -- use the non-CDN endpoint for real-time queries
- **Webhook reliability**: Webhooks can be delayed during high-write periods -- do not rely on ordering
- **Token scopes**: Tokens can be scoped to specific datasets and permissions -- verify token access
- **Real-time listeners**: Listener connections consume resources -- monitor active listener count
