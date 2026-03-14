---
name: architecture-decision-record
enabled: true
description: |
  Architecture Decision Record (ADR) template covering context, decision drivers, considered options, decision outcome, consequences, and status tracking. Based on the MADR format. Use for documenting significant technical decisions with full rationale.
required_connections:
  - prefix: github
    label: "GitHub (for PR/issue context)"
config_fields:
  - key: adr_title
    label: "Decision Title"
    required: true
    placeholder: "e.g., Use PostgreSQL for order data"
  - key: adr_number
    label: "ADR Number"
    required: true
    placeholder: "e.g., ADR-042"
  - key: decision_scope
    label: "Scope / System"
    required: true
    placeholder: "e.g., order-platform, infrastructure, company-wide"
features:
  - ARCHITECTURE
---

# Architecture Decision Record Skill

Create ADR **{{ adr_number }}**: **{{ adr_title }}** for **{{ decision_scope }}**.

## Workflow

### Step 1 — ADR Header

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
ADR {{ adr_number }}: {{ adr_title }}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Status: PROPOSED / ACCEPTED / DEPRECATED / SUPERSEDED
Date: [auto-populated]
Scope: {{ decision_scope }}
Decision makers: [list names/roles]
Consulted: [list stakeholders consulted]
Informed: [list people to be informed]
```

### Step 2 — Context & Problem Statement

```
CONTEXT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PROBLEM STATEMENT:
[2-3 sentences describing the problem or question that needs a decision.
What is the current situation? Why does a decision need to be made now?]

DECISION DRIVERS:
  - [Driver 1: e.g., "Must support 10x traffic growth in 12 months"]
  - [Driver 2: e.g., "Team has limited experience with technology X"]
  - [Driver 3: e.g., "Must comply with SOC2 requirements"]
  - [Driver 4: e.g., "Budget constraint of $X/month"]

CONSTRAINTS:
  - [Constraint 1: e.g., "Must be compatible with existing CI/CD pipeline"]
  - [Constraint 2: e.g., "Cannot require more than 2 weeks of migration effort"]

ASSUMPTIONS:
  - [Assumption 1: e.g., "Traffic will grow 20% MoM"]
  - [Assumption 2: e.g., "Team will have 2 engineers available for implementation"]
```

### Step 3 — Considered Options

```
OPTIONS CONSIDERED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
OPTION A: [Name]
  Description: [1-2 sentences]
  Pros:
    + [advantage]
    + [advantage]
  Cons:
    - [disadvantage]
    - [disadvantage]
  Cost: [effort, money, time]
  Risk: LOW / MEDIUM / HIGH

OPTION B: [Name]
  Description: [1-2 sentences]
  Pros:
    + [advantage]
    + [advantage]
  Cons:
    - [disadvantage]
    - [disadvantage]
  Cost: [effort, money, time]
  Risk: LOW / MEDIUM / HIGH

OPTION C: [Name]
  Description: [1-2 sentences]
  Pros:
    + [advantage]
    + [advantage]
  Cons:
    - [disadvantage]
    - [disadvantage]
  Cost: [effort, money, time]
  Risk: LOW / MEDIUM / HIGH
```

### Step 4 — Decision Matrix

```
DECISION MATRIX
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
| Criteria | Weight | Option A | Option B | Option C |
|----------|--------|----------|----------|----------|
| [criteria 1] | [1-5] | [1-5] | [1-5] | [1-5] |
| [criteria 2] | [1-5] | [1-5] | [1-5] | [1-5] |
| [criteria 3] | [1-5] | [1-5] | [1-5] | [1-5] |
| [criteria 4] | [1-5] | [1-5] | [1-5] | [1-5] |
| [criteria 5] | [1-5] | [1-5] | [1-5] | [1-5] |
| **Weighted Total** | | **___** | **___** | **___** |

Common criteria: scalability, maintainability, cost, team expertise,
time to implement, operational complexity, security, vendor lock-in
```

### Step 5 — Decision Outcome

```
DECISION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
CHOSEN OPTION: [Option X — Name]

RATIONALE:
[2-3 sentences explaining why this option was selected over alternatives.
Reference the decision drivers and how this option best satisfies them.]

WHAT THIS MEANS:
  We will: [concrete action]
  We will not: [explicitly rejected approach]
  We accept: [known trade-offs]
```

### Step 6 — Consequences

```
CONSEQUENCES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
POSITIVE:
  + [benefit this decision brings]
  + [benefit]
  + [benefit]

NEGATIVE:
  - [trade-off or cost accepted]
  - [trade-off]

RISKS:
  - [risk]: [mitigation strategy]
  - [risk]: [mitigation strategy]

FOLLOW-UP DECISIONS NEEDED:
  - [decision that will need to be made as a result]
  - [decision]
```

### Step 7 — Implementation Plan

```
IMPLEMENTATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
| Phase | Task | Owner | Timeline |
|-------|------|-------|----------|
| 1 | [task] | [name] | [dates] |
| 2 | [task] | [name] | [dates] |
| 3 | [task] | [name] | [dates] |

VALIDATION CRITERIA:
  [ ] [How we will know the decision was correct]
  [ ] [Metric or milestone to evaluate]

REVIEW DATE: [when to revisit this decision]
```

### Step 8 — Related ADRs

```
RELATED DECISIONS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Supersedes: [ADR-XXX (if replacing a previous decision)]
  Related to: [ADR-YYY, ADR-ZZZ]
  Superseded by: [none — will be updated if this ADR is replaced]
```

## Output Format

Produce an ADR document with:
1. **Header** (number, title, status, date, decision makers)
2. **Context** with problem statement, drivers, and constraints
3. **Options** with pros/cons analysis and decision matrix
4. **Decision** with rationale and chosen option
5. **Consequences** (positive, negative, risks, follow-ups)
6. **Implementation plan** with timeline and validation criteria
