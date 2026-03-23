---
name: managing-sleuth
description: |
  Use when working with Sleuth — sleuth deployment tracking, DORA metrics,
  change failure rate analysis, and deploy health monitoring. Covers deployment
  frequency, lead time, MTTR, change failure rate, feature flag impact, and code
  change tracking. Use when analyzing deployment health, reviewing DORA metrics,
  tracking change failure rates, or monitoring deploy frequency in Sleuth.
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
- **Org and project slugs**: Most endpoints require both organization and project slugs in the path
- **Deploy states**: `healthy`, `ailing`, `unhealthy`, `unknown`
- **DORA metrics**: Metrics are pre-calculated -- use metrics endpoint instead of computing manually
- **Impact sources**: Includes code changes, feature flags, errors, and custom sources
- **Rate limits**: Respect API rate limiting headers
