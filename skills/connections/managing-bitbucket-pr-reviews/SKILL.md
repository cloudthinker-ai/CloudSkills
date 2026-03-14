---
name: managing-bitbucket-pr-reviews
description: |
  Bitbucket pull request review management including default reviewers, merge checks, branch permissions, and build status integration. Use when configuring or automating Bitbucket PR review workflows across repositories and workspaces.
connection_type: bitbucket
preload: false
---

# Managing Bitbucket PR Reviews

## Overview

Manage Bitbucket pull request review workflows, including default reviewers, merge checks, branch permissions, and CI/CD integration for gated merges.

## Key Capabilities

- Configure default reviewers per repository or branch pattern
- Set up merge checks requiring approvals and successful builds
- Manage branch permissions and merge restrictions
- Configure merge strategies (merge commit, squash, fast-forward)
- Set up build status requirements for merge eligibility
- Enforce review policies across Bitbucket workspaces

## Workflow

### 1 — Default Reviewers

```
DEFAULT REVIEWERS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Repository-level default reviewers:
    - @backend-team (for src/**)
    - @frontend-team (for ui/**)
    - @devops-team (for pipelines/**)
[ ] Branch pattern reviewers:
    Pattern: main <- feature/*
    Reviewers: @senior-engineers
    Required approvals: 2
[ ] Branch pattern reviewers:
    Pattern: release/* <- *
    Reviewers: @release-managers
    Required approvals: 1
```

### 2 — Merge Checks

```
MERGE CHECKS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Minimum approvals: ___
[ ] No open tasks: YES / NO
[ ] Minimum successful builds: ___
[ ] All builds must pass: YES / NO
[ ] Merge strategy: merge / squash / fast-forward
[ ] Close source branch on merge: YES / NO
[ ] Require passing builds before merge: YES / NO
```

### 3 — Branch Permissions

```
BRANCH PERMISSIONS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Branch: main
[ ] Prevent direct pushes (require PR): YES / NO
[ ] Prevent deletions: YES / NO
[ ] Prevent rewriting history: YES / NO
[ ] Write access restricted to: ___
[ ] Merge access restricted to: ___
```

## Common Operations

### List PRs Awaiting Review
Query open pull requests pending reviewer action across repositories.

### Audit Merge Compliance
Verify that merged PRs met minimum approval and build requirements.

### Reviewer Workload
Analyze reviewer assignment distribution and review turnaround times.

## Troubleshooting

| Issue | Cause | Fix |
|-------|-------|-----|
| Default reviewers not assigned | Pattern mismatch | Check source/destination branch patterns |
| Merge button disabled | Merge checks not met | Verify approvals, builds, and task completion |
| Build status not showing | Pipeline not reporting | Ensure CI/CD reports build status to Bitbucket |
| Branch permissions ignored | Admin override | Admins can bypass; restrict admin merge access |
