---
name: managing-dagster
description: |
  Dagster data orchestration platform management. Covers asset management, pipeline runs, sensor and schedule status, IO manager configuration, partition management, and resource health. Use when checking asset materialization status, investigating run failures, managing schedules/sensors, or analyzing Dagster deployments.
connection_type: dagster
preload: false
---

# Dagster Management Skill

Manage and monitor Dagster assets, pipelines, and orchestration infrastructure via the Dagster GraphQL API.

## MANDATORY: Discovery-First Pattern

**Always query available repositories and asset groups before investigating specific runs or assets.**

### Phase 1: Discovery

```bash
#!/bin/bash

dagster_gql() {
    local query="$1"
    curl -s -X POST \
        -H "Content-Type: application/json" \
        -H "Dagster-Cloud-Api-Token: ${DAGSTER_API_TOKEN}" \
        "${DAGSTER_URL}/graphql" \
        -d "{\"query\": \"$query\"}"
}

echo "=== Repositories ==="
dagster_gql "{ repositoriesOrError { ... on RepositoryConnection { nodes { name location { name } } } } }" | jq -r '
    .data.repositoriesOrError.nodes[] | "\(.location.name)\t\(.name)"
' | column -t

echo ""
echo "=== Asset Groups ==="
dagster_gql "{ assetGroups { groupName } }" | jq -r '
    .data.assetGroups[] | .groupName
' 2>/dev/null | sort -u | head -20

echo ""
echo "=== Recent Runs ==="
dagster_gql "{ runsOrError(limit: 15) { ... on Runs { results { runId status pipelineName startTime endTime } } } }" | jq -r '
    .data.runsOrError.results[] | "\(.runId[0:8])\t\(.status)\t\(.pipelineName)\t\(.startTime | todate)"
' | column -t
```

## Core Helper Functions

```bash
#!/bin/bash

dagster_gql() {
    local query="$1"
    curl -s -X POST \
        -H "Content-Type: application/json" \
        -H "Dagster-Cloud-Api-Token: ${DAGSTER_API_TOKEN}" \
        "${DAGSTER_URL}/graphql" \
        -d "{\"query\": \"$query\"}"
}

# Convenience wrapper for common queries
dagster_runs() {
    local limit="${1:-10}"
    local status_filter="${2:-}"
    local filter=""
    if [ -n "$status_filter" ]; then
        filter="filter: {statuses: [${status_filter}]}"
    fi
    dagster_gql "{ runsOrError(limit: ${limit}, ${filter}) { ... on Runs { results { runId status pipelineName startTime endTime tags { key value } } } } }"
}
```

## Output Rules
- **TOKEN EFFICIENCY**: Target ≤50 lines per output
- Dagster uses GraphQL — request only needed fields in queries
- Never request full asset metadata — select specific fields

## Common Operations

### Run Status Dashboard

```bash
#!/bin/bash
echo "=== Run Summary (last 50 runs) ==="
dagster_gql "{ runsOrError(limit: 50) { ... on Runs { results { status } } } }" | jq '
    .data.runsOrError.results | group_by(.status) |
    map({status: .[0].status, count: length}) |
    sort_by(-.count) | .[] | "\(.status): \(.count)"
' -r

echo ""
echo "=== Failed Runs ==="
dagster_gql "{ runsOrError(limit: 10, filter: {statuses: [FAILURE]}) { ... on Runs { results { runId pipelineName startTime endTime } } } }" | jq -r '
    .data.runsOrError.results[] | "\(.runId[0:8])\t\(.pipelineName)\t\(.startTime | todate)"
' | column -t

echo ""
echo "=== Currently Running ==="
dagster_gql "{ runsOrError(filter: {statuses: [STARTED, STARTING]}) { ... on Runs { results { runId pipelineName startTime } } } }" | jq -r '
    .data.runsOrError.results[] | "\(.runId[0:8])\t\(.pipelineName)\t\(.startTime | todate)"
' | column -t
```

### Asset Materialization Status

```bash
#!/bin/bash
echo "=== Asset Keys ==="
dagster_gql "{ assetsOrError { ... on AssetConnection { nodes { key { path } } } } }" | jq -r '
    .data.assetsOrError.nodes[] | .key.path | join("/")
' | head -30

echo ""
echo "=== Latest Materializations ==="
dagster_gql '{
    assetsOrError {
        ... on AssetConnection {
            nodes {
                key { path }
                assetMaterializations(limit: 1) {
                    timestamp
                    runId
                    metadataEntries { label description }
                }
            }
        }
    }
}' | jq -r '
    .data.assetsOrError.nodes[] |
    select(.assetMaterializations | length > 0) |
    "\(.key.path | join("/"))\t\(.assetMaterializations[0].runId[0:8])\t\(.assetMaterializations[0].timestamp | tonumber | todate)"
' | column -t | head -20
```

### Sensor and Schedule Status

