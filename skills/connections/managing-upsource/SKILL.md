---
name: managing-upsource
description: |
  Use when working with Upsource — jetBrains Upsource code review management
  including review workflows, code inspections, branch review tracking, and IDE
  integration. Use when managing Upsource review processes, configuring
  automated inspections, and tracking review metrics.
connection_type: upsource
preload: false
---

# Managing Upsource

## Overview

Manage JetBrains Upsource code review workflows, including review creation, automated code inspections, branch-based reviews, and IDE integration for seamless review experiences.

## Key Capabilities

- Create and manage code reviews tied to branches or commits
- Run automated code inspections based on IntelliJ platform analysis
- Configure review workflows with custom states and transitions
- Set up branch review policies for automatic review creation
- Integrate with JetBrains IDEs for in-editor review participation
- Track code quality metrics and review analytics

## Workflow

### 1 — Review Workflow Configuration

```
REVIEW WORKFLOW
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Review model: branch-based / commit-based
[ ] Auto-create reviews for branches: YES / NO
[ ] Branch patterns for auto-review:
    - feature/*  -> require review
    - hotfix/*   -> require review
    - main       -> protected (no direct push)
[ ] Required reviewers: ___
[ ] Review completion criteria:
    - All reviewers accepted: YES / NO
    - No unresolved discussions: YES / NO
    - All inspections pass: YES / NO
```

### 2 — Code Inspections

```
AUTOMATED INSPECTIONS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Inspection profiles:
    - Default (all inspections)
    - Security-focused
    - Performance-focused
[ ] Run on: every commit / review creation / manual
[ ] Block merge on:
    - Critical issues: YES / NO
    - Warning-level issues: YES / NO
[ ] Custom inspection rules: ___
```

### 3 — Project Settings

```
PROJECT CONFIGURATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Default reviewers per project: ___
[ ] Review label schema: accept / concern / reject
[ ] Discussion resolution required: YES / NO
[ ] Merge check integration: YES / NO
[ ] Code intelligence enabled: YES / NO
```

## Common Operations

### List Open Reviews
Query open reviews by project, branch, or reviewer status.

### Inspection Results
View automated inspection findings grouped by severity and category.

### Review Analytics
Track review velocity, inspection pass rates, and code quality trends.

## Troubleshooting

| Issue | Cause | Fix |
|-------|-------|-----|
| Inspections not running | Profile not configured | Set inspection profile in project settings |
| Review not auto-created | Branch pattern mismatch | Verify branch naming matches auto-review patterns |
| IDE integration broken | Plugin version mismatch | Update Upsource plugin to match server version |
| Merge check failing | Unresolved discussions | Resolve all open discussions in review |

## Output Format

Present results as a structured report:
```
Managing Upsource Report
════════════════════════
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

