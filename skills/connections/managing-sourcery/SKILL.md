---
name: managing-sourcery
description: |
  Use when working with Sourcery — sourcery AI code quality and refactoring
  management including automated refactoring suggestions, code quality scoring,
  duplicate detection, and PR review integration. Use when configuring Sourcery
  for automated code improvement, quality gates, and refactoring workflows.
connection_type: sourcery
preload: false
---

# Managing Sourcery

## Overview

Manage Sourcery AI-powered code quality analysis and refactoring suggestions, including automated PR reviews, code quality scoring, duplicate detection, and custom refactoring rules.

## Key Capabilities

- Automatically suggest refactoring improvements on PRs
- Score code quality across complexity, readability, and style dimensions
- Detect code duplication and suggest consolidation
- Configure custom refactoring rules and coding standards
- Integrate with GitHub for PR-level feedback
- Track code quality metrics over time

## Workflow

### 1 — Quality Rules Configuration

```
QUALITY SETTINGS (.sourcery.yaml)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
refactor:
  skip:
    - tests/**
    - migrations/**
  rule_settings:
    - id: avoid-global-state
      enabled: true
    - id: use-contextlib-suppress
      enabled: true

metrics:
  quality_threshold: 25
  complexity:
    threshold: 15
  method_length:
    threshold: 30
  working_memory:
    threshold: 8

github:
  labels: true
  review_comment: true
  request_review: author
```

### 2 — Review Integration

```
PR REVIEW SETTINGS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Auto-review all PRs: YES / NO
[ ] Add quality score label: YES / NO
[ ] Block merge below quality threshold: YES / NO
[ ] Quality threshold for merge: ___
[ ] Comment with refactoring suggestions: YES / NO
[ ] Suggest code simplifications: YES / NO
[ ] Detect new duplications: YES / NO
```

### 3 — Custom Rules

```
CUSTOM REFACTORING RULES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
rules:
  - id: team-error-handling
    description: Use custom error classes
    pattern: |
      raise Exception(${msg})
    replacement: |
      raise ApplicationError(${msg})

  - id: team-logging
    description: Use structured logging
    pattern: |
      print(${msg})
    replacement: |
      logger.info(${msg})
```

## Common Operations

### Quality Dashboard
View code quality scores across repositories and track improvement trends.

### Refactoring Suggestions
Review and apply AI-suggested refactoring improvements.

### Duplication Report
Identify duplicate code blocks and plan consolidation efforts.

## Troubleshooting

| Issue | Cause | Fix |
|-------|-------|-----|
| Too many suggestions | Threshold too strict | Adjust quality_threshold in .sourcery.yaml |
| Wrong language analysis | File type detection | Check file extensions and language configuration |
| Custom rule not matching | Pattern syntax error | Test pattern against sample code |
| Quality score inconsistent | Excluded files | Review skip patterns in configuration |

## Output Format

Present results as a structured report:
```
Managing Sourcery Report
════════════════════════
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

