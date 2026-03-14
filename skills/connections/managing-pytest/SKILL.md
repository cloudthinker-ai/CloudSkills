---
name: managing-pytest
description: |
  Pytest testing framework management and analysis. Covers test discovery, fixture analysis, coverage reporting, marker-based filtering, parametrized test review, plugin management, and conftest configuration. Use when managing pytest suites, investigating test failures, reviewing code coverage, or analyzing test performance.
connection_type: pytest
preload: false
---

# Pytest Testing Framework Management Skill

Manage and analyze pytest test suites, coverage, and configurations.

## Core Helper Functions

```bash
#!/bin/bash

# Run pytest with JSON output
pytest_run() {
    local args="${1:-}"
    python -m pytest $args --tb=short -q 2>&1
}

# Parse pytest JUnit XML results
pytest_results() {
    local report="${1:-report.xml}"
    python -c "
import xml.etree.ElementTree as ET
tree = ET.parse('$report')
root = tree.getroot()
import json
print(json.dumps({
    'tests': int(root.attrib.get('tests', 0)),
    'failures': int(root.attrib.get('failures', 0)),
    'errors': int(root.attrib.get('errors', 0)),
    'skipped': int(root.attrib.get('skipped', 0)),
    'time': float(root.attrib.get('time', 0))
}))
" 2>/dev/null
}
```

## MANDATORY: Discovery-First Pattern

**Always discover pytest configuration and test structure before querying specifics.**

### Phase 1: Discovery

```bash
#!/bin/bash

echo "=== Pytest Configuration ==="
if [ -f "pytest.ini" ]; then
    cat pytest.ini | head -20
elif [ -f "pyproject.toml" ]; then
    grep -A 20 "\[tool.pytest" pyproject.toml | head -20
elif [ -f "setup.cfg" ]; then
    grep -A 20 "\[tool:pytest\]" setup.cfg | head -20
fi

echo ""
echo "=== Pytest Version ==="
python -m pytest --version 2>/dev/null

echo ""
echo "=== Test File Summary ==="
find . -name "test_*.py" -o -name "*_test.py" 2>/dev/null | grep -v __pycache__ | wc -l | xargs echo "Total test files:"
find . -name "test_*.py" 2>/dev/null | grep -v __pycache__ | head -15

echo ""
echo "=== Conftest Files ==="
find . -name "conftest.py" 2>/dev/null | grep -v __pycache__ | head -10

echo ""
echo "=== Installed Plugins ==="
python -m pytest --co -q 2>&1 | tail -3
```

### Phase 2: Analysis

```bash
#!/bin/bash

echo "=== Test Collection (dry run) ==="
python -m pytest --collect-only -q 2>/dev/null | tail -5

echo ""
echo "=== Markers ==="
python -m pytest --markers 2>/dev/null | head -15

echo ""
echo "=== Coverage Summary ==="
if [ -f "htmlcov/status.json" ]; then
    cat htmlcov/status.json | python -c "
import json, sys
d = json.load(sys.stdin)
print(f'Lines: {d.get(\"totals\",{}).get(\"percent_covered_display\",\"N/A\")}%')
" 2>/dev/null
elif [ -f ".coverage" ]; then
    python -m coverage report --show-missing 2>/dev/null | tail -10
fi

echo ""
echo "=== Last JUnit Report ==="
REPORT=$(find . -name "report.xml" -o -name "junit.xml" -o -name "test-results.xml" 2>/dev/null | head -1)
if [ -n "$REPORT" ]; then
    pytest_results "$REPORT" | python -m json.tool
fi
```

## Output Rules
- **TOKEN EFFICIENCY**: Target 50 lines per output
- Use `--tb=short` or `--tb=line` for concise failure output
- Parse JUnit XML or JSON reports rather than raw console output

## Anti-Hallucination Rules
- NEVER guess test function names — always discover via `--collect-only`
- NEVER fabricate coverage numbers — parse actual .coverage or reports
- NEVER assume conftest fixtures — check conftest.py files first

## Safety Rules
- NEVER modify test files without explicit user confirmation
- NEVER delete .coverage or htmlcov without user approval
- Be cautious with `--lf` (last failed) — it depends on cache state
