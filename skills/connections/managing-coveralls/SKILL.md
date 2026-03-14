---
name: managing-coveralls
description: |
  Coveralls coverage tracking management. Covers coverage reporting, PR status checks, repository configuration, coverage history, and badge management. Use when managing Coveralls coverage reports, configuring coverage thresholds, debugging coverage uploads, or analyzing coverage trends.
connection_type: coveralls
preload: false
---

# Coveralls Coverage Management Skill

Manage and analyze Coveralls coverage reports, thresholds, and coverage history.

## MANDATORY: Discovery-First Pattern

**Always check current Coveralls configuration before modifying coverage settings.**

### Phase 1: Discovery

```bash
#!/bin/bash

echo "=== Coveralls Configuration ==="
cat .coveralls.yml 2>/dev/null || echo "No .coveralls.yml found"

echo ""
echo "=== CI Coverage Upload ==="
grep -r 'coveralls\|COVERALLS' .github/workflows/ .circleci/ .travis.yml 2>/dev/null | head -10

echo ""
echo "=== Coverage Tool Config ==="
cat .nycrc 2>/dev/null || cat jest.config.* 2>/dev/null | grep -A5 'coverage' | head -10
cat .coveragerc 2>/dev/null | head -10
```

### Phase 2: Analysis

```bash
#!/bin/bash
REPO="${1:-${COVERALLS_REPO}}"

echo "=== Repository Coverage ==="
curl -s "https://coveralls.io/github/${REPO}.json" 2>/dev/null | jq '{
  coverage: .covered_percent,
  badge_url: .badge_url,
  created_at: .created_at,
  commit_sha: .commit_sha
}' 2>/dev/null

echo ""
echo "=== Recent Builds ==="
curl -s "https://coveralls.io/github/${REPO}.json?page=1" 2>/dev/null | jq '{
  coverage: .covered_percent,
  change: .coverage_change,
  relevant_lines: .relevant_lines,
  covered_lines: .covered_lines
}' 2>/dev/null
```

## Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- Report coverage percentage with change from previous
- Show relevant vs covered line counts
- Never expose repo tokens in output

## Common Operations

### Build Coverage History

```bash
#!/bin/bash
REPO="${1:?Repo required (owner/name)}"
echo "=== Coverage History ==="
curl -s "https://coveralls.io/github/${REPO}.json?page=1" 2>/dev/null | jq '{
  current: .covered_percent,
  change: .coverage_change,
  repo_token_set: (.repo_token != null)
}' 2>/dev/null
```

### Upload Verification

```bash
#!/bin/bash
echo "=== Recent Upload Status ==="
grep -r 'coveralls' .github/workflows/ 2>/dev/null | head -5
echo ""
echo "=== Coverage File ==="
find . -name "lcov.info" -o -name "coverage.xml" 2>/dev/null | head -5
```

## Safety Rules

- **Never commit `.coveralls.yml` with repo tokens** -- use CI environment variables
- **Verify coverage uploads** after CI pipeline changes
- **Review coverage decreases** on PRs before merging
- **Configure minimum coverage thresholds** to prevent regressions
