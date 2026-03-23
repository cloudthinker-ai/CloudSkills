---
name: managing-phabricator
description: |
  Use when working with Phabricator — phabricator Differential code review
  management including review workflows, Herald rules for automated actions,
  audit trails, and reviewer assignment. Use when managing Phabricator code
  review processes, Herald automation, and Differential revision workflows.
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

## Output Format

Present results as a structured report:
```
Managing Phabricator Report
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

