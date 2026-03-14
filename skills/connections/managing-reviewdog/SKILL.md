---
name: managing-reviewdog
description: |
  Reviewdog automated code review management. Covers linter integration, PR comment configuration, CI setup, reporter configuration, and multi-tool orchestration. Use when managing Reviewdog CI integration, configuring linter reporters, debugging review comments, or setting up automated code review workflows.
connection_type: reviewdog
preload: false
---

# Reviewdog Automated Code Review Management Skill

Manage and analyze Reviewdog linter integrations, PR reviews, and CI configurations.

## MANDATORY: Discovery-First Pattern

**Always check current Reviewdog configuration and CI setup before modifying review settings.**

### Phase 1: Discovery

```bash
#!/bin/bash

echo "=== Reviewdog Configuration ==="
cat .reviewdog.yml 2>/dev/null || echo "No .reviewdog.yml found"

echo ""
echo "=== CI Integration ==="
grep -r 'reviewdog' .github/workflows/ 2>/dev/null | head -10

echo ""
echo "=== Reviewdog Version ==="
reviewdog --version 2>/dev/null

echo ""
echo "=== Installed Linters ==="
grep -A5 'run:' .reviewdog.yml 2>/dev/null | head -15
```

### Phase 2: Analysis

```bash
#!/bin/bash

echo "=== Configured Runners ==="
cat .reviewdog.yml 2>/dev/null | grep -E 'name:|cmd:|format:|level:' | head -20

echo ""
echo "=== Reporter Settings ==="
grep -r 'reporter\|REVIEWDOG_REPORTER' .github/workflows/ 2>/dev/null | head -10

echo ""
echo "=== Workflow Integration ==="
grep -B2 -A10 'reviewdog' .github/workflows/*.yml 2>/dev/null | head -25
```

## Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- List configured linters with their reporters
- Show CI integration points
- Report review comment settings

## Common Operations

### Run Locally

```bash
#!/bin/bash
echo "=== Local Review ==="
reviewdog -list 2>/dev/null | head -10

echo ""
echo "=== Diff Review ==="
reviewdog -diff="git diff main" 2>&1 | head -20
```

### Linter Configuration

```bash
#!/bin/bash
echo "=== Available Formats ==="
echo "checkstyle, rdjsonl, rdjson, diff, sarif, golint, eslint, tslint"

echo ""
echo "=== Reporter Options ==="
echo "github-pr-check, github-pr-review, github-check, local, gitlab-mr-discussion"
```

## Safety Rules

- **Set appropriate error levels** -- warning vs error affects PR merge blocking
- **Test linter configurations locally** before deploying to CI
- **Review filter modes** (added, diff_context, file, nofilter) for appropriate scope
- **GitHub tokens** for reviewdog must have appropriate PR comment permissions
