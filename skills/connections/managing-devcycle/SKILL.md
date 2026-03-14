---
name: managing-devcycle
description: |
  DevCycle feature flag management, targeting rules, environments, variable management, and usage metrics. Covers feature creation, variation configuration, targeting rules, audience segments, and API usage tracking. Use when managing feature flags, configuring targeting rules, reviewing variable usage, or analyzing feature adoption in DevCycle.
connection_type: devcycle
preload: false
---

# DevCycle Management Skill

Manage and analyze features, variables, environments, and targeting rules in DevCycle.

## API Conventions

### Authentication
All API calls use the `Authorization: Bearer $DEVCYCLE_API_KEY` header (Management API token). Never hardcode tokens.

### Base URL
`https://api.devcycle.com/v1`

### Core Helper Function

```bash
#!/bin/bash

dvc_api() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"

    if [ -n "$data" ]; then
        curl -s -X "$method" \
            -H "Authorization: Bearer $DEVCYCLE_API_KEY" \
            -H "Content-Type: application/json" \
            "https://api.devcycle.com/v1${endpoint}" \
            -d "$data"
    else
        curl -s -X "$method" \
            -H "Authorization: Bearer $DEVCYCLE_API_KEY" \
            -H "Content-Type: application/json" \
            "https://api.devcycle.com/v1${endpoint}"
    fi
}
```

## Output Rules
- **TOKEN EFFICIENCY**: Extract only needed fields with `jq`
- Target <=50 lines per script output
- Never dump full API responses

## Discovery Phase

### List Projects and Environments

```bash
#!/bin/bash
echo "=== Projects ==="
dvc_api GET "/projects" \
    | jq -r '.[] | "\(.key)\t\(.name)\t\(.settings.sdkTypeVisibility // "all")"' | column -t

echo ""
PROJECT_KEY="${1:?Project key required}"
echo "=== Environments ==="
dvc_api GET "/projects/${PROJECT_KEY}/environments" \
    | jq -r '.[] | "\(.key)\t\(.name)\t\(.type)"' | column -t
```

### List Features

```bash
#!/bin/bash
PROJECT_KEY="${1:?Project key required}"

echo "=== Features ==="
dvc_api GET "/projects/${PROJECT_KEY}/features?perPage=25" \
    | jq -r '.[] | "\(.type)\t\(.key)\t\(.name[0:40])\t\(.status)"' | column -t

echo ""
echo "=== Variables ==="
dvc_api GET "/projects/${PROJECT_KEY}/variables?perPage=25" \
    | jq -r '.[] | "\(.type)\t\(.key)\t\(.feature.name[0:30] // "none")"' | column -t
```

## Analysis Phase

### Feature Detail

```bash
#!/bin/bash
PROJECT_KEY="${1:?Project key required}"
FEATURE_KEY="${2:?Feature key required}"

echo "=== Feature Details ==="
dvc_api GET "/projects/${PROJECT_KEY}/features/${FEATURE_KEY}" \
    | jq '{key, name, type, status, variations: [.variations[].key], variables: [.variables[].key]}'

echo ""
echo "=== Targeting Rules ==="
dvc_api GET "/projects/${PROJECT_KEY}/features/${FEATURE_KEY}/configurations" \
    | jq -r '.[] | "\(.environment.key)\t\(.status)\t\(.targets | length) targets"' | column -t
```

### Feature Overview

```bash
#!/bin/bash
PROJECT_KEY="${1:?Project key required}"

echo "=== Feature Status Summary ==="
dvc_api GET "/projects/${PROJECT_KEY}/features?perPage=100" \
    | jq '{
        total: length,
        by_status: (group_by(.status) | map({(.[0].status): length}) | add),
        by_type: (group_by(.type) | map({(.[0].type): length}) | add)
    }'

echo ""
echo "=== Recently Modified ==="
dvc_api GET "/projects/${PROJECT_KEY}/features?perPage=10&sortBy=updatedAt&sortOrder=desc" \
    | jq -r '.[] | "\(.updatedAt[0:16])\t\(.key)\t\(.status)"' | column -t
```

## Output Format
- Use tab-separated columns with `column -t`
- Limit lists to 15-25 items
- Show summaries before details

## Common Pitfalls
- **Management vs SDK API**: Management API for flag configuration; SDK API for flag evaluation
- **Feature types**: `release`, `experiment`, `permission`, `ops`
- **Feature statuses**: `active`, `inactive`, `archived`
- **Variables vs features**: Features contain variables -- variables are the actual values evaluated by SDKs
- **Targeting**: Targets use audience filters with AND/OR logic and custom properties
- **Pagination**: Use `perPage` and `page` query parameters
