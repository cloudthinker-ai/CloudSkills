---
name: managing-100ms
description: |
  100ms live video and audio infrastructure management for video conferencing, live streaming, and interactive sessions. Use when monitoring active rooms, analyzing session quality, reviewing usage metrics, managing room templates, or troubleshooting 100ms video/audio sessions.
connection_type: 100ms
preload: false
---

# 100ms Management Skill

Manage and analyze 100ms video/audio rooms, sessions, recordings, and usage.

## API Conventions

### Authentication
All API calls use Bearer management token, injected automatically.

### Base URL
`https://api.100ms.live/v2`

### Core Helper Function

```bash
#!/bin/bash

hms_api() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"

    if [ -n "$data" ]; then
        curl -s -X "$method" \
            -H "Authorization: Bearer $HMS_MANAGEMENT_TOKEN" \
            -H "Content-Type: application/json" \
            "https://api.100ms.live/v2${endpoint}" \
            -d "$data"
    else
        curl -s -X "$method" \
            -H "Authorization: Bearer $HMS_MANAGEMENT_TOKEN" \
            "https://api.100ms.live/v2${endpoint}"
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
echo "=== Room Templates ==="
hms_api GET "/room-templates?limit=20" \
    | jq -r '.data[] | "\(.id[0:12])\t\(.name)\t\(.roles | keys | join(","))"' \
    | column -t | head -15

echo ""
echo "=== Active Rooms ==="
hms_api GET "/active-rooms?limit=20" \
    | jq -r '.data[] | "\(.id[0:12])\t\(.name)\t\(.peers_count) peers\t\(.started_at[0:16])"' \
    | head -15

echo ""
echo "=== Rooms ==="
hms_api GET "/rooms?limit=20" \
    | jq -r '.data[] | "\(.id[0:12])\t\(.name)\t\(.enabled)\t\(.template_id[0:12])"' \
    | column -t | head -15
```

## Phase 2: Analysis

### Session Analytics

```bash
#!/bin/bash
echo "=== Recent Sessions ==="
hms_api GET "/sessions?limit=20" \
    | jq -r '.data[] | "\(.id[0:12])\t\(.room_id[0:12])\t\(.peers_count) peers\t\(.duration)s\t\(.created_at[0:16])"' \
    | head -20

echo ""
echo "=== Session Summary ==="
hms_api GET "/sessions?limit=100" \
    | jq '{
        total_sessions: (.data | length),
        total_peers: (.data | map(.peers_count // 0) | add),
        avg_duration_min: (.data | map(.duration // 0) | if length > 0 then add / length / 60 | floor else 0 end),
        avg_peers: (.data | map(.peers_count // 0) | if length > 0 then add / length | floor else 0 end)
    }'
```

### Recording & Streaming

```bash
#!/bin/bash
echo "=== Recordings ==="
hms_api GET "/recordings?limit=20" \
    | jq -r '.data[] | "\(.id[0:12])\t\(.room_id[0:12])\t\(.status)\t\(.duration)s\t\(.size // 0) bytes"' \
    | head -15

echo ""
echo "=== Recording Status Breakdown ==="
hms_api GET "/recordings?limit=100" \
    | jq -r '.data[] | .status' | sort | uniq -c | sort -rn
```

## Output Format

```
=== Templates: <count>  Active Rooms: <count> ===

--- Session Analytics ---
Total Sessions: <n>  Total Peers: <n>
Avg Duration: <n>min  Avg Peers/Session: <n>

--- Recordings ---
Total: <n>  Completed: <n>  Processing: <n>
```

## Common Pitfalls
- **Management token**: Must be generated from app access key and secret with RS256 JWT
- **Pagination**: Use `limit` and `start` cursor; check `last` field for next page
- **Rate limits**: 100 requests/minute for management API
- **Room vs Session**: A room is a configuration; a session is an active/completed meeting in that room
