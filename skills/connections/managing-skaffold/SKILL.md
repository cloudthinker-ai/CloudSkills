---
name: managing-skaffold
description: |
  Use when working with Skaffold — skaffold continuous development workflow
  management for Kubernetes. Covers dev loop configuration, build/deploy
  profiles, debug mode, file sync, render pipeline, and multi-module projects.
  Use when managing Skaffold development workflows, debugging build failures,
  configuring deploy profiles, or optimizing the inner dev loop.
connection_type: skaffold
preload: false
---

# Skaffold Management Skill

Manage Skaffold dev loops, build/deploy profiles, debugging, and file synchronization.

## Core Helper Functions

```bash
#!/bin/bash

# Skaffold command wrapper
skaffold_cmd() {
    skaffold "$@" 2>/dev/null
}

# Skaffold config parser
skaffold_config() {
    local config_file="${1:-skaffold.yaml}"
    cat "$config_file" 2>/dev/null
}

# Find skaffold configs in project
skaffold_find() {
    find "${1:-.}" -name "skaffold.yaml" -o -name "skaffold.yml" 2>/dev/null | sort
}
```

## MANDATORY: Discovery-First Pattern

**Always examine skaffold configuration and profiles before running dev/build/deploy.**

### Phase 1: Discovery

```bash
#!/bin/bash
PROJECT_DIR="${1:-.}"

echo "=== Skaffold Version ==="
skaffold version 2>/dev/null

echo ""
echo "=== Skaffold Config Files ==="
find "$PROJECT_DIR" -name "skaffold.yaml" -o -name "skaffold.yml" 2>/dev/null | sort

echo ""
echo "=== Config Overview ==="
CONFIG="${PROJECT_DIR}/skaffold.yaml"
if [ -f "$CONFIG" ]; then
    echo "API Version: $(grep "^apiVersion:" "$CONFIG" | head -1)"
    echo "Kind: $(grep "^kind:" "$CONFIG" | head -1)"
    echo ""
    echo "Build artifacts:"
    grep -A 3 "artifacts:" "$CONFIG" | grep "image:" | sed 's/.*image: /  /' | head -10
    echo ""
    echo "Deploy method:"
    grep -E "^deploy:|kubectl:|helm:|kustomize:" "$CONFIG" | head -5
fi

echo ""
echo "=== Available Profiles ==="
skaffold diagnose -p "" 2>&1 | grep "profile" | head -10 || \
grep -A 2 "^profiles:" "$CONFIG" 2>/dev/null | head -10 || \
grep "name:" "$CONFIG" 2>/dev/null | grep -A0 -B1 "profiles" | head -10
```

## Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- Parse skaffold.yaml with grep/yq for structured analysis
- Never dump full rendered manifests -- summarize build/deploy configuration

## Common Operations

### Dev Loop Configuration Analysis

```bash
#!/bin/bash
CONFIG="${1:-skaffold.yaml}"

echo "=== Build Configuration ==="
grep -A 20 "^build:" "$CONFIG" 2>/dev/null | head -25

echo ""
echo "=== Artifacts ==="
grep -B1 -A 5 "image:" "$CONFIG" 2>/dev/null | head -30

echo ""
echo "=== File Sync Configuration ==="
grep -A 10 "sync:" "$CONFIG" 2>/dev/null | head -15

echo ""
echo "=== Port Forwards ==="
grep -A 10 "portForward:" "$CONFIG" 2>/dev/null | head -15

echo ""
echo "=== Dev Loop Status Check ==="
echo "To start dev loop: skaffold dev [--profile <profile>] [--port-forward]"
echo "To start with debug: skaffold debug [--profile <profile>]"
```

### Build & Deploy Profile Management

```bash
#!/bin/bash
CONFIG="${1:-skaffold.yaml}"

echo "=== All Profiles ==="
# Extract profile names and their key characteristics
python3 -c "
import yaml, sys
with open('$CONFIG') as f:
    cfg = yaml.safe_load(f)
profiles = cfg.get('profiles', [])
for p in profiles:
    build_type = 'default'
    if 'build' in p:
        if 'googleCloudBuild' in p.get('build', {}):
            build_type = 'cloud-build'
        elif 'cluster' in p.get('build', {}):
            build_type = 'in-cluster'
        elif 'local' in p.get('build', {}):
            build_type = 'local'
    deploy_type = 'default'
    if 'deploy' in p:
        if 'kubectl' in p.get('deploy', {}):
            deploy_type = 'kubectl'
        elif 'helm' in p.get('deploy', {}):
            deploy_type = 'helm'
        elif 'kustomize' in p.get('deploy', {}):
            deploy_type = 'kustomize'
    print(f\"{p['name']}\tbuild={build_type}\tdeploy={deploy_type}\")
" 2>/dev/null || grep -A 1 "- name:" "$CONFIG" 2>/dev/null | grep "name:" | sed 's/.*name: //'

echo ""
echo "=== Profile Activation ==="
grep -A 5 "activation:" "$CONFIG" 2>/dev/null | head -15

echo ""
echo "=== Profile Patches ==="
grep -A 10 "patches:" "$CONFIG" 2>/dev/null | head -20
```

