---
name: managing-codeball
description: |
  CodeBall AI-powered pull request risk assessment including automatic PR quality scoring, risk classification, and auto-approval for low-risk changes. Use when configuring CodeBall for automated PR triage, risk-based review routing, and review workload optimization.
connection_type: codeball
preload: false
---

# Managing CodeBall

## Overview

Manage CodeBall AI-powered PR risk assessment, including automatic quality scoring, risk classification, auto-approval for safe changes, and integration with review workflows.

## Key Capabilities

- Automatically assess PR risk level using AI analysis
- Auto-approve low-risk PRs to reduce reviewer burden
- Classify PRs by risk: low, medium, high
- Integrate risk scores into existing review workflows
- Track risk assessment accuracy over time
- Configure risk thresholds and auto-approval policies

## Workflow

### 1 — Risk Assessment Configuration

```
RISK ASSESSMENT SETUP
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Enable AI risk scoring: YES / NO
[ ] Risk classification thresholds:
    - Low risk (auto-approve eligible): score < ___
    - Medium risk (standard review): score ___ - ___
    - High risk (senior review required): score > ___
[ ] Analysis scope:
    - All PRs: YES / NO
    - Exclude draft PRs: YES / NO
    - Exclude WIP PRs: YES / NO
```

### 2 — Auto-Approval Policy

```
AUTO-APPROVAL RULES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Enable auto-approve for low-risk PRs: YES / NO
[ ] Additional conditions for auto-approve:
    [ ] All CI checks pass
    [ ] PR size < ___ lines
    [ ] No changes to critical paths (auth, payments, etc.)
    [ ] Author has > ___ merged PRs
[ ] Label auto-approved PRs: YES / NO
[ ] Post approval comment: YES / NO
```

### 3 — Review Routing

```
RISK-BASED ROUTING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Low risk: auto-approve or assign to any reviewer
[ ] Medium risk: assign to team reviewer
[ ] High risk: assign to senior engineer + additional reviewer
[ ] Critical risk: assign to tech lead + security review
[ ] Add risk label to PR: YES / NO
```

## Common Operations

### Risk Score Dashboard
View aggregate risk scores across PRs, trending over time.

### Auto-Approval Audit
Review auto-approved PRs to validate AI assessment accuracy.

### Threshold Tuning
Adjust risk thresholds based on false positive/negative rates.

## Troubleshooting

| Issue | Cause | Fix |
|-------|-------|-----|
| All PRs marked high risk | Threshold too low | Increase high-risk threshold based on score distribution |
| False auto-approvals | Threshold too permissive | Lower auto-approve threshold or add conditions |
| Risk score not appearing | GitHub App permissions | Verify CodeBall app has read access to PR content |
| Assessment delayed | Queue backlog | Check CodeBall service status |
