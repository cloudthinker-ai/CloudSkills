---
name: managing-pre-commit
description: |
  Use when working with Pre Commit — pre-commit hook framework management.
  Covers hook configuration, repository management, hook execution, CI
  integration, and autoupdate management. Use when managing pre-commit hooks,
  adding or removing hooks, debugging hook failures, or configuring pre-commit
  in CI pipelines.
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

## Output Format

Present results as a structured report:
```
Managing Pre Commit Report
══════════════════════════
Resources discovered: [count]

Resource       Status    Key Metric    Issues
──────────────────────────────────────────────
[name]         [ok/warn] [value]       [findings]

Summary: [total] resources | [ok] healthy | [warn] warnings | [crit] critical
Action Items: [list of prioritized findings]
```

Target ≤50 lines of output. Use tables for multi-resource comparisons.

## Anti-Hallucination Rules

1. **NEVER assume resource names** — always discover via CLI/API in Phase 1 before referencing in Phase 2.
2. **NEVER fabricate metric names or dimensions** — verify against the service documentation or `--help` output.
3. **NEVER mix CLI commands between service versions** — confirm which version/API you are targeting.
4. **ALWAYS use the discovery → verify → analyze chain** — every resource referenced must have been discovered first.
5. **ALWAYS handle empty results gracefully** — an empty response is valid data, not an error to retry.

## Counter-Rationalizations

| Shortcut | Counter | Why |
|----------|---------|-----|
| "I'll skip discovery and check known resources" | Always run Phase 1 discovery first | Resource names change, new resources appear — assumed names cause errors |
| "The user only asked for a quick check" | Follow the full discovery → analysis flow | Quick checks miss critical issues; structured analysis catches silent failures |
| "Default configuration is probably fine" | Audit configuration explicitly | Defaults often leave logging, security, and optimization features disabled |
| "Metrics aren't needed for this" | Always check relevant metrics when available | API/CLI responses show current state; metrics reveal trends and intermittent issues |
| "I don't have access to that" | Try the command and report the actual error | Assumed permission failures prevent useful investigation; actual errors are informative |

