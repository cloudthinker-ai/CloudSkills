---
name: feature-flag-cleanup
enabled: true
description: |
  Use when performing feature flag cleanup — template for systematically
  identifying and removing stale feature flags from codebases. Covers flag
  inventory, staleness analysis, dependency mapping, safe removal workflow, and
  verification to reduce technical debt and codebase complexity from accumulated
  feature flags.
required_connections:
  - prefix: github
    label: "GitHub"
config_fields:
  - key: repository
    label: "Repository"
    required: true
    placeholder: "e.g., org/payment-service"
  - key: flag_system
    label: "Feature Flag System"
    required: true
    placeholder: "e.g., LaunchDarkly, Unleash, custom"
  - key: staleness_threshold
    label: "Staleness Threshold (days)"
    required: false
    placeholder: "e.g., 30"
features:
  - DEVOPS
  - ENGINEERING
---

# Feature Flag Cleanup Skill

Audit and clean up stale feature flags in **{{ repository }}** using **{{ flag_system }}**.

## Workflow

### Phase 1 — Flag Inventory

```
FEATURE FLAG CATALOG
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Total feature flags: ___
[ ] Flags by status:
    - Fully rolled out (100% on): ___
    - Partially rolled out: ___
    - Disabled (0% on): ___
    - Kill switches (permanent): ___
    - Experiment flags: ___
[ ] Flags by age:
    - < 30 days: ___
    - 30-90 days: ___
    - 90-180 days: ___
    - > 180 days: ___
[ ] Flags without owner: ___
```

### Phase 2 — Staleness Analysis

```
STALE FLAG IDENTIFICATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Staleness criteria (flag is stale if ANY apply):
[ ] Fully rolled out for > {{ staleness_threshold }} days
[ ] Disabled for > {{ staleness_threshold }} days
[ ] No configuration changes in > {{ staleness_threshold }} days
[ ] Associated feature/experiment completed

STALE FLAGS FOR REMOVAL
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Flag Name              | Status  | Age    | Owner   | Action
_______________________|_________|________|_________|________
                       |         |        |         |
                       |         |        |         |
                       |         |        |         |

FLAGS TO KEEP (with justification)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Flag Name              | Reason to Keep
_______________________|_______________________
                       |
                       |
```

### Phase 3 — Dependency Analysis

```
CODE REFERENCES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
For each stale flag:
[ ] Code references identified (grep/search):
    - Source files: ___
    - Test files: ___
    - Configuration files: ___
[ ] Conditional branches mapped:
    - if (flag) branches to keep: ___
    - else branches to remove: ___
[ ] No external dependencies on flag value
[ ] No A/B test data collection dependencies
```

### Phase 4 — Safe Removal

```
REMOVAL WORKFLOW (per flag)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] 1. Confirm flag is fully rolled out or fully disabled
[ ] 2. Remove flag checks from code:
       - Replace if(flag) blocks with the winning branch
       - Remove else/fallback branches
[ ] 3. Remove flag from configuration/flag system
[ ] 4. Remove flag-specific tests
[ ] 5. Update documentation
[ ] 6. Create PR with clear description of removal
[ ] 7. Review and merge
[ ] 8. Deploy and verify no regressions
```

### Phase 5 — Verification

```
POST-CLEANUP VALIDATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] All tests pass after flag removal
[ ] No runtime errors referencing removed flags
[ ] Flag removed from flag management system
[ ] Code review confirmed clean removal
[ ] Monitoring shows no impact on:
    - Error rates
    - Performance metrics
    - User-facing behavior
[ ] Flags removed in this cleanup: ___
[ ] Remaining flags: ___
[ ] Next cleanup scheduled: ___
```

## Counter-Rationalizations

| Shortcut | Counter | Why |
|----------|---------|-----|
| "We can skip some steps for this case" | Adapt the workflow steps, don't skip them | Skipped steps are where incidents and oversights originate |
| "The user seems to already know what to do" | Complete all workflow phases with the user | The workflow catches blind spots that experience alone misses |
| "This is a minor case, full process is overkill" | Scale the process down, don't turn it off | Minor cases become major when unstructured; the process scales, not disappears |
| "I'll fill in the details later" | Complete each section before moving on | Deferred details are forgotten; real-time capture is more accurate |
| "The template output isn't necessary" | Always produce the structured output format | Structured output enables comparison, audit trails, and handoff to other teams |

## Output Format

Produce a feature flag cleanup report with:
1. **Inventory summary** (total flags, stale count, categorization)
2. **Flags removed** (list with justification for each)
3. **Flags retained** (list with justification for keeping)
4. **Code changes** (files modified, lines removed)
5. **Recommendations** (process improvements, cleanup cadence)
