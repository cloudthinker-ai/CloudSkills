---
name: managing-playwright-deep
description: |
  Playwright end-to-end testing management and analysis. Covers test execution monitoring, trace analysis, browser context configuration, test report parsing, flaky test detection, and parallel execution tuning. Use when investigating test failures, analyzing test performance, or managing Playwright test suites.
connection_type: playwright
preload: false
---

# Playwright E2E Testing Management Skill

Manage and analyze Playwright test suites, results, and configurations.

## Core Helper Functions

```bash
#!/bin/bash

# Run Playwright tests with JSON reporter
playwright_run() {
    local args="${1:-}"
    npx playwright test $args --reporter=json 2>/dev/null
}

# Parse Playwright test results from last-run.json
playwright_results() {
    local results_dir="${PLAYWRIGHT_RESULTS_DIR:-test-results}"
    cat "${results_dir}/../playwright-report/report.json" 2>/dev/null || echo '{"suites":[]}'
}
```

## MANDATORY: Discovery-First Pattern

**Always discover test configuration and recent results before querying specifics.**

### Phase 1: Discovery

```bash
#!/bin/bash

echo "=== Playwright Configuration ==="
if [ -f "playwright.config.ts" ]; then
    grep -E "(testDir|timeout|retries|workers|projects|use)" playwright.config.ts | head -20
elif [ -f "playwright.config.js" ]; then
    grep -E "(testDir|timeout|retries|workers|projects|use)" playwright.config.js | head -20
fi

echo ""
echo "=== Test File Summary ==="
TEST_DIR=$(grep -oP "testDir:\s*['\"]([^'\"]+)" playwright.config.* 2>/dev/null | head -1 | grep -oP "['\"][^'\"]+$" | tr -d "'" || echo "tests")
find "$TEST_DIR" -name "*.spec.ts" -o -name "*.spec.js" -o -name "*.test.ts" -o -name "*.test.js" 2>/dev/null | wc -l | xargs echo "Total test files:"
find "$TEST_DIR" -name "*.spec.ts" -o -name "*.spec.js" 2>/dev/null | head -15

echo ""
echo "=== Installed Browsers ==="
npx playwright --version 2>/dev/null
npx playwright install --dry-run 2>/dev/null | head -10
```

### Phase 2: Analysis

```bash
#!/bin/bash

echo "=== Last Test Run Results ==="
REPORT="playwright-report/report.json"
if [ -f "$REPORT" ]; then
    cat "$REPORT" | jq '{
        total: (.stats.expected + .stats.unexpected + .stats.skipped + .stats.flaky),
        passed: .stats.expected,
        failed: .stats.unexpected,
        flaky: .stats.flaky,
        skipped: .stats.skipped,
        duration_sec: (.stats.duration / 1000 | floor)
    }'

    echo ""
    echo "=== Failed Tests ==="
    cat "$REPORT" | jq -r '
        [.. | objects | select(.status == "unexpected")] |
        .[:10][] | "\(.title)\t\(.projectName // "default")\t\(.duration/1000|floor)s"
    ' | column -t
fi

echo ""
echo "=== Flaky Tests ==="
if [ -f "$REPORT" ]; then
    cat "$REPORT" | jq -r '
        [.. | objects | select(.status == "flaky")] |
        .[:10][] | "\(.title)\tretries=\(.retry)"
    ' | column -t
fi
```

## Output Rules
- **TOKEN EFFICIENCY**: Target 50 lines per output
- Parse JSON reports rather than raw console output
- Never dump full trace files — summarize key actions and errors

## Anti-Hallucination Rules
- NEVER guess test file names — always discover via filesystem first
- NEVER fabricate test results — parse actual report JSON
- NEVER assume browser availability — check installed browsers first

## Safety Rules
- NEVER modify test files without explicit user confirmation
- NEVER delete test results or traces without user approval
- Running tests may take significant time — warn user before execution
