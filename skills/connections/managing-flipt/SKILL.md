---
name: managing-flipt
description: |
  Flipt feature flag management, segment-based targeting, rule configuration, and namespace organization. Covers flag and variant management, segment constraints, distribution rules, rollout percentages, and audit logging. Use when managing feature flags, configuring targeting segments, reviewing flag evaluations, or auditing changes in Flipt.
connection_type: flipt
preload: false
---

# Flipt Management Skill

Manage and analyze feature flags, segments, rules, and namespaces in Flipt.

## API Conventions

### Authentication
All API calls use the `Authorization: Bearer $FLIPT_API_KEY` header. Never hardcode tokens.

### Base URL
`$FLIPT_URL/api/v1` (self-hosted, typically `http://localhost:8080/api/v1`)

### Core Helper Function

```bash
#!/bin/bash

FLIPT_BASE="${FLIPT_URL:-http://localhost:8080}"

flipt_api() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"

    if [ -n "$data" ]; then
        curl -s -X "$method" \
            -H "Authorization: Bearer $FLIPT_API_KEY" \
            -H "Content-Type: application/json" \
            "${FLIPT_BASE}/api/v1${endpoint}" \
            -d "$data"
    else
        curl -s -X "$method" \
            -H "Authorization: Bearer $FLIPT_API_KEY" \
            -H "Content-Type: application/json" \
            "${FLIPT_BASE}/api/v1${endpoint}"
    fi
}
```

## Output Rules
- **TOKEN EFFICIENCY**: Extract only needed fields with `jq`
- Target <=50 lines per script output
- Never dump full API responses

## Discovery Phase

### List Namespaces and Flags

```bash
#!/bin/bash
echo "=== Namespaces ==="
flipt_api GET "/namespaces" \
    | jq -r '.namespaces[] | "\(.key)\t\(.name)\t\(.description[0:40])"' | column -t

echo ""
NAMESPACE="${1:-default}"
echo "=== Flags in ${NAMESPACE} ==="
flipt_api GET "/namespaces/${NAMESPACE}/flags" \
    | jq -r '.flags[] | "\(.type)\t\(.key)\t\(.enabled)\t\(.name[0:40])"' | column -t | head -25
```

### List Segments

```bash
#!/bin/bash
NAMESPACE="${1:-default}"

echo "=== Segments ==="
flipt_api GET "/namespaces/${NAMESPACE}/segments" \
    | jq -r '.segments[] | "\(.key)\t\(.name)\t\(.matchType)\t\(.constraints | length) constraints"' \
    | column -t | head -20
```

## Analysis Phase

### Flag Details and Rules

```bash
#!/bin/bash
NAMESPACE="${1:-default}"
FLAG_KEY="${2:?Flag key required}"

echo "=== Flag Details ==="
flipt_api GET "/namespaces/${NAMESPACE}/flags/${FLAG_KEY}" \
    | jq '{key, name, type, enabled, variants: [.variants[].key]}'

echo ""
echo "=== Rules ==="
flipt_api GET "/namespaces/${NAMESPACE}/flags/${FLAG_KEY}/rules" \
    | jq -r '.rules[] | "\(.rank)\t\(.segmentKey)\t\(.distributions | map("\(.variant.key):\(.rollout)%") | join(", "))"' \
    | column -t

echo ""
echo "=== Rollouts (boolean flags) ==="
flipt_api GET "/namespaces/${NAMESPACE}/flags/${FLAG_KEY}/rollouts" \
    | jq -r '.rules[] | "\(.rank)\t\(.type)\t\(.segment.segmentKey // "threshold")\t\(.threshold.percentage // "segment-based")%"' \
    | column -t 2>/dev/null
```

### Audit Overview

```bash
#!/bin/bash
NAMESPACE="${1:-default}"

echo "=== Flag Summary ==="
flipt_api GET "/namespaces/${NAMESPACE}/flags" \
    | jq '{
        total: (.flags | length),
        enabled: ([.flags[] | select(.enabled)] | length),
        disabled: ([.flags[] | select(.enabled | not)] | length),
        by_type: (.flags | group_by(.type) | map({(.[0].type): length}) | add)
    }'

echo ""
echo "=== Segments Summary ==="
flipt_api GET "/namespaces/${NAMESPACE}/segments" \
    | jq -r '.segments[] | "\(.key)\t\(.matchType)\t\(.constraints | length) constraints"' | column -t | head -10
```

## Output Format
- Use tab-separated columns with `column -t`
- Limit lists to 15-25 items
- Show summaries before details

## Common Pitfalls
- **Self-hosted**: Base URL varies per installation -- always use `$FLIPT_URL` env variable
- **Flag types**: `VARIANT_FLAG_TYPE` (multi-variant) and `BOOLEAN_FLAG_TYPE` (simple on/off)
- **Namespaces**: Flags and segments are scoped to namespaces -- default namespace is `default`
- **Match types**: Segments use `ALL_MATCH_TYPE` (AND) or `ANY_MATCH_TYPE` (OR) for constraints
- **Rules vs rollouts**: Variant flags use rules with distributions; boolean flags use rollouts
- **GitOps support**: Flipt supports declarative flag management via YAML files
