---
name: incident-response-runbook
enabled: true
description: |
  Use when a production incident is declared, when investigating service degradation,
  or when validating incident response readiness. Structured workflow covering detection,
  triage, investigation, mitigation, resolution, and post-mortem. Integrates with
  PagerDuty, Slack, Jira, and Confluence for coordinated response.
required_connections:
  - prefix: slack
    label: "Slack (for incident bridge)"
config_fields:
  - key: incident_title
    label: "Incident Title"
    required: true
    placeholder: "e.g., Payment service returning 500 errors"
  - key: severity
    label: "Severity (SEV1 / SEV2 / SEV3)"
    required: true
    placeholder: "e.g., SEV2"
  - key: incident_channel
    label: "Slack Incident Channel"
    required: false
    placeholder: "e.g., #inc-2024-01-15-payment"
  - key: affected_service
    label: "Affected Service(s)"
    required: false
    placeholder: "e.g., payment-api, checkout-service"
features:
  - RCA
  - INCIDENT
---

# Incident Response Runbook

Execute structured incident response for: **{{ incident_title }}**
Severity: **{{ severity }}** | Service: **{{ affected_service }}**

## Severity Decision Matrix

| Signal | SEV1 | SEV2 | SEV3 | SEV4 |
|--------|------|------|------|------|
| User impact | >25% users | 5-25% users | <5% users | None |
| Revenue impact | High / checkout broken | Medium / degraded | Low / workaround exists | None |
| Data integrity | At risk | Not at risk | Not at risk | Not at risk |
| Response | All-hands, immediate | Team, within 15 min | Individual, within 1h | Business hours |
| Post-mortem | Required within 48h | Required within 48h | Brief review within 1 week | Ticket only |

[Severity-specific playbooks with escalation matrices](./references/severity-playbooks.md)

## Workflow

### Phase 1 — DETECT & DECLARE (0-5 min)

1. **Confirm incident is real** — not a monitoring false positive
   - Check dashboard for corroborating signals
   - Verify user impact exists (not just synthetic test failure)

2. **Declare the incident**
   - Assign Incident Commander (IC) — single decision-maker
   - Open incident channel: `{{ incident_channel }}`
   - Post initial broadcast:

   ```
   INCIDENT DECLARED — {{ severity }}
   Title: {{ incident_title }}
   Affected: {{ affected_service }}
   IC: [your name]
   Bridge: {{ incident_channel }}
   Status: INVESTIGATING
   ```

3. **Page on-call** if not already paged
   - Escalate to secondary if primary does not ACK within 5 min (SEV1) / 15 min (SEV2)

### Phase 2 — TRIAGE (5-15 min)

Answer ALL five triage questions — do not skip any:

| # | Question | What to check |
|---|----------|--------------|
| 1 | **WHAT** is broken? | Services, endpoints, error type (5xx/timeout/data loss) |
| 2 | **WHO** is impacted? | % users, segments, regions, internal vs customer-facing |
| 3 | **HOW LONG?** | Start time, ongoing vs intermittent |
| 4 | **WHAT CHANGED?** | Deployments (last 2h), infra changes, traffic patterns, third-party status |
| 5 | **CAN WE MITIGATE NOW?** | Kill switch, feature flag, rollback, traffic reroute |

### Phase 3 — INVESTIGATE (15-60 min)

Systematic investigation order:
1. **Dashboards** — error rate, latency, throughput
2. **Logs** — first error occurrence, error patterns
3. **Recent changes** — deployment history, config changes
4. **Dependencies** — database, cache, external API status
5. **Capacity** — CPU, memory, disk, connection pool

**Investigation log** (IC maintains):
```
[HH:MM] SIGNAL: [what was observed]
[HH:MM] ACTION: [what was tried]
[HH:MM] RESULT: [what happened]
[HH:MM] HYPOTHESIS: [current best guess]
[HH:MM] REJECTED: [why hypothesis was wrong] ← capture failed hypotheses too
```

