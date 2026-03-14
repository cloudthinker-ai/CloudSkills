---
name: managing-zendesk-deep
description: |
  Zendesk advanced support management covering ticket workflows, macros, triggers, automations, SLA policies, views, and reporting. Use when managing complex ticket routing, configuring automation rules, analyzing support metrics, monitoring SLA compliance, or optimizing helpdesk agent workflows and productivity.
connection_type: zendesk
preload: false
---

# Zendesk Advanced Management Skill

Manage and analyze Zendesk tickets, macros, triggers, automations, SLA policies, and support metrics.

## API Conventions

### Authentication
All API calls use Basic Auth (email/token) or OAuth — injected automatically. Never hardcode credentials.

### Base URL
`https://{{subdomain}}.zendesk.com/api/v2`

### Core Helper Function

```bash
#!/bin/bash

zd_api() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"

    if [ -n "$data" ]; then
        curl -s -X "$method" \
            -H "Authorization: Bearer $ZENDESK_TOKEN" \
            -H "Content-Type: application/json" \
            "${ZENDESK_URL}/api/v2${endpoint}" \
            -d "$data"
    else
        curl -s -X "$method" \
            -H "Authorization: Bearer $ZENDESK_TOKEN" \
            -H "Content-Type: application/json" \
            "${ZENDESK_URL}/api/v2${endpoint}"
    fi
}
```

## Output Rules
- **TOKEN EFFICIENCY**: Extract only needed fields with `jq`
- Target <=50 lines per script output
- Never dump full API responses

## Common Operations

### Ticket Workflow Management

```bash
#!/bin/bash
echo "=== Open Tickets by Priority ==="
zd_api GET "/search.json?query=type:ticket+status:open+status:pending&sort_by=priority&sort_order=desc" \
    | jq -r '.results[:25] | .[] | "\(.id)\t\(.priority // "none")\t\(.status)\t\(.subject[0:60])"' \
    | column -t

echo ""
echo "=== Ticket Volume by Status ==="
for status in new open pending hold solved; do
    count=$(zd_api GET "/search.json?query=type:ticket+status:${status}" | jq '.count')
    echo "${status}: ${count}"
done

echo ""
echo "=== Unassigned Tickets ==="
zd_api GET "/search.json?query=type:ticket+status<solved+assignee:none&sort_by=created_at&sort_order=desc" \
    | jq -r '.results[:15] | .[] | "\(.id)\t\(.priority // "-")\t\(.created_at[0:16])\t\(.subject[0:50])"' \
    | column -t
```

### Macro and Automation Management

```bash
#!/bin/bash
echo "=== Active Macros ==="
zd_api GET "/macros/active.json?sort_by=usage_1m&sort_order=desc" \
    | jq -r '.macros[:20] | .[] | "\(.id)\t\(.usage_1m // 0) uses/mo\t\(.title[0:50])"' \
    | column -t

echo ""
echo "=== Active Triggers ==="
zd_api GET "/triggers/active.json" \
    | jq -r '.triggers[:20] | .[] | "\(.id)\t\(.position)\t\(.title[0:60])"' \
    | column -t

echo ""
echo "=== Active Automations ==="
zd_api GET "/automations/active.json" \
    | jq -r '.automations[:20] | .[] | "\(.id)\t\(.position)\t\(.title[0:60])"' \
    | column -t
```

### SLA Policy Monitoring

```bash
#!/bin/bash
echo "=== SLA Policies ==="
zd_api GET "/slas/policies.json" \
    | jq -r '.sla_policies[] | "\(.id)\t\(.title)\t\(.filter.all | length) conditions"' \
    | column -t

echo ""
echo "=== Tickets Breaching SLA ==="
zd_api GET "/search.json?query=type:ticket+status<solved+sla_policy_breached:true" \
    | jq -r '.results[:15] | .[] | "\(.id)\t\(.priority // "-")\t\(.subject[0:50])"' \
    | column -t
```

### Support Metrics and Reporting

```bash
#!/bin/bash
echo "=== Agent Activity (today) ==="
zd_api GET "/incremental/tickets.json?start_time=$(date -u -d '24 hours ago' +%s)" \
    | jq -r '[.tickets[] | .assignee_id] | group_by(.) | map({agent: .[0], count: length}) | sort_by(.count) | reverse | .[:15] | .[] | "Agent \(.agent): \(.count) tickets"'

echo ""
echo "=== Satisfaction Ratings (last 30 days) ==="
zd_api GET "/satisfaction_ratings.json?sort_by=created_at&sort_order=desc" \
    | jq '{
        total: (.satisfaction_ratings | length),
        good: ([.satisfaction_ratings[] | select(.score == "good")] | length),
        bad: ([.satisfaction_ratings[] | select(.score == "bad")] | length)
    }'
```

## Common Pitfalls

- **Search syntax**: Use `+` for AND, `status<solved` means open/pending/hold — not literal less-than
- **Rate limits**: 700 requests/min for Enterprise, 400 for Professional — check `X-Rate-Limit-Remaining` header
- **Pagination**: Use `next_page` URL from response for cursor-based pagination — max 100 per page
- **Incremental exports**: Use `/incremental/` endpoints for bulk data — more efficient than search for large datasets
- **Side-loading**: Use `?include=users,groups` to reduce API calls when you need related data
- **Ticket fields**: Custom fields are in `custom_fields` array — reference by field ID, not name
- **Time zones**: All timestamps are UTC — convert for display as needed
