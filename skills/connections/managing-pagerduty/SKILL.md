---
name: managing-pagerduty
description: |
  PagerDuty incident management, alerting, escalation policies, on-call scheduling, and service management. Covers incident creation and lifecycle, on-call rotation queries, alert routing, analytics, postmortem tracking, and service health. Use when investigating active incidents, reviewing on-call schedules, analyzing incident trends, or managing PagerDuty services.
connection_type: pagerduty
preload: false
---

# PagerDuty Management Skill

Manage and analyze PagerDuty incidents, on-call schedules, services, and escalation policies.

## API Conventions

### Authentication
All API calls use the `Authorization: Token token=XXXXXX` header — injected automatically. Never hardcode tokens.

### Base URL
`https://api.pagerduty.com`

### Core Helper Function

```bash
#!/bin/bash

pd_api() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"

    if [ -n "$data" ]; then
        curl -s -X "$method" \
            -H "Authorization: Token token=$PAGERDUTY_API_KEY" \
            -H "Content-Type: application/json" \
            -H "Accept: application/vnd.pagerduty+json;version=2" \
            "https://api.pagerduty.com${endpoint}" \
            -d "$data"
    else
        curl -s -X "$method" \
            -H "Authorization: Token token=$PAGERDUTY_API_KEY" \
            -H "Accept: application/vnd.pagerduty+json;version=2" \
            "https://api.pagerduty.com${endpoint}"
    fi
}
```

## Output Rules
- **TOKEN EFFICIENCY**: Extract only needed fields with `jq`
- Target ≤50 lines per script output
- Always filter by relevant time range to avoid huge response sets
- Never dump full API responses

## Parallel Execution

```bash
# Run independent API calls in parallel
{
    pd_api GET "/incidents?statuses[]=triggered&statuses[]=acknowledged&limit=10" &
    pd_api GET "/oncalls?limit=25" &
    pd_api GET "/services?limit=25" &
}
wait
```

## Common Operations

### Active Incident Overview

```bash
#!/bin/bash
echo "=== Active Incidents ==="
pd_api GET "/incidents?statuses[]=triggered&statuses[]=acknowledged&limit=25&sort_by=created_at:desc" \
    | jq -r '.incidents[] | "\(.created_at[0:16])\t\(.urgency)\t\(.status)\t\(.title[0:60])"' \
    | column -t

echo ""
echo "=== Incident Count by Urgency ==="
pd_api GET "/incidents?statuses[]=triggered&statuses[]=acknowledged&limit=100" \
    | jq -r '.incidents[] | .urgency' | sort | uniq -c | sort -rn

echo ""
echo "=== Services with Active Alerts ==="
pd_api GET "/incidents?statuses[]=triggered&statuses[]=acknowledged&limit=100" \
    | jq -r '.incidents[].service.summary' | sort | uniq -c | sort -rn | head -10
```

### On-Call Schedule

```bash
#!/bin/bash
echo "=== Current On-Call Responders ==="
pd_api GET "/oncalls?limit=50" \
    | jq -r '.oncalls[] | "\(.schedule.summary // "No Schedule")\t\(.user.summary)\t\(.start[0:16])\t\(.end[0:16])"' \
    | sort | uniq | column -t

echo ""
echo "=== On-Call Gaps (next 7 days) ==="
FROM=$(date -u +%Y-%m-%dT%H:%M:%SZ)
TO=$(date -u -d '7 days' +%Y-%m-%dT%H:%M:%SZ)

pd_api GET "/schedules?limit=25" \
    | jq -r '.schedules[].id' | while read schedule_id; do
    result=$(pd_api GET "/schedules/${schedule_id}/users?since=${FROM}&until=${TO}")
    name=$(pd_api GET "/schedules/${schedule_id}" | jq -r '.schedule.name')
    count=$(echo "$result" | jq '.users | length')
    echo "$name: $count on-call periods"
done
```

### Service Management

```bash
#!/bin/bash
echo "=== All Services ==="
pd_api GET "/services?limit=50&sort_by=name:asc" \
    | jq -r '.services[] | "\(.status)\t\(.name)\t\(.escalation_policy.summary)"' \
    | column -t

echo ""
echo "=== Services in Critical/Warning Status ==="
pd_api GET "/services?limit=50" \
    | jq -r '.services[] | select(.status != "active") | "\(.status)\t\(.name)\t\(.id)"' | head -20

echo ""
echo "=== Service Alert Volumes (last 30 days) ==="
FROM=$(date -u -d '30 days ago' +%Y-%m-%dT%H:%M:%SZ)
TO=$(date -u +%Y-%m-%dT%H:%M:%SZ)

pd_api GET "/incidents?since=${FROM}&until=${TO}&limit=100&time_zone=UTC" \
    | jq -r '.incidents[].service.summary' | sort | uniq -c | sort -rn | head -15
```

### Incident Analytics

