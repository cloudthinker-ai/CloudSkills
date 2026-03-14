---
name: managing-victorops
description: |
  Splunk On-Call (VictorOps) incident management covering incident timeline visualization, routing key configuration, escalation policies, on-call scheduling, team management, and alert rules. Use when managing VictorOps routing keys, reviewing incident timelines, configuring escalation workflows, or analyzing on-call rotations.
connection_type: victorops
preload: false
---

# Splunk On-Call (VictorOps) Management Skill

Manage Splunk On-Call incident timelines, routing keys, escalation policies, and on-call schedules.

## API Conventions

### Authentication
All API calls use `X-VO-Api-Id` and `X-VO-Api-Key` headers — injected automatically. Never hardcode credentials.

### Base URL
`https://api.victorops.com`

### Core Helper Function

```bash
#!/bin/bash

vo_api() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"

    if [ -n "$data" ]; then
        curl -s -X "$method" \
            -H "X-VO-Api-Id: $VICTOROPS_API_ID" \
            -H "X-VO-Api-Key: $VICTOROPS_API_KEY" \
            -H "Content-Type: application/json" \
            "https://api.victorops.com${endpoint}" \
            -d "$data"
    else
        curl -s -X "$method" \
            -H "X-VO-Api-Id: $VICTOROPS_API_ID" \
            -H "X-VO-Api-Key: $VICTOROPS_API_KEY" \
            "https://api.victorops.com${endpoint}"
    fi
}
```

## Output Rules
- **TOKEN EFFICIENCY**: Extract only needed fields with `jq`
- Target ≤50 lines per script output
- Always filter by relevant time range

## Incident Timeline

### Get Current Incidents
```bash
vo_api GET "/api-public/v1/incidents" | jq '[.incidents[] | {
  incidentNumber, currentPhase, startTime,
  entityId, entityDisplayName,
  transitions: [.transitions[] | {name, at, by}]
}]'
```

### Get Incident Timeline Details
```bash
vo_api GET "/api-public/v1/incidents/INCIDENT_NUMBER" | jq '{
  incidentNumber, entityDisplayName,
  startTime, currentPhase,
  pagedTeams, pagedUsers,
  timeline: [.transitions[] | {name, at, by, message}]
}'
```

## Routing Keys

### List All Routing Keys
```bash
vo_api GET "/api-public/v1/org/routing-keys" | jq '[.routingKeys[] | {routingKey, targets: [.targets[]?.policySlug]}]'
```

### Create a Routing Key
```bash
vo_api POST "/api-public/v1/org/routing-keys" '{
  "routingKey": "database-critical",
  "targets": [{"policySlug": "team-database", "type": "escalationPolicy"}]
}'
```

## Escalation Policies

### List Escalation Policies
```bash
vo_api GET "/api-public/v1/policies" | jq '[.policies[] | {slug, name, steps: [.steps[] | {timeout, entries: [.entries[] | .executionType]}]}]'
```

## On-Call Management

### Get Current On-Call Users
```bash
vo_api GET "/api-public/v2/team/TEAM_SLUG/oncall/schedule" | jq '.schedule | {
  team,
  schedules: [.schedules[] | {
    policy: .policySlug,
    schedule: [.overrides[]? // .rotations[] | {user: .onCallUser.username, start, end}]
  }]
}'
```

### List All Teams
```bash
vo_api GET "/api-public/v1/team" | jq '[.[] | {name, slug, memberCount: (.members | length)}]'
```

## Alert Rules

### Get Alert Rules for Routing Key
```bash
vo_api GET "/api-public/v1/org/routing-keys/ROUTING_KEY/rules" | jq '[.rules[] | {
  id, matchingCondition, transformations
}]'
```

## Common Tasks

1. **Map routing keys to teams** — audit which routing keys target which escalation policies
2. **Review incident timeline** — trace who was paged, when they acknowledged, and resolution steps
3. **Optimize escalation policies** — adjust timeouts and rotation order
4. **Audit on-call coverage** — verify all routing keys have active on-call responders
5. **Analyze incident patterns** — review triggered vs acknowledged vs resolved ratios
