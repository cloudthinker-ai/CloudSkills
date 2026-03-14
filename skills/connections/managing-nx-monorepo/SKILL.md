---
name: managing-nx-monorepo
description: |
  Nx monorepo build system management. Covers workspace configuration, project graph analysis, affected commands, computation caching, task executors, and distributed task execution. Use when managing Nx workspaces, analyzing project dependencies, debugging build failures, or optimizing CI pipelines.
connection_type: nx
preload: false
---

# Nx Monorepo Build System Management Skill

Manage and analyze Nx monorepo workspaces, project graphs, and build orchestration.

## MANDATORY: Discovery-First Pattern

**Always check current Nx workspace configuration before modifying projects or targets.**

### Phase 1: Discovery

```bash
#!/bin/bash

echo "=== Nx Workspace Configuration ==="
cat nx.json 2>/dev/null | jq '{
  npmScope: .npmScope,
  tasksRunnerOptions: (.tasksRunnerOptions | keys),
  targetDefaults: (.targetDefaults | keys),
  namedInputs: (.namedInputs | keys)
}' 2>/dev/null

echo ""
echo "=== Projects ==="
npx nx show projects 2>/dev/null | head -20

echo ""
echo "=== Nx Version ==="
npx nx --version 2>/dev/null
```

### Phase 2: Analysis

```bash
#!/bin/bash

echo "=== Project Graph Summary ==="
npx nx graph --file=stdout 2>/dev/null | jq '{
  total_projects: (.graph.nodes | length),
  total_dependencies: (.graph.dependencies | map(length) | add),
  projects: [.graph.nodes | to_entries[] | {name: .key, type: .value.type}]
}' 2>/dev/null | head -30

echo ""
echo "=== Affected Projects (since main) ==="
npx nx show projects --affected --base=main 2>/dev/null | head -15

echo ""
echo "=== Cache Status ==="
ls -la .nx/cache/ 2>/dev/null | tail -10
```

## Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- Summarize project graphs with counts and types
- List affected projects concisely
- Report cache utilization metrics

## Common Operations

### Run Affected Targets

```bash
#!/bin/bash
TARGET="${1:-build}"
echo "=== Affected $TARGET ==="
npx nx affected -t "$TARGET" --base=main --dry-run 2>/dev/null | head -20
```

### Dependency Analysis

```bash
#!/bin/bash
PROJECT="${1:?Project name required}"
echo "=== Dependencies for $PROJECT ==="
npx nx show project "$PROJECT" --json 2>/dev/null | jq '{
  name: .name,
  targets: (.targets | keys),
  implicitDependencies: .implicitDependencies
}' 2>/dev/null
```

## Safety Rules

- **Run affected commands** before full workspace builds to save CI time
- **Never clear the Nx cache** in production CI without understanding rebuild cost
- **Test executor changes** on individual projects before applying workspace-wide
- **Review project graph** after adding new dependencies to detect circular references
