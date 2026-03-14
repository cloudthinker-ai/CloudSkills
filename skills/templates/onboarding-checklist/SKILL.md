---
name: onboarding-checklist
enabled: true
description: |
  Provides a comprehensive onboarding checklist for new engineering team members covering environment setup, access provisioning, codebase orientation, team introductions, and ramp-up milestones. This template helps teams deliver a consistent, thorough onboarding experience that gets new engineers productive quickly.
required_connections:
  - prefix: ticketing
    label: "Ticketing System"
  - prefix: collaboration
    label: "Collaboration Tool"
config_fields:
  - key: team_name
    label: "Team Name"
    required: true
    placeholder: "e.g., Search Infrastructure"
  - key: new_hire_name
    label: "New Hire Name"
    required: true
    placeholder: "e.g., Jane Smith"
  - key: start_date
    label: "Start Date"
    required: true
    placeholder: "e.g., 2026-04-01"
features:
  - ONBOARDING
  - ENGINEERING_MANAGEMENT
  - TEAM_PROCESS
---

# Onboarding Checklist

## Phase 1: Pre-Start Preparation (Before Day 1)

Complete before the new team member arrives.

- [ ] Assign onboarding buddy: ___
- [ ] Assign manager: ___
- [ ] Order equipment (laptop, monitors, peripherals)
- [ ] Create accounts:
  - [ ] Email
  - [ ] Source control (GitHub / GitLab)
  - [ ] CI/CD platform
  - [ ] Cloud provider console
  - [ ] Ticketing system
  - [ ] Collaboration tools (Slack, Teams)
  - [ ] Monitoring and observability platforms
  - [ ] VPN / network access
- [ ] Add to relevant team channels and distribution lists
- [ ] Schedule Week 1 meetings (manager 1:1, team intro, buddy sync)
- [ ] Prepare starter task(s) in the backlog

## Phase 2: Week 1 — Environment and Orientation

- [ ] Welcome meeting with manager (team mission, expectations, 30/60/90 goals)
- [ ] Team introductions and social coffee chat
- [ ] Development environment setup:
  - [ ] Clone primary repositories
  - [ ] Run local build and tests successfully
  - [ ] Set up IDE with team-standard extensions and config
  - [ ] Verify access to staging/dev environments
- [ ] Review key documentation:
  - [ ] Architecture overview
  - [ ] Team working agreements
  - [ ] On-call expectations and runbooks
  - [ ] Incident response process
- [ ] First code change: small, low-risk PR (typo fix, test addition, doc update)
- [ ] Daily check-in with onboarding buddy

## Phase 3: Weeks 2-4 — Ramp-Up

- [ ] Complete starter task(s) with buddy support
- [ ] Shadow an on-call shift
- [ ] Participate in sprint ceremonies (standup, planning, retro)
- [ ] Review recent incident postmortems
- [ ] Understand deployment pipeline end-to-end
- [ ] Cross-team introduction meetings:
  - [ ] Key upstream dependencies: ___
  - [ ] Key downstream consumers: ___
  - [ ] Platform / infrastructure team
- [ ] Complete any required compliance training
- [ ] Give feedback on onboarding experience so far

## Phase 4: 30/60/90 Day Milestones

| Milestone | Target | Status |
|-----------|--------|--------|
| First PR merged | Week 1 | |
| Starter task completed | Week 2-3 | |
| Independent feature work | Week 4-6 | |
| First on-call shift | Week 6-8 | |
| Lead a small project | Week 8-12 | |
| Onboarding feedback submitted | Day 30 | |
| 1:1 check-in with skip-level manager | Day 60 | |
| Full team contributor | Day 90 | |

## Output Format

### Summary

- **New hire:** ___
- **Team:** ___
- **Start date:** ___
- **Buddy:** ___
- **Manager:** ___
- **Current phase:** ___

### Action Items

- [ ] Complete all pre-start account provisioning
- [ ] Verify development environment works end-to-end
- [ ] Schedule all Week 1 meetings
- [ ] Review and update onboarding docs based on new hire feedback
- [ ] Conduct 30-day onboarding retrospective with new hire
