---
name: privacy-impact-assessment
enabled: true
description: |
  Use when performing privacy impact assessment — template for conducting
  Privacy Impact Assessments (PIA) on new projects or system changes involving
  personal data. Covers data flow mapping, purpose limitation analysis, data
  minimization review, consent mechanisms, third-party sharing evaluation, and
  risk mitigation to ensure privacy by design.
required_connections:
  - prefix: jira
    label: "Jira (or project tracker)"
config_fields:
  - key: project_name
    label: "Project/Feature Name"
    required: true
    placeholder: "e.g., customer-analytics-v2"
  - key: data_subjects
    label: "Data Subjects"
    required: true
    placeholder: "e.g., customers, employees, partners"
  - key: regulation
    label: "Primary Regulation"
    required: true
    placeholder: "e.g., GDPR, CCPA, PIPEDA"
features:
  - COMPLIANCE
  - PRIVACY
---

# Privacy Impact Assessment Skill

Conduct PIA for **{{ project_name }}** processing data of **{{ data_subjects }}** under **{{ regulation }}**.

## Workflow

### Phase 1 — Project Description

```
PROJECT OVERVIEW
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Project: {{ project_name }}
[ ] Description: ___
[ ] Data subjects: {{ data_subjects }}
[ ] Primary regulation: {{ regulation }}
[ ] Project stage: [ ] Design  [ ] Development  [ ] Production
[ ] Business justification: ___
[ ] Project owner: ___
[ ] DPO consulted: [ ] YES  [ ] NO
```

### Phase 2 — Data Flow Mapping

```
DATA FLOWS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Personal data collected:
    Data Element         | Category    | Sensitivity | Source
    _____________________|_____________|_____________|________
                         |             |             |
                         |             |             |
                         |             |             |

[ ] Data flow:
    Collection -> Processing -> Storage -> Sharing -> Deletion
    __________ -> __________ -> _______ -> _______ -> ________

[ ] Data storage locations: ___
[ ] Cross-border transfers: [ ] YES — countries: ___
[ ] Third parties receiving data:
    - ___: purpose: ___
    - ___: purpose: ___
```

### Phase 3 — Legal Basis and Purpose

```
LEGAL BASIS ANALYSIS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Lawful basis for processing ({{ regulation }}):
    [ ] Consent (explicit, informed, withdrawable)
    [ ] Contractual necessity
    [ ] Legal obligation
    [ ] Vital interests
    [ ] Public interest
    [ ] Legitimate interests (balancing test required)

[ ] Purpose limitation:
    - Stated purposes:
      1. ___
      2. ___
    - Purpose is specific and explicit: [ ] YES
    - No secondary use without additional basis: [ ] CONFIRMED

[ ] Data minimization:
    - All collected data necessary for stated purpose: [ ] YES
    - Data that could be removed/anonymized: ___
    - Retention period justified: [ ] YES
```

### Phase 4 — Data Subject Rights

```
RIGHTS IMPLEMENTATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Right to access: [ ] IMPLEMENTED — mechanism: ___
[ ] Right to rectification: [ ] IMPLEMENTED — mechanism: ___
[ ] Right to erasure: [ ] IMPLEMENTED — mechanism: ___
[ ] Right to portability: [ ] IMPLEMENTED — format: ___
[ ] Right to object: [ ] IMPLEMENTED — mechanism: ___
[ ] Right to restrict processing: [ ] IMPLEMENTED — mechanism: ___
[ ] Automated decision-making:
    - Used: [ ] YES  [ ] NO
    - Right to human review: [ ] IMPLEMENTED
[ ] Response timeline: ___ days (regulatory max: ___ days)
```

### Phase 5 — Risk Assessment

```
PRIVACY RISKS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Risk                         | Likelihood | Impact  | Severity | Mitigation
_____________________________|____________|_________|__________|___________
Unauthorized access          |            |         |          |
Data breach                  |            |         |          |
Excessive data collection    |            |         |          |
Purpose creep                |            |         |          |
Insufficient consent         |            |         |          |
Cross-border transfer risk   |            |         |          |
Third-party misuse           |            |         |          |
Reidentification risk        |            |         |          |

Residual risk after mitigations: [ ] LOW  [ ] MEDIUM  [ ] HIGH
```

### Phase 6 — Approval

```
PIA DECISION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Mitigations implemented before launch
[ ] Privacy notice updated
[ ] Consent mechanisms deployed (if applicable)
[ ] DPO sign-off: [ ] APPROVED  [ ] CONDITIONAL  [ ] REJECTED
[ ] Conditions (if applicable):
    - ___
    - ___
[ ] Review date: ___
[ ] Reassessment trigger: material change in data processing
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

Produce a Privacy Impact Assessment report with:
1. **Project summary** (description, data subjects, legal basis)
2. **Data flow map** (collection, processing, storage, sharing)
3. **Rights implementation** (status of each data subject right)
4. **Risk assessment** (identified risks with mitigations)
5. **Decision** (approval status, conditions, review schedule)
