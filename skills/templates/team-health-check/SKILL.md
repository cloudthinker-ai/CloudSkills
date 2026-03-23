---
name: team-health-check
enabled: true
description: |
  Use when performing team health check — provides a structured framework for
  assessing engineering team health across key dimensions including delivery
  pace, code quality, collaboration, well-being, and technical practices. This
  template helps engineering managers and team leads identify areas of strength
  and opportunities for improvement through regular pulse checks.
required_connections:
  - prefix: collaboration
    label: "Collaboration Tool"
  - prefix: ticketing
    label: "Ticketing System"
config_fields:
  - key: team_name
    label: "Team Name"
    required: true
    placeholder: "e.g., Backend Platform Team"
  - key: assessment_period
    label: "Assessment Period"
    required: true
    placeholder: "e.g., Q1 2026"
features:
  - TEAM_HEALTH
  - ENGINEERING_MANAGEMENT
  - CULTURE
---

# Team Health Check

## Phase 1: Health Dimensions Assessment

Rate each dimension on a scale from 1 (needs urgent attention) to 5 (thriving). Gather input from all team members anonymously.

| Dimension | Rating (1-5) | Trend (Up/Down/Stable) | Notes |
|-----------|:------------:|:----------------------:|-------|
| Delivery Pace | | | |
| Code Quality | | | |
| Technical Debt | | | |
| On-Call Experience | | | |
| Collaboration | | | |
| Psychological Safety | | | |
| Learning & Growth | | | |
| Work-Life Balance | | | |
| Tooling & Infrastructure | | | |
| Alignment with Mission | | | |

## Phase 2: Deep Dive on Low-Scoring Areas

For each dimension rated 3 or below, investigate root causes.

- [ ] Identify the 2-3 lowest-scoring dimensions
- [ ] For each:
  - [ ] What specific symptoms are team members experiencing?
  - [ ] When did this become a problem?
  - [ ] What has been tried already?
  - [ ] What is the impact on team output and morale?

**Dimension: ___**
- Symptoms: ___
- Root cause: ___
- Impact: ___

## Phase 3: Strength Amplification

For dimensions rated 4-5, identify what is working and how to sustain it.

- [ ] What practices or conditions enable this strength?
- [ ] Is this strength at risk from upcoming changes?
- [ ] Can these practices be shared with other teams?

## Phase 4: Improvement Plan

| Dimension | Current | Target | Action | Owner | Timeline |
|-----------|:-------:|:------:|--------|-------|----------|
|           |         |        |        |       |          |

- [ ] Limit to 2-3 improvement initiatives per quarter
- [ ] Each initiative has a measurable target
- [ ] Progress is reviewed in regular 1:1s and team meetings

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
- **Period:** ___
- **Overall health score:** ___ / 5.0 (average)
- **Strongest dimension:** ___
- **Weakest dimension:** ___
- **Trend from last check:** Improving / Stable / Declining

### Action Items

- [ ] Share anonymized results with the team
- [ ] Create improvement initiatives for lowest-scoring areas
- [ ] Schedule follow-up health check in 4-6 weeks
- [ ] Escalate organizational blockers to leadership
- [ ] Celebrate team strengths and recognize contributors
