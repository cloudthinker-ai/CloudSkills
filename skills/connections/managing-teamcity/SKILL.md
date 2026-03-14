---
name: managing-teamcity
description: |
  TeamCity CI/CD server management. Covers build configurations, agent pools, VCS roots, build queue monitoring, project hierarchy, and build chain analysis. Use when checking build status, investigating failures, managing agents, or auditing TeamCity project configurations.
connection_type: teamcity
preload: false
---

# TeamCity Management Skill

Manage and monitor TeamCity build configurations, agents, and projects.

## Core Helper Functions

```bash
#!/bin/bash

# TeamCity REST API helper
tc_api() {
    local method="${1:-GET}"
    local endpoint="$2"
    local data="${3:-}"

    if [ -n "$data" ]; then
        curl -s -X "$method" \
            -H "Authorization: Bearer ${TEAMCITY_TOKEN}" \
            -H "Content-Type: application/json" \
            -H "Accept: application/json" \
            "${TEAMCITY_URL}/app/rest/${endpoint}" \
            -d "$data"
    else
        curl -s -X "$method" \
            -H "Authorization: Bearer ${TEAMCITY_TOKEN}" \
            -H "Accept: application/json" \
            "${TEAMCITY_URL}/app/rest/${endpoint}"
    fi
}
```

## MANDATORY: Discovery-First Pattern

**Always list projects, build types, and agents before querying specifics.**

### Phase 1: Discovery

```bash
#!/bin/bash

echo "=== TeamCity Server Info ==="
tc_api GET "server" | jq '{version: .version, buildNumber: .buildNumber, startTime: .startTime}'

echo ""
echo "=== Projects ==="
tc_api GET "projects" | jq -r '
    .project[] | select(.archived != true) |
    "\(.id)\t\(.name)\t\(.parentProjectId // "root")"
' | column -t | head -20

echo ""
echo "=== Build Configurations ==="
tc_api GET "buildTypes" | jq -r '
    .buildType[] | "\(.id)\t\(.name)\t\(.projectName)"
' | column -t | head -20

echo ""
echo "=== Agent Summary ==="
tc_api GET "agents?locator=authorized:true" | jq -r '
    .agent[] | "\(.id)\t\(.name)\t\(if .connected then "CONNECTED" else "DISCONNECTED" end)\t\(if .enabled then "ENABLED" else "DISABLED" end)"
' | column -t
```

## Output Rules
- **TOKEN EFFICIENCY**: Target 50 lines per output
- Use TeamCity locators for server-side filtering (e.g., `locator=status:failure,count:10`)
- Never dump full build logs — use build problem and test failure endpoints

## Common Operations

### Build Status Dashboard

```bash
#!/bin/bash
echo "=== Recent Builds ==="
tc_api GET "builds?locator=count:20,defaultFilter:false" | jq -r '
    .build[] |
    "\(.buildType.name)\t#\(.number)\t\(.status)\t\(.state)\t\(.branchName // "default")\t\(.finishDate[0:15] // "running")"
' | column -t

echo ""
echo "=== Failed Builds ==="
tc_api GET "builds?locator=status:FAILURE,count:10" | jq -r '
    .build[] |
    "\(.buildType.name)\t#\(.number)\t\(.statusText[0:50])\t\(.finishDate[0:15])"
' | column -t

echo ""
echo "=== Build Queue ==="
tc_api GET "buildQueue" | jq -r '
    .build[]? |
    "\(.buildType.name)\t\(.branchName // "default")\tqueued=\(.queuedDate[0:15])\treason=\(.waitReason // "unknown")"
' | column -t
```

### Build Configuration Analysis

