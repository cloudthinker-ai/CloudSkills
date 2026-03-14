# Contributing to CloudSkills

Thank you for contributing to the CloudSkills registry! Every skill you add helps cloud engineering teams work faster and more reliably.

---

## Quick Start

1. **Fork** this repository
2. **Create** your skill directory and `SKILL.md` file
3. **Test** your skill locally
4. **Open a pull request**
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

See [SPEC.md](SPEC.md) for the full format specification. Key points:

- **Frontmatter** — YAML metadata with name, description, and connection details
- **Discovery phase** — enumerate resources before analyzing
- **Analysis phase** — check health, metrics, or compliance
- **Output format** — structured results, ≤50 lines target

---

## Quality Checklist

Before submitting, verify:

- [ ] `name` in frontmatter matches the directory name
- [ ] `description` clearly explains what the skill does and when to use it
- [ ] Skill uses **read-only operations** by default (no destructive commands)
- [ ] No hardcoded secrets, tokens, or credentials
- [ ] Output is structured and stays within ≤50 lines
- [ ] Bash scripts include error handling for missing tools/permissions
- [ ] AWS skills include `export AWS_PAGER=""` and use `--output text --query`
- [ ] API integrations use environment variables for authentication
- [ ] Skill has been tested with at least one real scenario

---

## Pull Request Process

1. **Title** — use the format: `feat: add <skill-name> skill`
2. **Description** — briefly explain what the skill does and why it's useful
3. **One skill per PR** preferred, but batches of related skills are acceptable
4. CI will validate your SKILL.md frontmatter automatically
5. A maintainer will review for quality and merge

---

## Updating Existing Skills

- Fix bugs, improve commands, or add missing edge cases
- Keep the same `name` and directory — don't rename without discussion
- Explain what changed and why in your PR description

---

## Code of Conduct

Be respectful, constructive, and helpful. We're building tools that teams depend on in production — quality and reliability matter.

---

## Questions?

- Open an issue on this repository
- Visit [cloudthinker.io](https://cloudthinker.io) for documentation
