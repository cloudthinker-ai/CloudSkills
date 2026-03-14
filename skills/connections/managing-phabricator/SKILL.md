---
name: managing-phabricator
description: |
  Phabricator Differential code review management including review workflows, Herald rules for automated actions, audit trails, and reviewer assignment. Use when managing Phabricator code review processes, Herald automation, and Differential revision workflows.
connection_type: phabricator
preload: false
---

# Managing Phabricator

## Overview

Manage Phabricator Differential code review workflows, including revision management, Herald rules for automation, reviewer policies, and audit configuration.

## Key Capabilities

- Manage Differential revisions and review workflows
- Configure Herald rules for automated reviewer assignment and actions
- Set up audit rules for post-commit review
- Define reviewer policies and blocking reviewers
- Configure repository-level review requirements
- Manage review groups and project-based reviewer pools

## Workflow

### 1 — Differential Review Setup

```
DIFFERENTIAL CONFIGURATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Review status flow:
    Needs Review -> Accepted / Needs Revision
    Needs Revision -> Needs Review (after update)
    Accepted -> Closed (after landing)
[ ] Blocking reviewers: YES / NO
[ ] Accept with comments allowed: YES / NO
[ ] Require test plan: YES / NO
[ ] Auto-close revisions on push: YES / NO
```

### 2 — Herald Rules

```
HERALD AUTOMATION RULES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Rule: Security File Review
  When: Differential revision is created
  If: Changed file path matches /src/auth/**
  Action: Add reviewer @security-team (blocking)
  Action: Add subscriber @security-leads

Rule: Large Diff Warning
  When: Differential revision is created
  If: Diff size > 500 lines
  Action: Add comment "Large diff - consider splitting"
  Action: Add reviewer @senior-engineers

Rule: Database Changes
  When: Differential revision is created
  If: Changed file matches *.sql OR migrations/**
  Action: Add reviewer @dba-team (blocking)
  Action: Flag for special attention
```

### 3 — Audit Configuration

```
AUDIT RULES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Post-commit audit rules:
    - All commits to main: audit by @tech-leads
    - Commits without review: audit by @engineering-managers
    - Commits by new engineers: audit by @mentors
[ ] Audit status tracking: concern-raised / accepted
[ ] Audit response SLA: ___ hours
```

## Common Operations

### List Pending Revisions
Query open Differential revisions awaiting review action.

### Herald Rule Testing
Test Herald rules against sample revisions to validate behavior.

### Audit Compliance
Track post-commit audits and ensure timely responses.

## Troubleshooting

| Issue | Cause | Fix |
|-------|-------|-----|
| Herald rule not triggering | Condition mismatch | Test rule against revision in Herald test console |
| Reviewer not notified | Notification preferences | Check user notification settings |
| Revision stuck in review | Blocking reviewer absent | Reassign blocking reviewer or remove requirement |
| Audit not created | Rule scope mismatch | Verify repository is within audit rule scope |
