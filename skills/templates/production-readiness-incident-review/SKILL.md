---
name: production-readiness-incident-review
enabled: true
description: |
  Production readiness validation focused on incident response preparedness before launching a new service or major feature. Reviews on-call coverage, runbook completeness, monitoring and alerting setup, escalation paths, rollback procedures, and communication plans to ensure the team can effectively respond to incidents.
required_connections:
  - prefix: slack
    label: "Slack (for review coordination)"
config_fields:
  - key: service_name
    label: "Service/Feature Name"
    required: true
    placeholder: "e.g., new-checkout-api"
  - key: launch_date
    label: "Planned Launch Date"
    required: true
    placeholder: "e.g., 2024-03-01"
  - key: service_owner
    label: "Service Owner / Team"
    required: false
    placeholder: "e.g., Payments Team"
features:
  - INCIDENT
---

# Production Readiness — Incident Response Review

Service: **{{ service_name }}** | Owner: **{{ service_owner }}**
Launch Date: **{{ launch_date }}**

## Purpose

This review validates that the team is prepared to detect, respond to, and resolve incidents for **{{ service_name }}** before it goes to production.

## 1. On-Call Coverage

| Requirement | Status | Notes |
|-------------|--------|-------|
| On-call rotation configured | _yes/no_ | _tool and schedule name_ |
| Minimum 2 engineers per rotation | _yes/no_ | — |
| On-call engineers trained on the service | _yes/no_ | — |
| Escalation policy defined | _yes/no_ | _policy name_ |
| Secondary/management escalation path | _yes/no_ | — |
| After-hours coverage confirmed | _yes/no_ | — |

## 2. Monitoring and Alerting

| Requirement | Status | Notes |
|-------------|--------|-------|
| Health check endpoint exists | _yes/no_ | _endpoint URL_ |
| Key SLIs defined (latency, error rate, throughput) | _yes/no_ | _list SLIs_ |
| SLO targets documented | _yes/no_ | _e.g., 99.9% availability_ |
| Alert rules configured for SLO breaches | _yes/no_ | — |
| Dashboards created for key metrics | _yes/no_ | _dashboard link_ |
| Log aggregation configured | _yes/no_ | _tool name_ |
| Distributed tracing enabled | _yes/no_ | _tool name_ |
| Synthetic monitoring / uptime checks | _yes/no_ | — |
| Alert routing to correct on-call team | _yes/no_ | — |
| Alert thresholds tested (not too noisy, not too quiet) | _yes/no_ | — |

## 3. Runbooks

| Requirement | Status | Notes |
|-------------|--------|-------|
| Service overview runbook exists | _yes/no_ | _link_ |
| Common failure mode runbooks | _yes/no_ | _list covered scenarios_ |
| Dependency failure runbook | _yes/no_ | — |
| Scaling runbook (manual and auto) | _yes/no_ | — |
| Data recovery runbook | _yes/no_ | — |
| Runbooks link to dashboards and log queries | _yes/no_ | — |
| Runbooks reviewed by on-call engineers | _yes/no_ | — |

## 4. Rollback and Recovery

| Requirement | Status | Notes |
|-------------|--------|-------|
| Rollback procedure documented | _yes/no_ | — |
| Rollback tested in staging | _yes/no_ | _date tested_ |
| Rollback can be executed in < 15 minutes | _yes/no_ | — |
| Database migration rollback plan | _yes/no_ | — |
| Feature flags for gradual rollout | _yes/no_ | _flag names_ |
| Blue/green or canary deployment capability | _yes/no_ | — |
| Backup and restore tested | _yes/no_ | _date tested_ |

## 5. Communication Plan

| Requirement | Status | Notes |
|-------------|--------|-------|
| Incident channel naming convention agreed | _yes/no_ | — |
| Status page component created | _yes/no_ | _component name_ |
| Customer communication templates ready | _yes/no_ | — |
| Support team briefed on new service | _yes/no_ | — |
| Stakeholder notification list defined | _yes/no_ | — |

## 6. Dependencies

| Dependency | Owner | Failure Mode | Mitigation | Documented |
|------------|-------|-------------|------------|------------|
| _service/DB/API_ | _team_ | _timeout/unavailable_ | _circuit breaker/cache/fallback_ | _yes/no_ |

## 7. Game Day / Drill Readiness

| Requirement | Status | Notes |
|-------------|--------|-------|
| Failure injection drill planned | _yes/no_ | _scheduled date_ |
| Team has practiced incident response | _yes/no_ | — |
| Tabletop exercise completed | _yes/no_ | _date_ |

## Review Verdict

| Verdict | Criteria |
|---------|----------|
| **APPROVED** | All critical items pass, no blocking gaps |
| **CONDITIONAL** | Minor gaps with mitigation plan and timeline |
| **NOT READY** | Critical gaps that must be resolved before launch |

### Decision: ___________

### Blocking Items (if any)
| Item | Required Action | Owner | Due Date |
|------|----------------|-------|----------|
| _item_ | _action_ | _name_ | _date_ |

### Reviewer: ___________
### Date: ___________
