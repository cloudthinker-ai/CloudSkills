---
name: managing-rubygems
description: |
  RubyGems package registry management. Covers gem publishing, version management, Bundler dependency resolution, gemspec configuration, and security scanning. Use when managing Ruby gems, publishing to RubyGems.org, resolving Bundler conflicts, or auditing gem vulnerabilities.
connection_type: rubygems
preload: false
---

# RubyGems Registry Management Skill

Manage and analyze Ruby gems, Bundler dependencies, and gem publishing.

## MANDATORY: Discovery-First Pattern

**Always check current Gemfile and gemspec configuration before modifying packages.**

### Phase 1: Discovery

```bash
#!/bin/bash

echo "=== Gemspec ==="
cat *.gemspec 2>/dev/null | head -20

echo ""
echo "=== Gemfile ==="
cat Gemfile 2>/dev/null | head -20

echo ""
echo "=== Ruby/Bundler Version ==="
ruby --version 2>/dev/null
bundler --version 2>/dev/null

echo ""
echo "=== Gem Sources ==="
gem sources --list 2>/dev/null
```

### Phase 2: Analysis

```bash
#!/bin/bash

echo "=== Installed Gems ==="
bundle list 2>/dev/null | head -15

echo ""
echo "=== Outdated Gems ==="
bundle outdated 2>/dev/null | head -15

echo ""
echo "=== Security Audit ==="
bundle audit check 2>/dev/null | head -15
```

## Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- List gems with version constraints
- Report audit findings by severity
- Never expose gem credentials in output

## Common Operations

### Gem Lookup

```bash
#!/bin/bash
GEM="${1:?Gem name required}"
echo "=== Gem Info: $GEM ==="
curl -s "https://rubygems.org/api/v1/gems/${GEM}.json" | jq '{
  name: .name,
  version: .version,
  downloads: .downloads,
  info: .info,
  licenses: .licenses
}' 2>/dev/null
```

### Build and Push Preview

```bash
#!/bin/bash
echo "=== Build Gem ==="
gem build *.gemspec 2>&1 | tail -5
ls -la *.gem 2>/dev/null
```

## Safety Rules

- **Never expose RubyGems API keys** in Gemfile or configuration
- **Run `bundle audit`** before deploying to catch known vulnerabilities
- **Use Gemfile.lock** for applications to ensure reproducible installs
- **Test gem builds** with `gem build` before pushing to RubyGems.org
