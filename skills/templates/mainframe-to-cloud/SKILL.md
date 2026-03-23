---
name: mainframe-to-cloud
enabled: true
description: |
  Use when performing mainframe to cloud — provides a structured methodology for
  migrating mainframe workloads (COBOL, JCL, CICS, IMS) to cloud-native
  platforms. Covers code analysis, automated conversion, data migration from
  hierarchical and VSAM stores, batch job modernization, and phased cutover with
  parallel validation.
required_connections:
  - prefix: mainframe
    label: "Mainframe System"
  - prefix: cloud-provider
    label: "Target Cloud Provider"
config_fields:
  - key: mainframe_platform
    label: "Mainframe Platform"
    required: true
    placeholder: "e.g., IBM z/OS, AS/400, Unisys"
  - key: primary_languages
    label: "Primary Languages"
    required: true
    placeholder: "e.g., COBOL, PL/I, Natural/ADABAS"
  - key: target_language
    label: "Target Language/Platform"
    required: false
    placeholder: "e.g., Java, .NET, cloud-native containers"
features:
  - CLOUD_MIGRATION
  - MAINFRAME
  - MODERNIZATION
---

# Mainframe to Cloud Migration Plan

## Phase 1: Mainframe Discovery
1. Inventory all mainframe assets
   - [ ] Programs (COBOL, PL/I, Assembler, Natural)
   - [ ] JCL jobs and batch schedules
   - [ ] CICS/IMS online transactions
   - [ ] Databases (DB2, IMS DB, VSAM, ADABAS)
   - [ ] Copybooks and data structures
   - [ ] Inter-system interfaces (MQ, FTP, CICS MRO)
2. Analyze code complexity and dead code
3. Map business processes to technical components
4. Document batch job dependencies and scheduling

### Workload Classification

| Component | Type | Lines of Code | Complexity | Business Criticality | Migration Approach |
|-----------|------|---------------|------------|---------------------|-------------------|
|           | Batch/Online/DB | | Low/Med/High | Critical/Important/Low | Rehost/Refactor/Replace |

## Phase 2: Migration Strategy Selection

### Decision Matrix

| Approach | Risk | Cost | Timeline | Modernization Level | Best For |
|----------|------|------|----------|--------------------| ---------|
| Rehost (emulation) | Low | Medium | Short | Minimal | Quick lift |
| Automated refactor | Medium | Medium | Medium | Moderate | COBOL to Java |
| Manual rewrite | High | High | Long | Maximum | Complex logic |
| Replace with COTS/SaaS | Medium | Variable | Medium | High | Standard functions |

1. Select approach per workload based on business value and risk
2. Identify workloads suitable for automated conversion tools
3. Plan for workloads requiring manual rewriting
4. Determine which functions to replace with SaaS solutions

## Phase 3: Foundation & Tooling
1. Set up cloud landing zone for mainframe workloads
2. Configure mainframe-to-cloud conversion tools
3. Establish connectivity between mainframe and cloud
4. Set up parallel testing environment
5. Create automated regression test suites from production data

## Phase 4: Code Migration
1. Convert or rewrite programs in priority order
2. Migrate copybooks to modern data structures
3. Transform JCL batch jobs to cloud-native orchestration
4. Modernize online transactions to APIs or web services
5. Validate each converted component against original behavior

## Phase 5: Data Migration
1. Design target data models (relational, NoSQL)
2. Build ETL pipelines for data transformation
3. Migrate DB2/IMS/VSAM data to cloud databases
4. Handle EBCDIC to ASCII/Unicode conversion
5. Validate data integrity with row counts and checksums

## Phase 6: Parallel Run & Cutover
1. Run mainframe and cloud systems in parallel
2. Compare outputs of batch jobs between environments
3. Validate online transaction responses match
4. Execute cutover during planned maintenance window
5. Keep mainframe available for rollback period

## Counter-Rationalizations

| Shortcut | Counter | Why |
|----------|---------|-----|
| "We can skip some steps for this case" | Adapt the workflow steps, don't skip them | Skipped steps are where incidents and oversights originate |
| "The user seems to already know what to do" | Complete all workflow phases with the user | The workflow catches blind spots that experience alone misses |
| "This is a minor case, full process is overkill" | Scale the process down, don't turn it off | Minor cases become major when unstructured; the process scales, not disappears |
| "I'll fill in the details later" | Complete each section before moving on | Deferred details are forgotten; real-time capture is more accurate |
| "The template output isn't necessary" | Always produce the structured output format | Structured output enables comparison, audit trails, and handoff to other teams |

## Output Format
- **Asset Inventory**: Complete mainframe program and data catalog
- **Migration Strategy Document**: Approach per workload with justification
- **Conversion Report**: Automated and manual conversion results
- **Parallel Run Results**: Comparison reports between mainframe and cloud
- **Cutover Runbook**: Step-by-step production migration procedures

## Action Items
- [ ] Complete mainframe asset discovery and classification
- [ ] Select migration approach per workload
- [ ] Execute proof of concept with representative workloads
- [ ] Build and validate automated test suites
- [ ] Migrate workloads in priority waves
- [ ] Run parallel validation for each wave
- [ ] Decommission mainframe after full stabilization
