---
name: managing-pullrequest-com
description: |
  PullRequest professional code review service management including reviewer pool configuration, review SLAs, quality standards, and integration with GitHub/GitLab/Bitbucket. Use when managing PullRequest.com professional review workflows, reviewer expertise matching, and review quality tracking.
connection_type: pullrequest
preload: false
---

# Managing PullRequest.com

## Overview

Manage PullRequest.com professional code review service, including reviewer pool configuration, SLA management, review quality standards, and integration with source code hosting platforms.

## Key Capabilities

- Configure professional reviewer assignments by technology and domain
- Set review SLAs and turnaround time expectations
- Define review quality standards and checklists
- Integrate with GitHub, GitLab, and Bitbucket for seamless PR flow
- Track review quality metrics and reviewer performance
- Manage reviewer expertise matching for specialized codebases

## Workflow

### 1 — Service Configuration

```
SERVICE SETUP
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Repository connections:
    - GitHub: org/repo-1, org/repo-2
    - GitLab: group/project-1
[ ] Review scope:
    - All PRs: YES / NO
    - PRs with specific labels: ___
    - PRs targeting specific branches: ___
[ ] Technology stack: ___
[ ] Review turnaround SLA: ___ hours
```

### 2 — Review Standards

```
QUALITY STANDARDS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Review focus areas:
    [ ] Correctness and logic
    [ ] Security vulnerabilities
    [ ] Performance implications
    [ ] Code style and maintainability
    [ ] Test coverage adequacy
    [ ] Documentation completeness
[ ] Severity levels for findings:
    - Critical: must fix before merge
    - Suggestion: recommended improvement
    - Nitpick: optional style preference
[ ] Custom review checklist: ___
```

### 3 — Reviewer Matching

```
EXPERTISE MATCHING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Match reviewers by:
    - Language expertise: ___
    - Framework knowledge: ___
    - Domain experience: ___
[ ] Preferred reviewers: ___
[ ] Reviewer consistency (same reviewer for related PRs): YES / NO
```

## Common Operations

### Track Review Status
Monitor pending, in-progress, and completed reviews across repositories.

### Review Quality Audit
Analyze review thoroughness, finding accuracy, and false positive rates.

### SLA Monitoring
Track review turnaround times against configured SLAs.

## Troubleshooting

| Issue | Cause | Fix |
|-------|-------|-----|
| PR not picked up | Label/branch filter mismatch | Check repository filter configuration |
| Review delayed | SLA breach | Escalate or adjust reviewer pool availability |
| Low quality feedback | Expertise mismatch | Update technology stack and matching preferences |
| Integration error | Webhook misconfigured | Verify webhook URL and authentication token |
