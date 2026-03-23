---
name: managing-reviewdog
description: |
  Use when working with Reviewdog — reviewdog automated code review management.
  Covers linter integration, PR comment configuration, CI setup, reporter
  configuration, and multi-tool orchestration. Use when managing Reviewdog CI
  integration, configuring linter reporters, debugging review comments, or
  setting up automated code review workflows.
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

## Output Format

Present results as a structured report:
```
Managing Reviewdog Report
═════════════════════════
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

