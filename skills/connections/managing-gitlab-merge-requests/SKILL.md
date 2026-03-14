---
name: managing-gitlab-merge-requests
description: |
  GitLab merge request review management including approval rules, merge checks, code ownership via CODEOWNERS, merge request policies, and pipeline integration. Use when configuring or automating GitLab MR review workflows across projects and groups.
connection_type: gitlab
preload: false
---

# Managing GitLab Merge Requests

## Overview

Manage GitLab merge request review workflows, including approval rules, CODEOWNERS enforcement, merge checks, and pipeline-gated merges.

## Key Capabilities

- Configure merge request approval rules at project and group level
- Set up CODEOWNERS for automatic approval requirements
- Define merge checks (pipeline success, resolved discussions, signed commits)
- Manage merge request policies and merge methods
- Configure merge trains for high-throughput repositories
- Enforce approval policies via group-level compliance frameworks

## Workflow

### 1 — Approval Rules Configuration

```
APPROVAL RULES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Default approvals required: ___
[ ] Rules:
    Rule Name            | Approvers              | Required
    ─────────────────────┼────────────────────────┼─────────
    Backend Review       | @backend-team          | 1
    Security Review      | @security-team         | 1
    Architecture Review  | @architects            | 1 (optional)
[ ] Prevent author self-approval: YES / NO
[ ] Prevent committers from approving: YES / NO
[ ] Remove all approvals on new push: YES / NO
```

### 2 — Merge Checks

```
MERGE CHECKS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Pipeline must succeed: YES / NO
[ ] All discussions must be resolved: YES / NO
[ ] All status checks must pass: YES / NO
[ ] Signed commits required: YES / NO
[ ] Merge method: merge commit / squash / fast-forward
[ ] Merge trains enabled: YES / NO
[ ] Semi-linear history: YES / NO
```

### 3 — CODEOWNERS Setup

```
CODEOWNERS FILE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Location: CODEOWNERS (root or docs/)

Sections:
  [Backend]
  /src/api/         @backend-team
  /src/services/    @backend-team

  [Frontend]
  /src/ui/          @frontend-team
  /src/components/  @frontend-team

  [Infrastructure]
  /terraform/       @platform-team
  .gitlab-ci.yml    @devops-team

Optional vs Required sections:
  ^[Docs]           @tech-writers    (optional)
  [Security]        @security-team   (required)
```

### 4 — Compliance Framework

```
GROUP-LEVEL COMPLIANCE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Compliance framework applied: ___
[ ] Separation of duties enforced: YES / NO
[ ] Compliance pipeline configured: YES / NO
[ ] Audit events enabled: YES / NO
```

## Common Operations

### Review Pending MRs
List open merge requests awaiting approval, filter by project or group.

### Audit Approval Compliance
Verify that merge requests follow required approval rules and CODEOWNERS requirements.

### Merge Train Management
Monitor and manage merge train queues for high-throughput branches.

## Troubleshooting

| Issue | Cause | Fix |
|-------|-------|-----|
| Approvals not required | Rules not configured at project level | Set approval rules in Project > Settings > Merge Requests |
| CODEOWNERS not enforced | Premium/Ultimate required | CODEOWNERS approval requires GitLab Premium+ |
| Merge train failures | Pipeline conflicts | Check merge train pipeline logs for conflicts |
| Approvals reset unexpectedly | "Remove approvals on push" enabled | Disable in project settings if not desired |
