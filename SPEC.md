# CloudSkills Specification

This document defines the structure and conventions for skills in the CloudSkills registry.

---

## Skill Types

### Connection Skills

Located in `skills/connections/<skill-id>/SKILL.md`. These integrate with specific tools, services, or cloud providers.

**Frontmatter:**

```yaml
---
name: skill-id                # kebab-case, matches directory name
description: |
  What this skill does and when to invoke it.
connection_type: tool-name    # required cloud/tool connection
preload: false                # whether to preload in agent context
---
```

| Field | Required | Description |
|:------|:--------:|:------------|
| `name` | Yes | Kebab-case identifier matching the directory name |
| `description` | Yes | One paragraph explaining purpose, scope, and when to use |
| `connection_type` | Yes | The tool or service this skill connects to (e.g., `aws`, `k8s`, `github`) |
| `preload` | No | If `true`, skill is loaded into agent context automatically. Default `false` |

### Template Skills

Located in `skills/templates/<skill-id>/SKILL.md`. These provide reusable workflows, checklists, and runbooks.

**Frontmatter:**

```yaml
---
name: skill-id
enabled: true
description: |
  What this template does and when to use it.
required_connections:
  - prefix: tool-name
    label: "Display Name"
config_fields:
  - key: field_name
    label: "Field Label"
    required: true
    placeholder: "e.g., example value"
features:
  - FEATURE_TAG
---
```

| Field | Required | Description |
|:------|:--------:|:------------|
| `name` | Yes | Kebab-case identifier matching the directory name |
| `enabled` | Yes | Whether this template is active |
| `description` | Yes | One paragraph explaining purpose and when to use |
| `required_connections` | No | List of connections this template needs |
| `config_fields` | No | User-configurable fields with labels and placeholders |
| `features` | No | Feature tags for categorization (e.g., `DEPLOYMENT`, `INCIDENT`, `COST`) |

---

## Skill Body Structure

### Connection Skills

After the frontmatter, connection skills follow this structure:

```markdown
# Skill Title

Brief description of what the skill does.

## Phase 1 — Discovery

List available resources, inventory what exists.
Uses bash/curl/CLI commands to enumerate resources.

## Phase 2 — Analysis

Check health, metrics, utilization, and issues.
Uses bash/curl/CLI commands to gather data.

## Output Format

How to present results. Target ≤50 lines of output.

## Common Pitfalls

Tool-specific gotchas and safety notes.
```

### Template Skills

```markdown
# Template Title

Brief description with config field interpolation: **{{ field_name }}**

## Workflow

### Step 1 — Phase Name
Structured checklist or procedure.

### Step 2 — Phase Name
Decision matrices, action items, or validation steps.

## Output Format

What the completed template produces.
```

---

## Quality Guidelines

### Discovery-First Pattern

Skills should use a two-phase execution model:
1. **Discovery** — enumerate what exists before acting
2. **Analysis** — inspect discovered resources for health, performance, or compliance

### Safety Rules

- **Read-only by default** — skills should not modify resources unless explicitly designed to
- **No secret exposure** — never output API keys, tokens, passwords, or connection strings
- **Output limits** — target ≤50 lines of structured output per execution
- **Error handling** — check for empty results and missing permissions gracefully

### AWS-Specific Conventions

- Always include `export AWS_PAGER=""`
- Use `--output text --query` for structured output
- Use parallel execution with `&` and `wait` for multi-resource discovery
- CloudWatch statistics use spaces not commas: `--statistics Average Maximum`

### CLI/API Patterns

- Use `curl` with `jq` for REST API integrations
- Define helper functions for repeated API calls
- Include authentication header patterns in discovery phase
- Handle pagination where applicable

---

## Registry

All skills are indexed in `registry.json` at the repository root:

```json
{
  "version": "1.0.0",
  "updated_at": "2026-03-14",
  "skills": [
    {
      "id": "skill-id",
      "name": "Display Name",
      "description": "Brief description",
      "category": "code|operational|security|observability|database|cost|performance",
      "section": "connections|templates",
      "url": "https://raw.githubusercontent.com/cloudthinker-ai/CloudSkills/main/skills/..."
    }
  ]
}
```

### Categories

| Category | Description |
|:---------|:------------|
| `code` | Development tools, CI/CD, IaC, cloud providers, languages |
| `operational` | Incident management, ITSM, project management, communication |
| `security` | Vulnerability scanning, compliance, identity, secrets management |
| `observability` | Monitoring, APM, logging, tracing, alerting |
| `database` | Databases, caches, queues, data engineering, analytics |
| `cost` | FinOps, cost optimization, billing, resource efficiency |
| `performance` | Load testing, profiling, benchmarking, optimization |

---

## File Layout

```
CloudSkills/
├── README.md
├── SPEC.md                  # this file
├── CONTRIBUTING.md
├── LICENSE
├── registry.json            # skill index
├── assets/
│   ├── logo.svg
│   └── skills.png
└── skills/
    ├── connections/
    │   ├── aws/SKILL.md
    │   ├── managing-datadog/SKILL.md
    │   └── ...
    └── templates/
        ├── deployment-checklist/SKILL.md
        ├── incident-response-runbook/SKILL.md
        └── ...
```
