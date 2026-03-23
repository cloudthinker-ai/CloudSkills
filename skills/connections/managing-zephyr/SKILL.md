---
name: managing-zephyr
description: |
  Use when working with Zephyr — zephyr test management (Scale/Squad) monitoring
  and analysis. Covers test case management within Jira, test cycle execution
  tracking, folder organization, execution status reporting, traceability matrix
  review, and environment configuration. Use when managing test cases in Zephyr,
  tracking test execution within Jira, or reviewing QA coverage.
connection_type: zephyr
preload: false
---

# Zephyr Test Management Skill

Manage and analyze Zephyr Scale/Squad test cases, cycles, and executions within Jira.

## Core Helper Functions

```bash
#!/bin/bash

# Zephyr Scale API helper (Cloud)
zephyr_api() {
    local method="${1:-GET}"
    local endpoint="$2"
    local data="${3:-}"

    if [ -n "$data" ]; then
        curl -s -X "$method" \
            -H "Authorization: Bearer ${ZEPHYR_API_TOKEN}" \
            -H "Content-Type: application/json" \
            "https://api.zephyrscale.smartbear.com/v2/${endpoint}" \
            -d "$data"
    else
        curl -s -X "$method" \
            -H "Authorization: Bearer ${ZEPHYR_API_TOKEN}" \
            "https://api.zephyrscale.smartbear.com/v2/${endpoint}"
    fi
}
```

## MANDATORY: Discovery-First Pattern

**Always discover projects and test cycles before querying specifics.**

### Phase 1: Discovery

```bash
#!/bin/bash

echo "=== Zephyr Projects ==="
zephyr_api GET "projects?maxResults=20" | jq -r '
    .values[] | "\(.id)\t\(.key)\t\(.name)"
' | column -t

echo ""
echo "=== Test Cases ==="
PROJECT_KEY="${1:?Project key required}"
zephyr_api GET "testcases?projectKey=${PROJECT_KEY}&maxResults=20" | jq -r '
    .values[] | "\(.key)\t\(.name)\tpriority=\(.priority.name // "none")\tstatus=\(.status.name // "draft")"
' | column -t

echo ""
echo "=== Active Test Cycles ==="
zephyr_api GET "testcycles?projectKey=${PROJECT_KEY}&maxResults=10" | jq -r '
    .values[] | "\(.key)\t\(.name)\tstatus=\(.status.name)\tplanned=\(.plannedStartDate // "unset")"
' | column -t

echo ""
echo "=== Folders ==="
zephyr_api GET "folders?projectKey=${PROJECT_KEY}&folderType=TEST_CASE&maxResults=15" | jq -r '
    .values[] | "\(.id)\t\(.name)\ttype=\(.folderType)"
' | column -t | head -15
```

### Phase 2: Analysis

```bash
#!/bin/bash

PROJECT_KEY="${1:?Project key required}"

echo "=== Test Execution Summary ==="
CYCLE_KEY="${2:-}"
if [ -n "$CYCLE_KEY" ]; then
    zephyr_api GET "testexecutions?testCycle=${CYCLE_KEY}&maxResults=100" | jq '{
        total: .total,
        by_status: (.values | group_by(.testExecutionStatus.name) | map({status: .[0].testExecutionStatus.name, count: length}))
    }'

    echo ""
    echo "=== Failed Executions ==="
    zephyr_api GET "testexecutions?testCycle=${CYCLE_KEY}&maxResults=50" | jq -r '
        .values[] | select(.testExecutionStatus.name == "Fail") |
        "\(.testCase.key)\t\(.testCase.name // "unnamed")\texecuted=\(.executedOn // "unknown")"
    ' | column -t | head -15
fi

echo ""
echo "=== Traceability ==="
zephyr_api GET "testcases?projectKey=${PROJECT_KEY}&maxResults=20" | jq -r '
    .values[] | select(.links | length > 0) |
    "\(.key)\t\(.name)\tissue_links=\(.links | length)"
' | column -t | head -10

echo ""
echo "=== Environments ==="
zephyr_api GET "environments?projectKey=${PROJECT_KEY}" | jq -r '
    .values[] | "\(.id)\t\(.name)\t\(.description // "no description")"
' | column -t | head -10
```

## Output Rules
- **TOKEN EFFICIENCY**: Target 50 lines per output
- Use maxResults pagination parameter for large datasets
- Summarize execution statuses, not full test step details

## Anti-Hallucination Rules
- NEVER guess test case or cycle keys — always discover via API
- NEVER fabricate execution results — query actual Zephyr data
- NEVER assume Zephyr Scale vs Squad — check API endpoint compatibility

## Safety Rules
- NEVER create or delete test cycles without explicit user confirmation
- NEVER modify test case status without user approval
- NEVER change execution results without user consent

## Output Format

Present results as a structured report:
```
Managing Zephyr Report
══════════════════════
Resources discovered: [count]

Resource       Status    Key Metric    Issues
──────────────────────────────────────────────
[name]         [ok/warn] [value]       [findings]

Summary: [total] resources | [ok] healthy | [warn] warnings | [crit] critical
Action Items: [list of prioritized findings]
```

Target ≤50 lines of output. Use tables for multi-resource comparisons.

## Counter-Rationalizations

| Shortcut | Counter | Why |
|----------|---------|-----|
| "I'll skip discovery and check known resources" | Always run Phase 1 discovery first | Resource names change, new resources appear — assumed names cause errors |
| "The user only asked for a quick check" | Follow the full discovery → analysis flow | Quick checks miss critical issues; structured analysis catches silent failures |
| "Default configuration is probably fine" | Audit configuration explicitly | Defaults often leave logging, security, and optimization features disabled |
| "Metrics aren't needed for this" | Always check relevant metrics when available | API/CLI responses show current state; metrics reveal trends and intermittent issues |
| "I don't have access to that" | Try the command and report the actual error | Assumed permission failures prevent useful investigation; actual errors are informative |

