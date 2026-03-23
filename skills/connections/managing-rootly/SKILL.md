---
name: managing-rootly
description: |
  Use when working with Rootly — rootly incident management, on-call scheduling,
  workflows, retrospectives, and service catalog. Covers incident creation and
  lifecycle, automated workflows, alert routing, status pages, and post-incident
  analysis. Use when managing active incidents, configuring workflows, reviewing
  retrospectives, or analyzing incident trends in Rootly.
connection_type: rootly
preload: false
---

# Rootly Management Skill

Manage and analyze incidents, workflows, retrospectives, and services in Rootly.

## API Conventions

### Authentication
All API calls use the `Authorization: Bearer $ROOTLY_API_KEY` header. Never hardcode tokens.

### Base URL
`https://api.rootly.com/v1`

### Core Helper Function

```bash
#!/bin/bash

rootly_api() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"

    if [ -n "$data" ]; then
        curl -s -X "$method" \
            -H "Authorization: Bearer $ROOTLY_API_KEY" \
            -H "Content-Type: application/json" \
            "https://api.rootly.com/v1${endpoint}" \
            -d "$data"
    else
        curl -s -X "$method" \
            -H "Authorization: Bearer $ROOTLY_API_KEY" \
            -H "Content-Type: application/json" \
            "https://api.rootly.com/v1${endpoint}"
    fi
}
```

## Output Rules
- **TOKEN EFFICIENCY**: Extract only needed fields with `jq`
- Target <=50 lines per script output
- Never dump full API responses

## Discovery Phase

### List Active Incidents

```bash
#!/bin/bash
echo "=== Active Incidents ==="
rootly_api GET "/incidents?filter[status]=started,mitigated&page[size]=25" \
    | jq -r '.data[] | "\(.attributes.created_at[0:16])\t\(.attributes.severity.data.attributes.name // "none")\t\(.attributes.status)\t\(.attributes.title[0:60])"' \
    | column -t

echo ""
echo "=== Incident Count by Severity ==="
rootly_api GET "/incidents?filter[status]=started,mitigated&page[size]=100" \
    | jq -r '.data[] | .attributes.severity.data.attributes.name // "none"' | sort | uniq -c | sort -rn
```

### List Services and Severities

```bash
#!/bin/bash
echo "=== Services ==="
rootly_api GET "/services?page[size]=25" \
    | jq -r '.data[] | "\(.attributes.name)\t\(.attributes.slug)"' | column -t

echo ""
echo "=== Severities ==="
rootly_api GET "/severities" \
    | jq -r '.data[] | "\(.attributes.severity)\t\(.attributes.name)\t\(.attributes.description[0:50])"' | column -t
```

## Analysis Phase

### Incident Analytics

```bash
#!/bin/bash
echo "=== Resolved Incidents (recent) ==="
rootly_api GET "/incidents?filter[status]=resolved&page[size]=50" \
    | jq '{
        total: (.data | length),
        by_severity: (.data | group_by(.attributes.severity.data.attributes.name // "unknown") | map({(.[0].attributes.severity.data.attributes.name // "unknown"): length}) | add)
    }'

echo ""
echo "=== Action Items Pending ==="
rootly_api GET "/action_items?filter[status]=open&page[size]=15" \
    | jq -r '.data[] | "\(.attributes.priority // "none")\t\(.attributes.summary[0:60])"' | column -t
```

### Incident Detail

```bash
#!/bin/bash
INCIDENT_ID="${1:?Incident ID required}"

echo "=== Incident Details ==="
rootly_api GET "/incidents/${INCIDENT_ID}" \
    | jq '.data.attributes | {title, status, severity: .severity.data.attributes.name, created_at, resolved_at, summary: .summary[0:200]}'

echo ""
echo "=== Timeline Events ==="
rootly_api GET "/incidents/${INCIDENT_ID}/timeline_events?page[size]=15" \
    | jq -r '.data[] | "\(.attributes.created_at[0:16])\t\(.attributes.event_type)\t\(.attributes.content[0:60])"' | column -t
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
- **JSON:API format**: Responses use JSON:API spec with `data`, `attributes`, `relationships` structure
- **Pagination**: Use `page[size]` and `page[number]` parameters
- **Filters**: Use `filter[field]` syntax for query parameters
- **Status values**: `started`, `mitigated`, `resolved`, `cancelled`
- **Rate limits**: Respect `X-RateLimit-Remaining` header
