---
name: managing-grafana-oncall
description: |
  Grafana OnCall management covering on-call schedule configuration, escalation chain design, integration setup with monitoring tools, alert group management, notification routing, and shift override management. Use when configuring Grafana OnCall schedules, building escalation chains, connecting alerting integrations, or reviewing on-call workload and alert distribution.
connection_type: grafana-oncall
preload: false
---

# Grafana OnCall Management Skill

Manage Grafana OnCall schedules, escalation chains, integrations, and alert groups.

## API Conventions

### Authentication
All API calls use the `Authorization: XXXXXX` header — injected automatically. Never hardcode tokens.

### Base URL
`https://oncall-prod-us-central-0.grafana.net/oncall/api/v1`

### Core Helper Function

```bash
#!/bin/bash

goc_api() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"

    if [ -n "$data" ]; then
        curl -s -X "$method" \
            -H "Authorization: $GRAFANA_ONCALL_API_KEY" \
            -H "Content-Type: application/json" \
            "${GRAFANA_ONCALL_URL}/api/v1${endpoint}" \
            -d "$data"
    else
        curl -s -X "$method" \
            -H "Authorization: $GRAFANA_ONCALL_API_KEY" \
            "${GRAFANA_ONCALL_URL}/api/v1${endpoint}"
    fi
}
```

## Output Rules
- **TOKEN EFFICIENCY**: Extract only needed fields with `jq`
- Target ≤50 lines per script output

## On-Call Schedules

### List Schedules
```bash
goc_api GET "/schedules/" | jq '[.results[] | {
  id, name, type, team_id,
  slack_channel: .slack.channel_name,
  on_call_now: [.on_call_now[] | .username]
}]'
```

### Get Schedule Details
```bash
goc_api GET "/schedules/SCHEDULE_ID/" | jq '{
  name, type, team_id,
  on_call_now: [.on_call_now[] | {username, pk}],
  shifts: [.shifts[] | {id, name, type, start, duration, frequency}]
}'
```

### Create a Web Schedule
```bash
goc_api POST "/schedules/" '{
  "name": "Backend On-Call",
  "type": "web",
  "team_id": "TEAM_ID",
  "time_zone": "America/New_York"
}'
```

## Escalation Chains

### List Escalation Chains
```bash
goc_api GET "/escalation_chains/" | jq '[.results[] | {id, name, team_id}]'
```

### Get Escalation Chain Policies
```bash
goc_api GET "/escalation_policies/?escalation_chain_id=CHAIN_ID" | jq '[. | sort_by(.position) | .[] | {
  position, type: .step,
  notify_to_group: .notify_to_group,
  duration: .duration,
  important: .important
}]'
```

### Create Escalation Chain
```bash
goc_api POST "/escalation_chains/" '{
  "name": "Critical Service Chain",
  "team_id": "TEAM_ID"
}'
```

## Integrations

### List Integrations
```bash
goc_api GET "/integrations/" | jq '[.results[] | {
  id, name, type, team_id,
  link, default_route: .default_route.escalation_chain_id
}]'
```

### Create Integration
```bash
goc_api POST "/integrations/" '{
  "name": "Prometheus Alerts",
  "type": "grafana_alerting",
  "team_id": "TEAM_ID"
}'
```

## Alert Groups

### List Alert Groups
```bash
goc_api GET "/alert_groups/?status=0" | jq '[.results[] | {
  id, title, status, acknowledged_by,
  created_at, resolved_at,
  integration: .integration_id,
  alerts_count
}]'
```

### Acknowledge an Alert Group
```bash
goc_api POST "/alert_groups/ALERT_GROUP_ID/acknowledge/"
```

## Shift Overrides

### Create Override
```bash
goc_api POST "/on_call_shifts/" '{
  "name": "Holiday Override",
  "type": "override",
  "schedule": "SCHEDULE_ID",
  "start": "2024-12-25T00:00:00Z",
  "duration": 86400,
  "users": ["USER_ID"]
}'
```

## Common Tasks

1. **Build escalation chains** — create multi-step escalation with wait durations
2. **Configure schedules** — set up rotation-based on-call with overrides
3. **Connect integrations** — wire Grafana Alerting, Prometheus, or webhooks to OnCall
4. **Review alert groups** — manage active, acknowledged, and silenced alert groups
5. **Audit on-call coverage** — verify schedules have no gaps in coverage
