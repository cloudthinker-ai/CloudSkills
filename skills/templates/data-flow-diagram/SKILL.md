---
name: data-flow-diagram
enabled: true
description: |
  Use when performing data flow diagram — guides the creation of comprehensive
  data flow diagrams (DFDs) that map how data moves through a system,
  identifying sources, destinations, transformations, and storage points. This
  template supports privacy reviews, security assessments, and compliance
  documentation by producing clear data lineage artifacts.
required_connections:
  - prefix: wiki
    label: "Documentation Platform"
config_fields:
  - key: system_name
    label: "System Name"
    required: true
    placeholder: "e.g., Customer Data Platform"
  - key: data_classification
    label: "Highest Data Classification"
    required: true
    placeholder: "e.g., PII, Confidential, Public"
features:
  - DATA_FLOW
  - DOCUMENTATION
  - ARCHITECTURE
---

# Data Flow Diagram

## Phase 1: Scope Definition

Define the boundaries of the data flow analysis.

- [ ] System or subsystem under analysis: ___
- [ ] Data classification levels in scope: ___
- [ ] Regulatory requirements (GDPR, HIPAA, SOC2, etc.): ___
- [ ] Diagram level: Context (L0) / System (L1) / Process (L2)

## Phase 2: Entity Inventory

Catalog all entities that interact with data.

**External Entities (sources and sinks):**

| Entity | Type | Data Provided | Data Received | Trust Level |
|--------|------|---------------|---------------|-------------|
|        | User/System/Third-party | | | Trusted/Untrusted |

**Processes (data transformations):**

| Process | Description | Input Data | Output Data | Technology |
|---------|------------|------------|-------------|------------|
|         |            |            |             |            |

**Data Stores:**

| Store | Type | Data Held | Classification | Encryption | Retention | Backup |
|-------|------|-----------|----------------|------------|-----------|--------|
|       | DB/Cache/File/Queue | | | At-rest Y/N | | Y/N |

## Phase 3: Data Flow Mapping

Map every data flow between entities.

| Flow ID | Source | Destination | Data Elements | Classification | Protocol | Encrypted | Auth Required |
|---------|--------|-------------|---------------|----------------|----------|-----------|---------------|
| F1      |        |             |               |                |          | Y/N       | Y/N           |

**Data Element Catalog:**

| Element | Classification | PII | Sensitive | Format | Validation |
|---------|---------------|-----|-----------|--------|------------|
|         | Public/Internal/Confidential/Restricted | Y/N | Y/N | | |

## Phase 4: Trust Boundary Analysis

- [ ] Identify all trust boundaries in the system
- [ ] Map which data flows cross trust boundaries
- [ ] Verify encryption for all cross-boundary flows
- [ ] Verify authentication for all cross-boundary flows
- [ ] Identify data that crosses organizational boundaries

**Trust Boundary Crossings:**

| Boundary | Flows Crossing | Security Controls | Gaps |
|----------|---------------|-------------------|------|
|          |               |                   |      |

## Phase 5: Compliance Mapping

| Requirement | Relevant Data Flows | Current Controls | Compliant | Gap |
|-------------|-------------------|------------------|-----------|-----|
| Data minimization | | | Y/N | |
| Encryption in transit | | | Y/N | |
| Encryption at rest | | | Y/N | |
| Access logging | | | Y/N | |
| Data retention | | | Y/N | |
| Right to deletion | | | Y/N | |
| Cross-border transfer | | | Y/N | |

## Counter-Rationalizations

| Shortcut | Counter | Why |
|----------|---------|-----|
| "We can skip some steps for this case" | Adapt the workflow steps, don't skip them | Skipped steps are where incidents and oversights originate |
| "The user seems to already know what to do" | Complete all workflow phases with the user | The workflow catches blind spots that experience alone misses |
| "This is a minor case, full process is overkill" | Scale the process down, don't turn it off | Minor cases become major when unstructured; the process scales, not disappears |
| "I'll fill in the details later" | Complete each section before moving on | Deferred details are forgotten; real-time capture is more accurate |
| "The template output isn't necessary" | Always produce the structured output format | Structured output enables comparison, audit trails, and handoff to other teams |

## Output Format

### Summary

- **System:** ___
- **Data flows documented:** ___
- **Trust boundaries identified:** ___
- **PII data flows:** ___
- **Compliance gaps found:** ___

### Artifacts

- [ ] Context diagram (L0)
- [ ] System diagram (L1)
- [ ] Process diagrams (L2) for sensitive flows
- [ ] Data element catalog
- [ ] Trust boundary map

### Action Items

- [ ] Remediate identified compliance gaps
- [ ] Add encryption to unprotected cross-boundary flows
- [ ] Add authentication to unauthenticated flows
- [ ] Review data retention policies for all stores
- [ ] Update DFD when system architecture changes
- [ ] Share with privacy and security teams for review
