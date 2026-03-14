---
name: managing-xmatters
description: |
  xMatters communication workflow management covering on-call scheduling, group management, communication plan design, flow designer automation, event targeting, and notification analytics. Use when configuring xMatters communication workflows, managing on-call rotations, building flow designer integrations, or analyzing notification delivery and response patterns.
connection_type: xmatters
preload: false
---

# xMatters Management Skill

Manage xMatters communication workflows, on-call schedules, flow designer automations, and notification analytics.

## API Conventions

### Authentication
All API calls use Basic Authentication or Bearer token — injected automatically. Never hardcode credentials.

### Base URL
`https://INSTANCE.xmatters.com/api/xm/1`

### Core Helper Function

```bash
#!/bin/bash

xm_api() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"

    if [ -n "$data" ]; then
        curl -s -X "$method" \
            -H "Authorization: Bearer $XMATTERS_TOKEN" \
            -H "Content-Type: application/json" \
            "https://${XMATTERS_INSTANCE}.xmatters.com/api/xm/1${endpoint}" \
            -d "$data"
    else
        curl -s -X "$method" \
            -H "Authorization: Bearer $XMATTERS_TOKEN" \
            "https://${XMATTERS_INSTANCE}.xmatters.com/api/xm/1${endpoint}"
    fi
}
```

## Output Rules
- **TOKEN EFFICIENCY**: Extract only needed fields with `jq`
- Target ≤50 lines per script output

## On-Call Management

### Get Current On-Call Members for a Group
```bash
xm_api GET "/on-call?groups=GROUP_ID&membersPerShift=5" | jq '[.data[] | {
  group: .group.targetName,
  shift: .shift.name,
  members: [.members[] | {name: .member.targetName, position: .position}]
}]'
```

### List Groups
```bash
xm_api GET "/groups?offset=0&limit=100" | jq '[.data[] | {id, targetName, recipientType, status, observedByAll}]'
```

## Communication Plans

### List Communication Plans
```bash
xm_api GET "/plans?offset=0&limit=100" | jq '[.data[] | {id, name, planType, enabled, creator: .creator.targetName}]'
```

### Get Plan Forms
```bash
xm_api GET "/plans/PLAN_ID/forms" | jq '[.data[] | {id, name, description, senderOverrides}]'
```

## Flow Designer

### List Flows for a Plan
```bash
xm_api GET "/plans/PLAN_ID/flows" | jq '[.data[] | {id, name, description, enabled}]'
```

## Events and Notifications

### Get Recent Events
```bash
xm_api GET "/events?status=ACTIVE&offset=0&limit=25" | jq '[.data[] | {
  id, name, status, priority,
  created, terminated,
  submitter: .submitter.targetName,
  recipients: .properties.recipients
}]'
```

### Get Event Notification Deliveries
```bash
xm_api GET "/events/EVENT_ID/deliveries" | jq '[.data[] | {
  person: .person.targetName,
  device: .device.name,
  deliveryStatus,
  respondedAt
}]'
```

## Common Tasks

1. **Audit on-call coverage** — verify all groups have active shifts with members assigned
2. **Review communication plans** — ensure incident notification templates are current
3. **Monitor notification delivery** — check delivery success rates and response times
4. **Configure flow designer** — build automated enrichment and escalation flows
5. **Manage group membership** — verify team structures match organizational changes
