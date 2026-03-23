---
name: managing-pullrequest-com
description: |
  Use when working with Pullrequest Com — pullRequest professional code review
  service management including reviewer pool configuration, review SLAs, quality
  standards, and integration with GitHub/GitLab/Bitbucket. Use when managing
  PullRequest.com professional review workflows, reviewer expertise matching,
  and review quality tracking.
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

## Output Format

Present results as a structured report:
```
Managing Pullrequest Com Report
═══════════════════════════════
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

