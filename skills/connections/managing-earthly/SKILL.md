---
name: managing-earthly
description: |
  Earthly build system management. Covers Earthfile configuration, target analysis, artifact management, caching strategies, satellite builds, and CI integration. Use when managing Earthly builds, debugging targets, optimizing cache utilization, or configuring remote runners.
connection_type: earthly
preload: false
---

# Earthly Build System Management Skill

Manage and analyze Earthly builds, targets, artifacts, and remote execution.

## MANDATORY: Discovery-First Pattern

**Always check current Earthfile configuration and target structure before modifying builds.**

### Phase 1: Discovery

```bash
#!/bin/bash

echo "=== Earthfile ==="
cat Earthfile 2>/dev/null | head -30

echo ""
echo "=== Earthly Version ==="
earthly --version 2>/dev/null

echo ""
echo "=== Available Targets ==="
grep -E '^\w+:' Earthfile 2>/dev/null | sed 's/://' | head -15

echo ""
echo "=== Nested Earthfiles ==="
find . -name "Earthfile" -not -path "*/node_modules/*" 2>/dev/null | head -10
```

### Phase 2: Analysis

```bash
#!/bin/bash

echo "=== Target Dependencies ==="
grep -E '^\w+:|BUILD|COPY|FROM' Earthfile 2>/dev/null | head -25

echo ""
echo "=== Artifacts ==="
grep -E 'SAVE ARTIFACT|SAVE IMAGE' Earthfile 2>/dev/null | head -10

echo ""
echo "=== Cache Mounts ==="
grep -E 'CACHE|--mount.*cache' Earthfile 2>/dev/null | head -10

echo ""
echo "=== Satellite Status ==="
earthly sat ls 2>/dev/null | head -5
```

## Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- List targets with their FROM base images
- Summarize artifact outputs concisely
- Report satellite/remote runner status

## Common Operations

### Build Target

```bash
#!/bin/bash
TARGET="${1:?Target name required}"
echo "=== Building +$TARGET ==="
earthly "+$TARGET" 2>&1 | tail -20
```

### Cache Analysis

```bash
#!/bin/bash
echo "=== Cache Usage ==="
earthly prune --dry-run 2>/dev/null | head -10

echo ""
echo "=== Image Cache ==="
docker images --filter "label=dev.earthly" --format "table {{.Repository}}\t{{.Size}}\t{{.CreatedAt}}" 2>/dev/null | head -10
```

## Safety Rules

- **Never run `earthly prune -a`** without confirming rebuild cost
- **Use secrets via `--secret`** flag, never hardcode in Earthfiles
- **Test multi-platform builds** locally before pushing to CI
- **Review SAVE IMAGE targets** to avoid pushing unintended images to registries
