---
name: managing-courier
description: |
  Courier notification orchestration platform management covering messages, templates, brands, users, and delivery analytics. Use when monitoring notification delivery, analyzing template performance, reviewing delivery logs, managing notification preferences, or troubleshooting Courier notification issues.
connection_type: courier
preload: false
---

# Courier Management Skill

Manage and analyze Courier notification resources including messages, templates, and delivery analytics.

## API Conventions

### Authentication
All API calls use Bearer auth token, injected automatically.

### Base URL
`https://api.courier.com`

### Core Helper Function

```bash
#!/bin/bash

courier_api() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"

    if [ -n "$data" ]; then
        curl -s -X "$method" \
            -H "Authorization: Bearer $COURIER_AUTH_TOKEN" \
            -H "Content-Type: application/json" \
            "https://api.courier.com${endpoint}" \
            -d "$data"
    else
        curl -s -X "$method" \
            -H "Authorization: Bearer $COURIER_AUTH_TOKEN" \
            "https://api.courier.com${endpoint}"
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
echo "=== Recent Messages ==="
courier_api GET "/messages?limit=20" \
    | jq -r '.results[] | "\(.id[0:16])\t\(.status)\t\(.event[0:20])\t\(.recipient[0:16])\t\(.enqueued | . / 1000 | strftime("%Y-%m-%d"))"' \
    | column -t | head -20

echo ""
echo "=== Notification Templates ==="
courier_api GET "/notifications?limit=20" \
    | jq -r '.results[] | "\(.id[0:16])\t\(.title[0:30])\t\(.tags | join(",") | .[0:20])"' \
    | column -t | head -15

echo ""
echo "=== Brands ==="
courier_api GET "/brands?limit=10" \
    | jq -r '.results[] | "\(.id[0:16])\t\(.name)\t\(.published // false)"' | head -10
```

## Phase 2: Analysis

### Delivery Analytics

```bash
#!/bin/bash
echo "=== Message Status Summary ==="
courier_api GET "/messages?limit=100" \
    | jq -r '.results[] | .status' | sort | uniq -c | sort -rn

echo ""
echo "=== Messages by Event/Template ==="
courier_api GET "/messages?limit=100" \
    | jq -r '.results[] | .event // "unknown"' | sort | uniq -c | sort -rn | head -10

echo ""
echo "=== Failed Messages ==="
courier_api GET "/messages?limit=20&status=UNDELIVERABLE" \
    | jq -r '.results[] | "\(.id[0:16])\t\(.event[0:20])\t\(.recipient[0:16])\t\(.reason // "no reason")"' \
    | head -10

echo ""
echo "=== Delivery Channels Used ==="
courier_api GET "/messages?limit=100" \
    | jq -r '.results[] | .channel // "unknown"' | sort | uniq -c | sort -rn
```

### User & Preference Management

```bash
#!/bin/bash
echo "=== Recent Profiles ==="
courier_api GET "/profiles?limit=15" \
    | jq -r '.results[] | "\(.id[0:20])\t\(.profile.email // "no-email")"' | head -15

echo ""
echo "=== Subscription Topics ==="
courier_api GET "/preferences?limit=20" \
    | jq -r '.items[] | "\(.id[0:16])\t\(.topic_name)\t\(.default_status)"' | head -15

echo ""
echo "=== Lists ==="
courier_api GET "/lists?limit=15" \
    | jq -r '.results[] | "\(.id)\t\(.name[0:30])"' | head -15
```

## Output Format

```
=== Courier Workspace ===
Templates: <n>  Brands: <n>

--- Message Delivery ---
DELIVERED: <n>  SENT: <n>  UNDELIVERABLE: <n>  OPENED: <n>

--- By Template ---
<event>: <n> messages

--- By Channel ---
email: <n>  push: <n>  sms: <n>
```

## Common Pitfalls
- **Message statuses**: `ENQUEUED`, `SENT`, `DELIVERED`, `OPENED`, `CLICKED`, `UNDELIVERABLE`, `UNMAPPED`
- **Timestamps**: Unix milliseconds in responses
- **Pagination**: Use `limit` and `cursor`; check `paging.cursor` for next page
- **Rate limits**: 20 requests/second for most endpoints
- **Two auth tokens**: Published (production) and Draft (test) tokens are separate
