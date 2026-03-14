---
name: managing-dagster-deep
description: |
  Dagster deep data orchestration management covering job and asset inventory, run monitoring, schedule and sensor health, partition status, resource configuration, and daemon health checks. Use when investigating run failures, analyzing asset materialization, monitoring schedule ticks, or auditing Dagster configurations.
connection_type: dagster
preload: false
---

# Dagster Deep Management Skill

Manage and monitor Dagster jobs, assets, schedules, sensors, and infrastructure health.

## MANDATORY: Discovery-First Pattern

**Always list jobs and check daemon health before querying specific runs.**

### Phase 1: Discovery

```bash
#!/bin/bash

DAGSTER_API="${DAGSTER_URL:-http://localhost:3000}/graphql"

dagster_gql() {
    curl -s -H "Content-Type: application/json" \
         ${DAGSTER_API_TOKEN:+-H "Authorization: Bearer $DAGSTER_API_TOKEN"} \
         "${DAGSTER_API}" \
         -d "{\"query\": \"$1\"}"
}

echo "=== Dagster Instance Health ==="
dagster_gql "{ instance { daemonHealth { allDaemonStatuses { daemonType healthy lastHeartbeatTime } } } }" | jq -r '
    .data.instance.daemonHealth.allDaemonStatuses[] |
    "\(.daemonType)\t\(.healthy)\t\(.lastHeartbeatTime)"
' | column -t

echo ""
echo "=== Repositories ==="
dagster_gql "{ repositoriesOrError { ... on RepositoryConnection { nodes { name location { name } } } } }" | jq -r '
    .data.repositoriesOrError.nodes[] |
    "\(.name)\t\(.location.name)"
' | column -t

echo ""
echo "=== Jobs ==="
dagster_gql "{ repositoriesOrError { ... on RepositoryConnection { nodes { name pipelines { name } } } } }" | jq -r '
    .data.repositoriesOrError.nodes[] |
    .name as $repo | .pipelines[] |
    "\($repo)\t\(.name)"
' | column -t | head -30

echo ""
echo "=== Schedules ==="
dagster_gql "{ schedulesOrError { ... on Schedules { results { name scheduleState { status } cronSchedule } } } }" | jq -r '
    .data.schedulesOrError.results[] |
    "\(.name)\t\(.scheduleState.status)\t\(.cronSchedule)"
' | column -t | head -20
```

### Phase 2: Analysis

```bash
#!/bin/bash

echo "=== Failed Runs (recent) ==="
dagster_gql "{ runsOrError(filter: { statuses: [FAILURE] }, limit: 15) { ... on Runs { results { runId pipelineName status startTime endTime } } } }" | jq -r '
    .data.runsOrError.results[] |
    "\(.runId[:8])\t\(.pipelineName)\t\(.status)\t\(.startTime)"
' | column -t

echo ""
echo "=== Sensors ==="
dagster_gql "{ sensorsOrError { ... on Sensors { results { name sensorState { status } } } } }" | jq -r '
    .data.sensorsOrError.results[] |
    "\(.name)\t\(.sensorState.status)"
' | column -t

echo ""
echo "=== Asset Health ==="
dagster_gql "{ assetsOrError { ... on AssetConnection { nodes { key { path } assetMaterializations(limit: 1) { timestamp } } } } }" | jq -r '
    .data.assetsOrError.nodes[] |
    "\(.key.path | join("/"))\tLast: \(.assetMaterializations[0].timestamp // "never")"
' | column -t | head -20

echo ""
echo "=== Run Queue ==="
dagster_gql "{ runsOrError(filter: { statuses: [QUEUED, STARTING] }, limit: 10) { ... on Runs { results { runId pipelineName status } } } }" | jq -r '
    .data.runsOrError.results[] |
    "\(.runId[:8])\t\(.pipelineName)\t\(.status)"
' | column -t
```

## Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- Use status filters on GraphQL queries
- Never dump full run logs or asset metadata -- extract key status fields

## Common Pitfalls

- **Daemon health**: Scheduler and sensor daemons must be running -- stale heartbeats mean no scheduling
- **Run coordinator**: Run queue limits control concurrency -- queued runs wait for slots
- **Code location errors**: Import errors prevent jobs from loading -- check code location health
- **Partition backfills**: Large backfills can overwhelm the run coordinator
- **Asset freshness**: Stale assets may indicate upstream failures -- trace the dependency graph
- **Sensor cursor**: Sensor cursors track state -- resetting a cursor reprocesses events
- **Resource config**: Missing or invalid resource configurations cause immediate run failures
- **IO managers**: IO manager misconfiguration causes silent data loss between ops
