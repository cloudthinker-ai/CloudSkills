---
name: managing-upsource
description: |
  JetBrains Upsource code review management including review workflows, code inspections, branch review tracking, and IDE integration. Use when managing Upsource review processes, configuring automated inspections, and tracking review metrics.
connection_type: upsource
preload: false
---

# Managing Upsource

## Overview

Manage JetBrains Upsource code review workflows, including review creation, automated code inspections, branch-based reviews, and IDE integration for seamless review experiences.

## Key Capabilities

- Create and manage code reviews tied to branches or commits
- Run automated code inspections based on IntelliJ platform analysis
- Configure review workflows with custom states and transitions
- Set up branch review policies for automatic review creation
- Integrate with JetBrains IDEs for in-editor review participation
- Track code quality metrics and review analytics

## Workflow

### 1 — Review Workflow Configuration

```
REVIEW WORKFLOW
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Review model: branch-based / commit-based
[ ] Auto-create reviews for branches: YES / NO
[ ] Branch patterns for auto-review:
    - feature/*  -> require review
    - hotfix/*   -> require review
    - main       -> protected (no direct push)
[ ] Required reviewers: ___
[ ] Review completion criteria:
    - All reviewers accepted: YES / NO
    - No unresolved discussions: YES / NO
    - All inspections pass: YES / NO
```

### 2 — Code Inspections

```
AUTOMATED INSPECTIONS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Inspection profiles:
    - Default (all inspections)
    - Security-focused
    - Performance-focused
[ ] Run on: every commit / review creation / manual
[ ] Block merge on:
    - Critical issues: YES / NO
    - Warning-level issues: YES / NO
[ ] Custom inspection rules: ___
```

### 3 — Project Settings

```
PROJECT CONFIGURATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Default reviewers per project: ___
[ ] Review label schema: accept / concern / reject
[ ] Discussion resolution required: YES / NO
[ ] Merge check integration: YES / NO
[ ] Code intelligence enabled: YES / NO
```

## Common Operations

### List Open Reviews
Query open reviews by project, branch, or reviewer status.

### Inspection Results
View automated inspection findings grouped by severity and category.

### Review Analytics
Track review velocity, inspection pass rates, and code quality trends.

## Troubleshooting

| Issue | Cause | Fix |
|-------|-------|-----|
| Inspections not running | Profile not configured | Set inspection profile in project settings |
| Review not auto-created | Branch pattern mismatch | Verify branch naming matches auto-review patterns |
| IDE integration broken | Plugin version mismatch | Update Upsource plugin to match server version |
| Merge check failing | Unresolved discussions | Resolve all open discussions in review |
