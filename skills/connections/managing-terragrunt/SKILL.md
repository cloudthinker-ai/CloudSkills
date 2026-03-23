---
name: managing-terragrunt
description: |
  Use when working with Terragrunt — terragrunt Terraform wrapper management.
  Covers run-all operations, dependency management, configuration generation,
  input/output passing, remote state configuration, and multi-environment
  workflows. Use when managing Terragrunt configurations, running cross-module
  operations, debugging dependency issues, or auditing infrastructure layouts.
connection_type: terragrunt
preload: false
---

# Terragrunt Management Skill

Manage and inspect Terragrunt configurations, dependencies, and multi-module operations.

## MANDATORY: Discovery-First Pattern

**Always inspect the dependency graph and configuration before running operations.**

### Phase 1: Discovery

```bash
#!/bin/bash

echo "=== Terragrunt Version ==="
terragrunt --version 2>/dev/null

echo ""
echo "=== Configuration Structure ==="
find . -name "terragrunt.hcl" -not -path "./.terragrunt-cache/*" 2>/dev/null | sort | head -30

echo ""
echo "=== Root Configuration ==="
cat terragrunt.hcl 2>/dev/null | head -20

echo ""
echo "=== Dependency Graph ==="
terragrunt graph-dependencies 2>/dev/null | head -30
```

## Core Helper Functions

```bash
#!/bin/bash

# Terragrunt wrapper
tg_cmd() {
    terragrunt "$@" --terragrunt-non-interactive 2>&1
}

# Run in specific module directory
tg_module() {
    local module_dir="$1"
    shift
    terragrunt "$@" --terragrunt-working-dir "$module_dir" --terragrunt-non-interactive 2>&1
}

# Run-all with safety
tg_run_all() {
    terragrunt run-all "$@" --terragrunt-non-interactive 2>&1
}
```

## Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- Use `--terragrunt-non-interactive` to prevent prompts
- Filter `.terragrunt-cache` from file searches
- Use `graph-dependencies` for visual dependency overview

## Common Operations

### Dependency Graph Analysis

```bash
#!/bin/bash
echo "=== Full Dependency Graph ==="
terragrunt graph-dependencies 2>/dev/null

echo ""
echo "=== Module Dependencies ==="
find . -name "terragrunt.hcl" -not -path "./.terragrunt-cache/*" -exec grep -l 'dependency' {} \; 2>/dev/null | while read f; do
    DIR=$(dirname "$f")
    echo "--- $DIR ---"
    grep -A 3 'dependency "' "$f" 2>/dev/null | grep -E '(dependency|config_path)' | head -5
done | head -40
```

### Run-All Plan

```bash
#!/bin/bash
echo "=== Run-All Plan ==="
terragrunt run-all plan --terragrunt-non-interactive 2>&1 | \
    grep -E '(Plan:|No changes|Error|module)' | head -40

echo ""
echo "=== Change Summary by Module ==="
terragrunt run-all plan --terragrunt-non-interactive 2>&1 | \
    grep -E 'Plan:' | head -20
```

### Single Module Operations

```bash
#!/bin/bash
MODULE_DIR="${1:?Module directory required}"
ACTION="${2:-plan}"

echo "=== Module: $MODULE_DIR ==="
echo "=== Action: $ACTION ==="

case "$ACTION" in
    plan)
        terragrunt plan --terragrunt-working-dir "$MODULE_DIR" --terragrunt-non-interactive 2>&1 | tail -20
        ;;
    output)
        terragrunt output --terragrunt-working-dir "$MODULE_DIR" --terragrunt-non-interactive -json 2>/dev/null | jq '.'
        ;;
    state)
        terragrunt state list --terragrunt-working-dir "$MODULE_DIR" --terragrunt-non-interactive 2>/dev/null | head -20
        ;;
    validate)
        terragrunt validate --terragrunt-working-dir "$MODULE_DIR" --terragrunt-non-interactive 2>&1
        ;;
esac
```

### Configuration Generation and Inputs

```bash
#!/bin/bash
MODULE_DIR="${1:?Module directory required}"

echo "=== Generated Config ==="
terragrunt render-json --terragrunt-working-dir "$MODULE_DIR" 2>/dev/null | jq '{
    terraform_source: .terraform[0].source,
    inputs: (.inputs // {} | keys),
    dependencies: [.dependency // {} | to_entries[] | .key]
}' 2>/dev/null || echo "render-json not available in this version"

echo ""
echo "=== Terragrunt Config ==="
cat "${MODULE_DIR}/terragrunt.hcl" 2>/dev/null | head -40
```

