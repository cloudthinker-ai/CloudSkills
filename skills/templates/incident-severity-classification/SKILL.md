---
name: incident-severity-classification
enabled: true
description: |
  Use when performing incident severity classification — guide for classifying
  incident severity from SEV1 through SEV4 using a structured impact matrix that
  considers user impact, revenue impact, data integrity, and blast radius.
  Provides clear criteria for each severity level, escalation triggers, and
  response time expectations to ensure consistent severity assignment across
  teams.
required_connections:
  - prefix: slack
    label: "Slack (for severity announcements)"
config_fields:
  - key: incident_title
    label: "Incident Title"
    required: true
    placeholder: "e.g., Checkout page returning 500 errors"
  - key: affected_users
    label: "Estimated Affected Users"
    required: false
    placeholder: "e.g., 50%, all users, internal only"
  - key: revenue_impact
    label: "Revenue Impact"
    required: false
    placeholder: "e.g., $10K/hour, no direct revenue impact"
features:
  - INCIDENT
---

# Incident Severity Classification Skill

Classify the severity of: **{{ incident_title }}**
Affected users: **{{ affected_users }}** | Revenue impact: **{{ revenue_impact }}**

## Severity Matrix

### SEV1 — Critical
**Response time: Immediate (< 5 minutes)**
- Complete service outage affecting all or majority of users
- Data loss or data corruption confirmed
- Security breach with active exploitation
- Revenue-generating system fully unavailable
- SLA breach imminent or occurring

**Actions required:**
- Page incident commander immediately
- Open dedicated incident bridge
- Notify executive stakeholders within 15 minutes
- Post to status page within 20 minutes
- All-hands-on-deck until mitigated

### SEV2 — High
**Response time: < 15 minutes**
- Major feature unavailable but service partially functional
- Significant performance degradation (> 5x normal latency)
- Affecting a large subset of users (> 25%)
- Workaround may exist but is not sustainable
- Secondary system failure with potential to cascade

**Actions required:**
- Page on-call engineer and team lead
- Open incident channel in Slack
- Notify stakeholders within 30 minutes
- Post to status page if customer-facing
- Continuous updates every 30 minutes

### SEV3 — Medium
**Response time: < 1 hour**
- Minor feature degradation with workaround available
- Affecting a small subset of users (< 25%)
- Non-revenue-impacting service degradation
- Elevated error rates but within tolerance
- Single redundancy failure (backup still operational)

**Actions required:**
- Notify on-call engineer via standard alerting
- Create incident ticket
- Updates every 2 hours during business hours
- Fix within current or next business day

### SEV4 — Low
**Response time: < 4 hours (business hours)**
- Cosmetic issues or minor bugs
- Affecting internal tools only
- No user-facing impact
- Monitoring alert for trending metric (not yet impacting)
- Documentation or configuration inconsistency

**Actions required:**
- Create ticket in backlog
- Address in next sprint or maintenance window
- No status page update needed

## Impact Assessment Checklist

Evaluate each dimension to determine severity:

| Dimension | SEV1 | SEV2 | SEV3 | SEV4 |
|-----------|------|------|------|------|
| **User Impact** | All users blocked | Many users affected | Some users affected | Minimal/none |
| **Revenue** | Direct revenue loss | Indirect revenue risk | Potential future impact | No impact |
| **Data** | Loss or corruption | Inconsistency risk | Minor data delay | None |
| **Blast Radius** | Multiple services | Single critical service | Single non-critical | Isolated component |
| **Workaround** | None available | Difficult/unsustainable | Easy workaround | Not needed |

## Classification Decision Flow

1. **Is there confirmed data loss or security breach?** → SEV1
2. **Is the primary revenue path blocked for all users?** → SEV1
3. **Is a major feature unavailable or severely degraded?** → SEV2
4. **Is a significant user population affected (>25%)?** → SEV2
5. **Is there a workaround and limited user impact?** → SEV3
6. **Is the impact internal-only or cosmetic?** → SEV4

## Escalation Triggers (Upgrade Severity)

- Incident duration exceeds expected MTTR for current severity
- Blast radius expands to additional services
- Customer complaints increase significantly
- Workaround stops working
- Root cause indicates deeper systemic issue

## De-escalation Criteria (Downgrade Severity)

- Effective workaround deployed and confirmed
- Blast radius contained
- User impact significantly reduced
- Root cause identified and fix in progress

## Counter-Rationalizations

| Shortcut | Counter | Why |
|----------|---------|-----|
| "We can skip some steps for this case" | Adapt the workflow steps, don't skip them | Skipped steps are where incidents and oversights originate |
| "The user seems to already know what to do" | Complete all workflow phases with the user | The workflow catches blind spots that experience alone misses |
| "This is a minor case, full process is overkill" | Scale the process down, don't turn it off | Minor cases become major when unstructured; the process scales, not disappears |
| "I'll fill in the details later" | Complete each section before moving on | Deferred details are forgotten; real-time capture is more accurate |
| "The template output isn't necessary" | Always produce the structured output format | Structured output enables comparison, audit trails, and handoff to other teams |

