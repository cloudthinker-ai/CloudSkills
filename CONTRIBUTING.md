# Contributing to CloudSkills

Thank you for contributing to the CloudSkills registry! Every skill you add helps cloud engineering teams work faster and more reliably.

---

## Quick Start

1. **Fork** this repository
2. **Create** your skill directory and `SKILL.md` file
3. **Test** your skill using the TDD process (see below)
4. **Open a pull request** with testing evidence
5. After merge, the skill appears on [CloudThinker](https://cloudthinker.io/skills) within 1 hour

---

## Creating a Skill

### Choose the Right Type

| Type | Location | Use When |
|:-----|:---------|:---------|
| **Connection** | `skills/connections/<id>/SKILL.md` | Skill integrates with a specific tool, API, or cloud service |
| **Template** | `skills/templates/<id>/SKILL.md` | Skill is a reusable workflow, checklist, or runbook |

### Naming Convention

- Use **kebab-case** for directory names: `managing-datadog`, `deployment-checklist`
- Connection skills typically start with a verb: `managing-`, `analyzing-`, `monitoring-`, `tracking-`
- Template skills describe the workflow: `incident-response-runbook`, `cost-optimization-report`

### Write Your SKILL.md

See [SPEC.md](SPEC.md) for the full format specification. Key principles:

- **Progressive disclosure** — SKILL.md < 500 lines; deep content in `references/`
- **Description as trigger** — Start description with "Use when..." and list specific situations
- **Discovery-first** — enumerate resources before analyzing
- **Decision matrices** — provide decision frameworks, not single recommendations
- **Counter-rationalizations** — anticipate and counter LLM shortcuts
- **Scannable format** — tables, code blocks, imperative voice, no prose paragraphs

---

## Quality Checklist

Before submitting, verify:

### Metadata
- [ ] `name` in frontmatter matches the directory name
- [ ] `description` starts with "Use when..." and lists specific trigger situations
- [ ] Frontmatter is minimal — only required fields (extra fields waste tokens)

### Content Structure
- [ ] SKILL.md is under 500 lines (move detail to `references/`)
- [ ] Includes decision matrix for non-obvious choices
- [ ] Includes anti-hallucination rules (never assume resource names)
- [ ] Includes counter-rationalizations for common agent shortcuts
- [ ] Output format section with exact template
- [ ] Uses scannable format: tables, code blocks, imperative voice

### Safety
- [ ] Uses **read-only operations** by default (no destructive commands)
- [ ] No hardcoded secrets, tokens, or credentials
- [ ] Output is structured and stays within ≤50 lines
- [ ] Bash scripts include error handling for missing tools/permissions
- [ ] AWS skills include `export AWS_PAGER=""` and use `--output text --query`
- [ ] API integrations use environment variables for authentication

### Testing Evidence (required in PR)
- [ ] Baseline behavior documented (without skill loaded)
- [ ] Compliance behavior documented (with skill loaded)
- [ ] New rationalizations identified and countered

---

## Testing Skills (TDD for Documentation)

We follow a **RED-GREEN-REFACTOR** cycle to validate skill quality:

### RED Phase — Baseline

Run your target scenario WITHOUT the skill loaded. Document:
- What does the agent do by default?
- What best practices does it skip?
- What rationalizations does it use to justify shortcuts?

### GREEN Phase — Compliance

Run the SAME scenario WITH the skill loaded. Document:
- What behavior changed?
- Did the agent follow all skill instructions?
- What new rationalizations appeared?

### REFACTOR Phase — Counter-Rationalizations

For any new rationalization discovered:
1. Add a counter-rationalization to the skill's `## Counter-Rationalizations` section
2. Re-test to verify the agent no longer uses that shortcut
3. Update `tests/rationalization-table.md` with the new entry

### Example Test

```
Scenario: Analyze AWS API Gateway health
Prompt: "Check the health of our API Gateway APIs"

Baseline (no skill):
- Agent runs `aws apigateway get-rest-apis` but ignores HTTP APIs
- Agent skips CloudWatch metrics analysis
- Agent doesn't check stage configuration

Compliance (with skill):
- Agent discovers both REST and HTTP APIs in parallel
- Agent checks latency, error rates, and throttling metrics
- Agent audits stage logging and tracing configuration
- Agent reports structured output within 50-line limit
```

---

## Pull Request Process

1. **Title** — use the format: `feat: add <skill-name> skill`
2. **Description** — include testing evidence (baseline vs compliance behavior)
3. **One skill per PR** preferred, but batches of related skills are acceptable
4. CI will validate your SKILL.md frontmatter and structure automatically
5. A maintainer will review for quality and merge

### PR Template

```markdown
## Testing Evidence

### Baseline (without skill)
[What the agent did by default]

### Compliance (with skill)
[What behavior changed]

### Rationalizations Discovered
[Any new shortcuts the agent tried, and how you countered them]
```

---

## Updating Existing Skills

- Fix bugs, improve commands, or add missing edge cases
- Keep the same `name` and directory — don't rename without discussion
- Explain what changed and why in your PR description
- If adding progressive disclosure: create `references/` directory, move detail there

---

## Code of Conduct

Be respectful, constructive, and helpful. We're building tools that teams depend on in production — quality and reliability matter.

---

## Questions?

- Open an issue on this repository
- Visit [cloudthinker.io](https://cloudthinker.io) for documentation
