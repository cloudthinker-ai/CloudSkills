---
name: alert-fatigue-reduction
enabled: true
description: |
  Analyzes alerting configurations to identify noise, redundancy, and low-value alerts that contribute to on-call fatigue. This template walks teams through auditing their alert rules, measuring signal-to-noise ratios, and implementing changes to ensure every page is actionable and meaningful.
required_connections:
  - prefix: monitoring
    label: "Monitoring Platform"
  - prefix: pagerduty
    label: "Paging System"
config_fields:
  - key: team_name
    label: "Team Name"
    required: true
    placeholder: "e.g., Backend On-Call"
  - key: analysis_window
    label: "Analysis Window"
    required: true
    placeholder: "e.g., Last 30 days"
features:
  - ALERTING
  - ON_CALL
  - SRE_OPS
---

# Alert Fatigue Reduction

## Phase 1: Alert Volume Analysis

Gather alert data for the analysis window.

- [ ] Total alerts fired: ___
- [ ] Total unique alert rules that fired: ___
- [ ] Alerts per day (average): ___
- [ ] Alerts per on-call shift (average): ___
- [ ] Peak alert hour/day: ___
- [ ] Off-hours pages (nights/weekends): ___

## Phase 2: Alert Classification

Classify every alert rule that fired during the window.

| Alert Rule | Fires (count) | Actionable (%) | Avg Resolution Time | Auto-resolved (%) | Category |
|------------|---------------|----------------|---------------------|--------------------|----------|
|            |               |                |                     |                    |          |

**Categories:**

| Category | Definition |
|----------|-----------|
| Actionable | Required human intervention that prevented or mitigated user impact |
| Informational | Provided useful context but required no action |
| Noisy | Fired frequently without requiring action; contributes to fatigue |
| Redundant | Duplicates another alert for the same condition |
| Stale | Monitors a condition that is no longer relevant |
| Misconfigured | Threshold too sensitive or monitoring wrong metric |

## Phase 3: Signal-to-Noise Assessment

- [ ] Calculate signal-to-noise ratio: `actionable_alerts / total_alerts * 100`
- [ ] Target ratio: >70% actionable
- [ ] Current ratio: ___%
- [ ] Identify top 10 noisiest alert rules

**Decision Matrix — Alert Disposition:**

| Category | Action |
|----------|--------|
| Actionable | Keep. Review thresholds for optimization. |
| Informational | Convert to dashboard or log-based notification. Remove paging. |
| Noisy | Adjust thresholds, add dampening, or consolidate with related alerts. |
| Redundant | Delete or merge into parent alert. |
| Stale | Delete after confirming with service owner. |
| Misconfigured | Fix threshold, metric, or query. Revalidate. |

## Phase 4: On-Call Impact Assessment

- [ ] Survey on-call engineers about alert quality (1-5 scale)
- [ ] Measure sleep interruption frequency
- [ ] Identify alerts most commonly snoozed or acknowledged-without-action
- [ ] Assess on-call handoff notes for recurring complaints

## Phase 5: Remediation Plan

For each alert requiring changes:

1. - [ ] Document current configuration
2. - [ ] Define new configuration (threshold, window, dampening)
3. - [ ] Test in non-paging mode for 1 week
4. - [ ] Promote to paging after validation
5. - [ ] Monitor for false negatives

## Output Format

### Summary

- **Total alerts analyzed:** ___
- **Signal-to-noise ratio:** ___%
- **Alerts to remove:** ___
- **Alerts to tune:** ___
- **Projected reduction in alert volume:** ___%

### Action Items

- [ ] Delete all stale and redundant alerts
- [ ] Tune top 10 noisiest alerts within 2 weeks
- [ ] Convert informational alerts to dashboard widgets
- [ ] Establish monthly alert hygiene review
- [ ] Set team target for signal-to-noise ratio