### Multi-Environment Comparison

```bash
#!/bin/bash
echo "=== Environment Modules ==="
for env_dir in */; do
    if [ -f "${env_dir}terragrunt.hcl" ] || find "$env_dir" -name "terragrunt.hcl" -maxdepth 2 2>/dev/null | grep -q .; then
        MODULE_COUNT=$(find "$env_dir" -name "terragrunt.hcl" -not -path "*/.terragrunt-cache/*" 2>/dev/null | wc -l | tr -d ' ')
        echo "$env_dir: $MODULE_COUNT modules"
    fi
done

echo ""
echo "=== Cross-Environment Diff ==="
ENV1="${1:-dev}"
ENV2="${2:-prod}"
diff <(find "$ENV1" -name "terragrunt.hcl" -not -path "*/.terragrunt-cache/*" 2>/dev/null | sed "s|$ENV1/||" | sort) \
     <(find "$ENV2" -name "terragrunt.hcl" -not -path "*/.terragrunt-cache/*" 2>/dev/null | sed "s|$ENV2/||" | sort) 2>/dev/null || \
echo "Could not compare environments"
```

## Safety Rules

- **NEVER run `run-all apply` without `run-all plan` first** -- review all module changes
- **NEVER use `run-all destroy` without explicit confirmation** and `--terragrunt-parallelism 1`
- **Use `--terragrunt-non-interactive`** to prevent prompts in automation
- **Dependency order matters** -- `run-all` respects dependency graph but failures can cascade
- **Lock files** should be committed to prevent provider version drift across modules

## Output Format

Present results as a structured report:
```
Managing Terragrunt Report
══════════════════════════
Resources discovered: [count]

Resource       Status    Key Metric    Issues
──────────────────────────────────────────────
[name]         [ok/warn] [value]       [findings]

Summary: [total] resources | [ok] healthy | [warn] warnings | [crit] critical
Action Items: [list of prioritized findings]
```

Target ≤50 lines of output. Use tables for multi-resource comparisons.

## Anti-Hallucination Rules

1. **NEVER assume resource names** — always discover via CLI/API in Phase 1 before referencing in Phase 2.
2. **NEVER fabricate metric names or dimensions** — verify against the service documentation or `--help` output.
3. **NEVER mix CLI commands between service versions** — confirm which version/API you are targeting.
4. **ALWAYS use the discovery → verify → analyze chain** — every resource referenced must have been discovered first.
5. **ALWAYS handle empty results gracefully** — an empty response is valid data, not an error to retry.

## Counter-Rationalizations

| Shortcut | Counter | Why |
|----------|---------|-----|
| "I'll skip discovery and check known resources" | Always run Phase 1 discovery first | Resource names change, new resources appear — assumed names cause errors |
| "The user only asked for a quick check" | Follow the full discovery → analysis flow | Quick checks miss critical issues; structured analysis catches silent failures |
| "Default configuration is probably fine" | Audit configuration explicitly | Defaults often leave logging, security, and optimization features disabled |
| "Metrics aren't needed for this" | Always check relevant metrics when available | API/CLI responses show current state; metrics reveal trends and intermittent issues |
| "I don't have access to that" | Try the command and report the actual error | Assumed permission failures prevent useful investigation; actual errors are informative |

## Common Pitfalls

- **Cache corruption**: `.terragrunt-cache` can become stale -- delete it and re-init if seeing odd errors
- **Circular dependencies**: Terragrunt detects cycles but error messages can be cryptic -- check `graph-dependencies`
- **Source caching**: Terraform source is cached -- use `--terragrunt-source-update` to force refresh
- **Input variable type mismatch**: Terragrunt `inputs` must match Terraform variable types exactly
- **Remote state config**: Backend config is generated -- manual `.terraform/` changes will be overwritten
- **run-all parallelism**: Default parallelism can overwhelm APIs -- use `--terragrunt-parallelism` to limit
- **Relative paths**: `find_in_parent_folders()` walks up -- can match wrong config if directory structure changes
- **Include conflicts**: Multiple `include` blocks with overlapping settings cause merge conflicts
