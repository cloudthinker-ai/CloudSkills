---
name: managing-packagist
description: |
  Use when working with Packagist — packagist PHP package registry management.
  Covers Composer package publishing, version management, autoloading
  configuration, dependency resolution, and package metadata. Use when managing
  PHP packages on Packagist, configuring Composer repositories, resolving
  dependency conflicts, or analyzing package health.
connection_type: packagist
preload: false
---

# Packagist Registry Management Skill

Manage and analyze PHP packages, Composer dependencies, and Packagist publishing.

## MANDATORY: Discovery-First Pattern

**Always check current composer.json configuration before modifying packages.**

### Phase 1: Discovery

```bash
#!/bin/bash

echo "=== Composer Configuration ==="
cat composer.json 2>/dev/null | jq '{
  name: .name,
  type: .type,
  license: .license,
  require: (.require | keys | length),
  "require-dev": (."require-dev" | keys | length)
}' 2>/dev/null

echo ""
echo "=== Composer Version ==="
composer --version 2>/dev/null

echo ""
echo "=== Repository Sources ==="
cat composer.json 2>/dev/null | jq '.repositories' 2>/dev/null
```

### Phase 2: Analysis

```bash
#!/bin/bash

echo "=== Installed Packages ==="
composer show --format=json 2>/dev/null | jq '{
  total: (.installed | length),
  packages: [.installed[:10][] | {name: .name, version: .version}]
}' 2>/dev/null

echo ""
echo "=== Outdated Packages ==="
composer outdated --format=json 2>/dev/null | jq '[.installed[:10][] | {
  name: .name,
  current: .version,
  latest: .latest
}]' 2>/dev/null

echo ""
echo "=== Security Audit ==="
composer audit --format=json 2>/dev/null | jq '{
  total: (.advisories | length),
  advisories: [.advisories | to_entries[:5][] | {package: .key, count: (.value | length)}]
}' 2>/dev/null
```

## Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- Summarize dependency counts by type (require vs require-dev)
- List outdated packages with version gaps
- Report security advisories by package

## Common Operations

### Package Lookup

```bash
#!/bin/bash
PACKAGE="${1:?Package name required (vendor/name)}"
echo "=== Packagist: $PACKAGE ==="
curl -s "https://repo.packagist.org/p2/${PACKAGE}.json" | jq '{
  name: .packages[][0].name,
  version: .packages[][0].version,
  description: .packages[][0].description
}' 2>/dev/null
```

### Validate and Check

```bash
#!/bin/bash
echo "=== Validate composer.json ==="
composer validate 2>&1 | head -10

echo ""
echo "=== Check Platform Requirements ==="
composer check-platform-reqs 2>/dev/null | head -10
```

## Safety Rules

- **Run `composer validate`** before publishing packages
- **Use `composer.lock`** in applications for reproducible installs
- **Never commit auth.json** with Packagist credentials to repositories
- **Review security advisories** with `composer audit` before deploying

## Output Format

Present results as a structured report:
```
Managing Packagist Report
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

