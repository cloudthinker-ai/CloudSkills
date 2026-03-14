---
name: managing-sleuth
description: |
  Sleuth deployment tracking, DORA metrics, change failure rate analysis, and deploy health monitoring. Covers deployment frequency, lead time, MTTR, change failure rate, feature flag impact, and code change tracking. Use when analyzing deployment health, reviewing DORA metrics, tracking change failure rates, or monitoring deploy frequency in Sleuth.
connection_type: sleuth
preload: false
---

# Sleuth Management Skill

Manage and analyze deployments, DORA metrics, and change tracking in Sleuth.

## API Conventions

### Authentication
All API calls use the `Authorization: apikey $SLEUTH_API_KEY` header. Never hardcode tokens.

### Base URL
`https://app.sleuth.io/api/1`

### Core Helper Function

```bash
#!/bin/bash

sleuth_api() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"

    if [ -n "$data" ]; then
        curl -s -X "$method" \
            -H "Authorization: apikey $SLEUTH_API_KEY" \
            -H "Content-Type: application/json" \
            "https://app.sleuth.io/api/1${endpoint}" \
            -d "$data"
    else
        curl -s -X "$method" \
            -H "Authorization: apikey $SLEUTH_API_KEY" \
            -H "Content-Type: application/json" \
            "https://app.sleuth.io/api/1${endpoint}"
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
ORG_SLUG="${1:?Organization slug required}"

echo "=== Projects ==="
sleuth_api GET "/deployments/${ORG_SLUG}" \
    | jq -r '.[] | "\(.slug)\t\(.name)"' | column -t

echo ""
echo "=== Environments ==="
sleuth_api GET "/deployments/${ORG_SLUG}" \
    | jq -r '.[0].environments[] | "\(.slug)\t\(.name)\t\(.color)"' | column -t
```

### Recent Deployments

```bash
#!/bin/bash
ORG_SLUG="${1:?Organization slug required}"
PROJECT_SLUG="${2:?Project slug required}"

echo "=== Recent Deployments ==="
sleuth_api GET "/deployments/${ORG_SLUG}/${PROJECT_SLUG}/deploys?limit=20" \
    | jq -r '.[] | "\(.date[0:16])\t\(.environment)\t\(.state)\t\(.description[0:50])"' \
    | column -t
```

## Analysis Phase

### DORA Metrics

```bash
#!/bin/bash
ORG_SLUG="${1:?Organization slug required}"
PROJECT_SLUG="${2:?Project slug required}"

echo "=== DORA Metrics ==="
sleuth_api GET "/deployments/${ORG_SLUG}/${PROJECT_SLUG}/metrics" \
    | jq '{
        deploy_frequency: .deploy_frequency,
        lead_time: .lead_time,
        change_failure_rate: .change_failure_rate,
        mttr: .mttr
    }'

echo ""
echo "=== Deploy Health ==="
sleuth_api GET "/deployments/${ORG_SLUG}/${PROJECT_SLUG}/health" \
    | jq -r '.[] | "\(.date[0:10])\t\(.health_score)\t\(.deploys_count) deploys"' | head -15
```

### Change Failure Analysis

```bash
#!/bin/bash
ORG_SLUG="${1:?Organization slug required}"
PROJECT_SLUG="${2:?Project slug required}"

echo "=== Failed Deployments ==="
sleuth_api GET "/deployments/${ORG_SLUG}/${PROJECT_SLUG}/deploys?state=unhealthy&limit=15" \
    | jq -r '.[] | "\(.date[0:16])\t\(.environment)\t\(.description[0:50])\t\(.author)"' \
    | column -t

echo ""
echo "=== Impact Sources ==="
sleuth_api GET "/deployments/${ORG_SLUG}/${PROJECT_SLUG}/impact" \
    | jq -r '.[] | "\(.type)\t\(.name)\t\(.impact_level)"' | column -t | head -10
```

## Output Format
- Use tab-separated columns with `column -t`
- Limit lists to 15-25 items
- Show summaries before details

## Common Pitfalls
- **Org and project slugs**: Most endpoints require both organization and project slugs in the path
- **Deploy states**: `healthy`, `ailing`, `unhealthy`, `unknown`
- **DORA metrics**: Metrics are pre-calculated -- use metrics endpoint instead of computing manually
- **Impact sources**: Includes code changes, feature flags, errors, and custom sources
- **Rate limits**: Respect API rate limiting headers
