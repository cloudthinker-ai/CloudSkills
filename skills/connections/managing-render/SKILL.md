---
name: managing-render
description: |
  Use when working with Render — render platform management via the Render API.
  Covers web services, static sites, background workers, cron jobs, databases,
  and environment groups. Use when managing Render deployments or checking
  service health.
connection_type: render
preload: false
---

# Managing Render

Manage Render platform using the Render REST API via curl.

## MANDATORY: Discovery-First Pattern

**Always discover available resources before performing analysis.**

### Phase 1: Discovery

```bash
#!/bin/bash

RENDER_API="https://api.render.com/v1"
AUTH="Authorization: Bearer $RENDER_API_KEY"

echo "=== Owner Info ==="
curl -s "$RENDER_API/owners" -H "$AUTH" | jq -r '.[] | .owner | "\(.id)\t\(.name)\t\(.type)\t\(.email)"' | head -5

echo ""
echo "=== Services ==="
curl -s "$RENDER_API/services?limit=50" -H "$AUTH" | jq -r '.[] | .service | "\(.id)\t\(.name)\t\(.type)\t\(.serviceDetails.region // .region)\t\(.suspended)"' | head -30

echo ""
echo "=== Databases ==="
curl -s "$RENDER_API/postgres?limit=20" -H "$AUTH" | jq -r '.[] | .postgres | "\(.id)\t\(.name)\t\(.plan)\t\(.region)\t\(.status)\t\(.version)"' | head -10

echo ""
echo "=== Environment Groups ==="
curl -s "$RENDER_API/env-groups?limit=20" -H "$AUTH" | jq -r '.[] | .envGroup | "\(.id)\t\(.name)\t\(.createdAt)"' | head -10

echo ""
echo "=== Custom Domains ==="
curl -s "$RENDER_API/custom-domains?limit=20" -H "$AUTH" | jq -r '.[] | .customDomain | "\(.id)\t\(.name)\t\(.verificationStatus)\t\(.domainType)"' | head -10
```

### Phase 2: Analysis

```bash
#!/bin/bash

RENDER_API="https://api.render.com/v1"
AUTH="Authorization: Bearer $RENDER_API_KEY"
SERVICE_ID="${1:?Service ID required}"

echo "=== Service Details ==="
curl -s "$RENDER_API/services/$SERVICE_ID" -H "$AUTH" | jq '{
    id, name, type, suspended, autoDeploy,
    repo: .repo, branch: .branch,
    serviceDetails: {
        region: .serviceDetails.region,
        plan: .serviceDetails.plan,
        runtime: .serviceDetails.runtime,
        numInstances: .serviceDetails.numInstances,
        healthCheckPath: .serviceDetails.healthCheckPath
    }
}'

echo ""
echo "=== Recent Deploys ==="
curl -s "$RENDER_API/services/$SERVICE_ID/deploys?limit=10" -H "$AUTH" | jq -r '.[] | .deploy | "\(.id)\t\(.status)\t\(.trigger)\t\(.createdAt)\t\(.finishedAt // "in-progress")"' | head -10

echo ""
echo "=== Service Events ==="
curl -s "$RENDER_API/services/$SERVICE_ID/events?limit=10" -H "$AUTH" | jq -r '.[] | .event | "\(.id)\t\(.type)\t\(.timestamp)\t\(.details // {})"' | head -10

echo ""
echo "=== Scaling Info ==="
curl -s "$RENDER_API/services/$SERVICE_ID/scaling" -H "$AUTH" | jq '{min: .minInstances, max: .maxInstances, criteria: .criteria}' 2>/dev/null || echo "Scaling not configured"

echo ""
echo "=== Headers/Routes ==="
curl -s "$RENDER_API/services/$SERVICE_ID/headers" -H "$AUTH" | jq -r '.[] | .header | "\(.path)\t\(.name)\t\(.value)"' | head -10
```

## Output Format

```
ID               NAME           TYPE           REGION     SUSPENDED
srv-abc123       web-app        web_service    oregon     not_suspended
srv-def456       worker         background     oregon     not_suspended
```

## Safety Rules
- Use read-only GET API calls only
- Never run DELETE, PATCH, POST without explicit user confirmation
- Use jq for structured output parsing
- Limit output with `| head -N` to stay under 50 lines

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

