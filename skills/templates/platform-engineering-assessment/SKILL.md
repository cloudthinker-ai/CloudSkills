---
name: platform-engineering-assessment
enabled: true
description: |
  Assesses the maturity and effectiveness of an organization's internal developer platform (IDP). Covers self-service capabilities, developer experience, golden paths, platform team structure, adoption metrics, and roadmap for building a platform that accelerates software delivery.
required_connections:
  - prefix: project-management
    label: "Project Management Tool"
config_fields:
  - key: organization_name
    label: "Organization Name"
    required: true
    placeholder: "e.g., Acme Corp Engineering"
  - key: developer_count
    label: "Number of Developers Using Platform"
    required: true
    placeholder: "e.g., 200"
  - key: platform_stage
    label: "Current Platform Stage"
    required: false
    placeholder: "e.g., no platform, early stage, growing, mature"
features:
  - DEVOPS
  - PLATFORM_ENGINEERING
  - ASSESSMENT
---

# Platform Engineering Assessment

## Phase 1: Platform Capabilities Inventory
1. Catalog current platform capabilities
   - [ ] Infrastructure provisioning (self-service)
   - [ ] Application scaffolding / service templates
   - [ ] CI/CD pipeline templates
   - [ ] Environment management (create, clone, destroy)
   - [ ] Secrets management
   - [ ] Observability stack (logging, metrics, tracing)
   - [ ] Service catalog / developer portal
   - [ ] Database provisioning
   - [ ] API gateway / service mesh
   - [ ] Cost visibility per team/service
2. Identify capabilities that are manual or missing
3. Map capabilities to developer journey stages

### Capability Maturity Matrix

| Capability | Not Available | Manual/Ticket | Partially Automated | Self-Service | Fully Managed | Current |
|-----------|-------------|-------------|-------------------|-------------|---------------|---------|
| Infra provisioning | [ ] | [ ] | [ ] | [ ] | [ ] | |
| App scaffolding | [ ] | [ ] | [ ] | [ ] | [ ] | |
| CI/CD | [ ] | [ ] | [ ] | [ ] | [ ] | |
| Environments | [ ] | [ ] | [ ] | [ ] | [ ] | |
| Observability | [ ] | [ ] | [ ] | [ ] | [ ] | |
| Secrets | [ ] | [ ] | [ ] | [ ] | [ ] | |
| Databases | [ ] | [ ] | [ ] | [ ] | [ ] | |

## Phase 2: Developer Experience Assessment
1. Evaluate developer experience
   - [ ] Time from idea to first deployment (new service)
   - [ ] Time to onboard a new developer
   - [ ] Cognitive load on developers (infra knowledge required)
   - [ ] Number of tools developers must interact with
   - [ ] Documentation quality and discoverability
   - [ ] Developer satisfaction scores (survey)
2. Identify top developer pain points
3. Measure self-service adoption rate

### Developer Experience Metrics

| Metric | Current | Target | Industry Benchmark |
|--------|---------|--------|-------------------|
| New service time-to-deploy | days | < 1 day | Hours |
| Developer onboarding time | days | < 5 days | 1 week |
| Tools to learn | count | < 5 | 3-5 |
| Self-service adoption | % | > 80% | 70%+ |
| Developer satisfaction (NPS) | | > 30 | 20-40 |

## Phase 3: Golden Paths & Standards
1. Evaluate golden paths (paved roads)
   - [ ] Standardized service templates exist
   - [ ] Templates cover common architectures (API, worker, frontend)
   - [ ] Templates include CI/CD, monitoring, security by default
   - [ ] Templates are maintained and updated regularly
   - [ ] Deviation from golden path is possible but requires justification
   - [ ] Inner-source contribution model for templates
2. Assess standardization vs. flexibility balance

## Phase 4: Platform Team Assessment
1. Evaluate platform team structure and practices
   - [ ] Dedicated platform team exists
   - [ ] Team treats platform as a product (product management, roadmap)
   - [ ] User research conducted with internal developers
   - [ ] Platform backlog prioritized by developer impact
   - [ ] Platform SLOs defined and tracked
   - [ ] On-call rotation for platform services
   - [ ] Platform team size appropriate (1 platform engineer per 10-15 developers)
2. Assess platform team skills and capacity

## Phase 5: Adoption & Impact Metrics
1. Measure platform adoption and impact
   - [ ] Percentage of services using platform capabilities
   - [ ] Deployment frequency (platform users vs. non-users)
   - [ ] Lead time improvement from platform adoption
   - [ ] Incident rate (platform vs. non-platform services)
   - [ ] Developer time saved per week
   - [ ] Cost efficiency improvements
2. Identify barriers to adoption

### Platform Impact Dashboard

| Metric | Platform Users | Non-Platform Users | Improvement |
|--------|---------------|-------------------|-------------|
| Deploy frequency | /week | /week | x |
| Lead time | hours | hours | x |
| Change failure rate | % | % | -% |
| MTTR | min | min | -% |

## Phase 6: Improvement Roadmap
1. Prioritize platform improvements by developer impact
2. Plan capability buildout sequence
3. Define adoption targets and timeline
4. Plan team growth and skill development
5. Establish platform product management practices

## Output Format
- **Capability Inventory**: Current platform capabilities and gaps
- **Developer Experience Report**: Pain points and satisfaction metrics
- **Golden Path Assessment**: Template coverage and quality
- **Adoption Metrics**: Usage and impact data
- **Platform Roadmap**: Prioritized improvement plan

## Action Items
- [ ] Catalog all current platform capabilities
- [ ] Survey developers on pain points and satisfaction
- [ ] Measure key developer experience metrics
- [ ] Assess golden path coverage and quality
- [ ] Identify highest-impact platform improvements
- [ ] Develop phased platform roadmap
- [ ] Establish platform product management practices
