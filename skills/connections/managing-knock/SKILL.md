---
name: managing-knock
description: |
  Knock notification infrastructure management covering workflows, channels, users, messages, and delivery analytics. Use when monitoring notification delivery, analyzing workflow performance, reviewing channel health, managing notification preferences, or troubleshooting Knock notification issues.
connection_type: knock
preload: false
---

# Knock Management Skill

Manage and analyze Knock notification infrastructure including workflows, channels, and delivery.

## API Conventions

### Authentication
All API calls use Bearer secret key, injected automatically.

### Base URL
`https://api.knock.app/v1`

### Core Helper Function

```bash
#!/bin/bash

knock_api() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"

    if [ -n "$data" ]; then
        curl -s -X "$method" \
            -H "Authorization: Bearer $KNOCK_SECRET_KEY" \
            -H "Content-Type: application/json" \
            "https://api.knock.app/v1${endpoint}" \
            -d "$data"
    else
        curl -s -X "$method" \
            -H "Authorization: Bearer $KNOCK_SECRET_KEY" \
            "https://api.knock.app/v1${endpoint}"
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
knock_api GET "/workflows?page_size=20" \
    | jq -r '.entries[] | "\(.key)\t\(.name)\t\(.active)\t\(.updated_at[0:10])"' \
    | column -t | head -15

echo ""
echo "=== Channels ==="
knock_api GET "/channels" \
    | jq -r '.[] | "\(.id[0:16])\t\(.key)\t\(.type)\t\(.provider)"' \
    | column -t | head -15

echo ""
echo "=== Recent Messages ==="
knock_api GET "/messages?page_size=20" \
    | jq -r '.entries[] | "\(.id[0:16])\t\(.channel_id[0:12])\t\(.status)\t\(.workflow)\t\(.inserted_at[0:16])"' \
    | column -t | head -20
```

## Phase 2: Analysis

### Delivery Analytics

```bash
#!/bin/bash
echo "=== Message Delivery Summary ==="
knock_api GET "/messages?page_size=100" \
    | jq -r '.entries[] | .status' | sort | uniq -c | sort -rn

echo ""
echo "=== Messages by Channel ==="
knock_api GET "/messages?page_size=100" \
    | jq -r '.entries[] | .channel_id' | sort | uniq -c | sort -rn | head -10

echo ""
echo "=== Messages by Workflow ==="
knock_api GET "/messages?page_size=100" \
    | jq -r '.entries[] | .workflow // "unknown"' | sort | uniq -c | sort -rn | head -10

echo ""
echo "=== Failed/Bounced Messages ==="
knock_api GET "/messages?page_size=20&status=bounced,undelivered" \
    | jq -r '.entries[] | "\(.id[0:16])\t\(.status)\t\(.workflow)\t\(.recipient.id[0:16])\t\(.inserted_at[0:16])"' \
    | head -10
```

### User Preferences

```bash
#!/bin/bash
echo "=== Sample User Preferences ==="
knock_api GET "/users?page_size=10" \
    | jq -r '.entries[].id' | while read uid; do
    PREFS=$(knock_api GET "/users/$uid/preferences" | jq -c '.default // {}')
    echo "$uid: $PREFS"
done | head -10

echo ""
echo "=== Users with Custom Preferences ==="
knock_api GET "/users?page_size=50" \
    | jq '[.entries[] | select(.preferences != null)] | length | "Users with preferences: \(.)"'
```

## Output Format

```
=== Knock Environment ===
Workflows: <n>  Channels: <n>

--- Message Delivery ---
delivered: <n>  sent: <n>  bounced: <n>  undelivered: <n>

--- By Workflow ---
<workflow>: <n> messages

--- By Channel ---
<channel>: <n> messages
```

## Common Pitfalls
- **Environment scoping**: Secret key is scoped to development or production environment
- **Pagination**: Use `page_size` and `after` cursor; check `page_info.after` for next page
- **Message statuses**: `queued`, `sent`, `delivered`, `undelivered`, `bounced`, `seen`, `read`
- **Rate limits**: 100 requests/second for most endpoints
- **Workflow keys**: Use workflow key (slug), not ID, for most workflow operations
