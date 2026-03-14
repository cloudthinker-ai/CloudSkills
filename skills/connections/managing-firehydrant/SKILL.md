---
name: managing-firehydrant
description: |
  FireHydrant incident management, runbooks, service catalog, status pages, and retrospectives. Covers incident lifecycle, severity tracking, team assignments, change events, and reliability analytics. Use when managing active incidents, reviewing retrospectives, analyzing service health, or automating runbooks in FireHydrant.
connection_type: firehydrant
preload: false
---

# FireHydrant Management Skill

Manage and analyze incidents, services, runbooks, and retrospectives in FireHydrant.

## API Conventions

### Authentication
All API calls use the `Authorization: Bearer $FIREHYDRANT_API_KEY` header. Never hardcode tokens.

### Base URL
`https://api.firehydrant.io/v1`

### Core Helper Function

```bash
#!/bin/bash

fh_api() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"

    if [ -n "$data" ]; then
        curl -s -X "$method" \
            -H "Authorization: Bearer $FIREHYDRANT_API_KEY" \
            -H "Content-Type: application/json" \
            "https://api.firehydrant.io/v1${endpoint}" \
            -d "$data"
    else
        curl -s -X "$method" \
            -H "Authorization: Bearer $FIREHYDRANT_API_KEY" \
            -H "Content-Type: application/json" \
            "https://api.firehydrant.io/v1${endpoint}"
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
fh_api GET "/incidents?status=open&limit=25" \
    | jq -r '.data[] | "\(.created_at[0:16])\t\(.severity)\t\(.current_milestone)\t\(.name[0:60])"' \
    | column -t

echo ""
echo "=== Incident Count by Severity ==="
fh_api GET "/incidents?status=open&limit=100" \
    | jq -r '.data[] | .severity' | sort | uniq -c | sort -rn
```

### List Services and Teams

```bash
#!/bin/bash
echo "=== Services ==="
fh_api GET "/services?limit=25" \
    | jq -r '.data[] | "\(.service_tier // "none")\t\(.name)\t\(.owner.name // "unowned")"' \
    | column -t

echo ""
echo "=== Teams ==="
fh_api GET "/teams?limit=25" \
    | jq -r '.data[] | "\(.name)\t\(.memberships | length) members"' | column -t
```

## Analysis Phase

### Incident Analytics

```bash
#!/bin/bash
echo "=== Recent Resolved Incidents ==="
fh_api GET "/incidents?status=closed&limit=50" \
    | jq '{
        total: (.data | length),
        by_severity: (.data | group_by(.severity) | map({(.[0].severity // "unknown"): length}) | add),
        avg_duration_hrs: (.data | map(select(.resolved_at != null) | ((.resolved_at | fromdateiso8601) - (.created_at | fromdateiso8601)) / 3600) | if length > 0 then add / length | . * 10 | round / 10 else 0 end)
    }'

echo ""
echo "=== Services with Most Incidents ==="
fh_api GET "/incidents?status=closed&limit=100" \
    | jq -r '.data[].services[].name' | sort | uniq -c | sort -rn | head -10
```

### Retrospectives

```bash
#!/bin/bash
INCIDENT_ID="${1:?Incident ID required}"

echo "=== Incident Details ==="
fh_api GET "/incidents/${INCIDENT_ID}" \
    | jq '{name, severity, status: .current_milestone, created_at, resolved_at, summary: .description[0:200]}'

echo ""
echo "=== Retrospective ==="
fh_api GET "/incidents/${INCIDENT_ID}/retrospectives" \
    | jq -r '.data[] | "\(.created_at[0:16])\t\(.title[0:80])"' | head -10
```

## Output Format
- Use tab-separated columns with `column -t`
- Limit lists to 15-25 items
- Show summaries before details

## Common Pitfalls
- **Pagination**: Use `limit` and `page` parameters, max 100 per page
- **Milestones vs status**: Incidents use milestones (started, detected, mitigated, resolved) not simple statuses
- **Service tiers**: Filter by `service_tier` for criticality-based queries
- **Rate limits**: 100 requests per minute
- **Runbook steps**: Runbooks contain ordered steps -- always fetch steps with the runbook
