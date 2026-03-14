---
name: managing-just
description: |
  Just command runner management. Covers justfile analysis, recipe discovery, variable management, recipe dependencies, and cross-platform configuration. Use when managing justfiles, discovering available recipes, debugging recipe execution, or organizing project commands.
connection_type: just
preload: false
---

# Just Command Runner Management Skill

Manage and analyze justfiles, recipes, variables, and command execution.

## MANDATORY: Discovery-First Pattern

**Always check current justfile configuration and available recipes before modifying.**

### Phase 1: Discovery

```bash
#!/bin/bash

echo "=== Just Version ==="
just --version 2>/dev/null

echo ""
echo "=== Available Recipes ==="
just --list 2>/dev/null | head -25

echo ""
echo "=== Justfile Location ==="
just --justfile 2>/dev/null
just --summary 2>/dev/null
```

### Phase 2: Analysis

```bash
#!/bin/bash

echo "=== Recipe Details ==="
just --show --unsorted 2>/dev/null | head -30

echo ""
echo "=== Variables ==="
just --evaluate 2>/dev/null | head -15

echo ""
echo "=== Justfile Contents ==="
cat justfile 2>/dev/null || cat Justfile 2>/dev/null | head -30
```

## Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- List recipes with their descriptions
- Show recipe dependencies
- Report variable values concisely

## Common Operations

### Show Recipe

```bash
#!/bin/bash
RECIPE="${1:?Recipe name required}"
echo "=== Recipe: $RECIPE ==="
just --show "$RECIPE" 2>/dev/null
```

### Dry Run

```bash
#!/bin/bash
RECIPE="${1:?Recipe name required}"
echo "=== Dry Run: $RECIPE ==="
just --dry-run "$RECIPE" 2>&1 | head -15
```

## Safety Rules

- **Use `just --dry-run`** to preview commands before executing destructive recipes
- **Review recipe dependencies** to understand full execution chain
- **Environment variables** in justfiles should not contain secrets -- use .env files
- **Test cross-platform recipes** on all target platforms before committing