```bash
#!/bin/bash
BUILD_TYPE_ID="${1:?Build type ID required}"

echo "=== Build Config Details ==="
tc_api GET "buildTypes/id:${BUILD_TYPE_ID}" | jq '{
    id, name, projectName,
    vcs_roots: [.vcsRootEntries.vcsRootEntry[]? | .vcsRoot.name],
    steps: [."steps".step[]? | {name, type: .type}],
    triggers: [.triggers.trigger[]? | {type: .type}],
    parameters_count: (.parameters.property | length)
}'

echo ""
echo "=== Build History ==="
tc_api GET "builds?locator=buildType:id:${BUILD_TYPE_ID},count:15" | jq -r '
    .build[] |
    "\(#\(.number))\t\(.status)\t\(.branchName // "default")\t\(.finishDate[0:15] // "running")\tduration=\((.statistics.property[]? | select(.name == "BuildDuration") | .value) // "unknown")"
' | column -t
```

### Agent Pool Management

```bash
#!/bin/bash
echo "=== Agent Pools ==="
tc_api GET "agentPools" | jq -r '
    .agentPool[] | "\(.id)\t\(.name)\tagents=\(.agents.count // 0)\tprojects=\(.projects.count // "all")"
' | column -t

echo ""
echo "=== Agent Details ==="
tc_api GET "agents?locator=authorized:true&fields=agent(id,name,connected,enabled,pool,build,properties)" | jq -r '
    .agent[] |
    "\(.name)\t\(if .connected then "UP" else "DOWN" end)\tpool=\(.pool.name // "default")\tbusy=\(if .build then "yes" else "no" end)"
' | column -t

echo ""
echo "=== Disconnected Agents ==="
tc_api GET "agents?locator=connected:false,authorized:true" | jq -r '
    .agent[]? | "\(.id)\t\(.name)\tenabled=\(.enabled)"
' | column -t
```

### VCS Root Management

```bash
#!/bin/bash
echo "=== VCS Roots ==="
tc_api GET "vcs-roots" | jq -r '
    .["vcs-root"][] | "\(.id)\t\(.name)\t\(.vcsName)"
' | column -t | head -20

echo ""
echo "=== VCS Root Details ==="
VCS_ID="${1:?VCS root ID required}"
tc_api GET "vcs-roots/id:${VCS_ID}" | jq '{
    id, name, vcsName,
    url: (.properties.property[] | select(.name == "url") | .value),
    branch: (.properties.property[] | select(.name == "branch") | .value)
}'
```

### Build Problems & Test Failures

```bash
#!/bin/bash
BUILD_ID="${1:?Build ID required}"

echo "=== Build Problems ==="
tc_api GET "builds/id:${BUILD_ID}/problemOccurrences" | jq -r '
    .problemOccurrence[]? |
    "\(.type)\t\(.details[0:80])"
' | column -t

echo ""
echo "=== Test Failures ==="
tc_api GET "builds/id:${BUILD_ID}/testOccurrences?locator=status:FAILURE,count:20" | jq -r '
    .testOccurrence[]? |
    "\(.name | split(".")[-1])\t\(.duration // 0)ms\t\(.details[0:60] // "")"
' | column -t

echo ""
echo "=== Build Log (tail) ==="
curl -s -H "Authorization: Bearer ${TEAMCITY_TOKEN}" \
    "${TEAMCITY_URL}/downloadBuildLog.html?buildId=${BUILD_ID}" | tail -50
```

## Anti-Hallucination Rules
- NEVER guess build type IDs — always discover via projects or buildTypes endpoint
- NEVER fabricate build numbers — query build history first
- NEVER assume agent names — list agents to find actual names
- TeamCity uses locator syntax (not query params) for filtering — use correct format

## Safety Rules
- NEVER trigger builds without explicit user confirmation
- NEVER disable agents without user approval
- NEVER modify build configurations without understanding the build chain
- NEVER expose parameter values marked as password type

## Common Pitfalls
- **Locator syntax**: TeamCity uses custom locator format (e.g., `buildType:id:MyBuild,count:10`) not standard query params
- **Build chains**: Snapshot dependencies create build chains — triggering one build may trigger dependencies
- **Personal builds**: Personal builds run on agent but don't affect main status — filter with `personal:false`
- **Clean checkout**: Some build problems require clean checkout — check VCS checkout rules
- **Composite builds**: Composite build types aggregate results from dependencies — they have no own steps
- **REST API versions**: Older TeamCity versions may not support all REST endpoints — check server version
