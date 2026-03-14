---
name: managing-vitest
description: |
  Vitest testing framework management and analysis. Covers test suite configuration, coverage reporting, snapshot management, benchmark analysis, workspace setup review, and Vite-native test features. Use when managing Vitest test suites, investigating test failures, reviewing code coverage, or analyzing test performance.
connection_type: vitest
preload: false
---

# Vitest Testing Framework Management Skill

Manage and analyze Vitest test suites, coverage, and configurations.

## Core Helper Functions

```bash
#!/bin/bash

# Run Vitest with JSON reporter
vitest_run() {
    local args="${1:-}"
    npx vitest run $args --reporter=json 2>/dev/null
}
```

## MANDATORY: Discovery-First Pattern

**Always discover Vitest configuration and test structure before querying specifics.**

### Phase 1: Discovery

```bash
#!/bin/bash

echo "=== Vitest Configuration ==="
if [ -f "vitest.config.ts" ]; then
    grep -E "(include|exclude|coverage|environment|globals|setupFiles|testTimeout)" vitest.config.ts | head -15
elif [ -f "vite.config.ts" ]; then
    grep -A 20 "test:" vite.config.ts | head -20
fi

echo ""
echo "=== Vitest Version ==="
npx vitest --version 2>/dev/null

echo ""
echo "=== Test File Summary ==="
find . -name "*.test.ts" -o -name "*.test.tsx" -o -name "*.spec.ts" -o -name "*.spec.tsx" 2>/dev/null | grep -v node_modules | wc -l | xargs echo "Total test files:"
find . -name "*.test.ts" -o -name "*.spec.ts" 2>/dev/null | grep -v node_modules | head -15

echo ""
echo "=== Workspace Configuration ==="
if [ -f "vitest.workspace.ts" ] || [ -f "vitest.workspace.js" ]; then
    cat vitest.workspace.* | head -15
else
    echo "No workspace configuration found (single project)"
fi
```

### Phase 2: Analysis

```bash
#!/bin/bash

echo "=== Last Test Run Results ==="
REPORT="test-results.json"
if [ -f "$REPORT" ]; then
    cat "$REPORT" | jq '{
        total: .numTotalTests,
        passed: .numPassedTests,
        failed: .numFailedTests,
        skipped: .numPendingTests,
        suites: .numTotalTestSuites,
        duration_sec: (.startTime as $s | now - ($s / 1000) | floor)
    }'

    echo ""
    echo "=== Failed Tests ==="
    cat "$REPORT" | jq -r '
        .testResults[] | select(.status == "failed") |
        "\(.name | split("/") | last)\t\(.message | split("\n")[0])"
    ' | column -t | head -15
fi

echo ""
echo "=== Coverage Summary ==="
if [ -f "coverage/coverage-summary.json" ]; then
    cat coverage/coverage-summary.json | jq '.total | {
        lines: "\(.lines.pct)%",
        branches: "\(.branches.pct)%",
        functions: "\(.functions.pct)%",
        statements: "\(.statements.pct)%"
    }'
fi

echo ""
echo "=== Benchmark Results ==="
find . -name "*.bench.ts" -o -name "*.bench.js" 2>/dev/null | grep -v node_modules | head -5
```

## Output Rules
- **TOKEN EFFICIENCY**: Target 50 lines per output
- Parse JSON reporter output for structured results
- Never dump full snapshots — show diffs only

## Anti-Hallucination Rules
- NEVER guess test file names — always discover via filesystem
- NEVER fabricate coverage numbers — parse actual coverage-summary.json
- NEVER assume Vitest config location — check vitest.config.*, vite.config.*

## Safety Rules
- NEVER update snapshots without explicit user confirmation
- NEVER modify test or config files without user approval
- NEVER delete coverage reports without user consent
