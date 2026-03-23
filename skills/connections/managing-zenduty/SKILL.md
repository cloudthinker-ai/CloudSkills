---
name: managing-zenduty
description: |
  Use when working with Zenduty — zenduty incident management covering incident
  lifecycle, SLA tracking, escalation policies, on-call scheduling, postmortem
  generation, service dependency mapping, and integration management. Use when
  configuring Zenduty incident workflows, tracking SLA compliance, managing
  on-call rotations, generating postmortems, or analyzing incident trends.
connection_type: zenduty
preload: false
---

# Zenduty Incident Management Skill

Manage Zenduty incidents, SLA tracking, on-call schedules, escalation policies, and postmortems.

## API Conventions

### Authentication
All API calls use the `Authorization: Token XXXXXX` header — injected automatically. Never hardcode tokens.

### Base URL
`https://www.zenduty.com/api`

### Core Helper Function

```bash
#!/bin/bash

zd_api() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"

    if [ -n "$data" ]; then
        curl -s -X "$method" \
            -H "Authorization: Token $ZENDUTY_API_KEY" \
            -H "Content-Type: application/json" \
            "https://www.zenduty.com/api${endpoint}" \
            -d "$data"
    else
        curl -s -X "$method" \
            -H "Authorization: Token $ZENDUTY_API_KEY" \
            "https://www.zenduty.com/api${endpoint}"
    fi
}
```

## Output Rules
- **TOKEN EFFICIENCY**: Extract only needed fields with `jq`
- Target ≤50 lines per script output

## Incident Management

### List Active Incidents
```bash
zd_api GET "/incidents/?status=1&team_id=TEAM_ID" | jq '[.results[] | {
  unique_id, title, status, urgency,
  service: .service.name,
  assigned_to: [.assigned_to[] | .username],
  created, acknowledged, resolved
}]'
```

### Get Incident Details
```bash
zd_api GET "/incidents/INCIDENT_ID/" | jq '{
  title, status, urgency, summary,
  service: .service.name,
  escalation_policy: .escalation_policy.name,
  sla: {breached: .sla_breached, response_time: .sla_response_time},
  timeline: [.logs[] | {action, timestamp, user}]
}'
```

## SLA Tracking

### Get SLA Policies
```bash
zd_api GET "/account/sla/" | jq '[.[] | {
  id, name, description,
  acknowledge_time, resolve_time,
  is_active, escalation_policy
}]'
```

### Check SLA Compliance
```bash
zd_api GET "/analytics/sla/?period=30d" | jq '{
  period: "30 days",
  totalIncidents: .total,
  slaCompliant: .compliant,
  slaBreach: .breached,
  complianceRate: .compliance_percentage,
  avgResponseTime: .avg_response_time,
  avgResolveTime: .avg_resolve_time
}'
```

## Escalation Policies

### List Escalation Policies
```bash
zd_api GET "/account/teams/TEAM_ID/escalation_policies/" | jq '[.[] | {
  unique_id, name, description,
  rules: [.rules[] | {delay: .delay, targets: [.targets[] | .target_type]}]
}]'
```

## On-Call Schedules

### Get Current On-Call
```bash
zd_api GET "/account/teams/TEAM_ID/schedules/" | jq '[.[] | {
  unique_id, name, timezone,
  current_on_call: .on_call_user.username,
  layers: [.layers[] | {name, rotation_type, users: [.users[] | .username]}]
}]'
```

## Postmortems

### List Postmortems
```bash
zd_api GET "/postmortems/?team_id=TEAM_ID" | jq '[.results[] | {
  id, title, incident: .incident.title,
  created, status,
  action_items: [.action_items[] | {description, assignee, status}]
}]'
```

### Create Postmortem
```bash
zd_api POST "/postmortems/" '{
  "incident": "INCIDENT_ID",
  "title": "Postmortem: Payment Service Outage",
  "team": "TEAM_ID"
}'
```

## Services

### List Services
```bash
zd_api GET "/account/teams/TEAM_ID/services/" | jq '[.[] | {
  unique_id, name, description,
  escalation_policy: .escalation_policy.name,
  sla: .sla.name,
  status: .status
}]'
```

## Common Tasks

1. **Track SLA compliance** — monitor acknowledgment and resolution time against SLA targets
2. **Generate postmortems** — create structured post-incident reports with action items
3. **Configure escalation** — build multi-tier escalation policies with appropriate delays
4. **Manage on-call rotations** — set up schedules with layers and override support
5. **Analyze incident trends** — review incident volume, severity distribution, and team workload

## Output Format

Present results as a structured report:
```
Managing Zenduty Report
═══════════════════════
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

