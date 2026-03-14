---
name: managing-gerrit
description: |
  Gerrit code review system management including change review workflows, submit rules, label configuration, group permissions, and Prolog-based submit rules. Use when managing Gerrit review policies, change management, and approval workflows.
connection_type: gerrit
preload: false
---

# Managing Gerrit

## Overview

Manage Gerrit code review workflows, including change review processes, submit rules, label definitions, project permissions, and reviewer configuration.

## Key Capabilities

- Configure review labels (Code-Review, Verified, custom labels)
- Define submit rules using Prolog or simple configuration
- Manage project access controls and group permissions
- Set up change submission requirements and strategies
- Configure reviewer suggestions and attention sets
- Manage topic-based change grouping and submission

## Workflow

### 1 — Label Configuration

```
REVIEW LABELS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Code-Review:
    -2  This shall not be merged
    -1  I would prefer this is not merged as is
     0  No score
    +1  Looks good to me, but someone else must approve
    +2  Looks good to me, approved
[ ] Verified:
    -1  Fails
     0  No score
    +1  Verified
[ ] Custom labels:
    Label: ___  Range: ___ to ___
```

### 2 — Submit Rules

```
SUBMIT REQUIREMENTS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Required labels for submit:
    - Code-Review: +2 (at least one)
    - Code-Review: no -2 (block on negative)
    - Verified: +1
[ ] Submit type: merge / rebase / cherry-pick / fast-forward
[ ] Author must not self-approve: YES / NO
[ ] Require all inline comments resolved: YES / NO
```

### 3 — Project Access Control

```
ACCESS CONTROL
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Groups:
    - Developers: push, code-review -1..+1
    - Senior Devs: code-review -2..+2
    - CI System: verified -1..+1
    - Project Leads: submit, abandon
[ ] Branch permissions:
    refs/heads/main: restricted push
    refs/heads/*: allow push for Developers
[ ] Inherit from parent project: YES / NO
```

### 4 — Reviewer Configuration

```
REVIEWER SETUP
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Default reviewers by path:
    src/api/**     -> backend-reviewers
    src/ui/**      -> frontend-reviewers
    *.proto        -> api-reviewers
[ ] Attention set management: auto / manual
[ ] Reviewer suggestions enabled: YES / NO
```

## Common Operations

### Query Open Changes
List open changes pending review, filter by project, branch, or reviewer.

### Submit Rule Validation
Test submit rules against pending changes to verify policy compliance.

### Access Control Audit
Review project permissions to ensure least-privilege access.

## Troubleshooting

| Issue | Cause | Fix |
|-------|-------|-----|
| Cannot submit change | Missing required label score | Check submit requirements for all labels |
| Reviewer cannot +2 | Insufficient permissions | Add user to group with Code-Review +2 range |
| Submit rule not applied | Prolog syntax error | Validate rules.pl in project refs/meta/config |
| Change stuck in review | Attention set stale | Update attention set to notify appropriate reviewer |
