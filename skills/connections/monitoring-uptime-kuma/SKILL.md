---
name: monitoring-uptime-kuma
description: |
  Uptime Kuma self-hosted monitoring with monitor management, notification channels, status pages, heartbeat analysis, and maintenance windows. Covers HTTP/TCP/DNS/ping monitors, alert configuration, response time tracking, and uptime statistics. Use when managing monitors, analyzing uptime, configuring notifications, or reviewing status pages via API.
connection_type: uptime-kuma
preload: false
---

# Uptime Kuma Monitoring Skill

Manage and analyze Uptime Kuma monitors, notifications, and status pages.

## API Conventions

### Authentication
Uptime Kuma primarily uses Socket.IO for real-time communication. REST API available via `/api/` with API key or session auth.

### Base URL
- Web UI: `http://<host>:3001/`
- API: `http://<host>:3001/api/`
- Use connection-injected `UPTIME_KUMA_BASE_URL`.

### Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- Use `jq` to extract monitor status and response times
- NEVER dump full heartbeat histories — summarize with statistics

### Core Helper Function

```bash
#!/bin/bash

kuma_api() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"

    if [ -n "$data" ]; then
        curl -s -X "$method" \
            -H "Authorization: Bearer ${UPTIME_KUMA_API_KEY}" \
            -H "Content-Type: application/json" \
            "${UPTIME_KUMA_BASE_URL}/api${endpoint}" \
            -d "$data"
    else
        curl -s -X "$method" \
            -H "Authorization: Bearer ${UPTIME_KUMA_API_KEY}" \
            "${UPTIME_KUMA_BASE_URL}/api${endpoint}"
    fi
}

# Alternative: Use push endpoint for passive monitors
kuma_push() {
    local push_token="$1"
    local status="${2:-up}"
    local msg="${3:-OK}"
    local ping="${4:-}"
    curl -s "${UPTIME_KUMA_BASE_URL}/api/push/${push_token}?status=${status}&msg=$(python3 -c "import urllib.parse; print(urllib.parse.quote('${msg}'))")${ping:+&ping=${ping}}"
}
```

## Parallel Execution

```bash
{
    kuma_api GET "/monitors" &
    kuma_api GET "/status-pages" &
    kuma_api GET "/notifications" &
}
wait
```

## Anti-Hallucination Rules

**NEVER assume monitor IDs, notification IDs, or status page slugs. ALWAYS discover first.**

### Phase 1: Discovery

```bash
#!/bin/bash
echo "=== All Monitors ==="
kuma_api GET "/monitors" \
    | jq -r '.[] | "\(.id)\t\(.type)\t\(.active)\t\(.name)"' | head -20

echo ""
echo "=== Monitor Types ==="
kuma_api GET "/monitors" \
    | jq -r '[.[].type] | group_by(.) | map("\(.[0]): \(length)") | .[]'

echo ""
echo "=== Status Pages ==="
kuma_api GET "/status-pages" \
    | jq -r '.[] | "\(.id)\t\(.slug)\t\(.title)"' | head -10

echo ""
echo "=== Notification Channels ==="
kuma_api GET "/notifications" \
    | jq -r '.[] | "\(.id)\t\(.type)\t\(.name)"' | head -10
```

## Common Operations

### Monitor Status Overview

```bash
#!/bin/bash
echo "=== Monitor Status Summary ==="
MONITORS=$(kuma_api GET "/monitors")

echo "$MONITORS" | jq -r '{
    total: length,
    active: [.[] | select(.active == true)] | length,
    down: [.[] | select(.active == true and .heartbeat.status == 0)] | length,
    paused: [.[] | select(.active == false)] | length
}'

echo ""
echo "=== Down Monitors ==="
echo "$MONITORS" | jq -r '.[] | select(.active == true and .heartbeat.status == 0) | "\(.name)\t\(.type)\t\(.url // .hostname // "N/A")"' | head -10

echo ""
echo "=== All Monitor Status ==="
echo "$MONITORS" | jq -r '.[] | "\(if .heartbeat.status == 1 then "UP" elif .heartbeat.status == 0 then "DOWN" else "PENDING" end)\t\(.name)\t\(.heartbeat.ping // "N/A")ms"' | head -20
```

