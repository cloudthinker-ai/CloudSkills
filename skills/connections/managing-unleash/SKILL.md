---
name: managing-unleash
description: |
  Unleash feature toggle management, activation strategies, environment configuration, and usage metrics. Covers toggle lifecycle, gradual rollout strategies, constraint-based targeting, project management, and API token administration. Use when managing feature toggles, configuring rollout strategies, reviewing toggle usage, or auditing changes in Unleash.
connection_type: unleash
preload: false
---

# Unleash Management Skill

Manage and analyze feature toggles, strategies, projects, and environments in Unleash.

## API Conventions

### Authentication
All API calls use the `Authorization: $UNLEASH_API_KEY` header (admin token). Never hardcode tokens.

### Base URL
`$UNLEASH_URL/api` (self-hosted or Unleash-hosted)

### Core Helper Function

```bash
#!/bin/bash

UNLEASH_BASE="${UNLEASH_URL:-https://app.unleash-hosted.com}"

unleash_api() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"

    if [ -n "$data" ]; then
        curl -s -X "$method" \
            -H "Authorization: $UNLEASH_API_KEY" \
            -H "Content-Type: application/json" \
            "${UNLEASH_BASE}/api${endpoint}" \
            -d "$data"
    else
        curl -s -X "$method" \
            -H "Authorization: $UNLEASH_API_KEY" \
            -H "Content-Type: application/json" \
            "${UNLEASH_BASE}/api${endpoint}"
    fi
}
```

## Output Rules
- **TOKEN EFFICIENCY**: Extract only needed fields with `jq`
- Target <=50 lines per script output
- Never dump full API responses

## Discovery Phase

### List Projects and Toggles

```bash
#!/bin/bash
echo "=== Projects ==="
unleash_api GET "/admin/projects" \
    | jq -r '.projects[] | "\(.id)\t\(.name)\t\(.featureCount) toggles"' | column -t

echo ""
PROJECT_ID="${1:-default}"
echo "=== Feature Toggles ==="
unleash_api GET "/admin/projects/${PROJECT_ID}/features" \
    | jq -r '.features[0:25][] | "\(.type)\t\(.name)\t\(.enabled)\t\(.stale)"' | column -t
```

### List Environments

```bash
#!/bin/bash
echo "=== Environments ==="
unleash_api GET "/admin/environments" \
    | jq -r '.environments[] | "\(.name)\t\(.type)\t\(.enabled)"' | column -t

echo ""
echo "=== Strategies ==="
unleash_api GET "/admin/strategies" \
    | jq -r '.strategies[] | "\(.name)\t\(.editable)\t\(.description[0:50])"' | column -t
```

## Analysis Phase

### Toggle Status by Environment

```bash
#!/bin/bash
PROJECT_ID="${1:-default}"

echo "=== Toggle Status ==="
unleash_api GET "/admin/projects/${PROJECT_ID}/features" \
    | jq -r '.features[0:20][] | "\(.name)\t" + ([.environments[] | "\(.name):\(.enabled)"] | join("\t"))' \
    | column -t

echo ""
echo "=== Stale Toggles ==="
unleash_api GET "/admin/projects/${PROJECT_ID}/features" \
    | jq -r '.features[] | select(.stale == true) | "\(.name)\t\(.type)\tcreated:\(.createdAt[0:10])"' | column -t | head -10
```

### Event Log

```bash
#!/bin/bash
echo "=== Recent Events ==="
unleash_api GET "/admin/events?limit=20" \
    | jq -r '.events[] | "\(.createdAt[0:16])\t\(.createdBy)\t\(.type)\t\(.data.name // .featureName // "")"' \
    | column -t

echo ""
echo "=== Toggle Metrics ==="
TOGGLE_NAME="${1:?Toggle name required}"
unleash_api GET "/admin/client-metrics/features/${TOGGLE_NAME}" \
    | jq '{name: .featureName, lastHourRequests: .lastHourUsage | map(.yes + .no) | add, environments: [.lastHourUsage[] | .environment] | unique}'
```

## Output Format
- Use tab-separated columns with `column -t`
- Limit lists to 15-25 items
- Show summaries before details

## Common Pitfalls
- **Admin vs client API**: Admin API (`/admin/`) for management; client API (`/client/`) for SDKs
- **Toggle types**: `release`, `experiment`, `operational`, `kill-switch`, `permission`
- **Strategies**: Built-in strategies include `default`, `userWithId`, `gradualRolloutRandom`, `flexibleRollout`
- **Stale toggles**: Toggles older than lifecycle threshold are marked stale -- review and archive regularly
- **Constraints**: Strategy constraints allow targeting by context fields
- **Self-hosted**: Base URL varies -- always use `$UNLEASH_URL` env variable
