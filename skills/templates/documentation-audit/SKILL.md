---
name: documentation-audit
enabled: true
description: |
  Use when performing documentation audit — audits the state of technical
  documentation across an engineering organization. Covers documentation
  inventory, freshness assessment, gap identification, quality scoring,
  ownership assignment, and a remediation plan to achieve comprehensive,
  accurate, and maintainable documentation.
required_connections:
  - prefix: wiki
    label: "Documentation Platform"
config_fields:
  - key: documentation_platform
    label: "Documentation Platform"
    required: true
    placeholder: "e.g., Confluence, Notion, GitBook, README files"
  - key: scope
    label: "Audit Scope"
    required: true
    placeholder: "e.g., all engineering docs, backend team, platform services"
  - key: doc_count_estimate
    label: "Estimated Number of Documents"
    required: false
    placeholder: "e.g., 200"
features:
  - TEAM_PRODUCTIVITY
  - DOCUMENTATION
  - AUDIT
---

# Documentation Audit

## Phase 1: Documentation Inventory
1. Catalog all existing documentation
   - [ ] Architecture documents and diagrams
   - [ ] API documentation
   - [ ] Runbooks and operational procedures
   - [ ] Onboarding guides
   - [ ] Service READMEs
   - [ ] Decision records (ADRs)
   - [ ] Postmortem/incident reports
   - [ ] How-to guides and tutorials
   - [ ] Configuration references
   - [ ] Troubleshooting guides
2. Record metadata for each document (owner, last updated, location)
3. Identify documentation scattered across multiple platforms

### Documentation Inventory Summary

| Category | Expected | Exists | Up-to-Date | Has Owner | Quality Score |
|----------|---------|--------|-----------|-----------|-------------|
| Architecture | | | | | /5 |
| API docs | | | | | /5 |
| Runbooks | | | | | /5 |
| Onboarding | | | | | /5 |
| Service READMEs | | | | | /5 |
| ADRs | | | | | /5 |
| How-to guides | | | | | /5 |

## Phase 2: Freshness Assessment
1. Evaluate documentation freshness
   - [ ] Last modified date for each document
   - [ ] Correlation with code/infrastructure changes since last update
   - [ ] Known inaccuracies flagged by team members
   - [ ] References to deprecated tools, services, or processes
2. Classify documents by freshness

### Freshness Classification

| Status | Criteria | Document Count | Percentage |
|--------|----------|---------------|-----------|
| Current | Updated within 6 months, matches reality | | % |
| Stale | Updated 6-12 months ago, likely outdated | | % |
| Obsolete | Updated 12+ months ago or references deprecated items | | % |
| Missing | Expected documentation that does not exist | | % |

## Phase 3: Gap Analysis
1. Identify documentation gaps
   - [ ] Services without README or architecture doc
   - [ ] Operations without runbooks
   - [ ] APIs without reference documentation
   - [ ] No onboarding guide for new team members
   - [ ] Missing decision records for key architectural choices
   - [ ] No troubleshooting guides for common issues
   - [ ] Missing disaster recovery procedures
2. Prioritize gaps by impact

### Critical Gaps

| Gap | Category | Impact | Affected Teams | Priority | Effort to Create |
|-----|----------|--------|---------------|----------|-----------------|
|     |          | High/Med/Low | | 1-5 | Hours/Days |

## Phase 4: Quality Assessment
1. Score documents on quality dimensions
   - [ ] Accuracy: content matches current reality
   - [ ] Completeness: covers the topic adequately
   - [ ] Clarity: easy to understand for target audience
   - [ ] Findability: easy to discover and well-organized
   - [ ] Actionability: reader can follow steps successfully
   - [ ] Maintainability: easy to update when things change
2. Identify common quality issues

### Quality Scoring Rubric

| Dimension | 1 (Poor) | 3 (Adequate) | 5 (Excellent) |
|-----------|----------|-------------|---------------|
| Accuracy | Contains errors | Mostly correct | Verified accurate |
| Completeness | Major gaps | Covers basics | Comprehensive |
| Clarity | Confusing | Understandable | Clear with examples |
| Findability | Hard to find | Searchable | Well-organized, linked |
| Actionability | Cannot follow | Can follow with effort | Step-by-step with validation |
| Maintainability | Hard to update | Moderate effort | Template-based, modular |

## Phase 5: Ownership Assignment
1. Assign ownership for all documentation
   - [ ] Every document has a named owner
   - [ ] Owner responsible for quarterly review
   - [ ] Ownership transfers documented during team changes
   - [ ] Documentation included in service ownership model
2. Define documentation standards
   - [ ] Templates for each document type
   - [ ] Style guide for consistency
   - [ ] Review process for new documentation
   - [ ] Deprecation process for obsolete docs

## Phase 6: Remediation Plan
1. Prioritize remediation actions
   - Critical: Create missing runbooks and incident procedures
   - High: Update stale architecture and API documentation
   - Medium: Fill onboarding and how-to guide gaps
   - Low: Improve quality of adequate-but-basic documents
2. Assign owners and deadlines
3. Establish ongoing documentation health metrics

### Remediation Plan

| Priority | Action | Documents | Owner | Deadline | Status |
|----------|--------|----------|-------|----------|--------|
| Critical | Create missing runbooks | list | | | |
| High | Update stale architecture docs | list | | | |
| Medium | Fill onboarding gaps | list | | | |
| Low | Quality improvements | list | | | |

## Counter-Rationalizations

| Shortcut | Counter | Why |
|----------|---------|-----|
| "We can skip some steps for this case" | Adapt the workflow steps, don't skip them | Skipped steps are where incidents and oversights originate |
| "The user seems to already know what to do" | Complete all workflow phases with the user | The workflow catches blind spots that experience alone misses |
| "This is a minor case, full process is overkill" | Scale the process down, don't turn it off | Minor cases become major when unstructured; the process scales, not disappears |
| "I'll fill in the details later" | Complete each section before moving on | Deferred details are forgotten; real-time capture is more accurate |
| "The template output isn't necessary" | Always produce the structured output format | Structured output enables comparison, audit trails, and handoff to other teams |

## Output Format
- **Documentation Inventory**: Complete catalog with metadata
- **Freshness Report**: Classification of all documents by staleness
- **Gap Analysis**: Missing documentation prioritized by impact
- **Quality Scores**: Per-document and per-category quality ratings
- **Remediation Plan**: Prioritized actions with owners and deadlines

## Action Items
- [ ] Complete documentation inventory across all platforms
- [ ] Assess freshness and identify stale/obsolete documents
- [ ] Identify and prioritize documentation gaps
- [ ] Score document quality on key dimensions
- [ ] Assign owners to all documentation
- [ ] Create remediation plan with deadlines
- [ ] Establish quarterly documentation health review