### Render & Validate Pipeline

```bash
#!/bin/bash
PROFILE="${1:-}"
CONFIG="${2:-skaffold.yaml}"

echo "=== Render Output (dry-run) ==="
if [ -n "$PROFILE" ]; then
    skaffold render -p "$PROFILE" --digest-source=none 2>/dev/null | grep "^kind:" | sort | uniq -c | sort -rn
else
    skaffold render --digest-source=none 2>/dev/null | grep "^kind:" | sort | uniq -c | sort -rn
fi

echo ""
echo "=== Build Dry-Run ==="
skaffold build --dry-run ${PROFILE:+-p "$PROFILE"} 2>/dev/null | head -15

echo ""
echo "=== Diagnose Configuration ==="
skaffold diagnose ${PROFILE:+-p "$PROFILE"} 2>/dev/null | head -30

echo ""
echo "=== Schema Validation ==="
skaffold fix --overwrite=false 2>&1 | head -10
```

### Debug Mode Configuration

```bash
#!/bin/bash
CONFIG="${1:-skaffold.yaml}"

echo "=== Debug-Capable Artifacts ==="
grep -B2 -A 8 "image:" "$CONFIG" 2>/dev/null | head -30

echo ""
echo "=== Supported Debug Runtimes ==="
echo "  - Go: dlv (Delve)"
echo "  - Java: JDWP"
echo "  - Node.js: --inspect"
echo "  - Python: debugpy/ptvsd"
echo "  - .NET: vsdbg"

echo ""
echo "=== Debug Usage ==="
echo "Start debugging: skaffold debug [--port-forward]"
echo "This automatically configures debug ports and disables health check timeouts"
echo ""
echo "=== Current Port Forwards ==="
grep -A 5 "portForward:" "$CONFIG" 2>/dev/null | head -10

echo ""
echo "=== Custom Actions ==="
grep -A 10 "customActions:" "$CONFIG" 2>/dev/null | head -15
```

### Multi-Module Project Analysis

```bash
#!/bin/bash
PROJECT_DIR="${1:-.}"

echo "=== Skaffold Configs in Project ==="
find "$PROJECT_DIR" -name "skaffold.yaml" -o -name "skaffold.yml" 2>/dev/null | while read cfg; do
    DIR=$(dirname "$cfg")
    ARTIFACTS=$(grep "image:" "$cfg" 2>/dev/null | wc -l | tr -d ' ')
    echo "$DIR: $ARTIFACTS artifacts"
done

echo ""
echo "=== Module Dependencies ==="
grep -A 5 "requires:" "$PROJECT_DIR/skaffold.yaml" 2>/dev/null | head -15

echo ""
echo "=== Shared Config Imports ==="
grep "configs:" "$PROJECT_DIR/skaffold.yaml" 2>/dev/null | head -5

echo ""
echo "=== Build Concurrency ==="
grep "concurrency:" "$PROJECT_DIR/skaffold.yaml" 2>/dev/null || echo "Default concurrency (parallel)"

echo ""
echo "=== Artifact Dependencies ==="
grep -B1 -A 3 "requires:" "$PROJECT_DIR/skaffold.yaml" 2>/dev/null | head -20

echo ""
echo "=== Tag Policy ==="
grep -A 3 "tagPolicy:" "$PROJECT_DIR/skaffold.yaml" 2>/dev/null | head -5
```

## Safety Rules
- **Read-only by default**: Use `skaffold diagnose`, `skaffold render`, `skaffold build --dry-run`
- **Never run** `skaffold dev` or `skaffold run` without explicit user request -- they deploy to clusters
- **Profile awareness**: Always check which profile is active to avoid deploying to wrong environment
- **File sync**: Changes to synced files are applied immediately in dev mode -- be cautious

## Output Format

Present results as a structured report:
```
Managing Skaffold Report
════════════════════════
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
- **API version mismatch**: Run `skaffold fix` to migrate config to latest API version
- **Default repo**: Without `--default-repo`, images push to the configured registry -- may require auth
- **Cleanup on exit**: `skaffold dev` cleans up resources on Ctrl+C -- `skaffold run` does not
- **Build cache**: Skaffold caches builds by default -- use `--cache-artifacts=false` to force rebuild
- **Kustomize path**: When using kustomize deployer, paths must be relative to the skaffold.yaml location
