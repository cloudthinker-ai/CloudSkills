---
name: monitoring-pingdom
description: |
  Pingdom uptime monitoring with check management, transaction checks, page speed analysis, alerting configuration, and performance reporting. Covers HTTP/TCP/UDP checks, real user monitoring, response time analysis, outage history, and contact management. Use when managing uptime checks, analyzing performance, reviewing outages, or configuring alerts via Pingdom API.
connection_type: pingdom
preload: false
---

# Pingdom Monitoring Skill

Monitor and manage uptime checks, performance, and alerts using the Pingdom API.

## API Conventions

### Authentication
Pingdom API uses Bearer token authentication — injected by connection. Never hardcode tokens.

### Base URL
`https://api.pingdom.com/api/3.1/`

### Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- Use `jq` to extract check status and performance data
- NEVER dump full response histories — summarize with statistics

### Core Helper Function

```bash
#!/bin/bash

pingdom_api() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"

    if [ -n "$data" ]; then
        curl -s -X "$method" \
            -H "Authorization: Bearer ${PINGDOM_API_TOKEN}" \
            -H "Content-Type: application/json" \
            "https://api.pingdom.com/api/3.1${endpoint}" \
            -d "$data"
    else
        curl -s -X "$method" \
            -H "Authorization: Bearer ${PINGDOM_API_TOKEN}" \
            "https://api.pingdom.com/api/3.1${endpoint}"
    fi
}
```

## Parallel Execution

```bash
{
    pingdom_api GET "/checks" &
    pingdom_api GET "/alerts" &
    pingdom_api GET "/contacts" &
}
wait
```

## Anti-Hallucination Rules

**NEVER assume check IDs, check names, or contact IDs. ALWAYS discover first.**

### Phase 1: Discovery

```bash
#!/bin/bash
echo "=== All Checks ==="
pingdom_api GET "/checks" \
    | jq -r '.checks[] | "\(.id)\t\(.type)\t\(.status)\t\(.name)\t\(.hostname)"' | head -20

echo ""
echo "=== Check Types ==="
pingdom_api GET "/checks" \
    | jq -r '[.checks[].type] | group_by(.) | map("\(.[0]): \(length)") | .[]'

echo ""
echo "=== Alert Contacts ==="
pingdom_api GET "/contacts" \
    | jq -r '.contacts[] | "\(.id)\t\(.name)\t\(.notification_targets | keys | join(","))"' | head -10
```

## Common Operations

### Uptime Check Status Overview

```bash
#!/bin/bash
echo "=== Check Status Summary ==="
CHECKS=$(pingdom_api GET "/checks")

echo "$CHECKS" | jq '{
    total: (.checks | length),
    up: [.checks[] | select(.status == "up")] | length,
    down: [.checks[] | select(.status == "down")] | length,
    paused: [.checks[] | select(.status == "paused")] | length
}'

echo ""
echo "=== Down Checks ==="
echo "$CHECKS" | jq -r '.checks[] | select(.status == "down") | "\(.name)\t\(.hostname)\tlast_response:\(.lastresponsetime)ms"'

echo ""
echo "=== All Checks with Response Times ==="
echo "$CHECKS" | jq -r '.checks[] | select(.status != "paused") | "\(.status)\t\(.lastresponsetime)ms\t\(.name)\t\(.hostname)"' \
    | sort | head -20
```

### Performance Analysis

```bash
#!/bin/bash
CHECK_ID="${1:?Check ID required}"

echo "=== Performance Summary (30 days) ==="
FROM=$(date -d '30 days ago' +%s 2>/dev/null || date -v-30d +%s)
TO=$(date +%s)

pingdom_api GET "/summary.performance/${CHECK_ID}?from=${FROM}&to=${TO}&resolution=day" \
    | jq -r '.summary.days[] | "\(.starttime | strftime("%Y-%m-%d"))\tavg:\(.avgresponse)ms\tup:\(.uptime)s\tdown:\(.downtime)s"' \
    | head -15

echo ""
echo "=== Average Response Time ==="
pingdom_api GET "/summary.average/${CHECK_ID}?from=${FROM}&to=${TO}" \
    | jq '{avgresponse_ms: .summary.responsetime.avgresponse, from: (.summary.responsetime.from | strftime("%Y-%m-%d")), to: (.summary.responsetime.to | strftime("%Y-%m-%d"))}'
```

### Outage History

```bash
#!/bin/bash
CHECK_ID="${1:?Check ID required}"

echo "=== Outage History (30 days) ==="
FROM=$(date -d '30 days ago' +%s 2>/dev/null || date -v-30d +%s)
TO=$(date +%s)

pingdom_api GET "/summary.outage/${CHECK_ID}?from=${FROM}&to=${TO}" \
    | jq -r '.summary.states[] | select(.status == "down") | "\(.timefrom | strftime("%Y-%m-%d %H:%M"))\tto\t\(.timeto | strftime("%Y-%m-%d %H:%M"))\t\((.timeto - .timefrom) / 60 | floor)min"' \
    | head -15

echo ""
echo "=== Uptime Percentage ==="
pingdom_api GET "/summary.average/${CHECK_ID}?from=${FROM}&to=${TO}&includeuptime=true" \
    | jq '.summary.status | {
        total_up: .totalup,
        total_down: .totaldown,
        uptime_pct: ((.totalup / (.totalup + .totaldown)) * 10000 | round / 100)
    }'
```

### Transaction Checks

```bash
#!/bin/bash
echo "=== Transaction Checks ==="
pingdom_api GET "/checks?type=httpcustom" \
    | jq -r '.checks[] | "\(.id)\t\(.status)\t\(.name)\t\(.lastresponsetime)ms"' | head -15

echo ""
echo "=== Transaction Check Steps ==="
CHECK_ID="${1:-}"
if [ -n "$CHECK_ID" ]; then
    pingdom_api GET "/checks/${CHECK_ID}" \
        | jq -r '.check | {name, type, status, steps: (.steps // [] | length)}'
fi
```

### Alerting & Contact Management

```bash
#!/bin/bash
echo "=== Recent Alerts ==="
pingdom_api GET "/actions?limit=20" \
    | jq -r '.actions.alerts[] | "\(.checkid)\t\(.status)\t\(.messagefull[0:60])\t\(.contactname)"' | head -15

echo ""
echo "=== Contacts ==="
pingdom_api GET "/contacts" \
    | jq -r '.contacts[] | "\(.id)\t\(.name)\t\(.notification_targets | to_entries | map("\(.key):\(.value | length)") | join(", "))"'

echo ""
echo "=== Teams ==="
pingdom_api GET "/teams" \
    | jq -r '.teams[] | "\(.id)\t\(.name)\t\(.members | length) members"' | head -10
```

## Common Pitfalls

- **API version**: Use `/api/3.1/` — older versions are deprecated
- **Timestamps**: Unix epoch seconds for `from`/`to` parameters — not milliseconds
- **Resolution values**: `hour`, `day`, `week` for performance summaries — not arbitrary intervals
- **Check types**: `http`, `httpcustom`, `tcp`, `ping`, `dns`, `udp`, `smtp`, `pop3`, `imap`
- **Rate limits**: 7 requests/second — parallelize but add small stagger for >5 concurrent calls
- **Paused checks**: Paused checks return no performance data — filter with `status != "paused"`
- **Contact types**: `email`, `sms`, `push` notification targets — configure per contact
- **Probe regions**: Results vary by probe location — use `include_teams=true` for team-filtered results
