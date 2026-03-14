---
name: gitops-maturity-assessment
enabled: true
description: |
  Assesses an organization's GitOps adoption maturity across declarative configuration, version control practices, automated reconciliation, and observability. Evaluates adherence to GitOps principles and produces a roadmap for advancing to a fully automated, Git-driven operations model.
required_connections:
  - prefix: git
    label: "Git Repository Platform"
  - prefix: k8s
    label: "Kubernetes Cluster"
config_fields:
  - key: gitops_tool
    label: "GitOps Tool in Use"
    required: true
    placeholder: "e.g., ArgoCD, Flux, none yet"
  - key: cluster_count
    label: "Number of Kubernetes Clusters"
    required: true
    placeholder: "e.g., 5"
  - key: team_count
    label: "Number of Development Teams"
    required: false
    placeholder: "e.g., 12"
features:
  - DEVOPS
  - GITOPS
  - KUBERNETES
---

# GitOps Maturity Assessment

## Phase 1: GitOps Principles Evaluation
1. Assess adherence to core GitOps principles
   - [ ] Declarative: All desired state described declaratively
   - [ ] Versioned: Desired state stored in Git with full history
   - [ ] Automated: Approved changes applied automatically
   - [ ] Reconciled: Software agents continuously enforce desired state

### Principles Maturity

| Principle | Level 0 (None) | Level 1 (Partial) | Level 2 (Mostly) | Level 3 (Full) | Current |
|-----------|---------------|-------------------|------------------|---------------|---------|
| Declarative | Manual/imperative | Some manifests | Most resources | 100% declarative | |
| Versioned | No VCS for ops | Some in Git | Most in Git | All in Git, reviewed | |
| Automated | Manual apply | CI-triggered | Pull-based sync | Auto-reconcile | |
| Reconciled | No drift check | Manual checks | Periodic sync | Continuous reconcile | |

## Phase 2: Repository Structure Assessment
1. Evaluate Git repository organization
   - [ ] App repos separate from config/infra repos
   - [ ] Environment-specific configurations (overlays/patches)
   - [ ] Branching strategy for promotions (branch-per-env vs. directory-per-env)
   - [ ] Secrets management (sealed secrets, external secrets, vault)
   - [ ] Helm charts / Kustomize overlays well-structured
   - [ ] Consistent naming conventions
2. Review PR/merge workflow for config changes
3. Assess who has write access to production configs

### Repository Structure Review

| Aspect | Current State | Best Practice | Gap |
|--------|-------------|---------------|-----|
| Repo separation | | App + config repos | |
| Env management | | Directory or overlay per env | |
| Secret handling | | External secrets operator | |
| Templating | | Kustomize or Helm | |
| Access control | | PR required, restricted merge | |

## Phase 3: Automation & Tooling
1. Evaluate GitOps tooling
   - [ ] GitOps controller deployed (ArgoCD/Flux)
   - [ ] Automated sync enabled
   - [ ] Drift detection and alerting
   - [ ] Health checks for deployed resources
   - [ ] Rollback capability (Git revert triggers rollback)
   - [ ] Multi-cluster management
   - [ ] Progressive delivery (canary/blue-green via GitOps)
   - [ ] Policy enforcement (OPA/Kyverno)
2. Assess automation coverage

## Phase 4: Observability & Compliance
1. Evaluate GitOps observability
   - [ ] Sync status dashboards
   - [ ] Deployment history and audit trail
   - [ ] Drift detection alerts
   - [ ] Resource health monitoring
   - [ ] Git commit to deployment traceability
2. Assess compliance benefits
   - [ ] All changes auditable through Git history
   - [ ] Approval workflow enforced via PRs
   - [ ] Segregation of duties (dev vs. ops approvals)
   - [ ] Change evidence automatically generated

### Maturity Scorecard

| Dimension | Score (1-5) | Evidence | Key Gap |
|-----------|-----------|----------|---------|
| Declarative configuration | | | |
| Version control practices | | | |
| Automated reconciliation | | | |
| Drift management | | | |
| Multi-env management | | | |
| Secret management | | | |
| Observability | | | |
| Compliance/audit | | | |
| **Overall** | **/5** | | |

## Phase 5: Improvement Roadmap
1. Identify quick wins for GitOps adoption
2. Plan migration path for non-GitOps workloads
3. Design multi-cluster GitOps architecture
4. Plan progressive delivery integration
5. Define team training and onboarding plan

## Output Format
- **Principles Assessment**: Adherence to four GitOps principles
- **Maturity Scorecard**: Per-dimension maturity with evidence
- **Repository Review**: Structure assessment and recommendations
- **Tooling Evaluation**: Current tools and gaps
- **Improvement Roadmap**: Phased plan to advance maturity

## Action Items
- [ ] Assess current GitOps principles adherence
- [ ] Review repository structure and access controls
- [ ] Evaluate automation and tooling coverage
- [ ] Identify workloads not yet under GitOps management
- [ ] Develop phased improvement roadmap
- [ ] Plan training for teams new to GitOps
- [ ] Schedule quarterly re-assessment
