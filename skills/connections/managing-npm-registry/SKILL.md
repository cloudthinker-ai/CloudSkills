---
name: managing-npm-registry
description: |
  npm registry and package management. Covers package publishing, version management, registry configuration, access controls, audit scanning, and dependency analysis. Use when managing npm packages, configuring private registries, auditing vulnerabilities, or analyzing package download metrics.
connection_type: npm-registry
preload: false
---

# npm Registry Management Skill

Manage and analyze npm packages, registries, access controls, and security audits.

## MANDATORY: Discovery-First Pattern

**Always check current npm configuration and registry settings before modifying packages.**

### Phase 1: Discovery

```bash
#!/bin/bash

echo "=== npm Configuration ==="
npm config list 2>/dev/null | head -15

echo ""
echo "=== Registry Settings ==="
npm config get registry 2>/dev/null
cat .npmrc 2>/dev/null | grep -v '//.*:_authToken' | head -10

echo ""
echo "=== Package Info ==="
cat package.json 2>/dev/null | jq '{
  name: .name,
  version: .version,
  private: .private,
  publishConfig: .publishConfig
}' 2>/dev/null

echo ""
echo "=== npm Version ==="
npm --version 2>/dev/null
```

### Phase 2: Analysis

```bash
#!/bin/bash

echo "=== Security Audit ==="
npm audit --json 2>/dev/null | jq '{
  total: .metadata.totalDependencies,
  vulnerabilities: .metadata.vulnerabilities
}' 2>/dev/null

echo ""
echo "=== Outdated Packages ==="
npm outdated --json 2>/dev/null | jq 'to_entries | map({
  package: .key,
  current: .value.current,
  wanted: .value.wanted,
  latest: .value.latest
}) | .[0:10]' 2>/dev/null

echo ""
echo "=== Dependency Tree Depth ==="
npm ls --all --depth=0 2>/dev/null | tail -5
```

## Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- Summarize audit results by severity
- List outdated packages with version gaps
- Never expose auth tokens in output

## Common Operations

### Package Info Lookup

```bash
#!/bin/bash
PACKAGE="${1:?Package name required}"
echo "=== Package Info: $PACKAGE ==="
npm view "$PACKAGE" --json 2>/dev/null | jq '{
  name: .name,
  version: .version,
  description: .description,
  license: .license,
  downloads: .downloads,
  maintainers: [.maintainers[]?.name]
}' 2>/dev/null
```

### Publish Dry Run

```bash
#!/bin/bash
echo "=== Publish Preview ==="
npm publish --dry-run 2>&1 | head -20
npm pack --dry-run 2>&1 | head -15
```

## Safety Rules

- **Never expose npm tokens** in logs or .npmrc files committed to git
- **Use `npm publish --dry-run`** before actual publishing
- **Review `npm audit`** results before deploying to production
- **Use scoped packages** for private packages to avoid name squatting
