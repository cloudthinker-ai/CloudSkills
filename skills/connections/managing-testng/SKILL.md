---
name: managing-testng
description: |
  Use when working with Testng — testNG testing framework management and
  analysis. Covers test suite XML configuration, group-based execution, data
  provider analysis, parallel execution settings, report parsing, and listener
  configuration. Use when managing TestNG suites, investigating test failures,
  or reviewing Java test configurations with TestNG features.
connection_type: testng
preload: false
---

# TestNG Testing Framework Management Skill

Manage and analyze TestNG test suites, configurations, and reports.

## Core Helper Functions

```bash
#!/bin/bash

# Parse TestNG XML results
testng_parse() {
    local report="${1:-test-output/testng-results.xml}"
    python3 -c "
import xml.etree.ElementTree as ET, json
tree = ET.parse('$report')
root = tree.getroot()
ns = {'': root.tag.split('}')[0].strip('{')} if '}' in root.tag else {}
prefix = '{' + ns[''] + '}' if ns else ''
suite = root.find(f'{prefix}suite') or root
print(json.dumps({
    'name': suite.attrib.get('name',''),
    'duration_ms': suite.attrib.get('duration-ms','0'),
    'passed': int(suite.attrib.get('passed','0')),
    'failed': int(suite.attrib.get('failed','0')),
    'skipped': int(suite.attrib.get('skipped','0'))
}, indent=2))
" 2>/dev/null
}
```

## MANDATORY: Discovery-First Pattern

**Always discover suite configuration and test groups before querying specifics.**

### Phase 1: Discovery

```bash
#!/bin/bash

echo "=== TestNG Suite Files ==="
find . -name "testng*.xml" -o -name "suite*.xml" 2>/dev/null | grep -v build | head -10

echo ""
echo "=== Suite Configuration ==="
SUITE_FILE=$(find . -name "testng.xml" 2>/dev/null | grep -v build | head -1)
if [ -n "$SUITE_FILE" ]; then
    cat "$SUITE_FILE" | head -30
fi

echo ""
echo "=== Test Classes ==="
find . -path "*/test/java/*.java" 2>/dev/null | grep -v build | wc -l | xargs echo "Total test files:"
grep -rln "import org.testng" --include="*.java" 2>/dev/null | grep -v build | head -15

echo ""
echo "=== Test Groups ==="
grep -rn "@Test.*groups" --include="*.java" 2>/dev/null | grep -v build | grep -oP 'groups\s*=\s*\{[^}]+\}' | sort -u | head -10

echo ""
echo "=== Data Providers ==="
grep -rn "@DataProvider" --include="*.java" 2>/dev/null | grep -v build | head -10
```

### Phase 2: Analysis

```bash
#!/bin/bash

echo "=== Test Results Summary ==="
REPORT=$(find . -path "*/test-output/testng-results.xml" -o -path "*/surefire-reports/testng-results.xml" 2>/dev/null | head -1)
if [ -n "$REPORT" ]; then
    testng_parse "$REPORT"

    echo ""
    echo "=== Failed Tests ==="
    python3 -c "
import xml.etree.ElementTree as ET
tree = ET.parse('$REPORT')
for tc in tree.iter():
    if tc.tag.endswith('test-method') and tc.attrib.get('status') == 'FAIL':
        name = tc.attrib.get('name','')
        cls = tc.attrib.get('signature','').split('(')[0]
        print(f'{cls}\t{name}\t{tc.attrib.get(\"duration-ms\",\"0\")}ms')
" 2>/dev/null | column -t | head -15
fi

echo ""
echo "=== Parallel Configuration ==="
grep -rn "parallel\|thread-count\|data-provider-thread-count" --include="*.xml" 2>/dev/null | grep -v build | head -5

echo ""
echo "=== Listeners ==="
grep -rn "@Listeners\|<listener" --include="*.java" --include="*.xml" 2>/dev/null | grep -v build | head -10
```

## Output Rules
- **TOKEN EFFICIENCY**: Target 50 lines per output
- Parse testng-results.xml for structured data
- Never dump full stack traces — extract failure message only

## Anti-Hallucination Rules
- NEVER guess test class or group names — discover from source and XML
- NEVER fabricate test results — parse actual TestNG reports
- NEVER assume suite structure — check testng.xml configuration

## Safety Rules
- NEVER modify suite XML or test files without user confirmation
- NEVER delete test reports without user approval
- Be aware that parallel execution settings affect resource usage

## Output Format

Present results as a structured report:
```
Managing Testng Report
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

