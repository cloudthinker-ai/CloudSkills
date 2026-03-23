---
name: managing-sendbird
description: |
  Use when working with Sendbird — sendbird messaging platform management
  covering group channels, open channels, users, messages, moderation, and usage
  analytics. Use when monitoring chat health, analyzing message volumes,
  reviewing user engagement, managing channels and moderation, or
  troubleshooting Sendbird messaging issues.
connection_type: sendbird
preload: false
---

# Sendbird Management Skill

Manage and analyze Sendbird messaging resources including channels, users, messages, and moderation.

## API Conventions

### Authentication
All API calls use API token in header, injected automatically.

### Base URL
`https://api-{app_id}.sendbird.com/v3`

### Core Helper Function

```bash
#!/bin/bash

sendbird_api() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"

    if [ -n "$data" ]; then
        curl -s -X "$method" \
            -H "Api-Token: $SENDBIRD_API_TOKEN" \
            -H "Content-Type: application/json" \
            "https://api-${SENDBIRD_APP_ID}.sendbird.com/v3${endpoint}" \
            -d "$data"
    else
        curl -s -X "$method" \
            -H "Api-Token: $SENDBIRD_API_TOKEN" \
            "https://api-${SENDBIRD_APP_ID}.sendbird.com/v3${endpoint}"
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
echo "=== Group Channels ==="
sendbird_api GET "/group_channels?limit=20&order=latest_last_message" \
    | jq -r '.channels[] | "\(.channel_url[0:20])\t\(.name[0:30])\t\(.member_count) members\t\(.last_message.created_at // 0 | . / 1000 | strftime("%Y-%m-%d"))"' \
    | column -t | head -20

echo ""
echo "=== Open Channels ==="
sendbird_api GET "/open_channels?limit=20" \
    | jq -r '.channels[] | "\(.channel_url[0:20])\t\(.name[0:30])\t\(.participant_count) participants"' \
    | head -15

echo ""
echo "=== Users (recent) ==="
sendbird_api GET "/users?limit=20&order=latest_login" \
    | jq -r '.users[] | "\(.user_id[0:20])\t\(.nickname[0:20])\t\(.is_online)\t\(.last_seen_at | . / 1000 | strftime("%Y-%m-%d") // "never")"' \
    | column -t | head -15
```

## Phase 2: Analysis

### Channel Health

```bash
#!/bin/bash
echo "=== Channel Summary ==="
sendbird_api GET "/group_channels?limit=100" \
    | jq '{
        total_channels: (.channels | length),
        total_members: (.channels | map(.member_count) | add),
        avg_members: (.channels | map(.member_count) | if length > 0 then add / length | floor else 0 end),
        frozen_channels: [.channels[] | select(.freeze == true)] | length
    }'

echo ""
echo "=== Channels with Unread Messages ==="
sendbird_api GET "/group_channels?limit=20&unread_filter=unread_message" \
    | jq -r '.channels[] | "\(.channel_url[0:20])\t\(.name[0:25])\tunread:\(.unread_message_count)"' \
    | head -15

echo ""
echo "=== Empty Channels (0 members) ==="
sendbird_api GET "/group_channels?limit=20&members_exactly_in=&member_state_filter=joined_only" \
    | jq -r '.channels[] | select(.member_count <= 1) | "\(.channel_url[0:20])\t\(.name[0:25])\t\(.member_count) members"' \
    | head -10
```

### User & Moderation

```bash
#!/bin/bash
echo "=== Online Users ==="
sendbird_api GET "/users?limit=50&active_mode=activated&show_bot=false" \
    | jq '{
        total_returned: (.users | length),
        online: [.users[] | select(.is_online == true)] | length,
        offline: [.users[] | select(.is_online == false)] | length
    }'

echo ""
echo "=== Banned Users ==="
sendbird_api GET "/users?limit=20&user_ids_filter=" \
    | jq -r '[.users[] | select(.is_blocked == true)] | length | "Blocked users: \(.)"'

echo ""
echo "=== Moderation: Reported Messages ==="
sendbird_api GET "/report/messages?limit=20" \
    | jq -r '.report_logs[] | "\(.report_type)\t\(.reporting_user.user_id[0:16])\t\(.message.message[0:40])\t\(.created_at | . / 1000 | strftime("%Y-%m-%d"))"' \
    | head -10
```

## Output Format

```
=== Sendbird App: <app_id> ===

--- Channels ---
Group: <n>  Open: <n>  Frozen: <n>
Avg Members: <n>

--- Users ---
Total: <n>  Online: <n>  Blocked: <n>

--- Moderation ---
Reports: <n>
```

## Anti-Hallucination Rules

1. **NEVER assume resource names** — always discover via CLI/API in Phase 1 before referencing in Phase 2.
2. **NEVER fabricate metric names or dimensions** — verify against the service documentation or `--help` output.
3. **NEVER mix CLI commands between service versions** — confirm which version/API you are targeting.
4. **ALWAYS use the discovery → verify → analyze chain** — every resource referenced must have been discovered first.
5. **ALWAYS handle empty results gracefully** — an empty response is valid data, not an error to retry.

## Counter-Rationalizations

| Shortcut | Counter | Why |
|----------|---------|-----|
| "I'll skip discovery and check known resources" | Always run Phase 1 discovery first | Resource names change, new resources appear — assumed names cause errors |
| "The user only asked for a quick check" | Follow the full discovery → analysis flow | Quick checks miss critical issues; structured analysis catches silent failures |
| "Default configuration is probably fine" | Audit configuration explicitly | Defaults often leave logging, security, and optimization features disabled |
| "Metrics aren't needed for this" | Always check relevant metrics when available | API/CLI responses show current state; metrics reveal trends and intermittent issues |
| "I don't have access to that" | Try the command and report the actual error | Assumed permission failures prevent useful investigation; actual errors are informative |

## Common Pitfalls
- **Timestamps**: Sendbird uses Unix milliseconds, not seconds
- **Pagination**: Use `limit` and `token` (next page cursor); max 100 per request
- **Channel URL**: Channel URLs are unique identifiers; URL-encode special characters
- **Rate limits**: Varies by plan; check `X-RateLimit-*` response headers
- **App ID in URL**: Base URL includes the app ID as subdomain
