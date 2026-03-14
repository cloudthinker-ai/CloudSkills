---
name: cloud-billing-alert-setup
enabled: true
description: |
  Configures comprehensive billing alerts and budget notifications across cloud accounts. Covers budget threshold alerts, anomaly detection, per-service spending limits, team-level notifications, and escalation procedures to prevent unexpected cloud costs.
required_connections:
  - prefix: cloud-billing
    label: "Cloud Billing Account"
  - prefix: notification
    label: "Notification Channel (Slack, Email, PagerDuty)"
config_fields:
  - key: cloud_provider
    label: "Cloud Provider"
    required: true
    placeholder: "e.g., AWS, GCP, Azure"
  - key: monthly_budget
    label: "Monthly Budget Target"
    required: true
    placeholder: "e.g., $50,000"
  - key: notification_channel
    label: "Primary Notification Channel"
    required: true
    placeholder: "e.g., #cloud-costs Slack channel, finance@company.com"
features:
  - COST_MANAGEMENT
  - FINOPS
  - ALERTING
---

# Cloud Billing Alert Setup

## Phase 1: Budget Structure Design
1. Define budget hierarchy
   - [ ] Organization-level total budget
   - [ ] Per-account/project budgets
   - [ ] Per-team budgets (using tags/labels)
   - [ ] Per-environment budgets (prod, staging, dev)
   - [ ] Per-service budgets for high-spend services
2. Set budget periods (monthly, quarterly, annual)
3. Determine fixed vs. auto-adjusting budgets

### Budget Allocation Table

| Budget Scope | Owner | Monthly Amount | Alert Recipients | Escalation Contact |
|-------------|-------|---------------|-----------------|-------------------|
| Organization total | | $ | | |
| Production | | $ | | |
| Development | | $ | | |
| Team: | | $ | | |

## Phase 2: Alert Threshold Configuration
1. Configure progressive alert thresholds
   - [ ] 50% of budget - Informational notification
   - [ ] 75% of budget - Warning to team leads
   - [ ] 90% of budget - Alert to managers and finance
   - [ ] 100% of budget - Escalation to leadership
   - [ ] 120% of budget - Emergency alert with action required
2. Set up forecasted spend alerts (projected to exceed budget)
3. Configure actual spend alerts (already exceeded threshold)

### Alert Configuration Matrix

| Threshold | Type | Recipients | Channel | Action Required |
|-----------|------|-----------|---------|-----------------|
| 50% | Actual | Team | Slack | Awareness only |
| 75% | Actual | Team + Lead | Slack + Email | Review spending |
| 90% | Forecasted | Lead + Manager | Email | Reduce spend plan |
| 100% | Actual | Manager + Finance | Email + PagerDuty | Immediate review |
| 120% | Actual | Leadership | Phone + Email | Emergency response |

## Phase 3: Anomaly Detection
1. Enable cloud-native anomaly detection
2. Set up daily spend comparison (vs. 7-day average)
3. Configure per-service anomaly alerts
4. Define anomaly sensitivity thresholds
5. Set up automatic investigation triggers

## Phase 4: Notification Channel Setup
1. Configure Slack/Teams integration for real-time alerts
2. Set up email distribution lists for budget reports
3. Configure PagerDuty/Opsgenie for critical overspend
4. Create weekly automated cost summary reports
5. Set up dashboard access for self-service monitoring

## Phase 5: Response Procedures
1. Document response procedures per alert level
2. Define who can approve budget increases
3. Create runbook for emergency cost reduction
4. Establish weekly cost review meeting cadence
5. Assign cost optimization owners per team

### Escalation Matrix

| Alert Level | Response Time | Responder | Authority | Actions |
|------------|--------------|-----------|-----------|---------|
| Informational | Next business day | Team | None needed | Monitor |
| Warning | 4 hours | Team lead | Investigate | Review resources |
| Critical | 1 hour | Manager | Approve changes | Stop non-essential |
| Emergency | 30 minutes | Director | Budget increase | Scale down immediately |

## Output Format
- **Budget Configuration**: All budgets with amounts and owners
- **Alert Rules**: Complete alert configuration per threshold
- **Notification Setup**: Channel configuration and routing
- **Response Runbook**: Actions per alert level with contacts
- **Weekly Report Template**: Automated cost summary format

## Action Items
- [ ] Define budget structure and amounts with finance
- [ ] Configure all budget alerts in cloud console
- [ ] Set up notification channel integrations
- [ ] Test alerts with simulated threshold breaches
- [ ] Document and distribute response procedures
- [ ] Schedule recurring cost review meetings
