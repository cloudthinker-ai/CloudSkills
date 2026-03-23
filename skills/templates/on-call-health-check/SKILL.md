---
name: on-call-health-check
enabled: true
description: |
  Use when performing on call health check — on-call health assessment covering
  page volume analysis, MTTA/MTTR measurement, toil identification, alert
  quality review, burnout indicators, and improvement recommendations. Use for
  quarterly on-call reviews or team health retrospectives.
required_connections:
  - prefix: pagerduty
    label: "PagerDuty (or alerting platform)"
config_fields:
  - key: team_name
    label: "Team Name"
    required: true
    placeholder: "e.g., platform-team"
  - key: review_period
    label: "Review Period"
    required: true
    placeholder: "e.g., 2026-Q1, last 30 days"
  - key: rotation_size
    label: "On-Call Rotation Size"
    required: false
    placeholder: "e.g., 5 engineers"
features:
  - SRE
  - INCIDENT
---

# On-Call Health Check Skill

Assess on-call health for **{{ team_name }}** during **{{ review_period }}**.

## Workflow

### Step 1 — Page Volume Analysis

```
PAGE VOLUME METRICS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Period: {{ review_period }}
Team: {{ team_name }}
Rotation size: {{ rotation_size | "unknown" }}

VOLUME
  Total pages: ___
  Pages per week (avg): ___
  Pages per on-call shift: ___
  After-hours pages: ___ (___% of total)
  Weekend pages: ___ (___% of total)

DISTRIBUTION
  Pages by severity:
    SEV1 (critical): ___
    SEV2 (major): ___
    SEV3 (minor): ___
    SEV4 (info): ___

  Pages by time of day:
    Business hours (9am-6pm): ___%
    Evening (6pm-midnight): ___%
    Night (midnight-9am): ___%

TARGETS:
  [ ] < 2 pages per on-call shift (good)
  [ ] < 5 pages per on-call shift (acceptable)
  [ ] > 5 pages per on-call shift (NEEDS ATTENTION)
```

### Step 2 — Response Time Analysis

```
MTTA / MTTR
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
MTTA (Mean Time to Acknowledge):
  Overall: ___ minutes
  Business hours: ___ minutes
  After hours: ___ minutes
  Target: < 5 min (SEV1), < 15 min (SEV2)
  Status: MEETING TARGET / BELOW TARGET

MTTR (Mean Time to Resolve):
  Overall: ___ minutes
  SEV1: ___ minutes (target: < 60 min)
  SEV2: ___ minutes (target: < 4 hours)
  SEV3: ___ minutes (target: < 24 hours)
  Status: MEETING TARGET / BELOW TARGET

ESCALATION RATE:
  Pages escalated to secondary: ___ (___%)
  Pages escalated to management: ___ (___%)
  Pages requiring cross-team help: ___ (___%)
```

### Step 3 — Alert Quality Review

```
ALERT QUALITY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SIGNAL vs NOISE
  Actionable pages (required human intervention): ___ (___%)
  Non-actionable pages (auto-resolved, flapping, duplicate): ___ (___%)
  False positives: ___ (___%)

  Target: > 80% actionable rate
  Status: HEALTHY / NEEDS IMPROVEMENT

TOP NOISY ALERTS (fix these first):
| Alert Name | Count | Actionable? | Recommendation |
|------------|-------|-------------|----------------|
| [alert] | ___ | YES/NO | [tune/remove/automate] |
| [alert] | ___ | YES/NO | [tune/remove/automate] |
| [alert] | ___ | YES/NO | [tune/remove/automate] |
| [alert] | ___ | YES/NO | [tune/remove/automate] |
| [alert] | ___ | YES/NO | [tune/remove/automate] |

FLAPPING ALERTS (fired and resolved repeatedly):
| Alert Name | Flap Count | Root Cause | Fix |
|------------|-----------|------------|-----|
| [alert] | ___ | [cause] | [fix] |
```

### Step 4 — Toil Measurement

```
TOIL ASSESSMENT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Toil = manual, repetitive, automatable, reactive, no lasting value

COMMON TOIL TASKS:
| Task | Frequency | Time/Occurrence | Automatable? | Priority |
|------|-----------|----------------|-------------|----------|
| [task] | ___/week | ___ min | YES/NO | P1/P2/P3 |
| [task] | ___/week | ___ min | YES/NO | P1/P2/P3 |
| [task] | ___/week | ___ min | YES/NO | P1/P2/P3 |

Total toil hours per on-call shift: ___ hours
Toil as % of on-call time: ___%

Target: < 30% of on-call time spent on toil
Status: HEALTHY / NEEDS IMPROVEMENT
```

### Step 5 — Burnout Indicators

```
BURNOUT ASSESSMENT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Sleep interruptions per shift: ___ (target: < 1)
[ ] Consecutive nights with pages: ___ (target: 0)
[ ] On-call shift length: ___ days (recommended: 7 days max)
[ ] Time between on-call shifts: ___ weeks (recommended: ≥ 4 weeks)
[ ] Compensation / time-off for on-call: YES / NO
[ ] On-call handoff process: FORMAL / INFORMAL / NONE
[ ] Post-shift decompression time: YES / NO

TEAM SURVEY (anonymous):
  "I feel well-supported during on-call": ___/5
  "On-call does not impact my work-life balance": ___/5
  "I have the tools and runbooks to handle pages": ___/5
  "I would recommend on-call at this team": ___/5

BURNOUT RISK: LOW / MEDIUM / HIGH
```

### Step 6 — Improvement Plan

```
IMPROVEMENTS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
QUICK WINS (this sprint):
[ ] Tune or suppress top 3 noisy alerts
[ ] Update stale runbooks
[ ] Fix flapping alerts

MEDIUM-TERM (this quarter):
[ ] Automate top toil tasks
[ ] Implement SLO-based alerting to reduce page volume
[ ] Add self-healing for common failure modes
[ ] Improve monitoring coverage gaps

LONG-TERM (next quarter):
[ ] Reduce on-call burden to < 2 pages/shift
[ ] Achieve > 90% actionable alert rate
[ ] Reduce toil to < 20% of on-call time
[ ] Grow rotation to reduce frequency
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

Produce an on-call health report with:
1. **Page volume analysis** with trends and distribution
2. **MTTA/MTTR metrics** vs targets
3. **Alert quality** assessment with top noisy alerts
4. **Toil measurement** with automation opportunities
5. **Burnout risk** assessment
6. **Improvement plan** with prioritized actions
