---
name: cloud-migration-assessment
enabled: true
description: |
  Cloud migration readiness assessment covering application portfolio analysis, 6R migration strategy classification, dependency mapping, wave planning, risk assessment, and cost modeling. Use for planning data center exits, cloud-first transformations, or workload repatriation decisions.
required_connections:
  - prefix: aws
    label: "AWS (or target cloud provider)"
config_fields:
  - key: project_name
    label: "Migration Project Name"
    required: true
    placeholder: "e.g., DC-Exit-2026"
  - key: target_cloud
    label: "Target Cloud"
    required: true
    placeholder: "e.g., AWS, GCP, Azure, multi-cloud"
  - key: application_count
    label: "Approximate Application Count"
    required: false
    placeholder: "e.g., 50, 200"
features:
  - CLOUD
  - ARCHITECTURE
---

# Cloud Migration Assessment Skill

Assess cloud migration readiness for **{{ project_name }}** targeting **{{ target_cloud }}**.

## Workflow

### Step 1 — Portfolio Discovery

Build an application inventory:

```
APPLICATION PORTFOLIO
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Total applications: {{ application_count | "TBD" }}

| App Name | Owner | Tech Stack | Criticality | Current Host | Users |
|----------|-------|-----------|-------------|-------------|-------|
| [app] | [team] | [lang/framework] | CRITICAL/HIGH/MED/LOW | [DC/colo] | [count] |

For each application, capture:
[ ] Application name and business function
[ ] Owning team and technical contact
[ ] Technology stack (language, framework, runtime)
[ ] Business criticality tier
[ ] Current hosting (data center, colo, on-prem)
[ ] Dependencies (upstream and downstream)
[ ] Data sensitivity (PII, PHI, PCI, public)
[ ] Compliance requirements (SOC2, HIPAA, PCI, GDPR)
[ ] Current infrastructure cost (monthly)
[ ] Licensing constraints (tied to hardware, cores, etc.)
```

### Step 2 — 6R Strategy Classification

Classify each application using the 6R model:

```
6R CLASSIFICATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
REHOST (Lift and Shift):
  Criteria: No code changes, move as-is to cloud VMs
  Best for: Legacy apps with tight timelines
  Apps: [list]

REPLATFORM (Lift and Reshape):
  Criteria: Minor optimizations (managed DB, containers)
  Best for: Apps that benefit from managed services with minimal changes
  Apps: [list]

REPURCHASE (Replace with SaaS):
  Criteria: Replace with commercial SaaS product
  Best for: Commodity workloads (email, CRM, HR)
  Apps: [list]

REFACTOR (Re-architect):
  Criteria: Significant redesign for cloud-native
  Best for: Strategic apps that need scalability/resilience
  Apps: [list]

RETAIN (Keep on-premises):
  Criteria: Cannot move due to latency, compliance, or cost
  Best for: Mainframes, hardware-dependent, regulatory restrictions
  Apps: [list]

RETIRE (Decommission):
  Criteria: No longer needed, redundant, or replaced
  Best for: Legacy apps with no active users
  Apps: [list]

SUMMARY:
| Strategy | Count | % of Portfolio |
|----------|-------|---------------|
| Rehost | ___ | ___% |
| Replatform | ___ | ___% |
| Repurchase | ___ | ___% |
| Refactor | ___ | ___% |
| Retain | ___ | ___% |
| Retire | ___ | ___% |
```

### Step 3 — Dependency Mapping

```
DEPENDENCY ANALYSIS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Application dependency graph created
[ ] Shared databases identified (multi-app databases)
[ ] Shared services identified (auth, logging, messaging)
[ ] External integrations documented (APIs, file transfers)
[ ] Network dependencies mapped (latency-sensitive connections)
[ ] Data gravity analysis (where is the data, what depends on it)

MIGRATION BLOCKERS:
| Blocker | Affected Apps | Mitigation | Owner |
|---------|--------------|------------|-------|
| [blocker] | [apps] | [mitigation] | [name] |
```

### Step 4 — Wave Planning

```
MIGRATION WAVES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Wave 0 — Foundation (Month 1-2):
  [ ] Landing zone / account structure
  [ ] Networking (VPC, VPN/Direct Connect, DNS)
  [ ] Identity (SSO, IAM, RBAC)
  [ ] Security baseline (GuardDuty, Config, CloudTrail)
  [ ] Monitoring and logging infrastructure

Wave 1 — Quick Wins (Month 2-3):
  [ ] Low-risk, low-dependency applications
  [ ] Development/staging environments
  [ ] Internal tools and utilities
  Apps: [list]

Wave 2 — Core Services (Month 3-5):
  [ ] Shared services and platforms
  [ ] Databases and data stores
  [ ] Medium-criticality applications
  Apps: [list]

Wave 3 — Critical Workloads (Month 5-7):
  [ ] Production customer-facing applications
  [ ] High-criticality tier-1 services
  [ ] Data-intensive workloads
  Apps: [list]

Wave 4 — Cleanup (Month 7-9):
  [ ] Remaining applications
  [ ] Legacy migrations requiring refactoring
  [ ] Data center decommissioning
  Apps: [list]
```

### Step 5 — Risk Assessment

```
RISK REGISTER
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
| Risk | Likelihood | Impact | Mitigation | Owner |
|------|-----------|--------|------------|-------|
| Extended downtime during migration | MED | HIGH | Blue-green cutover | [name] |
| Data loss during transfer | LOW | CRITICAL | Checksums + dry run | [name] |
| Performance degradation in cloud | MED | HIGH | Load test pre-cutover | [name] |
| Cost overrun | HIGH | MED | FinOps review per wave | [name] |
| Skills gap | MED | MED | Training + partner support | [name] |
| Compliance violation | LOW | CRITICAL | Pre-migration audit | [name] |
| Vendor lock-in | MED | MED | Multi-cloud abstractions | [name] |
```

### Step 6 — Cost Model

```
COST COMPARISON
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
| Category | Current (Monthly) | Cloud (Monthly) | Delta |
|----------|------------------|-----------------|-------|
| Compute | $___ | $___ | ___% |
| Storage | $___ | $___ | ___% |
| Network | $___ | $___ | ___% |
| Database | $___ | $___ | ___% |
| Licensing | $___ | $___ | ___% |
| Operations/staff | $___ | $___ | ___% |
| **Total** | **$___** | **$___** | **___%** |

Migration one-time costs: $___
Payback period: ___ months
```

## Output Format

Produce a migration assessment report with:
1. **Portfolio summary** with application inventory and 6R classification
2. **Dependency map** with migration blockers identified
3. **Wave plan** with timeline and application assignments
4. **Risk register** with mitigations
5. **Cost model** with current vs cloud comparison
6. **Recommendations** and next steps
