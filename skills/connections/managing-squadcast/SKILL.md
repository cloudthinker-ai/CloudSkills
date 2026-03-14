---
name: managing-squadcast
description: |
  Squadcast incident management, on-call scheduling, escalation policies, SLO tracking, and runbooks. Covers incident lifecycle, alert deduplication, tagging, routing rules, and postmortem generation. Use when managing active incidents, reviewing on-call schedules, analyzing alert noise, or configuring routing rules in Squadcast.
connection_type: squadcast
preload: false
---

# Squadcast Management Skill

Manage and analyze incidents, on-call schedules, escalation policies, and services in Squadcast.

## API Conventions

### Authentication
All API calls use the `Authorization: Bearer $SQUADCAST_API_KEY` header. Never hardcode tokens.

### Base URL
`https://api.squadcast.com/v3`

### Core Helper Function

```bash
#!/bin/bash

sq_api() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"

    if [ -n "$data" ]; then
        curl -s -X "$method" \
            -H "Authorization: Bearer $SQUADCAST_API_KEY" \
            -H "Content-Type: application/json" \
            "https://api.squadcast.com/v3${endpoint}" \
            -d "$data"
    else
        curl -s -X "$method" \
            -H "Authorization: Bearer $SQUADCAST_API_KEY" \
            -H "Content-Type: application/json" \
            "https://api.squadcast.com/v3${endpoint}"
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
sq_api GET "/incidents?status=triggered,acknowledged&limit=25" \
    | jq -r '.data[] | "\(.created_at[0:16])\t\(.severity)\t\(.status)\t\(.title[0:60])"' \
    | column -t

echo ""
echo "=== Incident Count by Service ==="
sq_api GET "/incidents?status=triggered,acknowledged&limit=100" \
    | jq -r '.data[] | .service.name' | sort | uniq -c | sort -rn | head -10
```

### List Services and Escalation Policies

```bash
#!/bin/bash
echo "=== Services ==="
sq_api GET "/services" \
    | jq -r '.data[] | "\(.name)\t\(.escalation_policy.name // "none")"' | column -t | head -20

echo ""
echo "=== Escalation Policies ==="
sq_api GET "/escalation-policies" \
    | jq -r '.data[] | "\(.name)\t\(.rules | length) rules"' | column -t
```

## Analysis Phase

### Incident Analytics

```bash
#!/bin/bash
echo "=== Resolved Incidents Summary ==="
sq_api GET "/incidents?status=resolved&limit=50" \
    | jq '{
        total: (.data | length),
        by_severity: (.data | group_by(.severity) | map({(.[0].severity // "unknown"): length}) | add),
        avg_ack_time_min: (.data | map(select(.acknowledged_at != null) | ((.acknowledged_at | fromdateiso8601) - (.created_at | fromdateiso8601)) / 60) | if length > 0 then add / length | . * 10 | round / 10 else 0 end)
    }'

echo ""
echo "=== On-Call Now ==="
sq_api GET "/oncall" \
    | jq -r '.data[] | "\(.schedule.name)\t\(.user.name)\t\(.start[0:16]) - \(.end[0:16])"' | column -t | head -15
```

### Incident Detail

```bash
#!/bin/bash
INCIDENT_ID="${1:?Incident ID required}"

echo "=== Incident Details ==="
sq_api GET "/incidents/${INCIDENT_ID}" \
    | jq '.data | {id, title, status, severity, service: .service.name, created_at, resolved_at, description: .description[0:200]}'

echo ""
echo "=== Activity Timeline ==="
sq_api GET "/incidents/${INCIDENT_ID}/activities" \
    | jq -r '.data[0:15][] | "\(.created_at[0:16])\t\(.type)\t\(.message[0:60])"' | column -t
```

## Output Format
- Use tab-separated columns with `column -t`
- Limit lists to 15-25 items
- Show summaries before details

## Common Pitfalls
- **Status values**: `triggered`, `acknowledged`, `resolved`, `suppressed`
- **Deduplication**: Incidents may be grouped -- check `dedup_key` for related alerts
- **Tagging**: Use tags for filtering and routing -- accessible via `tags` array
- **Rate limits**: Respect API rate limits in response headers
- **Pagination**: Use `limit` and `offset` parameters
