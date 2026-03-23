---
name: managing-reviewboard
description: |
  Use when working with Reviewboard — review Board code review management
  including review requests, diff management, review groups, and repository
  configuration. Use when managing Review Board review workflows, configuring
  review groups, and automating review request assignment.
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

## Output Format

Present results as a structured report:
```
Managing Reviewboard Report
═══════════════════════════
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

