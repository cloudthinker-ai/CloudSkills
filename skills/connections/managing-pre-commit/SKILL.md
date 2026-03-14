---
name: managing-pre-commit
description: |
  pre-commit hook framework management. Covers hook configuration, repository management, hook execution, CI integration, and autoupdate management. Use when managing pre-commit hooks, adding or removing hooks, debugging hook failures, or configuring pre-commit in CI pipelines.
connection_type: pre-commit
preload: false
---

# pre-commit Hook Framework Management Skill

Manage and analyze pre-commit hook configurations, repositories, and CI integration.

## MANDATORY: Discovery-First Pattern

**Always check current pre-commit configuration before modifying hooks.**

### Phase 1: Discovery

```bash
#!/bin/bash

echo "=== pre-commit Configuration ==="
cat .pre-commit-config.yaml 2>/dev/null || echo "No .pre-commit-config.yaml found"

echo ""
echo "=== pre-commit Version ==="
pre-commit --version 2>/dev/null

echo ""
echo "=== Installed Hooks ==="
ls .git/hooks/pre-commit 2>/dev/null && echo "pre-commit hook installed" || echo "pre-commit hook not installed"

echo ""
echo "=== CI Integration ==="
grep -r 'pre-commit' .github/workflows/ 2>/dev/null | head -5
```

### Phase 2: Analysis

```bash
#!/bin/bash

echo "=== Hook Repositories ==="
grep -E 'repo:|rev:|hooks:' .pre-commit-config.yaml 2>/dev/null | head -20

echo ""
echo "=== Hook IDs ==="
grep -E '^\s+-\s+id:' .pre-commit-config.yaml 2>/dev/null | head -15

echo ""
echo "=== Hook Stages ==="
grep -E 'stages:' .pre-commit-config.yaml 2>/dev/null | head -5

echo ""
echo "=== Exclude Patterns ==="
grep -E 'exclude:' .pre-commit-config.yaml 2>/dev/null | head -5
```

## Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- List hooks with their repository sources
- Show hook stages and file patterns
- Report hook versions and update availability

## Common Operations

### Run All Hooks

```bash
#!/bin/bash
echo "=== Run All Hooks ==="
pre-commit run --all-files 2>&1 | tail -20
```

### Update Hooks

```bash
#!/bin/bash
echo "=== Available Updates ==="
pre-commit autoupdate --dry-run 2>&1 | head -15

echo ""
echo "=== Current Versions ==="
grep 'rev:' .pre-commit-config.yaml 2>/dev/null | head -10
```

### Validate Configuration

```bash
#!/bin/bash
echo "=== Validate Config ==="
pre-commit validate-config .pre-commit-config.yaml 2>&1 | head -10

echo ""
echo "=== Validate Manifest ==="
pre-commit validate-manifest .pre-commit-hooks.yaml 2>&1 | head -10
```

## Safety Rules

- **Run `pre-commit run --all-files`** after adding new hooks to check existing code
- **Pin hook versions** with `rev:` to ensure reproducible behavior
- **Test hook updates** with `pre-commit autoupdate` on a branch before merging
- **Never skip hooks** (`--no-verify`) as a permanent workaround -- fix the underlying issue
