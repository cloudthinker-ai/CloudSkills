---
name: runbook-automation-assessment
enabled: true
description: |
  Use when performing runbook automation assessment — evaluates existing
  runbooks for automation potential, assessing each procedure's complexity,
  frequency, and risk to determine which runbooks should be automated first.
  This template produces a prioritized automation backlog and identifies the
  tooling needed to convert manual runbooks into automated remediation
  workflows.
required_connections:
  - prefix: wiki
    label: "Documentation Platform"
  - prefix: automation
    label: "Automation Platform"
config_fields:
  - key: team_name
    label: "Team Name"
    required: true
    placeholder: "e.g., SRE Team"
  - key: runbook_source
    label: "Runbook Repository Location"
    required: true
    placeholder: "e.g., Confluence space or Git repo URL"
features:
  - RUNBOOK
  - AUTOMATION
  - SRE_OPS
---

# Runbook Automation Assessment

## Phase 1: Runbook Inventory

Catalog all existing runbooks.

1. List every runbook maintained by the team:
   - [ ] Runbook title and location
   - [ ] Associated service or system
   - [ ] Last updated date
   - [ ] Last executed date
   - [ ] Frequency of execution (per month)
   - [ ] Average execution time (minutes)
   - [ ] Required expertise level (L1/L2/L3)

2. Flag runbooks that are:
   - [ ] Outdated (not updated in >6 months)
   - [ ] Never executed (possibly obsolete)
   - [ ] Missing or incomplete

## Phase 2: Automation Feasibility Scoring

For each runbook, score automation feasibility.

| Runbook | Frequency | Time per Run | Steps Count | Decision Points | External Dependencies | Risk Level | Automation Score |
|---------|-----------|-------------|-------------|-----------------|----------------------|------------|-----------------|
|         | 1-5       | 1-5         | 1-5         | 1-5 (inverse)   | 1-5 (inverse)        | 1-5 (inverse) |              |

**Scoring (each dimension 1-5, higher = more automatable):**

| Dimension | 1 (Low) | 5 (High) |
|-----------|---------|----------|
| Frequency | Yearly | Multiple times daily |
| Time per Run | <5 min | >60 min |
| Steps Count | 1-2 steps | >10 steps |
| Decision Points (inverse) | Many judgment calls | Purely procedural |
| External Dependencies (inverse) | Many external systems | Self-contained |
| Risk Level (inverse) | Data loss possible | Read-only / safe to retry |

## Phase 3: Automation Strategy

For top-scoring runbooks, define automation approach.

- [ ] **Full automation:** No human in the loop. Triggered automatically.
- [ ] **Semi-automation:** Human approves, system executes.
- [ ] **Assisted automation:** System prepares context, human executes with guidance.

For each candidate:
1. - [ ] Define trigger mechanism (alert, schedule, manual)
2. - [ ] Identify required API integrations
3. - [ ] Define rollback procedure
4. - [ ] Specify testing approach
5. - [ ] Estimate development effort (hours)

## Phase 4: Tooling Assessment

- [ ] Evaluate current automation tooling capabilities
- [ ] Identify gaps in tooling
- [ ] Recommend new tools or platform investments if needed
- [ ] Estimate total investment for automation program

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

- **Total runbooks assessed:** ___
- **Automatable (full):** ___
- **Automatable (semi/assisted):** ___
- **Requires manual execution:** ___
- **Obsolete / to archive:** ___
- **Estimated annual time savings from automation:** ___ hours

### Prioritized Automation Backlog

| Priority | Runbook | Approach | Effort | Annual Time Saved | ROI |
|----------|---------|----------|--------|-------------------|-----|
| 1        |         |          |        |                   |     |

### Action Items

- [ ] Archive obsolete runbooks
- [ ] Update outdated runbooks before automating
- [ ] Begin automation of top 3 candidates
- [ ] Establish runbook review cadence (quarterly)
- [ ] Define automation testing standards
