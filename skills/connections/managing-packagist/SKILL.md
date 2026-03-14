---
name: managing-packagist
description: |
  Packagist PHP package registry management. Covers Composer package publishing, version management, autoloading configuration, dependency resolution, and package metadata. Use when managing PHP packages on Packagist, configuring Composer repositories, resolving dependency conflicts, or analyzing package health.
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
