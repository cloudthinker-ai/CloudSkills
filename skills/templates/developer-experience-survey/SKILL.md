---
name: developer-experience-survey
enabled: true
description: |
  Structures a comprehensive developer experience survey covering tooling satisfaction, development workflow friction, documentation quality, and overall developer productivity. This template helps platform and engineering leadership teams identify pain points and prioritize investments that improve developer velocity and satisfaction.
required_connections:
  - prefix: collaboration
    label: "Collaboration Tool"
config_fields:
  - key: org_name
    label: "Organization Name"
    required: true
    placeholder: "e.g., Engineering Department"
  - key: survey_period
    label: "Survey Period"
    required: true
    placeholder: "e.g., Q1 2026"
features:
  - DEVELOPER_EXPERIENCE
  - PLATFORM_ENGINEERING
  - SURVEY
---

# Developer Experience Survey

## Phase 1: Survey Design

Define survey scope and distribution plan.

- [ ] Target audience: ___ (all engineers / specific teams / new hires)
- [ ] Expected respondents: ___
- [ ] Survey open period: ___ to ___
- [ ] Anonymous: Yes / No
- [ ] Distribution channel: ___

## Phase 2: Survey Sections

### Section A: Development Environment (rate 1-5)

| Question | Rating | Comments |
|----------|:------:|----------|
| My local development setup is easy to configure | | |
| Build times are acceptable | | |
| Test execution speed is acceptable | | |
| IDE and tooling meet my needs | | |
| I can spin up a development environment quickly | | |

### Section B: CI/CD and Deployment (rate 1-5)

| Question | Rating | Comments |
|----------|:------:|----------|
| CI pipeline is fast and reliable | | |
| I can deploy my changes to production confidently | | |
| Rollback process is straightforward | | |
| Feature flags are easy to use | | |
| I get timely feedback on build/test failures | | |

### Section C: Documentation and Knowledge (rate 1-5)

| Question | Rating | Comments |
|----------|:------:|----------|
| Internal documentation is up to date | | |
| I can find the information I need quickly | | |
| Onboarding documentation is helpful | | |
| API documentation is accurate | | |
| Runbooks are useful during incidents | | |

### Section D: Collaboration and Process (rate 1-5)

| Question | Rating | Comments |
|----------|:------:|----------|
| Code reviews are timely and constructive | | |
| I understand the team priorities and goals | | |
| Meetings are effective and well-structured | | |
| I feel comfortable asking for help | | |
| Cross-team collaboration is smooth | | |

### Section E: Open-Ended Questions

1. What is the single biggest thing slowing you down?
2. What tool or process change would have the most impact?
3. What do we do well that we should keep doing?

## Phase 3: Results Analysis

- [ ] Calculate average scores per section
- [ ] Identify bottom 5 questions by score
- [ ] Compare results to previous survey (if applicable)
- [ ] Segment results by team, tenure, and role
- [ ] Extract common themes from open-ended responses

| Section | Avg Score | Previous | Change |
|---------|:---------:|:--------:|:------:|
| Development Environment | | | |
| CI/CD and Deployment | | | |
| Documentation and Knowledge | | | |
| Collaboration and Process | | | |

## Phase 4: Action Planning

| Finding | Impact (H/M/L) | Effort (H/M/L) | Owner | Target Date |
|---------|:---------------:|:---------------:|-------|-------------|
|         |                 |                 |       |             |

- [ ] Prioritize quick wins (high impact, low effort)
- [ ] Create project proposals for high-impact, high-effort items
- [ ] Assign owners for each action item
- [ ] Define success metrics for each initiative

## Output Format

### Summary

- **Organization:** ___
- **Response rate:** ___% (___ / ___ engineers)
- **Overall DX score:** ___ / 5.0
- **Highest-rated area:** ___
- **Lowest-rated area:** ___
- **Top requested improvement:** ___

### Action Items

- [ ] Share anonymized results with all respondents
- [ ] Present findings and action plan to leadership
- [ ] Begin work on top 3 quick-win improvements
- [ ] Schedule follow-up survey in next quarter
- [ ] Track improvement metrics for funded initiatives
