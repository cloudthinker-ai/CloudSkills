---
name: managing-jeli
description: |
  Jeli incident analysis, narrative-based post-incident reviews, opportunity identification, and learning extraction. Covers incident ingestion from Slack, timeline reconstruction, contributing factor analysis, and organizational learning patterns. Use when reviewing post-incident narratives, identifying systemic patterns, tracking opportunities, or analyzing incident learning in Jeli.
connection_type: jeli
preload: false
---

# Jeli Management Skill

Manage and analyze incidents, post-incident narratives, and organizational learning in Jeli.

## API Conventions

### Authentication
All API calls use the `Authorization: Bearer $JELI_API_KEY` header. Never hardcode tokens.

### Base URL
`https://api.jeli.io/v1`

### Core Helper Function

```bash
#!/bin/bash

jeli_api() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"

    if [ -n "$data" ]; then
        curl -s -X "$method" \
            -H "Authorization: Bearer $JELI_API_KEY" \
            -H "Content-Type: application/json" \
            "https://api.jeli.io/v1${endpoint}" \
            -d "$data"
    else
        curl -s -X "$method" \
            -H "Authorization: Bearer $JELI_API_KEY" \
            -H "Content-Type: application/json" \
            "https://api.jeli.io/v1${endpoint}"
    fi
}
```

## Output Rules
- **TOKEN EFFICIENCY**: Extract only needed fields with `jq`
- Target <=50 lines per script output
- Never dump full API responses

## Discovery Phase

### List Incidents

```bash
#!/bin/bash
echo "=== Recent Incidents ==="
jeli_api GET "/incidents?limit=25&sort=-created_at" \
    | jq -r '.incidents[] | "\(.created_at[0:16])\t\(.severity // "none")\t\(.status)\t\(.title[0:60])"' \
    | column -t

echo ""
echo "=== Incident Count by Status ==="
jeli_api GET "/incidents?limit=100" \
    | jq -r '.incidents[] | .status' | sort | uniq -c | sort -rn
```

### List Opportunities

```bash
#!/bin/bash
echo "=== Open Opportunities ==="
jeli_api GET "/opportunities?status=open&limit=20" \
    | jq -r '.opportunities[] | "\(.priority // "none")\t\(.title[0:60])\t\(.assignee // "unassigned")"' \
    | column -t

echo ""
echo "=== Opportunity Tags ==="
jeli_api GET "/opportunities?limit=50" \
    | jq -r '.opportunities[].tags[]' | sort | uniq -c | sort -rn | head -10
```

## Analysis Phase

### Incident Narrative Review

```bash
#!/bin/bash
INCIDENT_ID="${1:?Incident ID required}"

echo "=== Incident Details ==="
jeli_api GET "/incidents/${INCIDENT_ID}" \
    | jq '.incident | {id, title, status, severity, created_at, resolved_at, summary: .summary[0:200]}'

echo ""
echo "=== Narrative ==="
jeli_api GET "/incidents/${INCIDENT_ID}/narrative" \
    | jq -r '.narrative.content[0:500]'

echo ""
echo "=== Contributing Factors ==="
jeli_api GET "/incidents/${INCIDENT_ID}/factors" \
    | jq -r '.factors[] | "\(.category)\t\(.description[0:60])"' | column -t
```

### Learning Patterns

```bash
#!/bin/bash
echo "=== Recurring Themes ==="
jeli_api GET "/incidents?limit=50" \
    | jq -r '.incidents[].tags[]' | sort | uniq -c | sort -rn | head -15

echo ""
echo "=== Incidents by Team ==="
jeli_api GET "/incidents?limit=50" \
    | jq -r '.incidents[] | .teams[].name' | sort | uniq -c | sort -rn | head -10
```

## Output Format
- Use tab-separated columns with `column -t`
- Limit lists to 15-25 items
- Show summaries before details

## Common Pitfalls
- **Narrative-focused**: Jeli emphasizes narrative understanding over metrics -- summaries and context are key fields
- **Opportunities**: Jeli calls improvement items "opportunities" not "action items"
- **Slack integration**: Most incident data is ingested from Slack conversations
- **Rate limits**: Respect API rate limiting headers
- **Pagination**: Use `limit` and `offset` parameters
