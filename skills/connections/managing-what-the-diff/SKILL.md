---
name: managing-what-the-diff
description: |
  Use when working with What The Diff — whatTheDiff AI-powered PR summary
  generation including automatic change descriptions, reviewer-friendly
  summaries, and changelog automation. Use when configuring WhatTheDiff for
  automated PR documentation, change summarization, and review context
  enrichment.
connection_type: whatthediff
preload: false
---

# Managing WhatTheDiff

## Overview

Manage WhatTheDiff AI-powered PR summary generation, including automatic change descriptions, human-readable summaries for reviewers, and changelog entry automation.

## Key Capabilities

- Automatically generate human-readable PR summaries from code diffs
- Create reviewer-friendly descriptions of what changed and why
- Generate changelog entries from merged PRs
- Configure summary style and detail level
- Filter which PRs receive automatic summaries
- Integrate with existing PR templates and workflows

## Workflow

### 1 — Summary Configuration

```
SUMMARY SETTINGS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Auto-generate summaries for:
    [ ] All PRs
    [ ] PRs without description
    [ ] PRs with specific labels: ___
[ ] Summary style:
    - Technical detail level: low / medium / high
    - Include file-by-file breakdown: YES / NO
    - Highlight breaking changes: YES / NO
    - Note security implications: YES / NO
[ ] Summary placement: PR description / PR comment
[ ] Language: English / ___
```

### 2 — Changelog Generation

```
CHANGELOG AUTOMATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Auto-generate changelog entries: YES / NO
[ ] Changelog format: Keep a Changelog / custom
[ ] Categories:
    - Added: new features
    - Changed: modifications
    - Fixed: bug fixes
    - Removed: removed features
    - Security: vulnerability fixes
[ ] Include in: CHANGELOG.md / release notes / both
```

### 3 — Repository Settings

```
REPOSITORY CONFIGURATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Connected repositories: ___
[ ] Exclude file patterns:
    - package-lock.json
    - yarn.lock
    - *.generated.*
    - vendor/**
[ ] Maximum diff size for analysis: ___ lines
[ ] Summarize large PRs in chunks: YES / NO
```

## Common Operations

### Review Summary Quality
Audit generated summaries for accuracy and usefulness.

### Changelog Compilation
Compile changelog entries from a range of merged PRs for release notes.

### Usage Analytics
Track summary generation rates, reviewer feedback, and time savings.

## Troubleshooting

| Issue | Cause | Fix |
|-------|-------|-----|
| Summary not generated | PR too large | Increase max diff size or exclude generated files |
| Inaccurate summary | Complex refactoring | Add PR context in description to guide summarization |
| Changelog entry missing | PR label not mapped | Map PR labels to changelog categories |
| Duplicate summaries | Webhook firing twice | Check webhook configuration for duplicates |

## Output Format

Present results as a structured report:
```
Managing What The Diff Report
═════════════════════════════
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

