---
name: managing-novu
description: |
  Novu open-source notification infrastructure management covering workflows, subscribers, messages, integrations, and delivery analytics. Use when monitoring notification delivery, analyzing workflow performance, reviewing integration health, managing subscriber preferences, or troubleshooting Novu notification issues.
connection_type: novu
preload: false
---

# Novu Management Skill

Manage and analyze Novu notification infrastructure including workflows, subscribers, and delivery.

## API Conventions

### Authentication
All API calls use API key in header, injected automatically.

### Base URL
`https://api.novu.co/v1`

### Core Helper Function

```bash
#!/bin/bash

novu_api() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"

    if [ -n "$data" ]; then
        curl -s -X "$method" \
            -H "Authorization: ApiKey $NOVU_API_KEY" \
            -H "Content-Type: application/json" \
            "https://api.novu.co/v1${endpoint}" \
            -d "$data"
    else
        curl -s -X "$method" \
            -H "Authorization: ApiKey $NOVU_API_KEY" \
            "https://api.novu.co/v1${endpoint}"
    fi
}
```

## Output Rules
- Target ≤50 lines per script output
- Use `jq` to extract only needed fields
- Never dump full API responses

## Phase 1: Discovery

```bash
#!/bin/bash
echo "=== Workflows ==="
novu_api GET "/workflows?limit=20" \
    | jq -r '.data[] | "\(.id[0:16])\t\(.name[0:30])\t\(.active)\t\(.triggers[0].identifier)"' \
    | column -t | head -15

echo ""
echo "=== Integrations ==="
novu_api GET "/integrations" \
    | jq -r '.data[] | "\(.id[0:16])\t\(.providerId)\t\(.channel)\t\(.active)"' \
    | column -t | head -15

echo ""
echo "=== Recent Notifications ==="
novu_api GET "/notifications?limit=20" \
    | jq -r '.data[] | "\(.id[0:16])\t\(.template.name[0:25] // "unknown")\t\(.channels[0] // "?")\t\(.createdAt[0:16])"' \
    | column -t | head -20

echo ""
echo "=== Subscriber Count ==="
novu_api GET "/subscribers?limit=1" | jq '{total: .totalCount}'
```

## Phase 2: Analysis

### Delivery Analytics

```bash
#!/bin/bash
echo "=== Notification Status Summary ==="
novu_api GET "/notifications?limit=100" \
    | jq -r '.data[].jobs[].status' | sort | uniq -c | sort -rn

echo ""
echo "=== Notifications by Workflow ==="
novu_api GET "/notifications?limit=100" \
    | jq -r '.data[] | .template.name // "unknown"' | sort | uniq -c | sort -rn | head -10

echo ""
echo "=== Notifications by Channel ==="
novu_api GET "/notifications?limit=100" \
    | jq -r '.data[].channels[]' | sort | uniq -c | sort -rn

echo ""
echo "=== Failed Notifications ==="
novu_api GET "/notifications?limit=100" \
    | jq -r '.data[] | select(.jobs[] | .status == "failed") | "\(.id[0:16])\t\(.template.name[0:25])\t\(.createdAt[0:16])"' \
    | head -10
```

### Integration Health

```bash
#!/bin/bash
echo "=== Active Integrations ==="
novu_api GET "/integrations/active" \
    | jq -r '.data[] | "\(.providerId)\t\(.channel)\t\(.active)\t\(.primary)"' \
    | column -t | head -15

echo ""
echo "=== Integration by Channel ==="
novu_api GET "/integrations" \
    | jq -r '[.data[] | .channel] | group_by(.) | map({(.[0]): length}) | add'

echo ""
echo "=== Environment Info ==="
novu_api GET "/environments/me" \
    | jq '{name: .data.name, id: .data._id, identifier: .data.identifier}'
```

## Output Format

```
=== Novu Environment: <name> ===
Workflows: <n>  Subscribers: <n>  Integrations: <n>

--- Notification Delivery ---
completed: <n>  sent: <n>  failed: <n>

--- By Workflow ---
<workflow>: <n> notifications

--- By Channel ---
email: <n>  push: <n>  in_app: <n>  sms: <n>
```

## Common Pitfalls
- **Self-hosted vs cloud**: API URL may differ for self-hosted instances
- **Pagination**: Use `limit` and `page` parameters; check `totalCount` in response
- **Job statuses**: Each notification has jobs per channel with individual statuses
- **Rate limits**: 100 requests/10 seconds for cloud; varies for self-hosted
- **Trigger identifier**: Use workflow trigger identifier, not workflow ID, when triggering
