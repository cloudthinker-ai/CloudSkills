---
name: architecture-review-board
enabled: true
description: |
  Use when performing architecture review board — architecture review template
  for evaluating major system changes, RFC proposals, and design documents.
  Covers scalability analysis, technology selection rationale, integration
  patterns, operational readiness, and long-term maintainability to ensure
  architectural decisions align with organizational standards and goals.
required_connections:
  - prefix: github
    label: "GitHub"
config_fields:
  - key: repository
    label: "Repository"
    required: true
    placeholder: "e.g., org/platform-rfcs"
  - key: pr_number
    label: "PR/RFC Number"
    required: true
    placeholder: "e.g., 1234"
  - key: change_category
    label: "Change Category"
    required: true
    placeholder: "e.g., new-service, major-refactor, technology-adoption"
features:
  - CODE_REVIEW
---

# Architecture Review Board Skill

Architecture review of PR/RFC **#{{ pr_number }}** in **{{ repository }}** ({{ change_category }}).

## Workflow

### Phase 1 — Problem and Solution Assessment

```
PROBLEM STATEMENT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Problem clearly defined: YES / NO
[ ] Business justification provided: YES / NO
[ ] Success criteria measurable: YES / NO
[ ] Scope well-bounded: YES / NO
[ ] Alternatives considered:
    Alternative           | Pros              | Cons              | Why not chosen
    ──────────────────────┼───────────────────┼───────────────────┼───────────────
    ___                   | ___               | ___               | ___
    ___                   | ___               | ___               | ___
```

### Phase 2 — Scalability and Performance

```
SCALABILITY REVIEW
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Scale requirements:
    - Current load: ___
    - Expected load (1 year): ___
    - Expected load (3 years): ___
    - Peak load multiplier: ___
[ ] Scaling strategy:
    [ ] Horizontal scaling supported
    [ ] Stateless design (or state externalized)
    [ ] Database scaling plan (read replicas, sharding)
    [ ] Caching strategy defined
    [ ] Rate limiting configured
[ ] Performance:
    [ ] Latency requirements defined
    [ ] Throughput requirements defined
    [ ] Performance testing plan included
    [ ] Capacity planning documented
```

### Phase 3 — Technology Selection

```
TECHNOLOGY REVIEW
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] New technologies introduced:
    Technology     | Rationale          | Team experience | Maturity
    ───────────────┼────────────────────┼─────────────────┼─────────
    ___            | ___                | ___             | ___
[ ] Alignment with tech radar: YES / NO
[ ] Team has skills to build and operate: YES / NO
[ ] Training plan if new technology: ___
[ ] Vendor lock-in assessment: low / medium / high
[ ] Open source vs commercial decision justified: YES / NO
[ ] License compatibility verified: YES / NO
```

### Phase 4 — Operational Readiness

```
OPERATIONS REVIEW
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Deployment:
    [ ] CI/CD pipeline defined
    [ ] Zero-downtime deployment supported
    [ ] Rollback procedure documented
    [ ] Feature flag strategy for gradual rollout
[ ] Observability:
    [ ] Monitoring and alerting plan
    [ ] SLIs and SLOs defined
    [ ] Dashboards planned
    [ ] Runbooks outlined
[ ] Reliability:
    [ ] Failure modes identified (FMEA)
    [ ] Disaster recovery plan
    [ ] Data backup strategy
    [ ] Dependency failure handling
[ ] Security:
    [ ] Threat model completed
    [ ] Security review scheduled
    [ ] Compliance requirements identified
    [ ] Data classification documented
```

### Phase 5 — Integration and Migration

```
INTEGRATION REVIEW
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Integration points:
    System/Service       | Pattern           | Contract
    ─────────────────────┼───────────────────┼─────────
    ___                  | sync/async        | ___
[ ] Migration plan:
    [ ] Phased migration approach defined
    [ ] Dual-write/dual-read period planned
    [ ] Data migration strategy documented
    [ ] Rollback at each phase possible
    [ ] Timeline with milestones: ___
[ ] Impact on existing systems:
    [ ] Breaking changes to downstream consumers: YES / NO
    [ ] API versioning strategy: ___
    [ ] Communication plan for affected teams: YES / NO
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

Produce an architecture review report with:
1. **Decision recommendation** (approve / approve with conditions / defer / reject)
2. **Scalability assessment** (meets requirements / concerns / gaps)
3. **Technology evaluation** (aligned / deviation justified / not recommended)
4. **Operational readiness** (ready / gaps identified / not ready)
5. **Conditions for approval** (required changes before proceeding)
6. **Follow-up reviews** scheduled for implementation checkpoints
