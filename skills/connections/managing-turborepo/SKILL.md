---
name: managing-turborepo
description: |
  Use when working with Turborepo — turborepo monorepo build system management.
  Covers pipeline configuration, caching strategies, task dependencies, remote
  caching, package filtering, and build performance analysis. Use when managing
  Turborepo workspaces, debugging build pipelines, optimizing cache hit rates,
  or analyzing task execution graphs.
connection_type: turborepo
preload: false
---

# Turborepo Build System Management Skill

Manage and analyze Turborepo monorepo build pipelines, caching, and task orchestration.

## MANDATORY: Discovery-First Pattern

**Always check current Turborepo configuration and workspace structure before modifying pipelines.**

### Phase 1: Discovery

```bash
#!/bin/bash

echo "=== Turborepo Configuration ==="
cat turbo.json 2>/dev/null || echo "No turbo.json found"

echo ""
echo "=== Workspace Structure ==="
cat package.json 2>/dev/null | jq '.workspaces // empty' 2>/dev/null
cat pnpm-workspace.yaml 2>/dev/null

echo ""
echo "=== Packages ==="
ls -d packages/*/package.json apps/*/package.json 2>/dev/null | head -15

echo ""
echo "=== Turbo Version ==="
npx turbo --version 2>/dev/null
```

### Phase 2: Analysis

```bash
#!/bin/bash

echo "=== Pipeline Tasks ==="
cat turbo.json 2>/dev/null | jq '.pipeline // .tasks' 2>/dev/null

echo ""
echo "=== Task Dependency Graph ==="
npx turbo run build --dry=json 2>/dev/null | jq '{
  tasks: [.tasks[] | {
    taskId: .taskId,
    package: .package,
    command: .command,
    dependencies: .dependencies,
    cache: .cache
  }]
}' 2>/dev/null | head -40

echo ""
echo "=== Cache Status ==="
npx turbo run build --dry=json 2>/dev/null | jq '{
  total_tasks: (.tasks | length),
  cached: [.tasks[] | select(.cache.status == "HIT")] | length,
  cache_hit_rate: (([.tasks[] | select(.cache.status == "HIT")] | length) / (.tasks | length) * 100 | floor | tostring + "%")
}' 2>/dev/null
```

## Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- Summarize task graphs rather than dumping full JSON
- Group packages by workspace (apps vs packages)
- Report cache hit rates as percentages

## Common Operations

### Build Performance Analysis

```bash
#!/bin/bash
echo "=== Build Timing ==="
npx turbo run build --summarize 2>/dev/null
cat .turbo/runs/*.json 2>/dev/null | jq '{
  duration: .execution.duration,
  tasks: [.execution.tasks[] | {name: .taskId, duration: .execution.duration, cache: .cache.status}]
}' 2>/dev/null | head -30
```

### Remote Cache Configuration

```bash
#!/bin/bash
echo "=== Remote Cache Status ==="
npx turbo login --status 2>/dev/null
npx turbo link --status 2>/dev/null

echo ""
echo "=== Cache Configuration ==="
cat turbo.json 2>/dev/null | jq '{remoteCache: .remoteCache}' 2>/dev/null
```

## Safety Rules

- **Never disable caching** without understanding downstream impact on build times
- **Test pipeline changes** on a feature branch before merging to main
- **Remote cache tokens** should be stored in CI secrets, never in turbo.json
- **Validate task dependencies** after adding new packages to prevent missing builds

## Output Format

Present results as a structured report:
```
Managing Turborepo Report
═════════════════════════
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

