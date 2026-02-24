<h1 align="center">☁️ CloudSkills</h1>

<p align="center">
  <strong>Open-Source Operational Intelligence Skills for Autonomous Cloud Management</strong>
</p>

<p align="center">
  <a href="#skill-categories">Skills</a> •
  <a href="#skill-structure">Structure</a> •
  <a href="#contributing">Contributing</a> •
  <a href="#community--support">Community</a>
</p>

<p align="center">
  <a href="https://github.com/cloudthinker-ai/CloudSkills/blob/main/LICENSE"><img src="https://img.shields.io/badge/license-Apache%202.0-blue.svg" alt="License"></a>
  <a href="https://github.com/cloudthinker-ai/CloudSkills/stargazers"><img src="https://img.shields.io/github/stars/cloudthinker-ai/CloudSkills" alt="Stars"></a>
  <a href="https://github.com/cloudthinker-ai/CloudSkills/issues"><img src="https://img.shields.io/github/issues/cloudthinker-ai/CloudSkills" alt="Issues"></a>
  <a href="https://discord.com/invite/sRBWRWtaNR"><img src="https://img.shields.io/badge/discord-join-7289da.svg" alt="Discord"></a>
  <a href="https://www.linkedin.com/company/cloud-thinker/"><img src="https://img.shields.io/badge/LinkedIn-follow-0A66C2.svg" alt="LinkedIn"></a>
</p>

---

## What is CloudSkills?

