---
name: managing-make
description: |
  GNU Make build system management. Covers Makefile analysis, target discovery, dependency graphs, variable inspection, and build debugging. Use when managing Makefiles, understanding target dependencies, debugging build failures, or optimizing parallel builds.
connection_type: make
preload: false
---

# GNU Make Build System Management Skill

Manage and analyze Makefiles, build targets, dependencies, and variables.

## MANDATORY: Discovery-First Pattern

**Always check current Makefile configuration and target structure before modifying builds.**

### Phase 1: Discovery

```bash
#!/bin/bash

echo "=== Make Version ==="
make --version 2>/dev/null | head -2

echo ""
echo "=== Makefile Targets ==="
make -pRrq : 2>/dev/null | awk -F: '/^[a-zA-Z0-9][^$#\/\t=]*:([^=]|$)/ {split($1,a," ");print a[1]}' | sort -u | head -20

echo ""
echo "=== Makefile Includes ==="
grep -E '^include\s|^-include\s' Makefile 2>/dev/null | head -10

echo ""
echo "=== Default Goal ==="
make -pRrq : 2>/dev/null | grep '.DEFAULT_GOAL' | head -1
```

### Phase 2: Analysis

```bash
#!/bin/bash

echo "=== Key Variables ==="
make -pRrq : 2>/dev/null | grep -E '^[A-Z_]+\s*=' | head -15

echo ""
echo "=== Target Dependencies ==="
grep -E '^[a-zA-Z0-9_-]+\s*:' Makefile 2>/dev/null | head -15

echo ""
echo "=== Phony Targets ==="
grep '.PHONY' Makefile 2>/dev/null | head -5
```

## Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- List targets with their direct dependencies
- Show key variable definitions
- Report build errors concisely

## Common Operations

### Dry Run

```bash
#!/bin/bash
TARGET="${1:-all}"
echo "=== Dry Run: $TARGET ==="
make -n "$TARGET" 2>&1 | head -20
```

### Debug Build

```bash
#!/bin/bash
TARGET="${1:-all}"
echo "=== Build Debug ==="
make -d "$TARGET" 2>&1 | grep -E 'Considering\|Must remake\|Successfully' | head -20
```

## Safety Rules

- **Use `make -n`** (dry run) to preview commands before running destructive targets
- **Parallel builds** (`make -j`) can expose missing dependencies -- test before enabling
- **Never override system variables** (CC, CXX) without understanding downstream effects
- **Review recursive make** calls for correctness -- they can miss dependency changes
