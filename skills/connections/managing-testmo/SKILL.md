---
name: managing-testmo
description: |
  Testmo test management platform monitoring and analysis. Covers project organization, test case and suite management, automation run tracking, exploratory session review, milestone progress, and field configuration. Use when managing test cases in Testmo, reviewing automated and manual test results, or tracking QA progress.
connection_type: testmo
preload: false
---

# Testmo Test Management Skill

Manage and analyze Testmo projects, test suites, automation runs, and results.

## Core Helper Functions

```bash
#!/bin/bash

# Testmo API helper
testmo_api() {
    local method="${1:-GET}"
    local endpoint="$2"
    local data="${3:-}"

    if [ -n "$data" ]; then
        curl -s -X "$method" \
            -H "Authorization: Bearer ${TESTMO_API_TOKEN}" \
            -H "Content-Type: application/json" \
            "${TESTMO_URL}/api/v1/${endpoint}" \
            -d "$data"
    else
        curl -s -X "$method" \
            -H "Authorization: Bearer ${TESTMO_API_TOKEN}" \
            "${TESTMO_URL}/api/v1/${endpoint}"
    fi
}
```

## MANDATORY: Discovery-First Pattern

**Always discover projects and resources before querying specifics.**

### Phase 1: Discovery

```bash
#!/bin/bash

echo "=== Testmo Projects ==="
testmo_api GET "projects" | jq -r '
    .result[] | "\(.id)\t\(.name)\tstatus=\(.status)"
' | column -t | head -15

echo ""
echo "=== Test Suites ==="
PROJECT_ID="${1:?Project ID required}"
testmo_api GET "projects/${PROJECT_ID}/suites" | jq -r '
    .result[] | "\(.id)\t\(.name)\tcases=\(.case_count // 0)"
' | column -t | head -15

echo ""
echo "=== Recent Automation Runs ==="
testmo_api GET "projects/${PROJECT_ID}/automation/runs?limit=10" | jq -r '
    .result[] | "\(.id)\t\(.name)\tstatus=\(.status_text)\tpassed=\(.passed_count)\tfailed=\(.failed_count)"
' | column -t

echo ""
echo "=== Milestones ==="
testmo_api GET "projects/${PROJECT_ID}/milestones" | jq -r '
    .result[] | "\(.id)\t\(.name)\tstatus=\(.status)\tprogress=\(.progress // 0)%"
' | column -t | head -10
```

### Phase 2: Analysis

```bash
#!/bin/bash

PROJECT_ID="${1:?Project ID required}"

echo "=== Test Case Statistics ==="
testmo_api GET "projects/${PROJECT_ID}/suites" | jq '{
    total_suites: (.result | length),
    total_cases: [.result[].case_count // 0] | add
}'

echo ""
echo "=== Automation Run Details ==="
RUN_ID="${2:-}"
if [ -n "$RUN_ID" ]; then
    testmo_api GET "projects/${PROJECT_ID}/automation/runs/${RUN_ID}" | jq '{
        name: .result.name,
        status: .result.status_text,
        passed: .result.passed_count,
        failed: .result.failed_count,
        elapsed: .result.elapsed,
        source: .result.source
    }'

    echo ""
    echo "=== Failed Tests ==="
    testmo_api GET "projects/${PROJECT_ID}/automation/runs/${RUN_ID}/tests?status=failed&limit=20" | jq -r '
        .result[] | "\(.name)\t\(.status_text)\t\(.elapsed // 0)s"
    ' | column -t | head -15
fi

echo ""
echo "=== Exploratory Sessions ==="
testmo_api GET "projects/${PROJECT_ID}/sessions?limit=5" | jq -r '
    .result[] | "\(.id)\t\(.name)\tissues=\(.issue_count // 0)\tnotes=\(.note_count // 0)"
' | column -t
```

## Output Rules
- **TOKEN EFFICIENCY**: Target 50 lines per output
- Use API pagination for large datasets
- Summarize test case metadata, not full step descriptions

## Anti-Hallucination Rules
- NEVER guess project or suite IDs — always discover via API
- NEVER fabricate run results — query actual data
- NEVER assume API endpoint structure — verify with Testmo docs

## Safety Rules
- NEVER create or delete runs without explicit user confirmation
- NEVER modify test cases without user approval
- NEVER close milestones without user consent
