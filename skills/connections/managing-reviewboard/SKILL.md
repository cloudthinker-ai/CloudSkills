---
name: managing-reviewboard
description: |
  Review Board code review management including review requests, diff management, review groups, and repository configuration. Use when managing Review Board review workflows, configuring review groups, and automating review request assignment.
connection_type: reviewboard
preload: false
---

# Managing Review Board

## Overview

Manage Review Board review workflows, including review request creation, diff management, reviewer group configuration, and review completion policies.

## Key Capabilities

- Create and manage review requests with multi-revision diffs
- Configure review groups and default reviewer assignment
- Manage repository integrations and diff processing
- Set up review completion requirements
- Configure extensions for custom workflow automation
- Track review request status and turnaround metrics

## Workflow

### 1 — Review Group Configuration

```
REVIEW GROUPS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Groups:
    Name                | Members          | Default for Repository
    ────────────────────┼──────────────────┼───────────────────────
    backend-review      | @backend-devs    | backend-service
    frontend-review     | @frontend-devs   | web-app
    security-review     | @security-team   | (all repositories)
    platform-review     | @platform-team   | infrastructure
[ ] Mailing list per group: YES / NO
[ ] Visible to: everyone / members only
[ ] Invite-only: YES / NO
```

### 2 — Default Reviewers

```
DEFAULT REVIEWERS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Repository-level defaults:
    Repository: backend-service
    Default people: @tech-lead
    Default groups: backend-review
[ ] File pattern defaults:
    Pattern: /security/**
    Reviewer: security-review group
    Pattern: /api/**
    Reviewer: @api-owner
```

### 3 — Review Completion Policy

```
REVIEW COMPLETION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Ship It required from: ___ reviewers
[ ] All reviewers must respond: YES / NO
[ ] Ship It from group member counts for group: YES / NO
[ ] Allow submitter to close without Ship It: YES / NO
[ ] Require all open issues to be resolved: YES / NO
```

## Common Operations

### List Pending Reviews
Query open review requests awaiting action, filter by group or assignee.

### Diff Comparison
Compare diff revisions within a review request to track changes between iterations.

### Review Metrics
Track Ship It rates, review turnaround time, and reviewer participation.

## Troubleshooting

| Issue | Cause | Fix |
|-------|-------|-----|
| Default reviewer not added | Pattern mismatch | Verify file path patterns in default reviewer config |
| Diff upload fails | Repository not configured | Add repository with correct SCM tool and path |
| Email notifications missing | SMTP not configured | Check Review Board email settings |
| Review request stuck | Missing Ship It | Contact assigned reviewers or reassign |