```bash
#!/bin/bash
FROM="${1:-$(date -u -d '30 days ago' +%Y-%m-%dT%H:%M:%SZ)}"
TO="${2:-$(date -u +%Y-%m-%dT%H:%M:%SZ)}"

echo "=== Incident Summary (last 30 days) ==="
INCIDENTS=$(pd_api GET "/incidents?since=${FROM}&until=${TO}&limit=100&time_zone=UTC&statuses[]=resolved")
echo "$INCIDENTS" | jq '{
    total: (.incidents | length),
    by_urgency: (.incidents | group_by(.urgency) | map({(.[0].urgency): length}) | add),
    avg_resolve_time_hrs: (.incidents | map(select(.resolved_at != null) | ((.resolved_at | fromdateiso8601) - (.created_at | fromdateiso8601)) / 3600) | add / length | . * 10 | round / 10)
}'

echo ""
echo "=== MTTR by Service ==="
echo "$INCIDENTS" | jq -r '
    .incidents
    | group_by(.service.summary)
    | map({
        service: .[0].service.summary,
        count: length,
        avg_resolve_hrs: (map(select(.resolved_at != null) | ((.resolved_at | fromdateiso8601) - (.created_at | fromdateiso8601)) / 3600) | if length > 0 then add / length else 0 end)
    })
    | sort_by(.count) | reverse
    | .[]
    | "\(.service)\tcount:\(.count)\tMTTR:\(.avg_resolve_hrs | . * 10 | round / 10)h"
' | column -t | head -15

echo ""
echo "=== Incidents by Day of Week ==="
echo "$INCIDENTS" | jq -r '.incidents[].created_at' | \
    xargs -I{} date -d "{}" +%A | sort | uniq -c | sort -k2 -k1 -rn
```

### Escalation Policies

```bash
#!/bin/bash
echo "=== Escalation Policies ==="
pd_api GET "/escalation_policies?limit=25&sort_by=name:asc" \
    | jq -r '.escalation_policies[] | "\(.name)\t\(.num_loops) loops\t\(.services | length) services"' \
    | column -t

echo ""
echo "=== Policies with Missing Escalation Rules ==="
pd_api GET "/escalation_policies?limit=50" \
    | jq -r '.escalation_policies[] | select((.escalation_rules | length) < 2) | "\(.name): only \(.escalation_rules | length) rule(s)"'
```

### Create Incident (when explicitly requested)

```bash
#!/bin/bash
SERVICE_ID="${1:?Service ID required}"
TITLE="${2:?Incident title required}"
URGENCY="${3:-high}"  # high or low
BODY="${4:-}"

echo "=== Creating PagerDuty Incident ==="
pd_api POST "/incidents" "{
    \"incident\": {
        \"type\": \"incident\",
        \"title\": \"$TITLE\",
        \"service\": {\"id\": \"$SERVICE_ID\", \"type\": \"service_reference\"},
        \"urgency\": \"$URGENCY\"
        ${BODY:+,\"body\": {\"type\": \"incident_body\", \"details\": \"$BODY\"}}
    }
}" | jq '{id: .incident.id, number: .incident.incident_number, status: .incident.status, url: .incident.html_url}'
```

### Postmortems / Incident Notes

```bash
#!/bin/bash
INCIDENT_ID="${1:?Incident ID required}"

echo "=== Incident Details ==="
pd_api GET "/incidents/${INCIDENT_ID}" \
    | jq '.incident | {
        id: .id,
        number: .incident_number,
        title: .title,
        status: .status,
        created: .created_at,
        resolved: .resolved_at,
        service: .service.summary,
        urgency: .urgency
    }'

echo ""
echo "=== Timeline Notes ==="
pd_api GET "/incidents/${INCIDENT_ID}/notes" \
    | jq -r '.notes[] | "\(.created_at[0:16])\t\(.user.summary)\t\(.content[0:100])"' | column -t

echo ""
echo "=== Alert Count ==="
pd_api GET "/incidents/${INCIDENT_ID}/alerts?limit=25" \
    | jq '.alerts | length | "Total alerts: \(.)"' -r
```

## Common Pitfalls

- **`statuses[]` array format**: Must use `statuses[]=triggered&statuses[]=acknowledged` (array notation, not `status=triggered,acknowledged`)
- **Time ranges required for analytics**: Always include `since` and `until` parameters for incident queries — no date range can return huge datasets
- **Service ID vs name**: Always look up service ID via `/services` — names can change or have duplicates
- **Rate limits**: PagerDuty API is rate-limited at 960 requests/min — stagger parallel calls with `sleep 0.1`
- **Pagination**: API returns max 100 items per page — check `more` field and `offset` for pagination
- **User vs team**: Some analytics require team context — check `/teams` if per-team data is needed
- **REST API v2**: Always set `Accept: application/vnd.pagerduty+json;version=2` header
- **Events API vs REST API**: For triggering alerts from monitoring tools use Events API v2 (`events.pagerduty.com`) — different from management REST API
