---
name: managing-practitest
description: |
  PractiTest test management platform monitoring and analysis. Covers project organization, test library management, test set and run execution, requirement traceability, issue tracking, custom field analysis, and dashboard metrics. Use when managing test cases in PractiTest, reviewing execution results, or tracking QA coverage and traceability.
connection_type: practitest
preload: false
---

# PractiTest Test Management Skill

Manage and analyze PractiTest projects, test libraries, runs, and traceability.

## Core Helper Functions

```bash
#!/bin/bash

# PractiTest API helper
practitest_api() {
    local method="${1:-GET}"
    local endpoint="$2"
    local data="${3:-}"

    if [ -n "$data" ]; then
        curl -s -X "$method" \
            -H "Authorization: custom ${PRACTITEST_API_TOKEN}" \
            -H "Content-Type: application/json" \
            "https://api.practitest.com/api/v2/${endpoint}" \
            -d "$data"
    else
        curl -s -X "$method" \
            -H "Authorization: custom ${PRACTITEST_API_TOKEN}" \
            "https://api.practitest.com/api/v2/${endpoint}"
    fi
}
```

## MANDATORY: Discovery-First Pattern

**Always discover projects and test libraries before querying specifics.**

### Phase 1: Discovery

```bash
#!/bin/bash

echo "=== PractiTest Projects ==="
practitest_api GET "projects.json" | jq -r '
    .data[] | "\(.id)\t\(.attributes.name)\tstatus=\(.attributes.status)"
' | column -t | head -15

echo ""
echo "=== Test Libraries ==="
PROJECT_ID="${1:?Project ID required}"
practitest_api GET "projects/${PROJECT_ID}/tests.json?page[number]=1&page[size]=20" | jq -r '
    .data[] | "\(.id)\t\(.attributes.name)\tstatus=\(.attributes.status)\tpriority=\(.attributes.priority // "none")"
' | column -t

echo ""
echo "=== Test Sets ==="
practitest_api GET "projects/${PROJECT_ID}/sets.json?page[number]=1&page[size]=15" | jq -r '
    .data[] | "\(.id)\t\(.attributes.name)\tstatus=\(.attributes.status)"
' | column -t

echo ""
echo "=== Requirements ==="
practitest_api GET "projects/${PROJECT_ID}/requirements.json?page[number]=1&page[size]=10" | jq -r '
    .data[] | "\(.id)\t\(.attributes.name)\tstatus=\(.attributes.status)"
' | column -t
```

### Phase 2: Analysis

```bash
#!/bin/bash

PROJECT_ID="${1:?Project ID required}"

echo "=== Run Instances ==="
SET_ID="${2:-}"
if [ -n "$SET_ID" ]; then
    practitest_api GET "projects/${PROJECT_ID}/instances.json?set-ids=${SET_ID}&page[size]=20" | jq -r '
        .data[] | "\(.id)\ttest=\(.attributes.test-id)\tstatus=\(.attributes.run-status)\tlast_run=\(.attributes.last-run-date // "never")"
    ' | column -t | head -15
fi

echo ""
echo "=== Recent Runs ==="
practitest_api GET "projects/${PROJECT_ID}/runs.json?page[number]=1&page[size]=10" | jq -r '
    .data[] | "\(.id)\tinstance=\(.attributes.instance-id)\tstatus=\(.attributes.status)\tdate=\(.attributes.created-at | split("T")[0])"
' | column -t

echo ""
echo "=== Issues ==="
practitest_api GET "projects/${PROJECT_ID}/issues.json?page[number]=1&page[size]=10" | jq -r '
    .data[] | "\(.id)\t\(.attributes.name)\tseverity=\(.attributes.severity // "none")\tstatus=\(.attributes.status)"
' | column -t

echo ""
echo "=== Traceability ==="
echo "Requirements linked to tests:"
practitest_api GET "projects/${PROJECT_ID}/requirements.json?page[size]=10" | jq -r '
    .data[] | "\(.id)\t\(.attributes.name)\tlinked_tests=\(.attributes["linked-tests-count"] // 0)"
' | column -t | head -10
```

## Output Rules
- **TOKEN EFFICIENCY**: Target 50 lines per output
- Use JSON:API pagination (page[number], page[size])
- Summarize traceability links, not full test step details

## Anti-Hallucination Rules
- NEVER guess project or test IDs — always discover via API
- NEVER fabricate run results — query actual PractiTest data
- NEVER assume custom field names — check project configuration

## Safety Rules
- NEVER create or delete test sets without explicit user confirmation
- NEVER modify test status without user approval
- NEVER delete issues without user consent
