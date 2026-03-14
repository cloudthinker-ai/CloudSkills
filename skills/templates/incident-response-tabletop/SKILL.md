---
name: incident-response-tabletop
enabled: true
description: |
  Plans and facilitates a tabletop exercise to test incident response procedures without impacting production systems. Covers scenario design, participant preparation, exercise facilitation, response evaluation, and after-action review to identify gaps in incident readiness.
required_connections:
  - prefix: incident-mgmt
    label: "Incident Management Platform"
config_fields:
  - key: scenario_type
    label: "Incident Scenario Type"
    required: true
    placeholder: "e.g., security breach, major outage, data loss, ransomware"
  - key: participants
    label: "Participant Teams"
    required: true
    placeholder: "e.g., engineering, security, communications, leadership"
  - key: exercise_duration
    label: "Exercise Duration"
    required: false
    placeholder: "e.g., 2 hours"
features:
  - TEAM_PRODUCTIVITY
  - INCIDENT_RESPONSE
  - EXERCISE
---

# Incident Response Tabletop Exercise

## Phase 1: Exercise Planning
1. Define exercise objectives
   - [ ] Test incident detection and escalation procedures
   - [ ] Validate communication channels and templates
   - [ ] Evaluate decision-making under pressure
   - [ ] Identify gaps in runbooks and documentation
   - [ ] Test coordination between teams
   - [ ] Verify compliance with notification requirements
2. Select scenario type and scope
3. Identify participants and assign roles
4. Schedule exercise and send calendar invitations

### Exercise Configuration

| Element | Details |
|---------|---------|
| Scenario | |
| Date/Time | |
| Duration | hours |
| Facilitator | |
| Observer/Scribe | |
| Participants | |
| Objectives | |

## Phase 2: Scenario Design
1. Create a realistic incident scenario
   - [ ] Initial detection signal (alert, customer report, security tool)
   - [ ] Escalating injects at timed intervals
   - [ ] Ambiguous information requiring investigation
   - [ ] Decisions points requiring trade-offs
   - [ ] External stakeholder communication triggers
   - [ ] Resolution path (but do not share with participants)
2. Prepare injects (new information introduced during exercise)

### Scenario Timeline

| Time (min) | Inject | Information Provided | Expected Response | Evaluation Criteria |
|-----------|--------|---------------------|-------------------|-------------------|
| 0 | Initial alert | | | Detection & triage |
| 15 | Escalation | | | Severity assessment |
| 30 | Scope expansion | | | Communication |
| 45 | Customer impact | | | External comms |
| 60 | Root cause clue | | | Investigation |
| 75 | Resolution option | | | Decision-making |
| 90 | Recovery | | | Recovery procedures |

## Phase 3: Participant Preparation
1. Prepare participants
   - [ ] Send pre-exercise briefing (objectives, not scenario details)
   - [ ] Remind participants to bring laptops, access to tools
   - [ ] Share ground rules (no real system changes, time compression)
   - [ ] Assign exercise roles (IC, communications, technical leads)
   - [ ] Provide reference materials (runbooks, escalation paths, contact lists)
2. Brief observers on evaluation criteria
3. Set up exercise communication channels (separate from production)

### Role Assignments

| Role | Participant | Responsibilities During Exercise |
|------|-----------|--------------------------------|
| Incident Commander | | Overall coordination, decision-making |
| Technical Lead | | Investigation, mitigation |
| Communications Lead | | Internal/external communications |
| Security Lead | | Security assessment (if applicable) |
| Executive Sponsor | | Business decisions, customer escalation |
| Observer/Scribe | | Document responses, timing, gaps |

## Phase 4: Exercise Facilitation
1. Run the tabletop exercise
   - [ ] Set the scene and deliver initial inject
   - [ ] Allow participants to discuss and respond naturally
   - [ ] Introduce injects at planned intervals
   - [ ] Ask probing questions to test depth of response
   - [ ] Observe but do not lead (let gaps surface naturally)
   - [ ] Track decisions made and rationale
   - [ ] Note areas of confusion or disagreement
   - [ ] Time-compress as needed to cover full scenario
2. Capture observations in real-time

### Facilitator Probing Questions
- "Who needs to be notified at this point?"
- "What would you communicate to customers?"
- "Where would you find the runbook for this?"
- "What is your rollback plan?"
- "How do you confirm the incident is fully resolved?"
- "What regulatory notifications are required?"

## Phase 5: After-Action Review
1. Conduct debrief immediately after exercise
   - [ ] What went well?
   - [ ] What surprised participants?
   - [ ] Where did confusion or delays occur?
   - [ ] Were runbooks and documentation adequate?
   - [ ] Were the right people in the room?
   - [ ] Were communication templates effective?
   - [ ] What would participants do differently?
2. Document all findings

### Gap Analysis

| Category | Finding | Severity | Root Cause | Remediation |
|----------|---------|----------|-----------|-------------|
| Detection | | High/Med/Low | | |
| Escalation | | | | |
| Communication | | | | |
| Technical response | | | | |
| Documentation | | | | |
| Decision-making | | | | |

## Phase 6: Improvement Plan
1. Prioritize identified gaps
2. Assign remediation actions with owners and deadlines
3. Update runbooks and procedures based on findings
4. Schedule follow-up exercises to validate improvements
5. Share lessons learned with broader organization

### Improvement Actions

| Priority | Action | Owner | Deadline | Status |
|----------|--------|-------|----------|--------|
| 1 | | | | |

## Output Format
- **Exercise Summary**: Scenario, participants, and timeline
- **Response Evaluation**: How well teams performed at each phase
- **Gap Analysis**: Identified weaknesses with severity
- **Improvement Plan**: Remediation actions with owners and deadlines
- **Lessons Learned**: Key takeaways for the organization

## Action Items
- [ ] Design realistic scenario with timed injects
- [ ] Prepare participants and assign roles
- [ ] Facilitate exercise and capture observations
- [ ] Conduct after-action review
- [ ] Document gaps and assign remediation actions
- [ ] Update runbooks and procedures based on findings
- [ ] Schedule next tabletop exercise (quarterly recommended)
