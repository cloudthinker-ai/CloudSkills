---
name: managing-pagerduty-deep
description: |
  Use when working with Pagerduty Deep — advanced PagerDuty management covering
  escalation policy design and optimization, event orchestration rules, AIOps
  noise reduction and intelligent grouping, analytics and reporting on incident
  volume and MTTA/MTTR trends, service dependency mapping, change events
  correlation, and automation actions. Use when performing deep PagerDuty
  configuration, tuning alert routing, analyzing on-call burden, or building
  event orchestration workflows.
connection_type: pagerduty
preload: false
---

# PagerDuty Advanced Management Skill

Deep management of PagerDuty escalation policies, event orchestration, AIOps features, and incident analytics.

## API Conventions

### Authentication
All API calls use the `Authorization: Token token=XXXXXX` header — injected automatically. Never hardcode tokens.

### Base URL
`https://api.pagerduty.com`

### Core Helper Function

```bash
#!/bin/bash

pd_api() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"

    if [ -n "$data" ]; then
        curl -s -X "$method" \
            -H "Authorization: Token token=$PAGERDUTY_API_KEY" \
            -H "Content-Type: application/json" \
            -H "Accept: application/vnd.pagerduty+json;version=2" \
            "https://api.pagerduty.com${endpoint}" \
            -d "$data"
    else
        curl -s -X "$method" \
            -H "Authorization: Token token=$PAGERDUTY_API_KEY" \
            -H "Accept: application/vnd.pagerduty+json;version=2" \
            "https://api.pagerduty.com${endpoint}"
    fi
}
```

## Output Rules
- **TOKEN EFFICIENCY**: Extract only needed fields with `jq`
- Target ≤50 lines per script output
- Always filter by relevant time range to avoid huge response sets

## Escalation Policy Management

### List All Escalation Policies
```bash
pd_api GET "/escalation_policies?total=true" | jq '{
  total: .total,
  policies: [.escalation_policies[] | {
    id, name, num_loops,
    teams: [.teams[]?.summary],
    rules_count: (.escalation_rules | length)
  }]
}'
```

### Analyze Escalation Policy Coverage
```bash
pd_api GET "/escalation_policies?total=true&include[]=targets" | jq '[.escalation_policies[] | {
  name,
  has_schedule: ([.escalation_rules[].targets[] | select(.type == "schedule_reference")] | length > 0),
  total_rules: (.escalation_rules | length),
  escalation_delay_minutes: [.escalation_rules[].escalation_delay_in_minutes]
}]'
```

## Event Orchestration

### List Event Orchestrations
```bash
pd_api GET "/event_orchestrations" | jq '[.orchestrations[] | {id, name, description, routes: .routes_count}]'
```

### Get Orchestration Rules
```bash
# Replace ORCH_ID with actual orchestration ID
pd_api GET "/event_orchestrations/ORCH_ID/router" | jq '.orchestration_path.sets[].rules[] | {
  label, conditions, actions
}'
```

## AIOps and Intelligent Grouping

### Review Intelligent Alert Grouping Settings
```bash
pd_api GET "/services?include[]=integrations&total=true" | jq '[.services[] | {
  name,
  alert_grouping_parameters: .alert_grouping_parameters,
  auto_resolve_timeout: .auto_resolve_timeout,
  acknowledgement_timeout: .acknowledgement_timeout
}]'
```

### Configure Alert Grouping for a Service
```bash
pd_api PUT "/services/SERVICE_ID" '{
  "service": {
    "alert_grouping_parameters": {
      "type": "intelligent"
    }
  }
}'
```

## Analytics and Reporting

### Get Incident Analytics for Time Range
```bash
pd_api POST "/analytics/metrics/incidents/all" '{
  "filters": {
    "created_at_start": "2024-01-01T00:00:00Z",
    "created_at_end": "2024-01-31T23:59:59Z"
  }
}' | jq '{
  total_incidents: .total,
  mean_time_to_resolve_seconds: .mean_seconds_to_resolve,
  mean_time_to_acknowledge_seconds: .mean_seconds_to_first_ack
}'
```

### Analyze On-Call Burden by Team
```bash
pd_api GET "/oncalls?earliest=true&since=2024-01-01T00:00:00Z&until=2024-01-31T23:59:59Z" | jq '
  [.oncalls[] | {user: .user.summary, schedule: .schedule.summary, escalation_policy: .escalation_policy.summary}]
  | group_by(.user) | map({user: .[0].user, schedules: length})
  | sort_by(-.schedules)
'
```

### Service Dependency Map
```bash
pd_api GET "/service_dependencies/technical_services" | jq '[.relationships[] | {
  dependent: .dependent_service.summary,
  supporting: .supporting_service.summary
}]'
```

## Change Events

### List Recent Change Events
```bash
pd_api GET "/change_events?since=2024-01-01T00:00:00Z&until=2024-01-31T23:59:59Z" | jq '[.change_events[] | {
  timestamp, summary,
  source: .source,
  services: [.services[]?.summary]
}]'
```

## Automation Actions

### List Automation Actions
```bash
pd_api GET "/automation_actions/actions" | jq '[.actions[] | {
  id, name, type: .action_type,
  runner: .runner_summary
}]'
```

## Common Tasks

1. **Audit escalation coverage** — verify every service has an escalation policy with on-call schedules
2. **Tune alert grouping** — switch services from time-based to intelligent grouping to reduce noise
3. **Analyze MTTA/MTTR trends** — use analytics endpoints to track improvement over time
4. **Review event orchestration** — check routing rules, suppression, and severity mapping
5. **Map service dependencies** — understand blast radius for upstream/downstream failures

## Output Format

Present results as a structured report:
```
Managing Pagerduty Deep Report
══════════════════════════════
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

