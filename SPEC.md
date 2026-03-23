# CloudSkills Specification

This document defines the structure and conventions for skills in the CloudSkills registry.

Inspired by best practices from [terraform-skill](https://github.com/antonbabenko/terraform-skill), [anthropics/skills](https://github.com/anthropics/skills), and the [Agent Skills Spec](https://agentskills.io).

---

## Architecture: Progressive Disclosure

Skills use a **three-tier token architecture** to minimize per-query cost:

| Tier | What loads | Token budget | When |
|------|-----------|-------------|------|
| **Metadata** | `name` + `description` | ~100 tokens | Always (all skills) |
| **Instructions** | Full SKILL.md body | <5000 tokens (~500 lines) | On activation |
| **Resources** | `references/*.md` files | As needed | On demand |

**Rule:** Keep SKILL.md under 500 lines. Move detailed reference material (cheat sheets, full CLI examples, compliance matrices) to `references/` files and link them from SKILL.md.

---

## Skill Types

### Connection Skills

Located in `skills/connections/<skill-id>/SKILL.md`. These integrate with specific tools, services, or cloud providers.

**Frontmatter (keep minimal — extra fields waste tokens):**

```yaml
---
name: skill-id                # kebab-case, matches directory name
description: |
  Use when [specific trigger situations]. [What the skill does].
  Covers [capability 1], [capability 2], and [capability 3].
connection_type: tool-name    # required cloud/tool connection
preload: false                # whether to preload in agent context
---
```

| Field | Required | Description |
|:------|:--------:|:------------|
| `name` | Yes | Kebab-case identifier matching the directory name |
| `description` | Yes | Activation trigger + capabilities. Start with "Use when..." |
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
  Use when [specific trigger situations]. [What the template does].
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
| `description` | Yes | Activation trigger + capabilities. Start with "Use when..." |
| `required_connections` | No | List of connections this template needs |
| `config_fields` | No | User-configurable fields with labels and placeholders |
| `features` | No | Feature tags for categorization (e.g., `DEPLOYMENT`, `INCIDENT`, `COST`) |

---

## Description as Activation Trigger

The `description` field is the **primary mechanism** for skill activation. It must serve double duty: telling agents **what** the skill does and **when** to activate it.

**Pattern:** Start with "Use when..." followed by specific trigger situations, then list capabilities.

**Good:**
```yaml
description: |
  Use when working with AWS API Gateway — creating REST/HTTP APIs, analyzing
  latency, debugging 5xx errors, auditing throttling configuration, or reviewing
  usage plans. Covers API inventory, stage analysis, metrics, and authorization.
```

**Bad:**
```yaml
description: |
  AWS API Gateway management skill for cloud teams.
```

---

## Skill Body Structure

### Connection Skills

```markdown
# Skill Title

One-line purpose statement.

## Decision Matrix

When-to-use tables, if-then-else decision guides, version-aware feature tables.

## Phase 1 — Discovery

Enumerate resources. Use bash/CLI commands with anti-hallucination guardrails.

## Phase 2 — Analysis

Inspect discovered resources. Reference only confirmed resources.

## Anti-Hallucination Rules

Explicit "NEVER assume X" rules to prevent fabricated resource names or wrong CLI commands.

## Counter-Rationalizations

Common excuses an agent might use to skip best practices, with explicit counters.

## Output Format

Structured results. Target ≤50 lines. Include output template.

## Common Pitfalls

Tool-specific gotchas and safety notes.

## References

Links to `references/*.md` files for deep-dive content loaded on demand.
```

### Template Skills

```markdown
# Template Title

Brief description with config field interpolation: **{{ field_name }}**

## Decision Matrix

Severity/priority selection guides, when-to-use tables.

## Workflow

### Step 1 — Phase Name
Structured checklist with time estimates.

### Step N — Phase Name
Decision matrices, action items, or validation steps.

## Counter-Rationalizations

Common shortcuts an agent might take, with explicit counters.

## Output Format

What the completed template produces. Include exact output template.
```

---

## Quality Guidelines

### Progressive Disclosure

Move deep-dive content to `references/` files:

```
skill-name/
├── SKILL.md              # Core instructions (<500 lines)
└── references/           # On-demand detail
    ├── cli-reference.md  # Full CLI command reference
    ├── troubleshooting.md # Diagnostic decision trees
    └── compliance.md     # Security/compliance matrices
```

Link from SKILL.md: `[See CLI Reference](./references/cli-reference.md)`

### Discovery-First Pattern

Skills must use a two-phase execution model:
1. **Discovery** — enumerate what exists before acting
2. **Analysis** — inspect only discovered resources

**NEVER** reference resource names, IDs, or endpoints without first discovering them via CLI/API.

### Decision Matrices Over Prescriptions

Provide agents with decision frameworks, not single recommendations:

```markdown
| Scenario | Recommendation | Why |
|----------|---------------|-----|
| < 10 APIs, simple routing | HTTP API | Lower cost, simpler |
| Need usage plans/API keys | REST API | HTTP APIs don't support usage plans |
| WebSocket needed | HTTP API (v2) | Only v2 supports WebSocket |
```

### Counter-Rationalization Strategy

Anticipate and counter common excuses an agent might use to skip best practices:

```markdown
## Counter-Rationalizations

| Rationalization | Counter | Why it matters |
|----------------|---------|---------------|
| "I'll check metrics later" | Always check metrics during discovery | Silent failures go undetected |
| "The default config is fine" | Audit stage config explicitly | Defaults leave logging disabled |
| "Usage plans aren't needed" | Review throttling if REST API has consumers | Unthrottled APIs cause cascading failures |
```

### Anti-Hallucination Rules

Every skill that references external resources must include explicit guardrails:

- **NEVER** assume resource names — discover them first
- **NEVER** mix CLI commands between service versions (e.g., `apigateway` vs `apigatewayv2`)
- **NEVER** fabricate metric names or dimensions — verify against documentation
- **ALWAYS** include the reasoning chain: discover → verify → analyze

### Safety Rules

- **Read-only by default** — skills should not modify resources unless explicitly designed to
- **No secret exposure** — never output API keys, tokens, passwords, or connection strings
- **Output limits** — target ≤50 lines of structured output per execution
- **Error handling** — check for empty results and missing permissions gracefully

### Scannable Format

Use tables, code blocks, and imperative voice. Avoid prose paragraphs.

- ✅ Tables for decision matrices and comparisons
- ✅ Code blocks with inline comments explaining "why"
- ✅ Imperative voice ("Use X", not "You should consider X")
- ✅ DO/DON'T patterns with checkmarks
- ❌ Long explanatory paragraphs
- ❌ Passive voice
- ❌ Ambiguous recommendations

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

## Testing Skills (TDD for Documentation)

Skills should be validated using a RED-GREEN-REFACTOR cycle:

1. **RED** — Run test scenarios WITHOUT the skill loaded. Document baseline agent behavior.
2. **GREEN** — Run the SAME scenarios WITH the skill loaded. Verify behavior improves.
3. **REFACTOR** — Identify new rationalizations the agent uses and add counter-rationalizations.

Test scenarios live in `tests/` at the repo root. See `tests/baseline-scenarios.md`.

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
├── tests/                   # TDD test scenarios
│   ├── baseline-scenarios.md
│   ├── compliance-verification.md
│   └── rationalization-table.md
└── skills/
    ├── connections/
    │   ├── aws-api-gateway/
    │   │   ├── SKILL.md
    │   │   └── references/
    │   │       ├── rest-vs-http.md
    │   │       └── troubleshooting.md
    │   ├── managing-datadog/SKILL.md
    │   └── ...
    └── templates/
        ├── deployment-checklist/SKILL.md
        ├── incident-response-runbook/
        │   ├── SKILL.md
        │   └── references/
        │       └── severity-playbooks.md
        └── ...
```
