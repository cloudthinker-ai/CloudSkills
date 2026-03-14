---
name: managing-crates-io
description: |
  crates.io Rust package registry management. Covers crate publishing, version management, dependency resolution, feature flags, build configurations, and crate metadata analysis. Use when managing Rust crates, publishing to crates.io, analyzing dependency trees, or configuring feature flags.
connection_type: crates-io
preload: false
---

# crates.io Registry Management Skill

Manage and analyze Rust crates, publishing, dependencies, and feature configurations.

## MANDATORY: Discovery-First Pattern

**Always check current Cargo.toml configuration before modifying crate settings.**

### Phase 1: Discovery

```bash
#!/bin/bash

echo "=== Crate Configuration ==="
cat Cargo.toml 2>/dev/null | head -25

echo ""
echo "=== Workspace Members ==="
grep -A20 '\[workspace\]' Cargo.toml 2>/dev/null | grep 'members' -A10 | head -12

echo ""
echo "=== Rust Toolchain ==="
rustc --version 2>/dev/null
cargo --version 2>/dev/null
cat rust-toolchain.toml 2>/dev/null | head -5
```

### Phase 2: Analysis

```bash
#!/bin/bash

echo "=== Dependency Tree ==="
cargo tree --depth=1 2>/dev/null | head -20

echo ""
echo "=== Outdated Dependencies ==="
cargo outdated 2>/dev/null | head -15

echo ""
echo "=== Security Audit ==="
cargo audit 2>/dev/null | tail -15
```

## Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- Summarize dependency trees at depth 1
- Report audit findings by severity
- List feature flags with their dependencies

## Common Operations

### Crate Lookup

```bash
#!/bin/bash
CRATE="${1:?Crate name required}"
echo "=== Crate Info: $CRATE ==="
curl -s "https://crates.io/api/v1/crates/${CRATE}" | jq '{
  name: .crate.name,
  max_version: .crate.max_version,
  downloads: .crate.downloads,
  description: .crate.description,
  repository: .crate.repository
}' 2>/dev/null
```

### Publish Dry Run

```bash
#!/bin/bash
echo "=== Publish Preview ==="
cargo publish --dry-run 2>&1 | tail -15
cargo package --list 2>/dev/null | head -15
```

## Safety Rules

- **Use `cargo publish --dry-run`** before actual publishing
- **Run `cargo audit`** before releases to catch known vulnerabilities
- **Never yank crate versions** without publishing a fix first
- **Review feature flag combinations** for compile-time correctness
