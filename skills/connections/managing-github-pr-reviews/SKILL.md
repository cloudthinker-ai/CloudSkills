---
name: managing-github-pr-reviews
description: |
  GitHub pull request review management including review assignments, CODEOWNERS enforcement, branch protection rules, required reviewers, review dismissal policies, and status check integration. Use when configuring or automating GitHub PR review workflows across repositories and organizations.
connection_type: github
preload: false
---

# Managing GitHub PR Reviews

## Overview

Manage GitHub pull request review workflows, including reviewer assignment, CODEOWNERS configuration, branch protection rules, and review automation.

## Key Capabilities

- Configure branch protection rules with required reviews
- Manage CODEOWNERS files for automatic reviewer assignment
- Set up required status checks and review counts
- Configure review dismissal and stale review policies
- Automate reviewer assignment with round-robin or load-balance algorithms
- Enforce code review policies across organizations

## Workflow

### 1 — Configure Branch Protection

```
BRANCH PROTECTION SETUP
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Required approving reviews: ___ (recommended: 2)
[ ] Dismiss stale reviews on new pushes: YES / NO
[ ] Require review from CODEOWNERS: YES / NO
[ ] Restrict who can dismiss reviews: YES / NO
[ ] Require status checks to pass: YES / NO
[ ] Require branches to be up to date: YES / NO
[ ] Require signed commits: YES / NO
[ ] Require linear history: YES / NO
```

### 2 — CODEOWNERS Configuration

```
CODEOWNERS FILE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Location: .github/CODEOWNERS

Pattern examples:
  *                    @org/engineering-leads
  /src/api/            @org/backend-team
  /src/frontend/       @org/frontend-team
  /infrastructure/     @org/platform-team
  *.sql                @org/dba-team
  /docs/               @org/tech-writers
  Dockerfile           @org/devops
  .github/workflows/   @org/ci-cd-team
```

### 3 — Review Assignment

```
AUTO-ASSIGNMENT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Algorithm: round-robin / load-balance
[ ] Number of reviewers: ___
[ ] Skip team members who are:
    [ ] On PTO / away
    [ ] Already assigned
    [ ] The PR author
[ ] Notify assigned reviewers: YES / NO
[ ] Review request timeout: ___ hours
```

### 4 — Review Policy Enforcement

```
REVIEW POLICIES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Minimum approvals before merge: ___
[ ] Required reviewers for sensitive paths: ___
[ ] Block merge on requested changes: YES / NO
[ ] Require re-review after force push: YES / NO
[ ] Auto-merge when all checks pass: YES / NO
[ ] Merge methods allowed: merge / squash / rebase
```

## Common Operations

### List Pending Reviews
Query open PRs awaiting review, filter by team or reviewer, and track review SLAs.

### Audit Review Coverage
Analyze CODEOWNERS coverage across the repository to identify unowned code paths.

### Review Metrics
Track review turnaround time, approval rates, and reviewer workload distribution.

## Troubleshooting

| Issue | Cause | Fix |
|-------|-------|-----|
| CODEOWNERS not triggering | File in wrong location | Must be in `.github/`, `docs/`, or root |
| Reviews not required | Branch protection not set | Enable "Require pull request reviews" |
| Wrong reviewers assigned | Pattern order matters | CODEOWNERS uses last matching pattern |
| Stale reviews not dismissed | Setting disabled | Enable "Dismiss stale pull request approvals" |
| Auto-merge not working | Missing required checks | Ensure all required status checks are configured |
