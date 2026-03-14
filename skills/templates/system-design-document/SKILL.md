---
name: system-design-document
enabled: true
description: |
  Provides a structured template for creating comprehensive system design documents that cover requirements, architecture decisions, component design, data models, API contracts, and operational considerations. Use this template to ensure design documents are thorough and follow organizational standards.
required_connections:
  - prefix: wiki
    label: "Documentation Platform"
config_fields:
  - key: project_name
    label: "Project Name"
    required: true
    placeholder: "e.g., User Notification Service"
  - key: author
    label: "Author"
    required: true
    placeholder: "e.g., Jane Smith"
  - key: target_date
    label: "Target Launch Date"
    required: false
    placeholder: "e.g., Q2 2026"
features:
  - SYSTEM_DESIGN
  - DOCUMENTATION
  - ARCHITECTURE
---

# System Design Document

## Phase 1: Context and Requirements

Define the problem space and requirements.

1. Problem statement:
   - [ ] What problem does this system solve?
   - [ ] Who are the users/consumers?
   - [ ] What is the business impact?

2. Functional requirements:
   - [ ] Core use cases (numbered list)
   - [ ] Input/output specifications
   - [ ] User-facing behavior

3. Non-functional requirements:
   - [ ] Availability target: ___
   - [ ] Latency target (p99): ___
   - [ ] Throughput target: ___
   - [ ] Data retention requirements: ___
   - [ ] Compliance requirements: ___
   - [ ] Security requirements: ___

4. Constraints:
   - [ ] Technology constraints
   - [ ] Timeline constraints
   - [ ] Budget constraints
   - [ ] Team capacity constraints

## Phase 2: High-Level Architecture

1. - [ ] Draw system context diagram (external systems, users, data flows)
2. - [ ] Draw component diagram (internal services, databases, queues)
3. - [ ] Identify synchronous vs asynchronous communication paths
4. - [ ] List all external dependencies

**Component Inventory:**

| Component | Responsibility | Technology | Owner |
|-----------|---------------|------------|-------|
|           |               |            |       |

## Phase 3: Detailed Design

For each component:

1. - [ ] Data model / schema design
2. - [ ] API contract (endpoints, request/response schemas)
3. - [ ] State management approach
4. - [ ] Error handling strategy
5. - [ ] Caching strategy
6. - [ ] Authentication and authorization

**Key Design Decisions:**

| Decision | Options Considered | Chosen | Rationale |
|----------|-------------------|--------|-----------|
|          |                   |        |           |

## Phase 4: Data Design

- [ ] Entity relationship diagram
- [ ] Storage technology selection and justification
- [ ] Read/write patterns and access patterns
- [ ] Data partitioning / sharding strategy
- [ ] Backup and recovery approach
- [ ] Data migration plan (if applicable)

## Phase 5: Operational Design

- [ ] Deployment strategy (blue-green, canary, rolling)
- [ ] Monitoring and alerting plan
- [ ] Logging strategy
- [ ] Runbook for common operations
- [ ] Capacity planning estimates
- [ ] Disaster recovery plan
- [ ] Feature flag strategy

## Phase 6: Security Review

- [ ] Authentication mechanism
- [ ] Authorization model
- [ ] Data encryption (at rest and in transit)
- [ ] Input validation
- [ ] Rate limiting
- [ ] Audit logging
- [ ] Threat model reference (link)

## Output Format

### Document Metadata

- **Project:** ___
- **Author:** ___
- **Status:** Draft / In Review / Approved
- **Reviewers:** ___
- **Last updated:** ___

### Review Checklist

- [ ] Requirements are testable and measurable
- [ ] Architecture diagram is clear and complete
- [ ] All external dependencies are identified
- [ ] Data model supports all use cases
- [ ] API contracts are defined
- [ ] Failure modes are addressed
- [ ] Security review is complete
- [ ] Operational concerns are addressed
- [ ] Cost estimates are included
- [ ] Timeline and milestones are defined
