---
name: managing-split-io
description: |
  Use when working with Split Io — split.io feature flag management, targeting
  rules, traffic allocation, experimentation, and metric tracking. Covers split
  definitions, treatment configurations, segment management, impression
  tracking, and change history. Use when managing feature splits, reviewing
  targeting rules, analyzing experiment results, or auditing configuration
  changes in Split.io.
connection_type: split-io
preload: false
---

# Split.io Management Skill

Manage and analyze feature splits, targeting rules, segments, and experiments in Split.io.

## API Conventions

### Authentication
All API calls use the `Authorization: Bearer $SPLIT_API_KEY` header (Admin API key). Never hardcode tokens.

### Base URL
`https://api.split.io/internal/api/v2`

### Core Helper Function

```bash
#!/bin/bash

split_api() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"

    if [ -n "$data" ]; then
        curl -s -X "$method" \
            -H "Authorization: Bearer $SPLIT_API_KEY" \
            -H "Content-Type: application/json" \
            "https://api.split.io/internal/api/v2${endpoint}" \
            -d "$data"
    else
        curl -s -X "$method" \
            -H "Authorization: Bearer $SPLIT_API_KEY" \
            -H "Content-Type: application/json" \
            "https://api.split.io/internal/api/v2${endpoint}"
    fi
}
```

## Output Rules
- **TOKEN EFFICIENCY**: Extract only needed fields with `jq`
- Target <=50 lines per script output
- Never dump full API responses

## Discovery Phase

### List Workspaces and Environments

```bash
#!/bin/bash
echo "=== Workspaces ==="
split_api GET "/workspaces" \
    | jq -r '.objects[] | "\(.id)\t\(.name)"' | column -t

echo ""
WORKSPACE_ID="${1:?Workspace ID required}"
echo "=== Environments ==="
split_api GET "/workspaces/${WORKSPACE_ID}/environments" \
    | jq -r '.[] | "\(.id)\t\(.name)"' | column -t
```

### List Splits

```bash
#!/bin/bash
WORKSPACE_ID="${1:?Workspace ID required}"

echo "=== Splits ==="
split_api GET "/splits/ws/${WORKSPACE_ID}?limit=25" \
    | jq -r '.objects[] | "\(.trafficType.name)\t\(.name)\t\(.creationTime | todate | .[0:10])"' \
    | column -t

echo ""
echo "=== Split Summary ==="
split_api GET "/splits/ws/${WORKSPACE_ID}?limit=100" \
    | jq '{total: .totalCount, by_traffic_type: (.objects | group_by(.trafficType.name) | map({(.[0].trafficType.name): length}) | add)}'
```

## Analysis Phase

### Split Definition

```bash
#!/bin/bash
WORKSPACE_ID="${1:?Workspace ID required}"
ENVIRONMENT_ID="${2:?Environment ID required}"
SPLIT_NAME="${3:?Split name required}"

echo "=== Split Definition ==="
split_api GET "/splits/ws/${WORKSPACE_ID}/environments/${ENVIRONMENT_ID}/${SPLIT_NAME}" \
    | jq '{name, environment: .environment.name, killed: .killed, treatments: [.treatments[].name], defaultTreatment, rules: (.rules | length), defaultRule: .defaultRule}'
```

### Change History

```bash
#!/bin/bash
WORKSPACE_ID="${1:?Workspace ID required}"

echo "=== Recent Changes ==="
split_api GET "/splits/ws/${WORKSPACE_ID}/changelog?limit=20" \
    | jq -r '.objects[] | "\(.timestamp | todate | .[0:16])\t\(.operationType)\t\(.splitName)\t\(.email // "system")"' \
    | column -t

echo ""
echo "=== Segments ==="
split_api GET "/segments/ws/${WORKSPACE_ID}?limit=15" \
    | jq -r '.objects[] | "\(.name)\t\(.trafficType.name)"' | column -t
```

## Output Format
- Use tab-separated columns with `column -t`
- Limit lists to 15-25 items
- Show summaries before details

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
- **Workspace scoping**: Most endpoints require workspace ID in the path
- **Treatments**: Splits have named treatments (not just on/off) -- always list available treatments
- **Traffic types**: Splits are scoped to traffic types (user, account, etc.)
- **Kill switch**: Use `killed` status to emergency-disable a split without removing rules
- **Admin API key**: Management operations require Admin API key, not SDK key
- **Rate limits**: 10 requests per second for Admin API
