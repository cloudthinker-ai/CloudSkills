---
name: managing-testrail
description: |
  TestRail test case management and reporting. Covers project and suite organization, test case review, test run and plan management, milestone tracking, result analysis, and user activity monitoring. Use when managing test cases in TestRail, reviewing test execution results, or tracking QA progress across milestones.
connection_type: testrail
preload: false
---

# TestRail Test Management Skill

Manage and analyze TestRail projects, test cases, runs, and results.

## Core Helper Functions

```bash
#!/bin/bash

# TestRail API helper
testrail_api() {
    local method="${1:-GET}"
    local endpoint="$2"
    local data="${3:-}"

    if [ -n "$data" ]; then
        curl -s -X "$method" \
            -u "${TESTRAIL_USER}:${TESTRAIL_API_KEY}" \
            -H "Content-Type: application/json" \
            "${TESTRAIL_URL}/index.php?/api/v2/${endpoint}" \
            -d "$data"
    else
        curl -s -X "$method" \
            -u "${TESTRAIL_USER}:${TESTRAIL_API_KEY}" \
            "${TESTRAIL_URL}/index.php?/api/v2/${endpoint}"
    fi
}
```

## MANDATORY: Discovery-First Pattern

**Always discover projects and suites before querying specific test cases or runs.**

### Phase 1: Discovery

```bash
#!/bin/bash

echo "=== TestRail Projects ==="
testrail_api GET "get_projects" | jq -r '
    .projects[] | select(.is_completed == false) |
    "\(.id)\t\(.name)\t\(.suite_mode)"
' | column -t | head -15

echo ""
echo "=== Recent Test Runs ==="
PROJECT_ID="${1:?Project ID required}"
testrail_api GET "get_runs/${PROJECT_ID}&is_completed=0" | jq -r '
    .runs[:10][] | "\(.id)\t\(.name)\t\(.passed_count)/\(.untested_count + .passed_count + .failed_count + .retest_count) passed\t\(.failed_count) failed"
' | column -t

echo ""
echo "=== Active Milestones ==="
testrail_api GET "get_milestones/${PROJECT_ID}&is_completed=0" | jq -r '
    .milestones[] | "\(.id)\t\(.name)\t\(.due_on | if . then (. | strftime("%Y-%m-%d")) else "no date" end)"
' | column -t | head -10
```

### Phase 2: Analysis

```bash
#!/bin/bash

PROJECT_ID="${1:?Project ID required}"

echo "=== Test Case Summary ==="
testrail_api GET "get_cases/${PROJECT_ID}" | jq '{
    total: (.cases | length),
    by_priority: (.cases | group_by(.priority_id) | map({priority: .[0].priority_id, count: length})),
    by_type: (.cases | group_by(.type_id) | map({type: .[0].type_id, count: length}))
}' | head -20

echo ""
echo "=== Run Results ==="
RUN_ID="${2:-}"
if [ -n "$RUN_ID" ]; then
    testrail_api GET "get_results_for_run/${RUN_ID}" | jq -r '
        .results[:20][] | "\(.test_id)\t\(if .status_id == 1 then "PASSED" elif .status_id == 5 then "FAILED" else "OTHER" end)\t\(.created_on | strftime("%Y-%m-%d %H:%M"))"
    ' | column -t
fi

echo ""
echo "=== Test Plan Overview ==="
testrail_api GET "get_plans/${PROJECT_ID}&is_completed=0" | jq -r '
    .plans[:5][] | "\(.id)\t\(.name)\tpassed=\(.passed_count)\tfailed=\(.failed_count)\tuntested=\(.untested_count)"
' | column -t
```

## Output Rules
- **TOKEN EFFICIENCY**: Target 50 lines per output
- Use API pagination (&limit=&offset=) for large datasets
- Never dump full test case descriptions — show title and status only

## Anti-Hallucination Rules
- NEVER guess project or run IDs — always discover via API
- NEVER fabricate test results — query actual run data
- NEVER assume suite mode — check project configuration first

## Safety Rules
- NEVER create or delete test runs without explicit user confirmation
- NEVER modify test cases without user approval
- NEVER close milestones or runs without user consent
