---
name: managing-hex-pm
description: |
  Hex.pm Elixir/Erlang package registry management. Covers package publishing, dependency resolution, Mix configuration, Hex organization management, and package metadata. Use when managing Hex packages, publishing Elixir/Erlang libraries, resolving Mix dependency conflicts, or auditing package security.
connection_type: hex-pm
preload: false
---

# Hex.pm Registry Management Skill

Manage and analyze Elixir/Erlang packages, Hex publishing, and Mix dependencies.

## MANDATORY: Discovery-First Pattern

**Always check current mix.exs configuration before modifying packages.**

### Phase 1: Discovery

```bash
#!/bin/bash

echo "=== Mix Project ==="
cat mix.exs 2>/dev/null | head -25

echo ""
echo "=== Hex Info ==="
mix hex.info 2>/dev/null | head -10

echo ""
echo "=== Elixir/Erlang Version ==="
elixir --version 2>/dev/null | head -3
```

### Phase 2: Analysis

```bash
#!/bin/bash

echo "=== Dependencies ==="
mix deps 2>/dev/null | head -15

echo ""
echo "=== Outdated Deps ==="
mix hex.outdated 2>/dev/null | head -15

echo ""
echo "=== Dependency Tree ==="
mix deps.tree --depth=1 2>/dev/null | head -20

echo ""
echo "=== Security Audit ==="
mix hex.audit 2>/dev/null | head -10
```

## Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- List dependencies with version constraints
- Report outdated packages with available versions
- Never expose Hex API keys in output

## Common Operations

### Package Lookup

```bash
#!/bin/bash
PACKAGE="${1:?Package name required}"
echo "=== Hex Package: $PACKAGE ==="
curl -s "https://hex.pm/api/packages/${PACKAGE}" | jq '{
  name: .name,
  latest: .releases[0].version,
  downloads: .downloads.all,
  description: .meta.description,
  licenses: .meta.licenses
}' 2>/dev/null
```

### Publish Preview

```bash
#!/bin/bash
echo "=== Publish Preview ==="
mix hex.publish --dry-run 2>&1 | tail -15
```

## Safety Rules

- **Use `mix hex.publish --dry-run`** before publishing
- **Run `mix hex.audit`** to check for retired packages
- **Lock dependency versions** with mix.lock for reproducible builds
- **Never commit Hex API keys** to version control
