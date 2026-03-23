---
name: sprint-retrospective
enabled: true
description: |
  Use when performing sprint retrospective — facilitates structured sprint
  retrospectives that help engineering teams reflect on what went well, what
  could be improved, and what actions to take. This template guides teams
  through data-driven reflection, collaborative discussion, and actionable
  commitment tracking across sprint cycles.
required_connections:
  - prefix: ticketing
    label: "Ticketing System"
  - prefix: collaboration
    label: "Collaboration Tool"
config_fields:
  - key: team_name
    label: "Team Name"
    required: true
    placeholder: "e.g., Payments Squad"
  - key: sprint_name
    label: "Sprint Name"
    required: true
    placeholder: "e.g., Sprint 24"
  - key: sprint_dates
    label: "Sprint Dates"
    required: true
    placeholder: "e.g., 2026-03-01 to 2026-03-14"
features:
  - RETROSPECTIVE
  - AGILE
  - TEAM_PROCESS
---

# Sprint Retrospective

## Phase 1: Sprint Data Review

Gather objective data about the sprint before discussion.

- [ ] Sprint goal(s): ___
- [ ] Sprint goal met: Yes / Partially / No
- [ ] Stories committed: ___ | Stories completed: ___
- [ ] Story points committed: ___ | Story points completed: ___
- [ ] Bugs found during sprint: ___
- [ ] Unplanned work added mid-sprint: ___ items, ___ points
- [ ] Carry-over from previous sprint: ___ items

**Previous Retro Action Items Status:**

| Action Item | Owner | Status |
|-------------|-------|--------|
|             |       | Done / In Progress / Not Started |

## Phase 2: Team Reflection

Each team member contributes to these categories (timebox: 10 minutes).

**What went well:**

1.
2.
3.

**What could be improved:**

1.
2.
3.

**What puzzled or surprised us:**

1.
2.
3.

## Phase 3: Discussion and Theming

Group related items and discuss root causes (timebox: 20 minutes).

| Theme | Related Items | Root Cause | Impact (H/M/L) |
|-------|--------------|------------|-----------------|
|       |              |            |                 |

- [ ] Identify top 2-3 themes by team vote or dot voting
- [ ] Discuss root causes for highest-impact themes
- [ ] Distinguish between team-solvable vs. organizational issues

## Phase 4: Action Commitments

Define specific, achievable actions for the next sprint (limit to 2-3).

| Action | Owner | Due Date | Success Criteria |
|--------|-------|----------|------------------|
|        |       |          |                  |

- [ ] Each action has a single owner
- [ ] Actions are achievable within one sprint
- [ ] Success criteria are measurable
- [ ] Actions are added to the next sprint backlog

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
- **Sprint:** ___
- **Sprint goal achieved:** ___
- **Velocity:** ___ points
- **Top theme:** ___
- **Actions committed:** ___

### Action Items

- [ ] Add retro actions to next sprint backlog
- [ ] Follow up on incomplete actions from previous retro
- [ ] Share retro summary with stakeholders if applicable
- [ ] Schedule next retrospective
