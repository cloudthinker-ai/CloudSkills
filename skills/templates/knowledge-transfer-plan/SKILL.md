---
name: knowledge-transfer-plan
enabled: true
description: |
  Structures a knowledge transfer plan for engineering teams facing team transitions, departures, or domain ownership changes. This template ensures critical knowledge about systems, processes, and tribal context is documented, transferred to receiving team members, and validated before the transition is complete.
required_connections:
  - prefix: collaboration
    label: "Collaboration Tool"
  - prefix: ticketing
    label: "Ticketing System"
config_fields:
  - key: transfer_reason
    label: "Transfer Reason"
    required: true
    placeholder: "e.g., Team member departure, ownership transfer, re-org"
  - key: source_person
    label: "Knowledge Source (Person/Team)"
    required: true
    placeholder: "e.g., Jane Smith or Platform Team"
  - key: target_person
    label: "Knowledge Recipient (Person/Team)"
    required: true
    placeholder: "e.g., John Doe or API Team"
  - key: deadline
    label: "Transfer Deadline"
    required: true
    placeholder: "e.g., 2026-04-15"
features:
  - KNOWLEDGE_TRANSFER
  - ENGINEERING_MANAGEMENT
  - DOCUMENTATION
---

# Knowledge Transfer Plan

## Phase 1: Knowledge Inventory

Catalog all knowledge areas that need to be transferred.

| Knowledge Area | Type | Criticality (H/M/L) | Documentation Exists | Transfer Method |
|---------------|------|:--------------------:|:--------------------:|-----------------|
|               | System / Process / Domain | | Y/N | Pairing / Doc / Walkthrough |

**Knowledge Types:**

- [ ] System architecture and design decisions
- [ ] Operational procedures and runbooks
- [ ] Business domain context and rules
- [ ] Key stakeholder relationships
- [ ] Historical context (why things are the way they are)
- [ ] Undocumented tribal knowledge
- [ ] Credentials, access, and administrative procedures

## Phase 2: Documentation Sprint

For each knowledge area with missing or outdated documentation:

- [ ] Create or update architecture diagrams
- [ ] Document key design decisions and trade-offs
- [ ] Record operational procedures as runbooks
- [ ] Document common failure modes and their resolutions
- [ ] Capture FAQ and troubleshooting guides
- [ ] Record or transcribe walkthrough sessions

| Document | Author | Reviewer | Status |
|----------|--------|----------|--------|
|          |        |          | Draft / Review / Complete |

## Phase 3: Transfer Sessions

Schedule and conduct structured knowledge transfer sessions.

| Session Topic | Date | Duration | Source | Recipient | Recording |
|--------------|------|----------|--------|-----------|-----------|
|              |      |          |        |           | Y/N       |

**Session Format:**

1. Source presents the topic (30 min)
2. Recipient asks questions (15 min)
3. Hands-on exercise or pairing (30 min)
4. Recipient summarizes understanding (15 min)

- [ ] All sessions recorded and stored in: ___
- [ ] Recipient can independently explain each topic
- [ ] Recipient has performed key procedures at least once

## Phase 4: Validation and Sign-Off

Verify the transfer is complete and the recipient is self-sufficient.

| Validation Task | Status | Notes |
|----------------|--------|-------|
| Recipient can deploy the service independently | | |
| Recipient can diagnose and resolve common issues | | |
| Recipient can handle an on-call page for the service | | |
| Recipient knows who to escalate to for edge cases | | |
| All critical documentation is reviewed and accurate | | |
| Access and credentials are transferred | | |

- [ ] Source and recipient both sign off on completion
- [ ] Manager approves transfer completion
- [ ] Shadow period defined: ___ weeks

## Output Format

### Summary

- **Transfer reason:** ___
- **Source:** ___
- **Recipient:** ___
- **Deadline:** ___
- **Knowledge areas:** ___ total, ___ transferred, ___ remaining
- **Status:** On Track / At Risk / Complete

### Action Items

- [ ] Complete documentation for all critical knowledge areas
- [ ] Conduct all scheduled transfer sessions
- [ ] Perform validation exercises
- [ ] Obtain sign-off from all parties
- [ ] Schedule follow-up check-in 2 weeks after transfer completion
- [ ] Archive transfer plan and recordings for future reference
