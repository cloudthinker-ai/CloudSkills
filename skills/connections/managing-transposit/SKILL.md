---
name: managing-transposit
description: |
  Use when working with Transposit — transposit incident management platform
  covering runbook automation, incident lifecycle management, activity tracking,
  automated workflows, integration connectors, and post-incident review. Use
  when managing Transposit runbooks, automating incident response workflows,
  tracking incident activities, or configuring integration connectors for
  coordinated response.
connection_type: transposit
preload: false
---

# Transposit Incident Management Skill

Manage Transposit incident lifecycle, runbook automation, workflows, and integrations.

## API Conventions

### Authentication
All API calls use the `Authorization: Bearer XXXXXX` header — injected automatically. Never hardcode tokens.

### Base URL
`https://api.transposit.com`

### Core Helper Function

```bash
#!/bin/bash

tp_api() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"

    if [ -n "$data" ]; then
        curl -s -X "$method" \
            -H "Authorization: Bearer $TRANSPOSIT_API_KEY" \
            -H "Content-Type: application/json" \
            "https://api.transposit.com${endpoint}" \
            -d "$data"
    else
        curl -s -X "$method" \
            -H "Authorization: Bearer $TRANSPOSIT_API_KEY" \
            "https://api.transposit.com${endpoint}"
    fi
}
```

## Output Rules
- **TOKEN EFFICIENCY**: Extract only needed fields with `jq`
- Target ≤50 lines per script output

## Incident Management

### List Active Incidents
```bash
tp_api GET "/v1/incidents?status=active&limit=25" | jq '[.incidents[] | {
  id, title, severity, status,
  commander, createdAt,
  slackChannel, services: [.services[]]
}]'
```

### Get Incident Details
```bash
tp_api GET "/v1/incidents/INCIDENT_ID" | jq '{
  title, severity, status, impact,
  commander, createdAt, resolvedAt,
  timeline: [.activities[] | {type, message, author, timestamp}],
  runbooksExecuted: [.runbooks[] | .name]
}'
```

### Create Incident
```bash
tp_api POST "/v1/incidents" '{
  "title": "Payment service degradation",
  "severity": "SEV2",
  "commander": "user@company.com",
  "services": ["payment-api"]
}'
```

## Runbook Automation

### List Runbooks
```bash
tp_api GET "/v1/runbooks" | jq '[.runbooks[] | {id, name, description, lastRun, triggerType}]'
```

### Execute a Runbook
```bash
tp_api POST "/v1/runbooks/RUNBOOK_ID/execute" '{
  "incidentId": "INCIDENT_ID",
  "parameters": {"service": "payment-api", "action": "restart"}
}'
```

### Get Runbook Execution History
```bash
tp_api GET "/v1/runbooks/RUNBOOK_ID/executions?limit=10" | jq '[.executions[] | {
  id, status, startedAt, completedAt,
  triggeredBy, incidentId,
  steps: [.steps[] | {name, status, output}]
}]'
```

## Activity Tracking

### Get Incident Activities
```bash
tp_api GET "/v1/incidents/INCIDENT_ID/activities" | jq '[.activities[] | {
  type, message, author, timestamp
}]'
```

### Add Activity to Incident
```bash
tp_api POST "/v1/incidents/INCIDENT_ID/activities" '{
  "type": "note",
  "message": "Root cause identified: database connection pool exhaustion"
}'
```

## Workflow Management

### List Workflows
```bash
tp_api GET "/v1/workflows" | jq '[.workflows[] | {id, name, trigger, enabled, actions: [.steps[] | .type]}]'
```

## Common Tasks

1. **Execute runbooks** — trigger automated response procedures during incidents
2. **Track incident lifecycle** — monitor creation, escalation, and resolution activities
3. **Review runbook history** — analyze execution success rates and step-level outcomes
4. **Configure workflows** — set up automated triggers for incident lifecycle events
5. **Post-incident review** — gather timeline data for blameless postmortems

## Output Format

Present results as a structured report:
```
Managing Transposit Report
══════════════════════════
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

