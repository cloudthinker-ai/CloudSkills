---
name: cloud-cost-allocation-model
enabled: true
description: |
  Use when performing cloud cost allocation model — designs a cost allocation
  and chargeback model for cloud spending across teams, projects, and
  environments. Covers tagging strategy, allocation rules for shared services,
  showback/chargeback reporting, and budgeting integration to drive
  accountability and optimize spending.
required_connections:
  - prefix: cloud-billing
    label: "Cloud Billing Account"
config_fields:
  - key: cloud_provider
    label: "Cloud Provider"
    required: true
    placeholder: "e.g., AWS, GCP, Azure"
  - key: org_structure
    label: "Organization Structure"
    required: true
    placeholder: "e.g., business units, product teams, cost centers"
  - key: monthly_spend
    label: "Approximate Monthly Cloud Spend"
    required: false
    placeholder: "e.g., $150,000"
features:
  - COST_MANAGEMENT
  - FINOPS
---

# Cloud Cost Allocation Model

## Phase 1: Define Allocation Hierarchy
1. Map organizational structure for cost ownership
   - [ ] Business units / departments
   - [ ] Product teams / squads
   - [ ] Environments (prod, staging, dev, sandbox)
   - [ ] Projects or initiatives
2. Identify cost centers and budget owners
3. Define allocation granularity (team, project, environment)
4. Determine showback vs. chargeback model

### Allocation Model Decision

| Factor | Showback | Chargeback | Hybrid |
|--------|----------|------------|--------|
| Organizational maturity | Low | High | Medium |
| Executive sponsorship | Optional | Required | Recommended |
| Behavioral impact | Awareness | Accountability | Balanced |
| Implementation effort | Low | High | Medium |
| Selected | [ ] | [ ] | [ ] |

## Phase 2: Tagging Strategy
1. Define mandatory tags for all resources
   - [ ] `team` - owning team
   - [ ] `environment` - prod/staging/dev/sandbox
   - [ ] `project` - project or product name
   - [ ] `cost-center` - financial cost center code
   - [ ] `managed-by` - terraform/manual/other
2. Define optional enrichment tags
3. Implement tag enforcement policies
4. Plan remediation for untagged resources
5. Set up tag compliance monitoring

## Phase 3: Shared Cost Allocation Rules
1. Identify shared services and infrastructure
   - [ ] Networking (VPC, load balancers, NAT gateways)
   - [ ] Security (WAF, firewalls, key management)
   - [ ] Monitoring and logging platforms
   - [ ] CI/CD infrastructure
   - [ ] Shared databases or caches
2. Define allocation method per shared service

### Shared Cost Allocation Methods

| Shared Service | Proportional (usage) | Even Split | Fixed Ratio | Custom Formula |
|---------------|---------------------|------------|-------------|----------------|
| Networking    | [ ]                 | [ ]        | [ ]         | [ ]            |
| Security      | [ ]                 | [ ]        | [ ]         | [ ]            |
| Monitoring    | [ ]                 | [ ]        | [ ]         | [ ]            |
| CI/CD         | [ ]                 | [ ]        | [ ]         | [ ]            |

## Phase 4: Reporting & Dashboards
1. Build cost allocation dashboards by team, project, environment
2. Create monthly cost reports for budget owners
3. Implement anomaly detection for unexpected spend
4. Track unit economics (cost per transaction, cost per user)
5. Generate trend reports for capacity planning

## Phase 5: Budget Integration
1. Set budgets per team and project aligned to fiscal calendar
2. Configure budget alerts at 50%, 75%, 90%, 100% thresholds
3. Implement approval workflows for budget overruns
4. Create quarterly budget review cadence
5. Feed allocation data into financial planning tools

## Counter-Rationalizations

| Shortcut | Counter | Why |
|----------|---------|-----|
| "We can skip some steps for this case" | Adapt the workflow steps, don't skip them | Skipped steps are where incidents and oversights originate |
| "The user seems to already know what to do" | Complete all workflow phases with the user | The workflow catches blind spots that experience alone misses |
| "This is a minor case, full process is overkill" | Scale the process down, don't turn it off | Minor cases become major when unstructured; the process scales, not disappears |
| "I'll fill in the details later" | Complete each section before moving on | Deferred details are forgotten; real-time capture is more accurate |
| "The template output isn't necessary" | Always produce the structured output format | Structured output enables comparison, audit trails, and handoff to other teams |

## Output Format
- **Tagging Policy Document**: Required and optional tags with enforcement rules
- **Allocation Rules**: Shared cost distribution methodology
- **Dashboard Templates**: Cost views by team, project, environment
- **Monthly Report Template**: Standardized cost report for stakeholders
- **Budget Template**: Per-team budget with alert thresholds

## Action Items
- [ ] Get executive sponsorship for allocation model
- [ ] Define and publish tagging policy
- [ ] Implement tag enforcement and remediation
- [ ] Build cost allocation dashboards
- [ ] Distribute first monthly allocation reports
- [ ] Establish quarterly budget review meetings
