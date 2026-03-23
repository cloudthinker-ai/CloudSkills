---
name: quarterly-planning-template
enabled: true
description: |
  Use when performing quarterly planning template — provides a structured
  framework for engineering quarterly planning, covering goal setting, capacity
  allocation, dependency mapping, risk assessment, and milestone definition.
  This template helps engineering teams align their quarterly work with
  organizational objectives while maintaining realistic commitments and
  appropriate investment in tech debt and innovation.
required_connections:
  - prefix: ticketing
    label: "Ticketing System"
  - prefix: collaboration
    label: "Collaboration Tool"
config_fields:
  - key: team_name
    label: "Team Name"
    required: true
    placeholder: "e.g., Core Infrastructure"
  - key: quarter
    label: "Quarter"
    required: true
    placeholder: "e.g., Q2 2026"
features:
  - QUARTERLY_PLANNING
  - ENGINEERING_MANAGEMENT
  - ROADMAP
---

# Quarterly Planning Template

## Phase 1: Context and Inputs

Gather inputs needed for planning.

- [ ] Review company/org-level objectives for the quarter
- [ ] Review previous quarter results and carry-over items
- [ ] Collect stakeholder requests and priorities
- [ ] Assess team capacity:

| Factor | Value |
|--------|-------|
| Team size (engineers) | |
| Working days in quarter | |
| Planned PTO / holidays (days) | |
| On-call tax (% of capacity) | |
| Available engineering weeks | |

**Investment Allocation (target %):**

| Category | Target % | Weeks |
|----------|:--------:|:-----:|
| Feature work | | |
| Tech debt / reliability | | |
| Innovation / exploration | | |
| On-call / operational | | |
| Total | 100% | |

## Phase 2: Goal Setting

Define 3-5 quarterly goals aligned with organizational objectives.

| # | Goal | Org Objective Alignment | Success Criteria | Confidence (H/M/L) |
|---|------|------------------------|------------------|:-------------------:|
| 1 | | | | |
| 2 | | | | |
| 3 | | | | |
| 4 | | | | |
| 5 | | | | |

- [ ] Each goal has measurable success criteria
- [ ] Goals are achievable within available capacity
- [ ] Goals are prioritized (if capacity is reduced, what gets cut?)

## Phase 3: Milestone Planning

Break goals into monthly milestones.

**Month 1:**

| Milestone | Goal # | Owner | Dependencies | Status |
|-----------|:------:|-------|-------------|--------|
|           |        |       |             |        |

**Month 2:**

| Milestone | Goal # | Owner | Dependencies | Status |
|-----------|:------:|-------|-------------|--------|
|           |        |       |             |        |

**Month 3:**

| Milestone | Goal # | Owner | Dependencies | Status |
|-----------|:------:|-------|-------------|--------|
|           |        |       |             |        |

## Phase 4: Dependency and Risk Analysis

**Cross-team dependencies:**

| Dependency | Owning Team | Needed By | Status | Risk |
|------------|------------|-----------|--------|------|
|            |            |           | Confirmed / Pending | H/M/L |

**Risks:**

| Risk | Likelihood (H/M/L) | Impact (H/M/L) | Mitigation |
|------|:-------------------:|:---------------:|------------|
|      |                     |                 |            |

- [ ] All critical dependencies confirmed with owning teams
- [ ] Mitigation plan exists for high-likelihood or high-impact risks
- [ ] Buffer capacity reserved for unknowns (recommended 15-20%)

## Phase 5: Communication and Tracking

- [ ] Quarterly plan shared with stakeholders
- [ ] Goals entered into OKR / goal tracking system
- [ ] Monthly check-in meetings scheduled
- [ ] Mid-quarter review date set: ___
- [ ] End-of-quarter review date set: ___

## Counter-Rationalizations

| Shortcut | Counter | Why |
|----------|---------|-----|
| "We can skip some steps for this case" | Adapt the workflow steps, don't skip them | Skipped steps are where incidents and oversights originate |
| "The user seems to already know what to do" | Complete all workflow phases with the user | The workflow catches blind spots that experience alone misses |
| "This is a minor case, full process is overkill" | Scale the process down, don't turn it off | Minor cases become major when unstructured; the process scales, not disappears |
| "I'll fill in the details later" | Complete each section before moving on | Deferred details are forgotten; real-time capture is more accurate |
| "The template output isn't necessary" | Always produce the structured output format | Structured output enables comparison, audit trails, and handoff to other teams |

## Output Format

### Summary

- **Team:** ___
- **Quarter:** ___
- **Goals:** ___
- **Available capacity:** ___ engineering weeks
- **Key dependencies:** ___
- **Top risk:** ___

### Action Items

- [ ] Finalize and publish quarterly plan
- [ ] Confirm all cross-team dependencies
- [ ] Create epics/tickets for all milestones
- [ ] Schedule monthly milestone check-ins
- [ ] Schedule mid-quarter review
- [ ] Communicate plan to stakeholders and leadership
