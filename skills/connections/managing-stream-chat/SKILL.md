---
name: managing-stream-chat
description: |
  Stream Chat messaging platform management covering channels, users, messages, moderation, and usage analytics. Use when monitoring chat health, analyzing message volumes, reviewing user activity, managing channels and moderation policies, or troubleshooting Stream Chat messaging issues.
connection_type: stream-chat
preload: false
---

# Stream Chat Management Skill

Manage and analyze Stream Chat resources including channels, users, messages, and moderation.

## API Conventions

### Authentication
All API calls use API key and secret with server-side token, injected automatically.

### Base URL
`https://chat.stream-io-api.com`

### Core Helper Function

```bash
#!/bin/bash

stream_api() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"

    if [ -n "$data" ]; then
        curl -s -X "$method" \
            -H "Authorization: $STREAM_AUTH_TOKEN" \
            -H "Content-Type: application/json" \
            -H "stream-auth-type: jwt" \
            "https://chat.stream-io-api.com${endpoint}?api_key=$STREAM_API_KEY" \
            -d "$data"
    else
        curl -s -X "$method" \
            -H "Authorization: $STREAM_AUTH_TOKEN" \
            -H "stream-auth-type: jwt" \
            "https://chat.stream-io-api.com${endpoint}?api_key=$STREAM_API_KEY"
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
echo "=== App Settings ==="
stream_api GET "/app" | jq '{name: .app.name, organization: .app.organization, push_notifications: .app.push_notifications}'

echo ""
echo "=== Channel Types ==="
stream_api GET "/channeltypes" \
    | jq -r '.channel_types | to_entries[] | "\(.key)\tmax_members:\(.value.max_message_length)\tautomod:\(.value.automod)"' \
    | head -15

echo ""
echo "=== Recent Channels ==="
stream_api POST "/channels" '{"filter_conditions": {}, "sort": [{"field": "last_message_at", "direction": -1}], "limit": 20}' \
    | jq -r '.channels[] | "\(.channel.id[0:20])\t\(.channel.type)\t\(.channel.member_count) members\t\(.channel.last_message_at[0:16] // "no messages")"' \
    | column -t | head -20
```

## Phase 2: Analysis

### Chat Health

```bash
#!/bin/bash
echo "=== Channel Summary ==="
stream_api POST "/channels" '{"filter_conditions": {}, "limit": 100}' \
    | jq '{
        total_channels: (.channels | length),
        total_members: (.channels | map(.channel.member_count // 0) | add),
        avg_members: (.channels | map(.channel.member_count // 0) | if length > 0 then add / length | floor else 0 end),
        by_type: (.channels | group_by(.channel.type) | map({(.[0].channel.type): length}) | add)
    }'

echo ""
echo "=== Active Channels (with recent messages) ==="
stream_api POST "/channels" '{"filter_conditions": {"last_message_at": {"$gt": "'$(date -d '24 hours ago' +%Y-%m-%dT%H:%M:%SZ)'"}}, "limit": 20}' \
    | jq -r '.channels[] | "\(.channel.id[0:20])\t\(.channel.type)\t\(.channel.member_count) members"' \
    | head -15

echo ""
echo "=== Inactive Channels (no messages in 30d) ==="
stream_api POST "/channels" '{"filter_conditions": {"last_message_at": {"$lt": "'$(date -d '30 days ago' +%Y-%m-%dT%H:%M:%SZ)'"}}, "limit": 20}' \
    | jq -r '.channels[] | "\(.channel.id[0:20])\t\(.channel.type)\t\(.channel.last_message_at[0:10] // "never")"' \
    | head -10
```

### User & Moderation

```bash
#!/bin/bash
echo "=== User Query ==="
stream_api POST "/users" '{"filter_conditions": {}, "sort": [{"field": "last_active", "direction": -1}], "limit": 20}' \
    | jq -r '.users[] | "\(.id[0:20])\t\(.online)\t\(.last_active[0:16] // "never")\tbanned:\(.banned // false)"' \
    | column -t | head -15

echo ""
echo "=== Banned Users ==="
stream_api POST "/users" '{"filter_conditions": {"banned": true}, "limit": 20}' \
    | jq -r '.users[] | "\(.id[0:20])\t\(.ban_expires[0:16] // "permanent")"' | head -10

echo ""
echo "=== Flagged Messages ==="
stream_api GET "/moderation/flags/messages?limit=20" \
    | jq -r '.flags[] | "\(.message.id[0:16])\t\(.message.text[0:40])\t\(.user.id)\t\(.created_at[0:16])"' | head -10
```

## Output Format

```
=== Stream Chat App: <name> ===

--- Channels ---
Total: <n>  Active (24h): <n>  Inactive (30d): <n>
By Type: messaging: <n>, livestream: <n>

--- Users ---
Total: <n>  Online: <n>  Banned: <n>

--- Moderation ---
Flagged Messages: <n>
```

## Common Pitfalls
- **Server-side auth**: Use JWT tokens generated with API secret for server-side operations
- **Query endpoints are POST**: Channel and user queries use POST with filter conditions
- **Filter syntax**: Uses MongoDB-style query operators (`$gt`, `$lt`, `$eq`, etc.)
- **Rate limits**: 60 requests/minute for most endpoints
- **Pagination**: Use `limit` and `offset`; max 100 per request
