---
name: managing-robot-framework
description: |
  Robot Framework test automation management and analysis. Covers test suite organization, keyword library management, variable file configuration, output XML parsing, log and report analysis, and resource file review. Use when managing Robot Framework suites, investigating test failures, or reviewing keyword-driven test automation.
connection_type: robot-framework
preload: false
---

# Robot Framework Test Automation Management Skill

Manage and analyze Robot Framework test suites, keywords, and results.

## Core Helper Functions

```bash
#!/bin/bash

# Parse Robot Framework output.xml
robot_results() {
    local output="${1:-output.xml}"
    python3 -c "
from robot.api import ExecutionResult
result = ExecutionResult('$output')
stats = result.statistics.total
import json
print(json.dumps({
    'total': stats.total,
    'passed': stats.passed,
    'failed': stats.failed,
    'skipped': stats.skipped,
    'elapsed': str(result.suite.elapsedtime)
}))
" 2>/dev/null
}
```

## MANDATORY: Discovery-First Pattern

**Always discover test suites and keyword libraries before querying specifics.**

### Phase 1: Discovery

```bash
#!/bin/bash

echo "=== Robot Framework Version ==="
robot --version 2>/dev/null || python3 -m robot --version 2>/dev/null

echo ""
echo "=== Test Suite Files ==="
find . -name "*.robot" 2>/dev/null | wc -l | xargs echo "Total .robot files:"
find . -name "*.robot" 2>/dev/null | head -15

echo ""
echo "=== Resource Files ==="
find . -name "*.resource" 2>/dev/null | head -10

echo ""
echo "=== Variable Files ==="
find . -name "*variables*" -name "*.py" -o -name "*variables*" -name "*.yaml" 2>/dev/null | head -10

echo ""
echo "=== Library Imports ==="
grep -rh "Library " --include="*.robot" 2>/dev/null | sort -u | head -15

echo ""
echo "=== Tags in Use ==="
grep -rh "\[Tags\]" --include="*.robot" 2>/dev/null | sed 's/.*\[Tags\]\s*//' | tr '    ' '\n' | sort | uniq -c | sort -rn | head -15
```

### Phase 2: Analysis

```bash
#!/bin/bash

echo "=== Test Results ==="
OUTPUT=$(find . -name "output.xml" 2>/dev/null | head -1)
if [ -n "$OUTPUT" ]; then
    robot_results "$OUTPUT"

    echo ""
    echo "=== Failed Tests ==="
    python3 -c "
from robot.api import ExecutionResult
result = ExecutionResult('$OUTPUT')
for test in result.suite.all_tests:
    if test.status == 'FAIL':
        print(f'{test.name}\t{test.message[:80]}')
" 2>/dev/null | column -t | head -15

    echo ""
    echo "=== Suite Statistics ==="
    python3 -c "
from robot.api import ExecutionResult
result = ExecutionResult('$OUTPUT')
for suite in result.suite.suites:
    stats = suite.statistics
    print(f'{suite.name}\tP={stats.passed}\tF={stats.failed}\tS={stats.skipped}')
" 2>/dev/null | column -t | head -15
fi

echo ""
echo "=== Custom Keywords ==="
grep -rh "^\*\*\* Keywords \*\*\*" --include="*.robot" -A 20 2>/dev/null | grep -E "^[A-Z]" | head -15
```

## Output Rules
- **TOKEN EFFICIENCY**: Target 50 lines per output
- Parse output.xml programmatically via robot.api
- Never dump full log.html — summarize key failures and statistics

## Anti-Hallucination Rules
- NEVER guess test case names — always discover from .robot files
- NEVER fabricate test results — parse actual output.xml
- NEVER assume keyword availability — check Library imports and resource files

## Safety Rules
- NEVER modify .robot files without explicit user confirmation
- NEVER delete output.xml, log.html, or report.html without user approval
- NEVER run tests without user consent — they may interact with live systems
