---
name: toil-reduction-analysis
enabled: true
description: |
  Use when performing toil reduction analysis — systematically identifies,
  quantifies, and prioritizes toil within engineering teams. This template
  guides SRE and operations teams through cataloging repetitive manual work,
  measuring its impact on productivity, and developing automation strategies to
  reclaim engineering time for higher-value projects.
required_connections:
  - prefix: ticketing
    label: "Ticketing System"
  - prefix: monitoring
    label: "Monitoring Platform"
config_fields:
  - key: team_name
    label: "Team Name"
    required: true
    placeholder: "e.g., Platform Engineering"
  - key: review_period
    label: "Review Period"
    required: true
    placeholder: "e.g., Q1 2026"
  - key: toil_threshold_hours
    label: "Weekly Toil Threshold (hours)"
    required: false
    placeholder: "e.g., 8"
features:
  - TOIL_TRACKING
  - AUTOMATION_PLANNING
  - SRE_OPS
---

# Toil Reduction Analysis

## Phase 1: Toil Inventory

Catalog all repetitive, manual, automatable work performed by the team.

1. List every recurring operational task performed in the review period.
2. For each task, record:
   - [ ] Task name and brief description
   - [ ] Frequency (daily, weekly, monthly, ad-hoc)
   - [ ] Average time per occurrence (minutes)
   - [ ] Number of occurrences in the review period
   - [ ] Total time spent (hours)
   - [ ] Who performs it (individual or rotation)

## Phase 2: Toil Classification

Classify each task against the standard toil characteristics.

| Task | Manual | Repetitive | Automatable | Tactical | No Lasting Value | Scales with Service | Toil Score (0-6) |
|------|--------|------------|-------------|----------|------------------|---------------------|-------------------|
|      | Y/N    | Y/N        | Y/N         | Y/N      | Y/N              | Y/N                 |                   |

**Decision Matrix — Prioritization:**

| Priority | Criteria |
|----------|----------|
| P0 — Immediate | Toil score 5-6, >4 hours/week, automation feasible in <2 weeks |
| P1 — High | Toil score 4-5, >2 hours/week, automation feasible in <1 month |
| P2 — Medium | Toil score 3-4, >1 hour/week, requires design work |
| P3 — Low | Toil score <3, <1 hour/week, or complex dependencies |

## Phase 3: Impact Analysis

For each P0/P1 item, quantify the impact:

- [ ] Calculate annual time cost: `occurrences_per_year * avg_time_per_occurrence`
- [ ] Estimate error rate introduced by manual execution
- [ ] Identify downstream effects (delays, incidents, developer frustration)
- [ ] Estimate cost of automation (engineering hours to build)
- [ ] Calculate ROI: `annual_time_saved / automation_cost`

## Phase 4: Automation Roadmap

1. Draft automation proposals for each prioritized item.
2. For each proposal:
   - [ ] Define target state (fully automated, semi-automated, self-service)
   - [ ] Identify tooling or platform requirements
   - [ ] Assign owner and estimated completion date
   - [ ] Define success metrics (time saved, error reduction)

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

- **Total toil identified:** ___ hours/week
- **Toil as percentage of team capacity:** ___%
- **Top 3 toil sources:**
  1. Task — hours/week
  2. Task — hours/week
  3. Task — hours/week

### Action Items

- [ ] File automation tickets for all P0 items by end of week
- [ ] Schedule design reviews for P1 items within 2 weeks
- [ ] Re-assess toil inventory at next review cycle
- [ ] Share findings with leadership for resourcing decisions
