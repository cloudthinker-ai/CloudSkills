---
name: managing-codecov
description: |
  Codecov coverage tracking management. Covers coverage reporting, PR comments, flag management, component analysis, and coverage trend tracking. Use when managing Codecov configuration, analyzing coverage reports, debugging coverage uploads, or configuring coverage thresholds.
connection_type: codecov
preload: false
---

# Codecov Coverage Management Skill

Manage and analyze Codecov coverage reports, flags, and coverage trends.

## MANDATORY: Discovery-First Pattern

**Always check current Codecov configuration before modifying coverage settings.**

### Phase 1: Discovery

```bash
#!/bin/bash

echo "=== Codecov Configuration ==="
cat codecov.yml 2>/dev/null || cat .codecov.yml 2>/dev/null || echo "No codecov.yml found"

echo ""
echo "=== Coverage Upload Config ==="
grep -r 'codecov\|CODECOV' .github/workflows/ 2>/dev/null | head -10

echo ""
echo "=== Coverage Files ==="
find . -name "coverage.xml" -o -name "lcov.info" -o -name "coverage.json" -o -name "*.gcov" 2>/dev/null | head -10
```

### Phase 2: Analysis

```bash
#!/bin/bash
REPO="${1:-${CODECOV_REPO}}"

echo "=== Repository Coverage ==="
curl -s -H "Authorization: token ${CODECOV_TOKEN}" \
  "https://codecov.io/api/v2/github/${REPO}" 2>/dev/null | jq '{
  coverage: .coverage,
  language: .language,
  branch: .branch
}' 2>/dev/null

echo ""
echo "=== Coverage by Flag ==="
curl -s -H "Authorization: token ${CODECOV_TOKEN}" \
  "https://codecov.io/api/v2/github/${REPO}/flags" 2>/dev/null | jq '[.results[:10][] | {
  name: .flag_name,
  coverage: .coverage
}]' 2>/dev/null

echo ""
echo "=== Coverage Configuration ==="
cat codecov.yml 2>/dev/null | head -20
```

## Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- Report coverage percentages with diff from target
- List flags and components with their coverage
- Show coverage trend direction

## Common Operations

### Commit Coverage

```bash
#!/bin/bash
REPO="${1:?Repo required (owner/name)}"
COMMIT="${2:-HEAD}"
echo "=== Commit Coverage ==="
curl -s -H "Authorization: token ${CODECOV_TOKEN}" \
  "https://codecov.io/api/v2/github/${REPO}/commits/${COMMIT}" 2>/dev/null | jq '{
  commitid: .commitid,
  coverage: .totals.coverage,
  files: .totals.files,
  lines: .totals.lines,
  hits: .totals.hits,
  misses: .totals.misses
}' 2>/dev/null
```

### Coverage Thresholds

```bash
#!/bin/bash
echo "=== Threshold Configuration ==="
cat codecov.yml 2>/dev/null | grep -A10 'coverage:' | head -15

echo ""
echo "=== Flag Configuration ==="
cat codecov.yml 2>/dev/null | grep -A10 'flags:' | head -15
```

## Safety Rules

- **Never lower coverage thresholds** without team agreement
- **Codecov tokens** must be stored in CI secrets, not in config files
- **Verify coverage uploads** in CI logs after pipeline changes
- **Review coverage diffs** on PRs before merging to catch regressions
