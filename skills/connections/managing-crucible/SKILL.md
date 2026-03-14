---
name: managing-crucible
description: |
  Atlassian Crucible code review management including review creation, commenting workflows, approval processes, and Jira integration. Use when managing Crucible review workflows, configuring review templates, and enforcing review completion policies.
connection_type: crucible
preload: false
---

# Managing Crucible

## Overview

Manage Atlassian Crucible code review workflows, including review creation, commenting, approval workflows, and integration with Jira and Bitbucket/Stash.

## Key Capabilities

- Create and manage code reviews with multiple changesets
- Configure review templates and default reviewers
- Manage commenting and defect tracking within reviews
- Set up approval workflows and completion conditions
- Integrate with Jira for review-to-issue traceability
- Configure notifications and review reminders

## Workflow

### 1 — Review Configuration

```
REVIEW SETUP
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Review type: changeset / patch / snippet
[ ] Project: ___
[ ] Default moderator: ___
[ ] Default reviewers: ___
[ ] Allow self-review: YES / NO
[ ] Review template: ___
[ ] Jira issue linkage: required / optional / disabled
```

### 2 — Approval Workflow

```
APPROVAL WORKFLOW
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Review states:
  Draft -> Under Review -> Summarized -> Closed

[ ] Require all reviewers to complete: YES / NO
[ ] Minimum approvals for completion: ___
[ ] Allow close with open defects: YES / NO
[ ] Require moderator summarization: YES / NO
[ ] Auto-close after ___ days of inactivity
```

### 3 — Comment and Defect Tracking

```
COMMENTING POLICY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Comment classifications:
  [ ] Defect — Must fix before approval
  [ ] Comment — Informational, no action required
  [ ] Question — Requires author response

[ ] Inline comments on specific lines: YES / NO
[ ] General review comments: YES / NO
[ ] Defect severity levels: critical / major / minor
[ ] Create Jira issues from defects: YES / NO
```

## Common Operations

### List Active Reviews
Query open reviews, filter by project, reviewer, or author.

### Review Metrics
Track review completion rates, defect density, and reviewer participation.

### Jira Integration
Link reviews to Jira issues and track review status from issue context.

## Troubleshooting

| Issue | Cause | Fix |
|-------|-------|-----|
| Review not starting | Missing reviewers | Add at least one reviewer before starting |
| Cannot close review | Open defects remain | Resolve or downgrade all defect comments |
| Jira link missing | Integration not configured | Configure Crucible-Jira application link |
| Notifications not sent | Email settings | Verify SMTP and user notification preferences |