### Heartbeat & Uptime Analysis

```bash
#!/bin/bash
MONITOR_ID="${1:?Monitor ID required}"

echo "=== Monitor Details ==="
kuma_api GET "/monitors/${MONITOR_ID}" \
    | jq '{name, type, url, interval, retryInterval, maxretries, active, uptime24: .uptime24, uptime720: .uptime720}'

echo ""
echo "=== Recent Heartbeats ==="
kuma_api GET "/monitors/${MONITOR_ID}/beats?hours=24" \
    | jq -r '.[-20:][] | "\(.time[11:19])\t\(if .status == 1 then "UP" else "DOWN" end)\t\(.ping // "N/A")ms\t\(.msg[0:60] // "")"'

echo ""
echo "=== Response Time Stats (24h) ==="
kuma_api GET "/monitors/${MONITOR_ID}/beats?hours=24" \
    | jq '[.[].ping | select(. != null)] | {
        avg_ms: (add / length | round),
        min_ms: min,
        max_ms: max,
        samples: length
    }'
```

### Notification Channels

```bash
#!/bin/bash
echo "=== Notification Channels ==="
kuma_api GET "/notifications" \
    | jq -r '.[] | "\(.id)\t\(.type)\t\(.name)\t\(.active)"'

echo ""
echo "=== Monitors per Notification ==="
MONITORS=$(kuma_api GET "/monitors")
echo "$MONITORS" | jq -r '.[] | "\(.name)\tnotifications:\(.notificationIDList | length)"' | head -15
```

### Status Page Management

```bash
#!/bin/bash
echo "=== Status Pages ==="
kuma_api GET "/status-pages" \
    | jq -r '.[] | "\(.slug)\t\(.title)\t\(.published)\tgroups:\(.publicGroupList | length)"'

echo ""
echo "=== Status Page Details ==="
SLUG="${1:-}"
if [ -n "$SLUG" ]; then
    kuma_api GET "/status-pages/${SLUG}" \
        | jq -r '.publicGroupList[] | "\(.name):\n\(.monitorList[] | "  - \(.name): \(if .heartbeat.status == 1 then "UP" else "DOWN" end)")"' \
        | head -20
fi
```

### Maintenance Windows

```bash
#!/bin/bash
echo "=== Active Maintenance ==="
kuma_api GET "/maintenances" \
    | jq -r '.[] | select(.active == true) | "\(.id)\t\(.title)\t\(.start[0:16]) to \(.end[0:16])"' | head -10

echo ""
echo "=== Upcoming Maintenance ==="
kuma_api GET "/maintenances" \
    | jq -r '.[] | select(.active == false) | "\(.id)\t\(.title)\t\(.start[0:16]) to \(.end[0:16])"' | head -10
```

## Common Pitfalls

- **Socket.IO primary**: Most Uptime Kuma features use Socket.IO — REST API may have limited endpoints depending on version
- **API key**: Must be created in Settings > API Keys — not available by default
- **Monitor types**: `http`, `port`, `ping`, `keyword`, `dns`, `docker`, `push`, `steam`, `mqtt` and more
- **Push monitors**: Use `/api/push/{token}` endpoint — passive monitoring, no active polling
- **Heartbeat status**: `1`=up, `0`=down, `2`=pending, `3`=maintenance — numeric, not strings
- **Rate limiting**: Self-hosted, no built-in rate limits — but avoid flooding with too many concurrent requests
- **Version differences**: API surface varies significantly between versions — check version first
- **Certificate monitoring**: HTTP monitors auto-check SSL — configure `expiryNotification` for cert expiry alerts
