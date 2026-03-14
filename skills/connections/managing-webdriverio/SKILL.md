---
name: managing-webdriverio
description: |
  WebdriverIO test automation management and analysis. Covers test suite configuration, service integration, browser and mobile testing, Allure report parsing, spec file organization, and WDIO runner analysis. Use when managing WebdriverIO test suites, investigating failures, or reviewing automation configurations.
connection_type: webdriverio
preload: false
---

# WebdriverIO Test Automation Management Skill

Manage and analyze WebdriverIO test suites, results, and configurations.

## Core Helper Functions

```bash
#!/bin/bash

# Run WDIO tests with specific config
wdio_run() {
    local config="${1:-wdio.conf.js}"
    npx wdio run "$config" 2>&1
}

# Parse WDIO Allure results
wdio_allure_results() {
    local results_dir="${ALLURE_RESULTS_DIR:-allure-results}"
    find "$results_dir" -name "*.json" -exec cat {} \; 2>/dev/null | jq -s '.'
}
```

## MANDATORY: Discovery-First Pattern

**Always discover test configuration and specs before querying specifics.**

### Phase 1: Discovery

```bash
#!/bin/bash

echo "=== WebdriverIO Configuration ==="
CONFIG=$(ls wdio.conf.{ts,js} wdio.*.conf.{ts,js} 2>/dev/null | head -5)
echo "Config files found: $CONFIG"
for f in $CONFIG; do
    echo "--- $f ---"
    grep -E "(specs|capabilities|services|framework|reporters|baseUrl)" "$f" | head -10
done

echo ""
echo "=== WDIO Version ==="
npx wdio --version 2>/dev/null

echo ""
echo "=== Test Spec Files ==="
SPEC_DIR=$(grep -oP "specs:\s*\[.*?['\"]([^'\"]+)" wdio.conf.* 2>/dev/null | head -1 | grep -oP "['\"][^'\"]+$" | tr -d "'\"" || echo "test/specs")
find . -maxdepth 4 -path "*/specs/*.ts" -o -path "*/specs/*.js" 2>/dev/null | grep -v node_modules | head -15

echo ""
echo "=== Configured Services ==="
grep -oP "services:\s*\[.*?\]" wdio.conf.* 2>/dev/null | head -5
```

### Phase 2: Analysis

```bash
#!/bin/bash

echo "=== Test Results Summary ==="
REPORT_DIR="${WDIO_REPORT_DIR:-allure-results}"
if [ -d "$REPORT_DIR" ]; then
    TOTAL=$(find "$REPORT_DIR" -name "*-result.json" | wc -l)
    PASSED=$(find "$REPORT_DIR" -name "*-result.json" -exec grep -l '"status":"passed"' {} \; | wc -l)
    FAILED=$(find "$REPORT_DIR" -name "*-result.json" -exec grep -l '"status":"failed"' {} \; | wc -l)
    echo "Total: $TOTAL | Passed: $PASSED | Failed: $FAILED"

    echo ""
    echo "=== Failed Tests ==="
    find "$REPORT_DIR" -name "*-result.json" -exec grep -l '"status":"failed"' {} \; | while read f; do
        jq -r '"\(.name)\t\(.status)\t\(.statusDetails.message // "unknown" | split("\n")[0])"' "$f"
    done | column -t | head -15
fi

echo ""
echo "=== Browser Capabilities ==="
grep -A 10 "capabilities" wdio.conf.* 2>/dev/null | grep -E "(browserName|browserVersion|platformName)" | head -10
```

## Output Rules
- **TOKEN EFFICIENCY**: Target 50 lines per output
- Parse Allure or JSON reporter output for structured results
- Never dump full spec files — summarize test descriptions

## Anti-Hallucination Rules
- NEVER guess spec file names — always discover via filesystem
- NEVER fabricate test results — parse actual Allure/JSON reports
- NEVER assume service availability — check wdio.conf for configured services

## Safety Rules
- NEVER execute tests without user confirmation
- NEVER modify config or spec files without explicit user approval
- NEVER delete test results or screenshots without user consent
