---
name: managing-ilert
description: |
  iLert alerting and incident management covering alert source configuration, on-call scheduling, escalation policies, status page management, heartbeat monitoring, uptime tracking, and notification channel setup. Use when configuring iLert alert sources, managing on-call rotations, setting up status pages, monitoring heartbeats, or analyzing incident response metrics.
connection_type: ilert
preload: false
---

# iLert Management Skill

Manage iLert alerting, on-call schedules, escalation policies, status pages, and heartbeat monitoring.

## API Conventions

### Authentication
All API calls use the `Authorization: XXXXXX` header — injected automatically. Never hardcode tokens.

### Base URL
`https://api.ilert.com/api`

### Core Helper Function

```bash
#!/bin/bash

il_api() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"

    if [ -n "$data" ]; then
        curl -s -X "$method" \
            -H "Authorization: $ILERT_API_KEY" \
            -H "Content-Type: application/json" \
            "https://api.ilert.com/api${endpoint}" \
            -d "$data"
    else
        curl -s -X "$method" \
            -H "Authorization: $ILERT_API_KEY" \
            "https://api.ilert.com/api${endpoint}"
    fi
}
```

## Output Rules
- **TOKEN EFFICIENCY**: Extract only needed fields with `jq`
- Target ≤50 lines per script output

## Alert Sources

### List Alert Sources
```bash
il_api GET "/alert-sources" | jq '[.[] | {
  id, name, status, integrationType,
  escalationPolicy: .escalationPolicy.name,
  teams: [.teams[]?.name]
}]'
```

### Get Alert Source Details
```bash
il_api GET "/alert-sources/ALERT_SOURCE_ID" | jq '{
  name, status, integrationType,
  escalationPolicy: .escalationPolicy.name,
  supportHours, autoResolutionTimeout
}'
```

## Incidents

### List Active Incidents
```bash
il_api GET "/incidents?states=PENDING,ACCEPTED" | jq '[.[] | {
  id, summary, status, priority,
  alertSource: .alertSource.name,
  assignedTo: .assignedTo.username,
  createdAt, acceptedAt
}]'
```

### Get Incident Timeline
```bash
il_api GET "/incidents/INCIDENT_ID/log-entries" | jq '[.[] | {
  type, text, timestamp,
  user: .user.username
}]'
```

## On-Call Schedules

### List Schedules
```bash
il_api GET "/schedules" | jq '[.[] | {
  id, name, timezone,
  currentOnCall: .currentShift.user.username,
  teams: [.teams[]?.name]
}]'
```

### Get Schedule Shifts
```bash
il_api GET "/schedules/SCHEDULE_ID/shifts?from=2024-01-01&until=2024-01-31" | jq '[.[] | {
  user: .user.username,
  start, end
}]'
```

## Escalation Policies

### List Escalation Policies
```bash
il_api GET "/escalation-policies" | jq '[.[] | {
  id, name,
  rules: [.escalationRules[] | {
    delayMinutes: .escalationTimeout,
    targets: [.users[]?.username // .schedules[]?.name]
  }]
}]'
```

## Status Pages

### List Status Pages
```bash
il_api GET "/status-pages" | jq '[.[] | {id, name, status, url, services: [.services[] | {name, status}]}]'
```

### Update Status Page Component
```bash
il_api PUT "/status-pages/PAGE_ID/services/SERVICE_ID" '{
  "status": "DEGRADED"
}'
```

## Heartbeat Monitoring

### List Heartbeat Monitors
```bash
il_api GET "/heartbeats" | jq '[.[] | {
  id, name, status, intervalSec,
  alertSource: .alertSource.name,
  lastPingAt
}]'
```

### Check Heartbeat Status
```bash
il_api GET "/heartbeats/HEARTBEAT_ID" | jq '{
  name, status, intervalSec,
  lastPingAt, lastAlertAt,
  alertSource: .alertSource.name
}'
```

## Common Tasks

1. **Configure alert sources** — set up integrations with monitoring tools and route to escalation policies
2. **Manage on-call schedules** — create rotation-based schedules with override support
3. **Build escalation policies** — define multi-step escalation with timeouts
4. **Maintain status pages** — update service status during incidents for external communication
5. **Monitor heartbeats** — verify critical services are sending regular health pings