```bash
#!/bin/bash
REPO_LOCATION="${1:?Repository location required}"
REPO_NAME="${2:?Repository name required}"

echo "=== Schedules ==="
dagster_gql "{ schedulesOrError(repositorySelector: {repositoryLocationName: \"${REPO_LOCATION}\", repositoryName: \"${REPO_NAME}\"}) { ... on Schedules { results { name scheduleState { status } cronSchedule pipelineName } } } }" | jq -r '
    .data.schedulesOrError.results[] | "\(.name)\t\(.scheduleState.status)\t\(.cronSchedule)\t\(.pipelineName)"
' | column -t

echo ""
echo "=== Sensors ==="
dagster_gql "{ sensorsOrError(repositorySelector: {repositoryLocationName: \"${REPO_LOCATION}\", repositoryName: \"${REPO_NAME}\"}) { ... on Sensors { results { name sensorState { status } sensorType } } } }" | jq -r '
    .data.sensorsOrError.results[] | "\(.name)\t\(.sensorState.status)\t\(.sensorType)"
' | column -t
```

### Run Details and Logs

```bash
#!/bin/bash
RUN_ID="${1:?Run ID required}"

echo "=== Run Details ==="
dagster_gql "{ runOrError(runId: \"${RUN_ID}\") { ... on Run { runId status pipelineName mode startTime endTime tags { key value } stepStats { stepKey status startTime endTime } } } }" | jq '{
    run_id: .data.runOrError.runId,
    status: .data.runOrError.status,
    pipeline: .data.runOrError.pipelineName,
    started: (.data.runOrError.startTime | todate),
    ended: (.data.runOrError.endTime | if . then todate else "running" end),
    tags: [.data.runOrError.tags[] | "\(.key)=\(.value)"] | join(", ")
}'

echo ""
echo "=== Step Stats ==="
dagster_gql "{ runOrError(runId: \"${RUN_ID}\") { ... on Run { stepStats { stepKey status startTime endTime expectationResults { success } } } } }" | jq -r '
    .data.runOrError.stepStats[] | "\(.stepKey)\t\(.status)\t\(if .endTime and .startTime then (.endTime - .startTime | floor) else 0 end)s"
' | column -t | head -20
```

### Partition Management

```bash
#!/bin/bash
REPO_LOCATION="${1:?Repository location required}"
REPO_NAME="${2:?Repository name required}"
PIPELINE="${3:?Pipeline name required}"

echo "=== Partition Sets ==="
dagster_gql "{ partitionSetsOrError(repositorySelector: {repositoryLocationName: \"${REPO_LOCATION}\", repositoryName: \"${REPO_NAME}\"}, pipelineName: \"${PIPELINE}\") { ... on PartitionSets { results { name pipelineName } } } }" | jq -r '
    .data.partitionSetsOrError.results[] | "\(.name)\t\(.pipelineName)"
' | column -t

echo ""
echo "=== Partition Status (first partition set) ==="
PSET=$(dagster_gql "{ partitionSetsOrError(repositorySelector: {repositoryLocationName: \"${REPO_LOCATION}\", repositoryName: \"${REPO_NAME}\"}, pipelineName: \"${PIPELINE}\") { ... on PartitionSets { results { name } } } }" | jq -r '.data.partitionSetsOrError.results[0].name')

dagster_gql "{ partitionSetOrError(repositorySelector: {repositoryLocationName: \"${REPO_LOCATION}\", repositoryName: \"${REPO_NAME}\"}, partitionSetName: \"${PSET}\") { ... on PartitionSet { partitionsOrError(limit: 10) { ... on Partitions { results { name status } } } } } }" | jq -r '
    .data.partitionSetOrError.partitionsOrError.results[] | "\(.name)\t\(.status // "NOT_STARTED")"
' | column -t
```

## Common Pitfalls

- **GraphQL only**: Dagster uses GraphQL — all queries must be valid GQL, not REST endpoints
- **Asset vs Op**: Assets are the modern abstraction (software-defined); ops/pipelines are legacy — check which model the project uses
- **Run statuses**: `STARTED`, `SUCCESS`, `FAILURE`, `CANCELED`, `STARTING`, `CANCELING`, `QUEUED` — filter accordingly
- **Sensor tick timing**: Sensors have evaluation intervals — a sensor showing `RUNNING` doesn't mean it's processing right now
- **Dagster Cloud vs OSS**: Cloud uses API tokens and `dagster-cloud` CLI; OSS uses the GraphQL endpoint directly
- **Partition backfills**: Backfilling many partitions can overwhelm the run queue — check concurrency limits
- **IO Managers**: Data storage is handled by IO managers — errors in "step execution" may be IO manager config issues
- **Code locations**: In Dagster Cloud, code is deployed to "code locations" — ensure the correct location is loaded
- **Timestamps**: Dagster GraphQL returns Unix timestamps (seconds) — convert with `todate` in jq