**CloudSkills** is [CloudThinker's](https://www.cloudthinker.io) open-source collection of operational skills for autonomous cloud infrastructure management. Each skill is a self-contained unit of cloud operational intelligence — designed to be discovered, chained, and executed by AI agents across AWS, GCP, and Azure.

CloudSkills powers **VibeOps** and **AIOps** workflows within the [CloudThinker platform](https://www.cloudthinker.io/skills).

```
"Investigate why our API latency spiked in the last hour"
     ↓
CloudThinker agents discover and chain the right skills:
     ↓
[metric-query] → [log-correlation] → [trace-analysis] → [root-cause-report]
```

---

## Skill Categories

### 🔍 Investigate

Skills for real-time diagnostics, troubleshooting, and incident triage.

| Skill | Description | Clouds |
|-------|-------------|--------|
| `log-correlation` | Correlate logs across services to identify failure chains | AWS, GCP, Azure |
| `trace-analysis` | Distributed tracing analysis with latency breakdown | AWS, GCP |
| `health-check` | Multi-service health assessment with dependency mapping | AWS, GCP, Azure |
| `network-diagnostics` | VPC flow log analysis and connectivity troubleshooting | AWS, GCP, Azure |
| `pod-triage` | Kubernetes pod failure analysis and remediation suggestions | EKS, GKE, AKS |

### 📊 Analyze

Skills for cost optimization, performance analysis, and capacity planning.

| Skill | Description | Clouds |
|-------|-------------|--------|
| `cost-anomaly-detection` | Detect unusual spending patterns with ML-based baselines | AWS, GCP, Azure |
| `instance-rightsizing` | Compute optimization recommendations based on actual usage | AWS, GCP, Azure |
| `capacity-forecast` | Predict resource needs based on historical trends | AWS, GCP |
| `performance-profiling` | Application performance bottleneck identification | AWS, GCP, Azure |
| `unused-resource-scan` | Find and flag idle or orphaned cloud resources | AWS, GCP, Azure |

### 🚀 Create

Skills for provisioning, deployment, and infrastructure automation.

| Skill | Description | Clouds |
|-------|-------------|--------|
| `infra-scaffold` | Generate IaC templates from natural language descriptions | AWS, GCP, Azure |
| `auto-scaling-config` | Intelligent auto-scaling policy generation | AWS, GCP |
| `security-group-builder` | Least-privilege network policy generation | AWS, GCP, Azure |
| `pipeline-generator` | CI/CD pipeline scaffolding for common frameworks | AWS, GCP, Azure |
| `k8s-manifest-builder` | Kubernetes manifest generation with best practices | EKS, GKE, AKS |

### 🛡️ Review

Skills for security auditing, compliance checking, and operational review.

| Skill | Description | Clouds |
|-------|-------------|--------|
| `security-posture` | Comprehensive security configuration assessment | AWS, GCP, Azure |
| `compliance-check` | Policy compliance validation (SOC 2, HIPAA, PCI-DSS) | AWS, GCP, Azure |
| `iam-audit` | Identity and access management review with risk scoring | AWS, GCP, Azure |
| `drift-detection` | Infrastructure drift detection against IaC state | AWS, GCP, Azure |
| `incident-review` | Post-incident analysis with timeline reconstruction | AWS, GCP, Azure |

---

## Skill Structure

Every skill follows a standard structure:

```
skills/
└── aws/
    └── cost-anomaly-detection/
        ├── skill.yaml          # Metadata, inputs/outputs, permissions
        ├── handler.py          # Core skill logic
        ├── tests/              # Unit and integration tests
        ├── simulations/        # Dry-run simulation data
        └── README.md           # Skill documentation
```

### skill.yaml

```yaml
name: cost-anomaly-detection
version: 1.2.0
category: analyze
description: Detect unusual cloud spending patterns using ML-based baselines
clouds:
  - aws
  - gcp
  - azure

inputs:
  - name: timeframe
    type: string
    default: "7d"
  - name: sensitivity
    type: float
    default: 0.8

outputs:
  - name: anomalies
    type: list

permissions:
  aws:
    - ce:GetCostAndUsage
    - ce:GetCostForecast
  gcp:
    - billing.accounts.getSpendingInformation
  azure:
    - Microsoft.CostManagement/query/action

tags:
  - finops
  - cost-optimization
  - anomaly-detection
```

---

## Related Projects

| Repository | Description |
|-----------|-------------|
| [CloudThinker](https://github.com/cloudthinker-ai/CloudThinker) | Main CloudThinker platform repository |
| [mcp-manager](https://github.com/Cloud-Thinker-AI/mcp-manager) | Unified CLI and daemon to manage multiple MCP servers |
| [aws-cli-mcp-server](https://github.com/Cloud-Thinker-AI/aws-cli-mcp-server) | MCP server bridge for executing AWS CLI commands |
| [postgres-mcp-pro-plus](https://github.com/Cloud-Thinker-AI/postgres-mcp-pro-plus) | PostgreSQL MCP server with advanced features |
| [mysql-mcp-pro-plus](https://github.com/Cloud-Thinker-AI/mysql_mcp_pro_plus) | MySQL MCP server with advanced features |

---

## Contributing

We welcome contributions! Whether it's a new skill, bug fix, or documentation improvement — every contribution helps.

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feat/my-new-skill`)
3. **Add** your skill following the [Skill Structure](#skill-structure)
4. **Test** your skill thoroughly
5. **Submit** a Pull Request

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines.

---

## Community & Support

### Get Help

- 📖 **[Documentation](https://docs.cloudthinker.io)** — Full platform docs
- 💬 **[Discord](https://discord.com/invite/sRBWRWtaNR)** — Chat with the team and community
- 🐛 **[GitHub Issues](https://github.com/cloudthinker-ai/CloudSkills/issues)** — Bug reports and feature requests
- 📧 **[Contact Us](https://www.cloudthinker.io/contact)** — Reach our team directly
- 📅 **[Book a Demo](https://calendar.google.com/calendar/u/0/appointments/schedules/AcZssZ2KcbytbqL4G9hl7apqhMrg9eTn9oQyHcTYWOV_RuRz2mnH5XiJP0wuRgIUluIPH6BEtEBPoXE6)** — Schedule a walkthrough

### Follow Us

- 🔗 **[LinkedIn](https://www.linkedin.com/company/cloud-thinker/)** — Company updates
- 🎥 **[YouTube](https://www.youtube.com/@CloudThinker-1224)** — Tutorials and demos
- 📘 **[Facebook](https://www.facebook.com/profile.php?id=61575949122542)** — Community updates
- 🐙 **[GitHub](https://github.com/Cloud-Thinker-AI)** — All open-source projects
- 📝 **[Blog](https://www.cloudthinker.io/blogs)** — Technical deep dives

### Programs

- 🤝 **[Affiliate Program](https://www.cloudthinker.io/affiliate)** — Partner with CloudThinker
- 💼 **[Careers](https://www.cloudthinker.io/careers)** — Join the team
- ☁️ **[AWS Marketplace](https://aws.amazon.com/marketplace/pp/prodview-cdndshu72ks6s)** — Deploy via AWS

---

## License

CloudSkills is open-source software licensed under the [Apache License 2.0](LICENSE).

---

<p align="center">
  Built with ❤️ by <a href="https://www.cloudthinker.io">CloudThinker</a> — Thu Duc City, Ho Chi Minh City, Vietnam
  <br/><br/>
  <a href="https://www.cloudthinker.io"><img src="https://img.shields.io/badge/Website-cloudthinker.io-blue" alt="Website"></a>
  <a href="https://discord.com/invite/sRBWRWtaNR"><img src="https://img.shields.io/badge/Discord-Join-7289da" alt="Discord"></a>
  <a href="https://www.linkedin.com/company/cloud-thinker/"><img src="https://img.shields.io/badge/LinkedIn-Follow-0A66C2" alt="LinkedIn"></a>
  <a href="https://www.youtube.com/@CloudThinker-1224"><img src="https://img.shields.io/badge/YouTube-Subscribe-FF0000" alt="YouTube"></a>
  <br/><br/>
  <em>VibeOps — Describe intent, not procedures.</em>
  <br/><br/>
  <img src="https://img.shields.io/badge/AWS-Partner-FF9900" alt="AWS Partner">
  <img src="https://img.shields.io/badge/Google-Cloud%20Startup-4285F4" alt="Google Cloud Startup">
  <img src="https://img.shields.io/badge/SOC%202-Type%20I%20%26%20II-green" alt="SOC 2">
</p>
