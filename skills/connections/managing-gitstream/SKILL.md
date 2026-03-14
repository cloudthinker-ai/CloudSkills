---
name: managing-gitstream
description: |
  gitStream PR automation management including routing rules, merge policies, auto-labeling, and reviewer assignment based on code changes. Use when configuring gitStream continuous merge automation, defining PR classification rules, and optimizing review workflows.
connection_type: gitstream
preload: false
---

# Managing gitStream

## Overview

Manage gitStream continuous merge automation, including PR routing rules, automatic labeling, reviewer assignment based on change characteristics, and merge policy enforcement.

## Key Capabilities

- Define PR classification rules based on file changes, size, and content
- Automate reviewer assignment using code expertise and change context
- Configure automatic labeling for PR categorization
- Set merge policies based on PR risk level
- Automate routine PR approvals for safe changes
- Define custom automation workflows using CM (Continuous Merge) files

## Workflow

### 1 — Classification Rules

```
PR CLASSIFICATION (.cm FILE)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
automations:
  safe_changes:
    if:
      - {{ is.docs or is.tests or is.formatting }}
    run:
      - action: add-label@v1
        args: label: "safe-change"
      - action: approve@v1
      - action: add-comment@v1
        args: comment: "Auto-approved: safe change"

  needs_security_review:
    if:
      - {{ files | match(term='auth') | some }}
      - {{ files | match(term='security') | some }}
    run:
      - action: add-label@v1
        args: label: "security-review"
      - action: add-reviewers@v1
        args: reviewers: ['security-team']
```

### 2 — Reviewer Routing

```
REVIEWER ASSIGNMENT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
automations:
  assign_by_expertise:
    if:
      - true
    run:
      - action: add-reviewers@v1
        args:
          reviewers: {{ repo | codeExperts(gt=30) }}

  large_pr_review:
    if:
      - {{ branch.diff.size > 500 }}
    run:
      - action: add-label@v1
        args: label: "large-pr"
      - action: add-reviewers@v1
        args: reviewers: ['@senior-engineers']
      - action: set-required-approvals@v1
        args: approvals: 2
```

### 3 — Merge Policies

```
MERGE POLICIES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
automations:
  enforce_squash_for_features:
    if:
      - {{ branch.name | includes(term='feature/') }}
    run:
      - action: merge@v1
        args: method: squash

  require_linear_history:
    if:
      - {{ branch.name | includes(term='release/') }}
    run:
      - action: merge@v1
        args:
          method: rebase
          wait_for_all_checks: true
```

## Common Operations

### Test CM Rules
Validate .cm file rules against sample PRs before deploying.

### Monitor Automations
Track which automations trigger, auto-approval rates, and reviewer assignment patterns.

### Optimize Review Routing
Analyze code expertise data to improve reviewer assignment accuracy.

## Troubleshooting

| Issue | Cause | Fix |
|-------|-------|-----|
| Automation not triggering | CM file syntax error | Validate .cm file syntax and conditions |
| Wrong reviewers assigned | Expertise data stale | Refresh code expertise analysis |
| Auto-approve too broad | Classification too permissive | Tighten safe-change conditions |
| Merge policy conflict | Multiple matching rules | Ensure rule priority ordering is correct |
