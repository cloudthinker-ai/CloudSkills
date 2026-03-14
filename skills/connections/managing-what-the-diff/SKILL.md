---
name: managing-what-the-diff
description: |
  WhatTheDiff AI-powered PR summary generation including automatic change descriptions, reviewer-friendly summaries, and changelog automation. Use when configuring WhatTheDiff for automated PR documentation, change summarization, and review context enrichment.
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
