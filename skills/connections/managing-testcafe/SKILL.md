---
name: managing-testcafe
description: |
  Use when working with Testcafe — testCafe end-to-end testing management and
  analysis. Covers test execution monitoring, browser provider configuration,
  concurrent test analysis, report parsing, fixture organization, and selector
  debugging. Use when managing TestCafe test suites, investigating failures, or
  reviewing test configurations.
connection_type: testcafe
preload: false
---

# TestCafe E2E Testing Management Skill

Manage and analyze TestCafe test suites, results, and configurations.

## Core Helper Functions

```bash
#!/bin/bash

# Run TestCafe with JSON reporter
testcafe_run() {
    local browser="${1:-chrome:headless}"
    local args="${2:-}"
    npx testcafe "$browser" $args --reporter json 2>/dev/null
}
```

## MANDATORY: Discovery-First Pattern

**Always discover test configuration and fixtures before querying specifics.**

### Phase 1: Discovery

```bash
#!/bin/bash

echo "=== TestCafe Version ==="
npx testcafe --version 2>/dev/null

echo ""
echo "=== TestCafe Configuration ==="
if [ -f ".testcaferc.json" ]; then
    cat .testcaferc.json | jq '{src: .src, browsers: .browsers, concurrency: .concurrency, reporter: .reporter, screenshots: .screenshots}' 2>/dev/null
elif [ -f ".testcaferc.js" ]; then
    head -30 .testcaferc.js
fi

echo ""
echo "=== Test Files ==="
find . -maxdepth 4 -name "*.testcafe.*" -o -name "*.test.ts" -o -name "*.test.js" 2>/dev/null | head -15

echo ""
echo "=== Fixtures Summary ==="
grep -rn "fixture\b" --include="*.ts" --include="*.js" 2>/dev/null | grep -v node_modules | head -15
```

### Phase 2: Analysis

```bash
#!/bin/bash

echo "=== Test Report Summary ==="
REPORT="reports/testcafe-report.json"
if [ -f "$REPORT" ]; then
    cat "$REPORT" | jq '{
        total: .total,
        passed: .passed,
        failed: (.total - .passed - .skipped),
        skipped: .skipped,
        duration_sec: (.duration / 1000 | floor)
    }'

    echo ""
    echo "=== Failed Tests ==="
    cat "$REPORT" | jq -r '
        .fixtures[].tests[] | select(.errs | length > 0) |
        "\(.name)\t\(.errs | length) errors\t\(.durationMs/1000|floor)s"
    ' | column -t | head -15
fi

echo ""
echo "=== Browser Configuration ==="
grep -rn "browsers\|concurrency" .testcaferc.* 2>/dev/null | head -10
```

## Output Rules
- **TOKEN EFFICIENCY**: Target 50 lines per output
- Parse JSON reporter output for structured results
- Never dump full error stacks — extract error message and location

## Anti-Hallucination Rules
- NEVER guess fixture or test names — always discover via filesystem
- NEVER fabricate test results — parse actual report files
- NEVER assume available browsers — check configuration first

## Safety Rules
- NEVER execute tests without user confirmation — they launch browsers
- NEVER modify test files without explicit user approval
- NEVER delete screenshots or reports without user consent

## Output Format

Present results as a structured report:
```
Managing Testcafe Report
════════════════════════
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

