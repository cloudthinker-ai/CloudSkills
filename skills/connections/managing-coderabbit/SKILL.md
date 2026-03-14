---
name: managing-coderabbit
description: |
  CodeRabbit AI code review management including automated review comments, auto-suggestions, review customization, and learning from feedback. Use when configuring CodeRabbit for AI-assisted code review, custom review rules, and automated suggestion workflows.
connection_type: coderabbit
preload: false
---

# Managing CodeRabbit

## Overview

Manage CodeRabbit AI-powered code review, including automated review comments, contextual suggestions, review customization, and feedback learning to improve review quality over time.

## Key Capabilities

- Automatically review PRs with AI-generated comments and suggestions
- Configure review focus areas (security, performance, style, bugs)
- Customize review rules and coding standards
- Learn from reviewer feedback to reduce false positives
- Generate PR summaries and walkthrough comments
- Integrate with GitHub, GitLab, and Azure DevOps

## Workflow

### 1 — Review Configuration

```
REVIEW SETTINGS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Review scope:
    [ ] All PRs automatically
    [ ] PRs with @coderabbitai mention
    [ ] PRs targeting specific branches: ___
[ ] Review focus areas:
    [ ] Bug detection
    [ ] Security vulnerabilities
    [ ] Performance issues
    [ ] Code style and best practices
    [ ] Error handling
    [ ] Documentation completeness
[ ] Review depth: superficial / standard / thorough
```

### 2 — Custom Instructions

```
CUSTOM REVIEW RULES (.coderabbit.yaml)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
reviews:
  profile: assertive / chill
  path_instructions:
    - path: "src/api/**"
      instructions: |
        Review for REST API best practices.
        Check error handling and status codes.
        Verify input validation.
    - path: "src/db/**"
      instructions: |
        Check for SQL injection risks.
        Verify index usage for queries.
        Review transaction handling.
  auto_review:
    enabled: true
    ignore_title_keywords:
      - "WIP"
      - "DO NOT MERGE"
    drafts: false
```

### 3 — Feedback Learning

```
FEEDBACK CONFIGURATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Learn from resolved/dismissed comments: YES / NO
[ ] Thumbs up/down feedback tracking: YES / NO
[ ] Suppress repeated false positives: YES / NO
[ ] Custom knowledge base: YES / NO
[ ] Team-specific review patterns: YES / NO
```

## Common Operations

### Review Analytics
Track AI review accuracy, accepted suggestions, and false positive rates.

### Rule Tuning
Adjust custom instructions based on feedback patterns to improve review quality.

### Incremental Reviews
Trigger re-review on updated PRs analyzing only the new changes.

## Troubleshooting

| Issue | Cause | Fix |
|-------|-------|-----|
| Too many comments | Review profile too assertive | Switch to "chill" profile or add path exclusions |
| Irrelevant suggestions | Missing context | Add path-specific instructions in .coderabbit.yaml |
| Review not triggered | Draft PR or WIP title | Remove WIP keyword or enable draft review |
| Slow review response | Large diff | Exclude generated files and vendor directories |
