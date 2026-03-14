---
name: managing-moogsoft
description: |
  Moogsoft AI-driven incident management covering intelligent alert detection, noise reduction, correlation engine tuning, situation management, workflow automation, and performance analytics. Use when configuring Moogsoft correlation algorithms, analyzing alert noise reduction effectiveness, managing situations, or reviewing AI-driven incident detection patterns.
connection_type: moogsoft
preload: false
---

# Moogsoft AI Incident Management Skill

Manage Moogsoft AI-driven alert detection, noise reduction, correlation, and situation management.

## API Conventions

### Authentication
All API calls use the `Authorization: Bearer XXXXXX` header — injected automatically. Never hardcode tokens.

### Base URL
`https://INSTANCE.moogsoft.ai/api`

### Core Helper Function

```bash
#!/bin/bash

ms_api() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"

    if [ -n "$data" ]; then
        curl -s -X "$method" \
            -H "Authorization: Bearer $MOOGSOFT_API_KEY" \
            -H "Content-Type: application/json" \
            "https://${MOOGSOFT_INSTANCE}.moogsoft.ai/api${endpoint}" \
            -d "$data"
    else
        curl -s -X "$method" \
            -H "Authorization: Bearer $MOOGSOFT_API_KEY" \
            "https://${MOOGSOFT_INSTANCE}.moogsoft.ai/api${endpoint}"
    fi
}
```

## Output Rules
- **TOKEN EFFICIENCY**: Extract only needed fields with `jq`
- Target ≤50 lines per script output

## Alert Management

### Get Active Alerts
```bash
ms_api GET "/v1/alerts?status=open&limit=50&sort=-createdAt" | jq '[.[] | {
  id, description, severity, source,
  class, service, createdAt,
  dedupCount, situationId
}]'
```

### Get Alert Statistics
```bash
ms_api GET "/v1/alerts/stats?period=24h" | jq '{
  totalAlerts: .total,
  deduplicated: .deduplicated,
  noiseReductionPercent: .noiseReduction,
  bySeverity: .bySeverity,
  topSources: [.bySource[:5]]
}'
```

## Situation Management

### List Active Situations
```bash
ms_api GET "/v1/situations?status=open&limit=25" | jq '[.[] | {
  id, description, severity, status,
  alertCount, createdAt,
  owner, services: [.services[]]
}]'
```

### Get Situation Details
```bash
ms_api GET "/v1/situations/SITUATION_ID" | jq '{
  description, severity, status,
  alertCount, createdAt, lastUpdated,
  alerts: [.alerts[] | {id, description, severity, source}],
  suggestedActions: .suggestions
}'
```

## Correlation Engine

### Get Correlation Definitions
```bash
ms_api GET "/v1/correlation-definitions" | jq '[.[] | {
  id, name, type, enabled,
  algorithm, parameters
}]'
```

### Review Noise Reduction Metrics
```bash
ms_api GET "/v1/metrics/noise-reduction?period=7d" | jq '{
  period: "7 days",
  totalIncoming: .totalAlerts,
  afterDedup: .afterDeduplication,
  afterCorrelation: .afterCorrelation,
  reductionPercent: .overallReduction,
  trend: .dailyTrend
}'
```

## Workflow Automation

### List Workflows
```bash
ms_api GET "/v1/workflows" | jq '[.[] | {id, name, enabled, trigger, actions: [.actions[] | .type]}]'
```

## Common Tasks

1. **Monitor noise reduction** — track deduplication and correlation effectiveness
2. **Tune correlation algorithms** — adjust time windows, similarity thresholds, and clustering
3. **Manage situations** — review, merge, or split correlated incident groups
4. **Analyze alert patterns** — identify noisy sources and flapping alerts
5. **Configure workflows** — automate situation assignment, notification, and enrichment
