---
name: incident-response-runbook
enabled: true
description: |
  Structured incident response workflow that guides through detection, triage, investigation, mitigation, and resolution. Integrates with PagerDuty, Slack, Jira, or Confluence to coordinate response. Use when a production incident is declared or when validating incident response readiness.
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

# Incident Response Runbook Skill

Execute a structured incident response for: **{{ incident_title }}**
Severity: **{{ severity }}** | Service: **{{ affected_service }}**

## Workflow

### Phase 1 — DETECT & DECLARE (0-5 minutes)

**Immediately upon detection:**

1. **Confirm the incident is real** — not a monitoring false positive
   - Check monitoring dashboard for corroborating signals
   - Verify user impact exists (not just synthetic test failure)
   - Check if other team members are already aware

2. **Declare the incident**
   - Assign Incident Commander (IC) — the single decision-maker
   - Open incident channel: `{{ incident_channel }}`
   - Post initial broadcast to Slack:

   ```
   🚨 INCIDENT DECLARED — {{ severity }}
   Title: {{ incident_title }}
   Affected: {{ affected_service }}
   IC: [your name]
   Bridge: {{ incident_channel }}
   Status: INVESTIGATING
   ```

3. **Page on-call if not already paged**
   - Verify PagerDuty incident is open for the affected service
   - Escalate to secondary if primary does not acknowledge within 5 min (SEV1) / 15 min (SEV2)

### Phase 2 — TRIAGE (5-15 minutes)

**Determine blast radius — answer these questions:**

```
TRIAGE QUESTIONS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
1. WHAT is broken?
   - Which service(s) / endpoints are affected?
   - Error type: 5xx / timeout / data loss / security / availability?

2. WHO is impacted?
   - % of users affected (0-100%)?
   - Which customer segments / regions?
   - Internal only or customer-facing?

3. HOW LONG?
   - When did this start (approximate)?
   - Is it ongoing or intermittent?

4. WHAT CHANGED?
   - Recent deployments in last 2 hours?
   - Infrastructure changes?
   - Traffic pattern changes?
   - Third-party service degradations?

5. CAN WE MITIGATE NOW?
   - Is there an immediate kill switch / feature flag?
   - Can we roll back?
   - Can we route traffic away from affected instances?
```

**Severity Matrix (adjust if needed):**
| Severity | User Impact | Revenue Impact | Response Time |
|----------|-------------|----------------|---------------|
| SEV1 | >25% users, checkout broken | High | Immediate, all-hands |
| SEV2 | 5-25% users, degraded | Medium | Within 15 min |
| SEV3 | <5% users, minor degradation | Low | Within 1 hour |
| SEV4 | No user impact, monitoring/infra | None | Business hours |

### Phase 3 — INVESTIGATE (15-60 minutes)

**Systematic investigation using available connections:**

1. **Check dashboards** — error rate, latency, throughput (Grafana, Datadog, New Relic, CloudWatch)
2. **Check logs** — look for first error occurrence and error patterns (Elasticsearch, CloudWatch Logs)
3. **Check recent changes** — deployment history, infrastructure changes, config changes
4. **Check dependencies** — database health, cache health, external API status pages
5. **Check capacity** — CPU, memory, disk, connection pool exhaustion

**Investigation Timeline Log** (IC maintains this):
```
[HH:MM] SIGNAL: [what was observed]
[HH:MM] ACTION: [what was tried]
[HH:MM] RESULT: [what happened]
[HH:MM] HYPOTHESIS: [current best guess]
```

**Status Updates** (post to {{ incident_channel }} every 15 minutes):
```
⏱ STATUS UPDATE — {{ severity }}
Time elapsed: [X] minutes
Current status: INVESTIGATING / MITIGATING / MONITORING
Current hypothesis: [one sentence]
Next action: [what is being tried]
ETA to resolution: [estimate or "unknown"]
```

### Phase 4 — MITIGATE (variable)

**Apply mitigation in order of risk (lowest risk first):**

Priority order for mitigation:
1. **Kill switch / feature flag** — toggle off broken feature (safest, reversible)
2. **Traffic routing** — shift load to healthy region/instance
3. **Rollback deployment** — revert to last known good version
4. **Scale up** — add capacity if resource exhaustion is root cause
5. **Infrastructure fix** — restart service, clear cache, release locks
6. **Hotfix** — deploy targeted code fix (highest risk, takes longest)

**Mitigation Decision:**
```
MITIGATION SELECTED: [describe action]
Reason: [why this was chosen over alternatives]
Risk: [what could go wrong]
Rollback of mitigation: [how to undo if it makes things worse]
Approval: IC approved at [HH:MM]
```

### Phase 5 — RESOLVE

**Incident is resolved when:**
- Error rate back to baseline (< 1% or pre-incident level)
- Latency back to baseline
- All services reporting healthy
- No customer complaints still coming in

**Resolution announcement:**
```
✅ INCIDENT RESOLVED — {{ severity }}
Title: {{ incident_title }}
Duration: [X hours Y minutes]
Root Cause (preliminary): [one sentence]
Resolution: [what fixed it]
Next Steps: Post-mortem scheduled for [date]
```

**Post-resolution actions:**
- [ ] Update status page (if applicable)
- [ ] Notify customer success team
- [ ] Create post-mortem issue in Jira/Linear
- [ ] Schedule post-mortem meeting (within 48h for SEV1/SEV2)
- [ ] Close PagerDuty incident

### Phase 6 — POST-MORTEM

**Post-mortem document structure** (create within 48 hours for SEV1/SEV2):

```
INCIDENT POST-MORTEM
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Title: {{ incident_title }}
Date: [incident date]
Duration: [total duration]
Severity: {{ severity }}
Author(s): [list]

IMPACT
- Users affected: [number/percentage]
- Features degraded: [list]
- Revenue impact: [estimate if known]

TIMELINE
[chronological list of key events]

ROOT CAUSE
[technical root cause — be specific, avoid blame]

CONTRIBUTING FACTORS
[systemic issues that made this possible]

WHAT WENT WELL
[things that worked during response]

WHAT COULD BE IMPROVED
[things that slowed response or made impact worse]

ACTION ITEMS
| Action | Owner | Due Date | Priority |
|--------|-------|----------|----------|
| [action] | [name] | [date] | P1/P2/P3 |
```

## Output Format

Produce a real-time incident log with:
1. **Incident header** (title, severity, IC, start time)
2. **Triage answers** based on gathered information
3. **Investigation findings** from connected tools
4. **Mitigation decision** with reasoning
5. **Resolution announcement** (once resolved)
6. **Post-mortem draft** (on request)
