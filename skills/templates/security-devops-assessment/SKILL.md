---
name: security-devops-assessment
enabled: true
description: |
  Assesses the integration of security practices into DevOps workflows (DevSecOps). Covers shift-left security, automated security testing in CI/CD, supply chain security, runtime protection, security culture, and vulnerability management maturity.
required_connections:
  - prefix: ci-cd
    label: "CI/CD Platform"
  - prefix: security-tools
    label: "Security Scanning Tools"
config_fields:
  - key: organization_name
    label: "Organization Name"
    required: true
    placeholder: "e.g., Acme Corp Engineering"
  - key: ci_cd_platform
    label: "CI/CD Platform"
    required: true
    placeholder: "e.g., GitHub Actions, GitLab CI, Jenkins"
  - key: primary_languages
    label: "Primary Languages"
    required: false
    placeholder: "e.g., Java, Python, Go, TypeScript"
features:
  - DEVOPS
  - SECURITY
  - DEVSECOPS
---

# Security DevOps (DevSecOps) Assessment

## Phase 1: Shift-Left Security Assessment
1. Evaluate pre-commit security practices
   - [ ] Pre-commit hooks for secret detection
   - [ ] IDE security plugins/linters
   - [ ] Secure coding guidelines published
   - [ ] Security training for developers (annual)
   - [ ] Threat modeling in design phase
   - [ ] Security champions program in dev teams
2. Score: 1 (No shift-left) to 5 (Security embedded in design)

### Security in Development Lifecycle

| Phase | Security Activity | Implemented | Automated | Blocking |
|-------|-------------------|-------------|-----------|----------|
| Design | Threat modeling | [ ] | N/A | N/A |
| Code | Secret scanning | [ ] | [ ] | [ ] |
| Code | SAST | [ ] | [ ] | [ ] |
| Build | SCA (dependency scan) | [ ] | [ ] | [ ] |
| Build | Container image scan | [ ] | [ ] | [ ] |
| Test | DAST | [ ] | [ ] | [ ] |
| Deploy | IaC security scan | [ ] | [ ] | [ ] |
| Runtime | RASP/WAF | [ ] | [ ] | N/A |
| Operate | Vulnerability management | [ ] | [ ] | N/A |

## Phase 2: CI/CD Pipeline Security
1. Evaluate security scanning in pipelines
   - [ ] SAST (Static Application Security Testing) integrated
   - [ ] SCA (Software Composition Analysis) for dependencies
   - [ ] Container image vulnerability scanning
   - [ ] IaC scanning (Terraform, CloudFormation, Kubernetes)
   - [ ] Secret detection in code and configs
   - [ ] License compliance checking
   - [ ] SBOM (Software Bill of Materials) generation
   - [ ] Scan results break builds for critical findings
2. Measure scan coverage and false positive rates

### Pipeline Security Scan Coverage

| Scan Type | Tool | Repos Covered | Auto-Run | Blocking | False Positive Rate |
|-----------|------|-------------|---------|----------|-------------------|
| SAST | | % | [ ] | [ ] | % |
| SCA | | % | [ ] | [ ] | % |
| Container | | % | [ ] | [ ] | % |
| IaC | | % | [ ] | [ ] | % |
| Secrets | | % | [ ] | [ ] | % |

## Phase 3: Supply Chain Security
1. Evaluate software supply chain security
   - [ ] Dependency pinning (lockfiles committed)
   - [ ] Private registry/mirror for packages
   - [ ] Dependency update automation (Dependabot, Renovate)
   - [ ] SBOM generation and storage
   - [ ] Signed commits enforced
   - [ ] Signed container images (cosign, Notary)
   - [ ] SLSA framework compliance level
   - [ ] Third-party code review process
2. Score: 1 (No controls) to 5 (SLSA Level 3+)

## Phase 4: Runtime Security
1. Evaluate production security controls
   - [ ] Web Application Firewall (WAF) deployed
   - [ ] Runtime application protection (RASP)
   - [ ] Network segmentation and policies
   - [ ] Container runtime security (Falco, Sysdig)
   - [ ] Workload identity and least-privilege IAM
   - [ ] Secrets management (Vault, cloud KMS)
   - [ ] Encryption in transit and at rest
   - [ ] API security (rate limiting, auth, input validation)
2. Score: 1 (Perimeter only) to 5 (Defense in depth)

## Phase 5: Vulnerability Management
1. Evaluate vulnerability management process
   - [ ] Vulnerability scanning schedule (continuous, weekly, monthly)
   - [ ] SLA for remediation by severity (critical: 7 days, etc.)
   - [ ] Vulnerability tracking and metrics
   - [ ] Exception/risk acceptance process
   - [ ] Patch management automation
   - [ ] Vulnerability trending and reporting
2. Measure vulnerability management metrics

### Vulnerability Metrics

| Metric | Current | Target | Status |
|--------|---------|--------|--------|
| Open critical vulns | | 0 | |
| Open high vulns | | < | |
| Mean time to remediate (critical) | days | < 7 days | |
| Mean time to remediate (high) | days | < 30 days | |
| Scan coverage | % | 100% | |

## Phase 6: Security Culture & Governance
1. Evaluate security culture
   - [ ] Security champions in each dev team
   - [ ] Regular security training and awareness
   - [ ] Security considered in sprint planning
   - [ ] Bug bounty or responsible disclosure program
   - [ ] Security metrics reported to leadership
   - [ ] Compliance automation (SOC 2, ISO 27001)
2. Score: 1 (Security is separate team only) to 5 (Security is everyone's job)

### Overall DevSecOps Maturity

| Dimension | Score (1-5) | Key Strength | Priority Gap |
|-----------|-----------|-------------|-------------|
| Shift-Left | | | |
| Pipeline Security | | | |
| Supply Chain | | | |
| Runtime Security | | | |
| Vulnerability Mgmt | | | |
| Culture & Governance | | | |
| **Overall** | **/5** | | |

## Output Format
- **Maturity Scorecard**: Per-dimension scores with evidence
- **Pipeline Security Gaps**: Missing scans and coverage
- **Vulnerability Report**: Open findings and remediation SLA compliance
- **Supply Chain Assessment**: SLSA compliance level
- **Improvement Roadmap**: Prioritized DevSecOps initiatives

## Action Items
- [ ] Integrate missing security scans into CI/CD pipelines
- [ ] Establish vulnerability remediation SLAs
- [ ] Implement supply chain security controls
- [ ] Launch security champions program
- [ ] Automate SBOM generation and tracking
- [ ] Set up security metrics dashboard for leadership
- [ ] Schedule quarterly DevSecOps maturity review
