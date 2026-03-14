---
name: sla-breach-escalation
enabled: true
description: |
  SLA breach detection and escalation procedure covering proactive SLA monitoring, breach notification workflows, escalation matrices, and remediation tracking. Ensures SLA breaches are identified early, stakeholders are notified promptly, and corrective actions are documented to prevent recurrence.
required_connections:
  - prefix: itsm
    label: "ITSM Tool (ServiceNow, Freshservice, etc.)"
config_fields:
  - key: ticket_id
    label: "Ticket / Incident ID"
    required: true
    placeholder: "e.g., INC-2026-0042, TICKET-5678"
  - key: sla_type
    label: "SLA Type"
    required: true
    placeholder: "e.g., First Response, Resolution, Update Frequency"
  - key: sla_target
    label: "SLA Target"
    required: true
    placeholder: "e.g., 1 hour, 4 hours, 24 hours"
  - key: current_elapsed
    label: "Current Elapsed Time"
    required: true
    placeholder: "e.g., 2 hours, 6 hours"
  - key: priority
    label: "Ticket Priority"
    required: false
    placeholder: "e.g., P1-Critical, P2-High, P3-Medium"
features:
  - HELPDESK
---

# SLA Breach Escalation Procedure

Ticket: **{{ ticket_id }}** | Priority: {{ priority }}
SLA Type: **{{ sla_type }}** | Target: {{ sla_target }} | Elapsed: {{ current_elapsed }}

## SLA Status Assessment

```
SLA STATUS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Ticket:       {{ ticket_id }}
Priority:     {{ priority }}
SLA Type:     {{ sla_type }}
SLA Target:   {{ sla_target }}
Time Elapsed: {{ current_elapsed }}
Status:       [ ] On Track / [ ] At Risk (>75%) / [ ] BREACHED
```

## Escalation Matrix

| Priority | SLA Target | Warning (75%) | Breach | Escalate To |
|----------|-----------|---------------|--------|-------------|
| P1-Critical | 1 hour | 45 min | 1 hour | Team Lead + Manager + Director |
| P2-High | 4 hours | 3 hours | 4 hours | Team Lead + Manager |
| P3-Medium | 8 hours | 6 hours | 8 hours | Team Lead |
| P4-Low | 24 hours | 18 hours | 24 hours | Team Lead (next business day) |

## Escalation Workflow

### Level 1 — Warning (SLA at 75%)
- [ ] Auto-alert assigned agent that SLA is at risk
- [ ] Agent reviews and updates ticket with current status
- [ ] If agent is unavailable: auto-reassign to available team member
- [ ] Notify team lead of at-risk ticket

### Level 2 — SLA Breached
- [ ] Immediate notification to:
  - Assigned agent
  - Team lead
  - Support manager (for P1/P2)
- [ ] Document breach in ticket:
  ```
  SLA BREACH NOTIFICATION
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Ticket: {{ ticket_id }}
  SLA Breached: {{ sla_type }}
  Target: {{ sla_target }}
  Actual: {{ current_elapsed }}
  Reason: [document why breach occurred]
  Corrective Action: [immediate steps being taken]
  ```
- [ ] Reassign to senior agent or specialist if needed
- [ ] Prioritize above non-breached tickets

### Level 3 — Extended Breach (2x SLA target)
- [ ] Escalate to department manager
- [ ] Notify customer/requester with status update and new ETA
- [ ] Convene mini-incident review if P1/P2
- [ ] Assign dedicated resource to resolution

### Level 4 — Critical Breach (3x+ SLA target)
- [ ] Escalate to director/VP level
- [ ] Formal customer communication required
- [ ] Post-breach review mandatory
- [ ] Capture for SLA compliance reporting

## Root Cause Analysis for Breach

When documenting the breach, identify which factor contributed:

- [ ] **Staffing**: Insufficient agents available
- [ ] **Skills**: Required expertise not available in team
- [ ] **Assignment**: Ticket routed to wrong group/agent
- [ ] **Prioritization**: Ticket incorrectly prioritized
- [ ] **Complexity**: Issue more complex than SLA tier allows
- [ ] **External dependency**: Waiting on vendor, other team, or customer
- [ ] **Tool/Process**: ITSM workflow or automation failure

## Preventive Actions

- [ ] Review and adjust SLA targets if consistently breached
- [ ] Implement automated SLA warning alerts at 50% and 75%
- [ ] Review ticket routing rules for accuracy
- [ ] Cross-train agents on common escalation topics
- [ ] Schedule periodic SLA compliance reviews (weekly/monthly)

## Output Format

Generate an escalation report with:
1. **Breach summary** (ticket, SLA type, target vs actual)
2. **Escalation actions taken** with timestamps
3. **Root cause** of breach
4. **Resolution** and time to resolve after escalation
5. **Preventive recommendations**
