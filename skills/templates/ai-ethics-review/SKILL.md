---
name: ai-ethics-review
enabled: true
description: |
  Use when performing ai ethics review — conducts an ethical review of AI/ML
  systems covering fairness, transparency, accountability, privacy, and safety.
  Evaluates potential harms, bias in training data and model outputs,
  explainability requirements, and produces an ethics impact assessment with
  mitigation recommendations.
required_connections:
  - prefix: ml-platform
    label: "ML Platform"
config_fields:
  - key: system_name
    label: "AI System Name"
    required: true
    placeholder: "e.g., Loan Approval Model, Content Recommendation Engine"
  - key: use_case
    label: "Primary Use Case"
    required: true
    placeholder: "e.g., automated decision-making for credit applications"
  - key: affected_population
    label: "Affected Population"
    required: false
    placeholder: "e.g., loan applicants, job candidates, content consumers"
features:
  - DATA
  - AI
  - ETHICS
---

# AI Ethics Review

## Phase 1: System Assessment
1. Document the AI system
   - [ ] System purpose and intended use
   - [ ] Decision types (advisory, automated, human-in-the-loop)
   - [ ] Affected stakeholders and populations
   - [ ] Data sources and training data composition
   - [ ] Model type and architecture
   - [ ] Deployment context and scale
   - [ ] Current safeguards and controls
2. Classify system risk level

### Risk Classification

| Factor | Low Risk | Medium Risk | High Risk | Assessment |
|--------|---------|-------------|-----------|-----------|
| Decision impact | Informational | Affects service quality | Affects rights/safety | |
| Reversibility | Easily reversed | Effort to reverse | Irreversible | |
| Affected population | Small, opt-in | Large, optional | Vulnerable, mandatory | |
| Autonomy level | Human decides | Human reviews | Fully automated | |
| **Overall Risk** | | | | |

## Phase 2: Fairness Assessment
1. Evaluate fairness and bias
   - [ ] Protected attributes identified (race, gender, age, disability)
   - [ ] Training data representation analyzed
   - [ ] Historical bias in training data assessed
   - [ ] Proxy variables for protected attributes identified
   - [ ] Fairness metrics defined (demographic parity, equalized odds, etc.)
   - [ ] Disparate impact analysis conducted
   - [ ] Subgroup performance compared
2. Document bias risks and mitigations

### Fairness Metrics

| Protected Group | Sample Size | Positive Rate | False Positive Rate | False Negative Rate | Disparity |
|----------------|------------|-------------|-------------------|--------------------|----------|
| Group A (reference) | | % | % | % | N/A |
| Group B | | % | % | % | ratio |
| Group C | | % | % | % | ratio |

## Phase 3: Transparency & Explainability
1. Assess transparency requirements
   - [ ] Model decisions are explainable to affected individuals
   - [ ] Feature importance is documented and reasonable
   - [ ] Decision rationale can be provided on request
   - [ ] Model limitations clearly documented
   - [ ] Users informed they are interacting with AI
   - [ ] Training data sources disclosed
2. Evaluate explainability methods
   - [ ] Global explanations (feature importance, model summary)
   - [ ] Local explanations (individual decision rationale)
   - [ ] Counterfactual explanations ("what would need to change")

## Phase 4: Privacy & Data Protection
1. Assess privacy risks
   - [ ] Consent obtained for data usage in AI training
   - [ ] Data minimization practiced (only necessary features)
   - [ ] Re-identification risk assessed for anonymized data
   - [ ] Model memorization risk evaluated
   - [ ] Data retention aligned with privacy policies
   - [ ] Right to be forgotten implementable
   - [ ] Cross-border data transfer compliance
2. Evaluate privacy-preserving techniques used

## Phase 5: Safety & Robustness
1. Assess safety considerations
   - [ ] Failure modes identified and mitigated
   - [ ] Adversarial robustness tested
   - [ ] Out-of-distribution detection implemented
   - [ ] Human override capability exists
   - [ ] Escalation path for edge cases
   - [ ] Monitoring for model degradation
   - [ ] Kill switch for emergency shutdown
2. Evaluate potential for harm

### Harm Assessment

| Potential Harm | Likelihood | Severity | Affected Group | Mitigation | Residual Risk |
|---------------|-----------|----------|---------------|-----------|---------------|
|               | Low/Med/High | Low/Med/High | | | Low/Med/High |

## Phase 6: Accountability & Governance
1. Assess accountability structures
   - [ ] Responsible party identified for AI system
   - [ ] Governance review board or ethics committee
   - [ ] Regular audit schedule established
   - [ ] Complaint/appeal mechanism for affected individuals
   - [ ] Documentation of decisions and rationale
   - [ ] Regulatory compliance verified (EU AI Act, etc.)
   - [ ] Model card published
2. Define ongoing monitoring and review cadence

## Counter-Rationalizations

| Shortcut | Counter | Why |
|----------|---------|-----|
| "We can skip some steps for this case" | Adapt the workflow steps, don't skip them | Skipped steps are where incidents and oversights originate |
| "The user seems to already know what to do" | Complete all workflow phases with the user | The workflow catches blind spots that experience alone misses |
| "This is a minor case, full process is overkill" | Scale the process down, don't turn it off | Minor cases become major when unstructured; the process scales, not disappears |
| "I'll fill in the details later" | Complete each section before moving on | Deferred details are forgotten; real-time capture is more accurate |
| "The template output isn't necessary" | Always produce the structured output format | Structured output enables comparison, audit trails, and handoff to other teams |

## Output Format
- **Ethics Impact Assessment**: Comprehensive review across all dimensions
- **Risk Classification**: System risk level with justification
- **Fairness Report**: Bias analysis with demographic breakdowns
- **Mitigation Plan**: Identified risks with recommended actions
- **Governance Framework**: Ongoing oversight and accountability plan

## Action Items
- [ ] Complete system documentation and risk classification
- [ ] Conduct fairness and bias analysis on model outputs
- [ ] Implement explainability methods appropriate to risk level
- [ ] Verify privacy compliance and data minimization
- [ ] Test robustness and document failure modes
- [ ] Establish accountability and governance structure
- [ ] Schedule recurring ethics review (minimum annually)
