---
name: managing-shoreline
description: |
  Shoreline.io incident automation platform covering Op packs, automated remediation actions, metric and resource queries, alarm configuration, bot management, and notebook-driven debugging. Use when building Shoreline remediation automations, managing Op packs, querying infrastructure resources, or configuring automated incident response actions.
connection_type: shoreline
preload: false
---

# Shoreline.io Incident Automation Skill

Manage Shoreline Op packs, automated remediation, resource queries, and alarm configurations.

## API Conventions

### Authentication
All API calls use the `Authorization: Bearer XXXXXX` header — injected automatically. Never hardcode tokens.

### Base URL
`https://INSTANCE.us.api.shoreline-REGION.io`

### Core Helper Function

```bash
#!/bin/bash

sl_api() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"

    if [ -n "$data" ]; then
        curl -s -X "$method" \
            -H "Authorization: Bearer $SHORELINE_TOKEN" \
            -H "Content-Type: application/json" \
            "https://${SHORELINE_URL}${endpoint}" \
            -d "$data"
    else
        curl -s -X "$method" \
            -H "Authorization: Bearer $SHORELINE_TOKEN" \
            "https://${SHORELINE_URL}${endpoint}"
    fi
}
```

## Output Rules
- **TOKEN EFFICIENCY**: Extract only needed fields with `jq`
- Target ≤50 lines per script output

## Op Packs

### List Installed Op Packs
```bash
sl_api GET "/v1/op-packs" | jq '[.[] | {name, version, description, enabled, actions: [.actions[]?.name]}]'
```

### Get Op Pack Details
```bash
sl_api GET "/v1/op-packs/OP_PACK_NAME" | jq '{
  name, version, description,
  alarms: [.alarms[] | {name, query}],
  actions: [.actions[] | {name, command, allowedEntities}],
  bots: [.bots[] | {name, alarm, action}]
}'
```

## Remediation Actions

### List Actions
```bash
sl_api GET "/v1/actions" | jq '[.[] | {name, description, command, resourceType, enabled}]'
```

### Create a Remediation Action
```bash
sl_api POST "/v1/actions" '{
  "name": "restart_service",
  "description": "Restart a failing service",
  "command": "sudo systemctl restart ${service_name}",
  "resourceType": "HOST",
  "params": [{"name": "service_name", "required": true}]
}'
```

## Resource Queries

### Query Resources
```bash
sl_api POST "/v1/query" '{
  "query": "hosts | filter(cpu_usage > 90)"
}' | jq '[.resources[] | {name, type, tags, metrics: {cpu: .cpu_usage, memory: .memory_usage}}]'
```

### Query Pods
```bash
sl_api POST "/v1/query" '{
  "query": "pods | filter(namespace = \"production\" AND restart_count > 3)"
}' | jq '[.resources[] | {name, namespace, restartCount, status}]'
```

## Alarms

### List Alarms
```bash
sl_api GET "/v1/alarms" | jq '[.[] | {name, query, fireQuery, clearQuery, enabled, severity}]'
```

### Get Alarm Status
```bash
sl_api GET "/v1/alarms/ALARM_NAME/status" | jq '{name, state, firingResources: [.firing[] | .name], lastFired, lastCleared}'
```

## Bots (Automation)

### List Bots
```bash
sl_api GET "/v1/bots" | jq '[.[] | {name, alarm, action, enabled, executionCount}]'
```

### Create a Bot
```bash
sl_api POST "/v1/bots" '{
  "name": "auto_restart_on_oom",
  "alarm": "high_memory_alarm",
  "action": "restart_service",
  "enabled": true
}'
```

## Common Tasks

1. **Deploy Op packs** — install pre-built remediation packages for common failure modes
2. **Build custom actions** — create remediation scripts for application-specific recovery
3. **Configure bots** — wire alarms to automated actions for self-healing infrastructure
4. **Query infrastructure** — use Shoreline's query language to find problematic resources
5. **Review alarm effectiveness** — analyze alarm firing frequency and false positive rates
