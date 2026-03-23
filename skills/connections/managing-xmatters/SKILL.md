---
name: managing-xmatters
description: |
  Use when working with Xmatters — xMatters communication workflow management
  covering on-call scheduling, group management, communication plan design, flow
  designer automation, event targeting, and notification analytics. Use when
  configuring xMatters communication workflows, managing on-call rotations,
  building flow designer integrations, or analyzing notification delivery and
  response patterns.
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

## Output Format

Present results as a structured report:
```
Managing Xmatters Report
════════════════════════
Resources discovered: [count]

Resource       Status    Key Metric    Issues
──────────────────────────────────────────────
[name]         [ok/warn] [value]       [findings]

Summary: [total] resources | [ok] healthy | [warn] warnings | [crit] critical
Action Items: [list of prioritized findings]
```

Target ≤50 lines of output. Use tables for multi-resource comparisons.

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

