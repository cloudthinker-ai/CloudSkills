---
name: ci-cd-pipeline-review
enabled: true
description: |
  Use when performing ci cd pipeline review — reviews CI/CD pipeline
  configuration for reliability, speed, security, and best practices. Covers
  build optimization, test strategy, deployment patterns, secret management,
  artifact handling, and pipeline-as-code quality to improve developer
  experience and release confidence.
required_connections:
  - prefix: ci-cd
    label: "CI/CD Platform"
config_fields:
  - key: ci_cd_platform
    label: "CI/CD Platform"
    required: true
    placeholder: "e.g., GitHub Actions, GitLab CI, Jenkins, CircleCI"
  - key: primary_language
    label: "Primary Language/Framework"
    required: true
    placeholder: "e.g., Node.js, Java, Python, Go"
  - key: deployment_target
    label: "Deployment Target"
    required: false
    placeholder: "e.g., Kubernetes, AWS Lambda, EC2, Cloud Run"
features:
  - DEVOPS
  - CI_CD
  - AUTOMATION
---

# CI/CD Pipeline Review

## Phase 1: Pipeline Architecture Assessment
1. Map the full pipeline flow
   - [ ] Trigger mechanisms (push, PR, schedule, manual)
   - [ ] Build stages and their sequence
   - [ ] Test stages (unit, integration, e2e, performance)
   - [ ] Security scanning stages
   - [ ] Artifact creation and storage
   - [ ] Deployment stages (staging, canary, production)
   - [ ] Post-deployment validation
2. Document pipeline dependencies and bottlenecks
3. Measure total pipeline duration (P50, P95)

### Pipeline Stage Timing

| Stage | Duration (P50) | Duration (P95) | Failure Rate | Parallelizable |
|-------|---------------|----------------|-------------|---------------|
| Checkout/Setup | | | % | N/A |
| Build | | | % | [ ] |
| Unit Tests | | | % | [ ] |
| Integration Tests | | | % | [ ] |
| Security Scan | | | % | [ ] |
| Artifact Build | | | % | [ ] |
| Deploy Staging | | | % | [ ] |
| E2E Tests | | | % | [ ] |
| Deploy Prod | | | % | [ ] |
| **Total** | | | | |

## Phase 2: Build Optimization
1. Review build performance
   - [ ] Dependency caching configured and effective
   - [ ] Build cache (Docker layer cache, incremental builds)
   - [ ] Parallel execution where possible
   - [ ] Minimal base images for containers
   - [ ] Build matrix efficient (not redundant)
   - [ ] Runner/agent sizing appropriate
2. Identify slow build steps and optimization opportunities

## Phase 3: Test Strategy Review
1. Evaluate test coverage and quality
   - [ ] Unit tests: coverage %, execution time
   - [ ] Integration tests: scope, reliability (flaky test rate)
   - [ ] E2E tests: critical path coverage, stability
   - [ ] Test parallelization and splitting
   - [ ] Test data management strategy
   - [ ] Flaky test handling (quarantine, retry, fix)
2. Assess test feedback loop speed

### Test Pyramid Assessment

| Level | Count | Duration | Coverage | Flaky Rate | Quality |
|-------|-------|----------|----------|-----------|---------|
| Unit | | s | % | % | Good/Fair/Poor |
| Integration | | s | | % | |
| E2E | | s | critical paths | % | |
| Performance | | s | | % | |

## Phase 4: Security & Compliance
1. Review pipeline security
   - [ ] Secrets management (no hardcoded secrets, vault integration)
   - [ ] SAST (static analysis) scanning
   - [ ] SCA (dependency vulnerability) scanning
   - [ ] Container image scanning
   - [ ] DAST (dynamic) scanning for web apps
   - [ ] License compliance checking
   - [ ] SBOM generation
   - [ ] Pipeline permissions (least privilege)
   - [ ] Signed commits and artifacts
2. Review approval gates and compliance controls

## Phase 5: Deployment Strategy Review
1. Assess deployment practices
   - [ ] Blue-green or canary deployment support
   - [ ] Automated rollback capability
   - [ ] Database migration handling
   - [ ] Feature flag integration
   - [ ] Deployment notification (Slack, email)
   - [ ] Post-deployment smoke tests
   - [ ] Environment promotion flow (dev → staging → prod)
   - [ ] Drift detection between environments
2. Review deployment frequency and success rate

## Phase 6: Pipeline-as-Code Quality
1. Review pipeline configuration quality
   - [ ] DRY (reusable workflows, templates, shared libraries)
   - [ ] Version controlled pipeline definitions
   - [ ] Environment-specific configuration separation
   - [ ] Clear naming and documentation
   - [ ] Error handling and failure notifications
   - [ ] Pipeline self-testing (validate on PR)

### Review Summary

| Area | Score (1-5) | Key Finding | Recommendation | Priority |
|------|-----------|-------------|----------------|----------|
| Build Speed | | | | |
| Test Quality | | | | |
| Security | | | | |
| Deployment | | | | |
| Maintainability | | | | |

## Counter-Rationalizations

| Shortcut | Counter | Why |
|----------|---------|-----|
| "We can skip some steps for this case" | Adapt the workflow steps, don't skip them | Skipped steps are where incidents and oversights originate |
| "The user seems to already know what to do" | Complete all workflow phases with the user | The workflow catches blind spots that experience alone misses |
| "This is a minor case, full process is overkill" | Scale the process down, don't turn it off | Minor cases become major when unstructured; the process scales, not disappears |
| "I'll fill in the details later" | Complete each section before moving on | Deferred details are forgotten; real-time capture is more accurate |
| "The template output isn't necessary" | Always produce the structured output format | Structured output enables comparison, audit trails, and handoff to other teams |

## Output Format
- **Pipeline Architecture Diagram**: Visual flow of all stages
- **Performance Report**: Stage timing and bottleneck analysis
- **Security Findings**: Vulnerabilities in pipeline configuration
- **Optimization Recommendations**: Prioritized improvements
- **Best Practices Checklist**: Compliance with CI/CD best practices

## Action Items
- [ ] Map and document current pipeline architecture
- [ ] Measure stage timing and identify bottlenecks
- [ ] Implement build caching and parallelization
- [ ] Address security gaps in pipeline configuration
- [ ] Reduce flaky test rate to < 1%
- [ ] Implement automated rollback capability
- [ ] Document pipeline configuration and runbooks