**Status updates** (every 15 min to `{{ incident_channel }}`):
```
STATUS UPDATE — {{ severity }}
Elapsed: [X] minutes
Status: INVESTIGATING / MITIGATING / MONITORING
Hypothesis: [one sentence]
Next action: [what is being tried]
ETA: [estimate or "unknown"]
```

### Phase 4 — MITIGATE (variable)

Apply mitigation in **risk-priority order** (lowest risk first):

| Priority | Action | Risk | Reversibility |
|----------|--------|------|---------------|
| 1 | Kill switch / feature flag | Lowest | Instant |
| 2 | Traffic routing to healthy region | Low | Fast |
| 3 | Rollback deployment | Medium | Minutes |
| 4 | Scale up capacity | Medium | Minutes |
| 5 | Infrastructure fix (restart, clear cache) | Medium | Variable |
| 6 | Hotfix deployment | Highest | Slow |

**Document the decision:**
```
MITIGATION: [action]
Reason: [why chosen over alternatives]
Risk: [what could go wrong]
Rollback plan: [how to undo if it makes things worse]
Approved by IC at [HH:MM]
```

### Phase 5 — RESOLVE

**Incident is resolved when ALL conditions met:**
- Error rate back to baseline (<1% or pre-incident level)
- Latency back to baseline
- All services reporting healthy
- No new customer complaints

**Resolution announcement:**
```
INCIDENT RESOLVED — {{ severity }}
Title: {{ incident_title }}
Duration: [X hours Y minutes]
Root Cause: [one sentence]
Resolution: [what fixed it]
Post-mortem: Scheduled for [date]
```

**Post-resolution checklist:**
- [ ] Update status page
- [ ] Notify customer success team
- [ ] Create post-mortem ticket (Jira/Linear)
- [ ] Schedule post-mortem meeting (within 48h for SEV1/SEV2)
- [ ] Close PagerDuty incident

### Phase 6 — POST-MORTEM

Create within 48h for SEV1/SEV2. Structure:

```
INCIDENT POST-MORTEM
Title: {{ incident_title }}
Date: [date] | Duration: [total] | Severity: {{ severity }}

IMPACT: [users affected, features degraded, revenue impact]
TIMELINE: [chronological key events]
ROOT CAUSE: [technical cause — be specific, avoid blame]
CONTRIBUTING FACTORS: [systemic issues]
WHAT WENT WELL: [things that worked]
WHAT TO IMPROVE: [things that slowed response]

ACTION ITEMS:
| Action | Owner | Due Date | Priority |
|--------|-------|----------|----------|
```

## Counter-Rationalizations

| Shortcut | Counter | Why |
|----------|---------|-----|
| "Skip triage, we know what's wrong" | Complete all 5 triage questions | Triage reveals blast radius — you can't mitigate what you haven't measured |
| "Just restart the service" | Investigate before restarting | Restart masks root cause, may cause data loss, and delays actual fix |
| "We don't need an IC" | Always assign an IC | Without single decision-maker, conflicting actions extend the incident |
| "Post-mortem can wait" | Schedule within 48h | Details fade quickly; action items lose urgency after a week |
| "This is only SEV3, skip the process" | Adapt the process, don't skip it | SEV3s become SEV1s when unmanaged — the process scales down, not off |
| "I'll check metrics later" | Check dashboards first in investigation | Silent failures are invisible without metrics; logs alone miss the big picture |
| "The fix is obvious, skip investigation" | Document hypothesis before applying fix | "Obvious" fixes that are wrong make the incident worse and longer |

## Output Format

Produce a real-time incident log:
1. **Header** — title, severity, IC, start time
2. **Triage answers** — all 5 questions answered
3. **Investigation findings** — signals, hypotheses, evidence
4. **Mitigation decision** — action, reasoning, rollback plan
5. **Resolution** — what fixed it, duration, next steps
6. **Post-mortem draft** — on request

## References

- [Severity Playbooks — Escalation Matrices & Investigation Runbooks](./references/severity-playbooks.md)
