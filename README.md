<div align="center">
  <img src="assets/logo.svg" alt="CloudThinker" height="36" />
  <br /><br />

  <h1>CloudSkills</h1>

  <p>
    The open-source community registry of AI skills for cloud engineering.<br />
    Browse, install, and contribute skills that run on <a href="https://cloudthinker.io">CloudThinker</a>.
  </p>

  <a href="https://cloudthinker.io/skills">
    <img src="https://img.shields.io/badge/Browse%20Skills-cloudthinker.io%2Fskills-ec4899?style=for-the-badge" alt="Browse Skills" />
  </a>
  &nbsp;
  <img src="https://img.shields.io/badge/skills-1000+-10b981?style=for-the-badge" alt="1000+ skills" />
  &nbsp;
  <img src="https://img.shields.io/badge/license-MIT-6366f1?style=for-the-badge" alt="MIT" />
  &nbsp;
  <img src="https://img.shields.io/badge/PRs-welcome-f59e0b?style=for-the-badge" alt="PRs welcome" />

  <br /><br />

  <img src="assets/skills.png" alt="CloudThinker Skills" width="560" />

  <br /><br />

</div>

---

## What is CloudSkills?

CloudSkills is the open-source registry powering the [Skills Hub](https://cloudthinker.io/skills) on CloudThinker. Each skill is a `SKILL.md` file — a structured instruction set that tells AI agents how to execute a specific cloud engineering task.

Skills are composable, guardrailed, and ready to deploy. They encode tribal knowledge — runbooks, SOPs, and expert workflows — into reusable AI instructions that run autonomously with human approval gates where needed.

---

## Skill Categories

### Cloud Connection Skills (804+)

Skills that operate on your connected cloud infrastructure and services.

| Category | Examples | Count |
|:---------|:---------|------:|
| **Cloud Providers** | AWS, Azure, GCP, DigitalOcean, Hetzner, Oracle OCI, Linode, IBM Cloud, Alibaba, Vultr, Scaleway | 40+ |
| **CI/CD & GitOps** | Jenkins, GitHub Actions, GitLab CI, ArgoCD, Flux, Tekton, Buildkite, CircleCI, Spinnaker | 25+ |
| **Containers & Orchestration** | Docker, Helm, Istio, Linkerd, Cilium, Kustomize, Rancher, OpenShift, Podman | 30+ |
| **Infrastructure as Code** | Terraform, Pulumi, Ansible, CloudFormation, CDK, Crossplane, Puppet, Chef | 30+ |
| **Databases & Caches** | PostgreSQL, MySQL, MongoDB, Redis, Kafka, Elasticsearch, DynamoDB, Cassandra, ClickHouse, Pinecone, Weaviate | 60+ |
| **Observability & Monitoring** | Datadog, Prometheus, Grafana, Splunk, New Relic, Dynatrace, Honeycomb, Zabbix, OpenTelemetry | 50+ |
| **Security & Compliance** | Snyk, Trivy, Vault, Falco, CrowdStrike, Prisma Cloud, Drata, Vanta, Checkov | 60+ |
| **Networking & CDN** | Nginx, Cloudflare, HAProxy, CoreDNS, Tailscale, Fastly, Akamai, Kong | 30+ |
| **Data Engineering & Analytics** | Airflow, dbt, Spark, Flink, Snowflake, BigQuery, Segment, Mixpanel, Tableau | 40+ |
| **AI/ML Platforms** | SageMaker, Vertex AI, MLflow, Kubeflow, Hugging Face, OpenAI, Anthropic | 25+ |
| **Serverless & Edge** | Lambda, Cloud Functions, Cloudflare Workers, Vercel, Netlify, Fly.io, Deno Deploy | 30+ |
| **Developer Tools** | SonarQube, Turborepo, Bazel, Codecov, Pre-commit, Renovate, Semantic Release | 30+ |
| **Incident Management** | PagerDuty, OpsGenie, incident.io, FireHydrant, Rootly, Grafana OnCall | 25+ |
| **IT Service Management** | ServiceNow, Zendesk, Freshservice, Jira Service Management, GLPI | 15+ |
| **Feature Flags** | LaunchDarkly, Split.io, Flagsmith, Unleash, GrowthBook, Statsig | 12+ |
| **Code Review** | GitHub PR Reviews, GitLab MRs, Gerrit, CodeRabbit, CodeScene, Sourcery | 15+ |
| **Identity & Access** | Okta, Auth0, Keycloak, AWS IAM, Azure Entra, CyberArk | 15+ |
| **Communication & Collaboration** | Slack, Teams, Discord, Notion, Confluence, Jira, Trello, Linear | 30+ |
| **Workflow Automation** | Zapier, Temporal, n8n, Windmill, Pipedream, Power Automate | 20+ |
| **Low-Code & CMS** | Appsmith, Retool, Strapi, Contentful, Sanity, Directus | 15+ |
| **FinOps & Cost** | Kubecost, Infracost, Spot.io, Cast AI, Vantage, CloudHealth | 15+ |
| **Storage & Backup** | MinIO, Ceph, Velero, S3, Cloudflare R2, Backblaze B2 | 15+ |
| **Package Registries** | npm, PyPI, Cargo, NuGet, Docker Hub, Harbor, Artifactory | 15+ |

### Template Skills (200+)

Reusable workflow templates for common cloud engineering processes.

| Category | Examples | Count |
|:---------|:---------|------:|
| **Deployment** | Deployment Checklist, Blue-Green, Canary, Zero-Downtime Migration | 15+ |
| **Incident Response** | Incident Runbook, Severity Classification, War Room Protocol, Root Cause Analysis | 25+ |
| **Security & Compliance** | Security Audit, SOC2, HIPAA, PCI-DSS, GDPR, CIS Benchmarks, Threat Modeling | 15+ |
| **Code Review** | PR Review Checklist, Security Code Review, Performance Review, IaC Review | 15+ |
| **IT HelpDesk** | Employee Onboarding/Offboarding, Access Requests, VPN Troubleshooting, Asset Management | 15+ |
| **SRE & Reliability** | SLO Workshop, Error Budget Review, Chaos Engineering, Alert Fatigue Reduction | 15+ |
| **Architecture & Design** | System Design Document, ADR Template, RFC Template, API Contract Review | 15+ |
| **Cost Optimization** | Cost Optimization Report, FinOps Maturity Assessment, Capacity Planning | 10+ |
| **Team & Process** | Sprint Retrospective, OKR Tracking, Onboarding Checklist, Knowledge Transfer | 15+ |
| **Performance** | Load Testing Plan, Database Tuning, CDN Optimization, Caching Strategy Review | 10+ |

---

## Installing a Skill

**One-click via CloudThinker**

Visit [cloudthinker.io/skills](https://cloudthinker.io/skills), find a skill, and click **Install**. The skill is copied directly into your workspace — no GitHub dependency at runtime.

**Manually**

Copy a `SKILL.md` into your project's skills directory:

```bash
mkdir -p .claude/skills/aws
curl -o .claude/skills/aws/SKILL.md \
  https://raw.githubusercontent.com/cloudthinker-ai/CloudSkills/main/skills/connections/aws/SKILL.md
```

---

## Skill Format

Every skill is a single `SKILL.md` file with YAML frontmatter:

```markdown
---
name: my-skill
description: |
  What this skill does and when to invoke it.
connection_type: aws   # optional — required connection
---

# My Skill

Step-by-step instructions for the AI agent...
```

| Field | Required | Description |
|:------|:--------:|:------------|
| `name` | Yes | Kebab-case identifier matching the directory name |
| `description` | Yes | Purpose and context for when to use this skill |
| `connection_type` | — | Required cloud connection (e.g. `aws`, `k8s`, `github`) |

**Connection skills** (`skills/connections/`) integrate with specific tools and services via API keys, CLI tools, or OAuth connections.

**Template skills** (`skills/templates/`) provide structured workflows, checklists, and runbooks that guide agents through multi-step processes.

See [SPEC.md](SPEC.md) for the full specification.

---

## Contributing

We welcome skills that encode real-world cloud engineering expertise.

1. **Fork** this repository
2. **Create** `skills/connections/<your-skill>/SKILL.md` or `skills/templates/<your-skill>/SKILL.md`
3. **Open a pull request** — CI validates your skill automatically
4. **After merge**, the skill appears on CloudThinker within 1 hour

Read [CONTRIBUTING.md](CONTRIBUTING.md) for the quality checklist and review process.

---

## License

MIT — see [LICENSE](LICENSE)

<div align="center">
  <br />
  <sub>Built with care by <a href="https://cloudthinker.io">CloudThinker</a></sub>
</div>
