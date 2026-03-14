---
name: okr-tracking-template
enabled: true
description: |
  Provides a structured template for defining, tracking, and grading OKRs (Objectives and Key Results) for engineering teams. This template covers objective setting, key result definition with measurable targets, progress tracking cadences, and end-of-cycle grading to help teams maintain focus and measure meaningful outcomes.
required_connections:
  - prefix: ticketing
    label: "Ticketing System"
  - prefix: collaboration
    label: "Collaboration Tool"
config_fields:
  - key: team_name
    label: "Team Name"
    required: true
    placeholder: "e.g., Developer Platform"
  - key: cycle
    label: "OKR Cycle"
    required: true
    placeholder: "e.g., Q2 2026"
features:
  - OKR_TRACKING
  - GOAL_SETTING
  - ENGINEERING_MANAGEMENT
---

# OKR Tracking Template

## Phase 1: Objective Definition

Define 2-4 objectives for the cycle. Objectives should be qualitative, ambitious, and inspiring.

**Guidelines for good objectives:**

- Aligned with team/org mission
- Qualitative and aspirational (not a metric)
- Achievable but stretching (aim for 70% completion)
- Time-bound to the OKR cycle

| # | Objective | Alignment | Owner |
|---|-----------|-----------|-------|
| O1 | | Company goal / team mission | |
| O2 | | | |
| O3 | | | |

## Phase 2: Key Results Definition

For each objective, define 2-4 measurable key results.

### O1: [Objective Title]

| KR | Key Result | Baseline | Target | Stretch | Current | Score |
|----|-----------|:--------:|:------:|:-------:|:-------:|:-----:|
| KR1.1 | | | | | | |
| KR1.2 | | | | | | |
| KR1.3 | | | | | | |

### O2: [Objective Title]

| KR | Key Result | Baseline | Target | Stretch | Current | Score |
|----|-----------|:--------:|:------:|:-------:|:-------:|:-----:|
| KR2.1 | | | | | | |
| KR2.2 | | | | | | |
| KR2.3 | | | | | | |

### O3: [Objective Title]

| KR | Key Result | Baseline | Target | Stretch | Current | Score |
|----|-----------|:--------:|:------:|:-------:|:-------:|:-----:|
| KR3.1 | | | | | | |
| KR3.2 | | | | | | |
| KR3.3 | | | | | | |

**Scoring Guide:**

| Score | Meaning |
|:-----:|---------|
| 0.0 | No progress |
| 0.3 | Some progress but fell significantly short |
| 0.5 | Made progress but missed target |
| 0.7 | Hit target (expected outcome for stretch goals) |
| 1.0 | Exceeded expectations |

## Phase 3: Weekly/Bi-Weekly Check-In

Track progress at regular intervals.

**Check-in Date: ___**

| KR | Status | Progress | Confidence | Blockers |
|----|:------:|:--------:|:----------:|----------|
| KR1.1 | On Track / At Risk / Behind | ___% | H/M/L | |
| KR1.2 | | | | |
| KR2.1 | | | | |

- [ ] Update current values for all key results
- [ ] Flag any key results at risk
- [ ] Identify and escalate blockers
- [ ] Adjust approach if needed (not the goal)

## Phase 4: End-of-Cycle Grading

Score each key result and calculate objective scores.

| Objective | KR Scores | Objective Score | Reflection |
|-----------|-----------|:---------------:|------------|
| O1 | KR1.1: ___, KR1.2: ___, KR1.3: ___ | (avg) | |
| O2 | KR2.1: ___, KR2.2: ___, KR2.3: ___ | (avg) | |
| O3 | KR3.1: ___, KR3.2: ___, KR3.3: ___ | (avg) | |

**Overall Score:** ___ (average of objective scores)

**Retrospective Questions:**

- [ ] Were objectives the right things to focus on?
- [ ] Were key results measurable and meaningful?
- [ ] What should carry over to next cycle?
- [ ] What did we learn about our planning accuracy?

## Output Format

### Summary

- **Team:** ___
- **Cycle:** ___
- **Objectives:** ___
- **Overall score:** ___ / 1.0
- **Key wins:** ___
- **Key misses:** ___

### Action Items

- [ ] Publish OKRs to team and stakeholders
- [ ] Set up automated tracking for measurable key results
- [ ] Schedule regular check-in cadence
- [ ] Conduct end-of-cycle grading session
- [ ] Draft next cycle OKRs based on learnings
- [ ] Share results and learnings with leadership
