---
name: managing-pusher
description: |
  Pusher real-time messaging platform management covering channels, presence, usage analytics, and webhook configuration. Use when monitoring active channels, analyzing connection metrics, reviewing usage quotas, managing Pusher apps, or troubleshooting real-time messaging issues.
connection_type: pusher
preload: false
---

# Pusher Management Skill

Manage and analyze Pusher real-time messaging resources including channels, connections, and usage.

## API Conventions

### Authentication
API calls use app ID, key, and secret for HMAC signing, injected automatically.

### Base URL
`https://api-{cluster}.pusher.com/apps/$PUSHER_APP_ID`

### Core Helper Function

```bash
#!/bin/bash

pusher_api() {
    local method="$1"
    local endpoint="$2"

    local timestamp=$(date +%s)
    local path="/apps/${PUSHER_APP_ID}${endpoint}"
    local query="auth_key=${PUSHER_KEY}&auth_timestamp=${timestamp}&auth_version=1.0"
    local to_sign="${method}\n${path}\n${query}"
    local signature=$(echo -ne "$to_sign" | openssl dgst -sha256 -hmac "$PUSHER_SECRET" | sed 's/.*= //')

    curl -s -X "$method" \
        "https://api-${PUSHER_CLUSTER}.pusher.com${path}?${query}&auth_signature=${signature}"
}
```

## Output Rules
- Target ≤50 lines per script output
- Use `jq` to extract only needed fields
- Never dump full API responses

## Phase 1: Discovery

```bash
#!/bin/bash
echo "=== Active Channels ==="
pusher_api GET "/channels" \
    | jq -r '.channels | to_entries[] | "\(.key)\t\(.value.occupied // true)"' \
    | column -t | head -20

echo ""
echo "=== Occupied Channel Count ==="
pusher_api GET "/channels?filter_by_prefix=&info=user_count" \
    | jq '{total_channels: (.channels | length)}'

echo ""
echo "=== Presence Channels ==="
pusher_api GET "/channels?filter_by_prefix=presence-&info=user_count" \
    | jq -r '.channels | to_entries[] | "\(.key)\t\(.value.user_count) users"' \
    | head -15
```

## Phase 2: Analysis

### Channel Health

```bash
#!/bin/bash
echo "=== Channel Type Breakdown ==="
pusher_api GET "/channels" \
    | jq -r '.channels | to_entries | {
        total: length,
        presence: [.[] | select(.key | startswith("presence-"))] | length,
        private: [.[] | select(.key | startswith("private-"))] | length,
        public: [.[] | select(.key | (startswith("presence-") or startswith("private-")) | not)] | length
    }'

echo ""
echo "=== Presence Channel Details ==="
pusher_api GET "/channels?filter_by_prefix=presence-&info=user_count,subscription_count" \
    | jq -r '.channels | to_entries[] | "\(.key)\tusers:\(.value.user_count)\tsubscriptions:\(.value.subscription_count // "N/A")"' \
    | column -t | head -15

echo ""
echo "=== Specific Channel Info ==="
CHANNEL=$(pusher_api GET "/channels" | jq -r '.channels | keys[0]')
if [ -n "$CHANNEL" ] && [ "$CHANNEL" != "null" ]; then
    pusher_api GET "/channels/${CHANNEL}" \
        | jq '{channel: "'$CHANNEL'", occupied: .occupied, user_count: .user_count, subscription_count: .subscription_count}'
fi
```

### Usage Monitoring

```bash
#!/bin/bash
echo "=== Connection Summary ==="
pusher_api GET "/channels?info=subscription_count" \
    | jq '{
        active_channels: (.channels | length),
        total_subscriptions: (.channels | to_entries | map(.value.subscription_count // 0) | add)
    }'

echo ""
echo "=== Presence Users Across Channels ==="
pusher_api GET "/channels?filter_by_prefix=presence-&info=user_count" \
    | jq '{
        presence_channels: (.channels | length),
        total_unique_users: (.channels | to_entries | map(.value.user_count // 0) | add)
    }'
```

## Output Format

```
=== Pusher App: <app_id> (Cluster: <cluster>) ===
Active Channels: <n>  Total Subscriptions: <n>

--- Channel Types ---
Public: <n>  Private: <n>  Presence: <n>

--- Presence ---
Channels: <n>  Total Users: <n>
```

## Common Pitfalls
- **HMAC auth**: All API requests must be signed with app secret
- **Cluster**: Include cluster name in API URL (e.g., `api-us2.pusher.com`)
- **Channel limits**: Max 100 channels returned per request
- **Info param**: Must explicitly request `user_count` or `subscription_count` with `info` param
- **Rate limits**: 10 requests/second for channel queries
